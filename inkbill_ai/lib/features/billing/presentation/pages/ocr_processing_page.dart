import 'dart:async';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:inkbill_ai/core/theme/app_theme.dart';
import 'package:inkbill_ai/features/ai/presentation/providers/recognition_provider.dart';
import 'package:inkbill_ai/features/billing/presentation/pages/recognized_bill_page.dart';
import 'package:inkbill_ai/features/ai/domain/entities/recognition_result.dart';
import 'package:inkbill_ai/services/recognition/recognition_logger.dart';
import 'package:inkbill_ai/features/billing/presentation/pages/ocr_diagnostics_page.dart';

enum _OcrState { processing, success, error, timeout, cancelled }

class OcrProcessingPage extends ConsumerStatefulWidget {
  final Uint8List imageBytes;
  final String pageId;

  const OcrProcessingPage({
    super.key,
    required this.imageBytes,
    required this.pageId,
  });

  @override
  ConsumerState<OcrProcessingPage> createState() => _OcrProcessingPageState();
}

class _OcrProcessingPageState extends ConsumerState<OcrProcessingPage>
    with SingleTickerProviderStateMixin {
  _OcrState _state = _OcrState.processing;
  String _statusText = 'Starting recognition...';
  String _errorMessage = '';
  String _rawText = '';
  late TextEditingController _textCtrl;
  bool _recognitionDone = false;
  bool _cancelled = false;
  double _progressValue = 0.0;

  @override
  void initState() {
    super.initState();
    RecognitionLogger.stage('OCR_PAGE', 'OcrProcessingPage opened');
    _textCtrl = TextEditingController();
    _startProcessing();
  }

  @override
  void dispose() {
    _textCtrl.dispose();
    if (!_recognitionDone) {
      RecognitionLogger.log('OCR page disposed while recognition active');
    }
    super.dispose();
  }

  void _startProcessing() {
    setState(() {
      _state = _OcrState.processing;
      _cancelled = false;
      _recognitionDone = false;
      _errorMessage = '';
      _progressValue = 0.0;
      _statusText = 'Analyzing handwriting...';
    });

    _runProgressAnimation();
    _runRecognition();
  }

  void _runProgressAnimation() async {
    while (!_recognitionDone && mounted && !_cancelled) {
      await Future.delayed(const Duration(milliseconds: 200));
      if (!mounted || _recognitionDone || _cancelled) break;
      setState(() {
        _progressValue = (_progressValue + 0.02).clamp(0.0, 0.85);
        if (_progressValue < 0.25) {
          _statusText = 'Analyzing handwriting...';
        } else if (_progressValue < 0.5) {
          _statusText = 'Detecting text layout...';
        } else {
          _statusText = 'Extracting bill items...';
        }
      });
    }
  }

  void _cancelRecognition() {
    _cancelled = true;
    _recognitionDone = true;
    try {
      final service = ref.read(recognitionServiceProvider);
      service.cancel();
    } catch (_) {}
    RecognitionLogger.log('Recognition cancelled by user');
  }

  Future<void> _runRecognition() async {
    try {
      final pngBytes = widget.imageBytes;

      print("====================");
      print("OCR Input Size: ${pngBytes.length}");
      print("====================");

      final service = ref.read(recognitionServiceProvider);

      if (!service.isReady) {
        RecognitionLogger.log(
            'OCR page: service not ready, calling ensureReady...');
        try {
          await service.ensureReady();
        } catch (e) {
          if (!mounted || _cancelled) return;
          _recognitionDone = true;
          setState(() {
            _state = _OcrState.error;
            _errorMessage = 'AI Recognition Engine failed to initialize.\n$e';
            _statusText = 'Initialization failed';
          });
          return;
        }
      }

      await service.recognizeImage(widget.imageBytes);

      if (_cancelled || !mounted) return;

      _recognitionDone = true;

      final billData = service.lastBillResult;

      if (billData != null && billData.failureCode != null) {
        if (mounted) {
          setState(() {
            _state = _OcrState.error;
            _errorMessage = 'Classification: ${billData.failureCode}\n'
                '${billData.warnings.join('\n')}';
            _statusText = billData.failureCode!;
          });
        }
        return;
      }

      if (billData == null || (billData.rawText.isEmpty && billData.lineItems.isEmpty)) {
        if (mounted) {
          setState(() {
            _state = _OcrState.error;
            _errorMessage = 'Classification: OCR_RETURNED_ZERO_BLOCKS\n'
                'No text or blocks were recognized by the OCR engine.';
            _statusText = 'OCR_RETURNED_ZERO_BLOCKS';
          });
        }
        return;
      }

      // TASK 7: Direct Raw OCR Text Output (Bypassing BillParser)
      final rawText = billData.rawText.isNotEmpty
          ? billData.rawText
          : billData.lineItems.map((e) => e.name).join('\n');

      if (mounted) {
        setState(() {
          _state = _OcrState.success;
          _rawText = rawText;
          _textCtrl.text = rawText;
          _progressValue = 1.0;
          _statusText = 'Raw OCR Complete (${billData.recognizerName})';
        });
        RecognitionLogger.stage(
            'OCR_PAGE', 'Raw Text Success: ${rawText.length} chars');
      }
    } catch (e, stack) {
      if (!mounted || _cancelled) return;
      _recognitionDone = true;
      RecognitionLogger.error('OCR_PAGE _runRecognition', e, stack);
      setState(() {
        _state = _OcrState.error;
        _errorMessage = 'An unexpected error occurred:\n$e';
        _statusText = 'Error';
      });
    }
  }

  void _convertToBill() {
    final items = _rawText
        .split('\n')
        .where((l) => l.trim().isNotEmpty)
        .map<LineItemData>((line) {
      return LineItemData(
        name: line.trim(),
        confidence: 1.0,
      );
    }).toList();

    Navigator.of(context).pushReplacement(
      MaterialPageRoute(
        builder: (_) => RecognizedBillPage(
          items: items,
          sourcePageId: widget.pageId,
          confidence: 1.0,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: Text(_appBarTitle),
        backgroundColor: Colors.white,
        foregroundColor: AppTheme.primaryColor,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            _cancelRecognition();
            Navigator.of(context).pop();
          },
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.bug_report),
            tooltip: 'OCR Diagnostics',
            onPressed: () {
              final service = ref.read(recognitionServiceProvider);
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => OcrDiagnosticsPage(
                    lastResult: service.lastBillResult,
                  ),
                ),
              );
            },
          ),
          if (_state == _OcrState.success)
            IconButton(
              icon: const Icon(Icons.close),
              onPressed: () {
                _cancelRecognition();
                Navigator.of(context).pop();
              },
            ),
        ],
      ),
      body: _buildBody(),
    );
  }

  String get _appBarTitle {
    switch (_state) {
      case _OcrState.processing:
        return 'Processing';
      case _OcrState.success:
        return 'Review OCR';
      case _OcrState.error:
        return 'Recognition Failed';
      case _OcrState.timeout:
        return 'Timed Out';
      case _OcrState.cancelled:
        return 'Cancelled';
    }
  }

  Widget _buildBody() {
    switch (_state) {
      case _OcrState.processing:
        return _buildProcessing();
      case _OcrState.success:
        return _buildPreview();
      case _OcrState.error:
      case _OcrState.timeout:
      case _OcrState.cancelled:
        return _buildError();
    }
  }

  Widget _buildProcessing() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            SizedBox(
              width: 120,
              height: 120,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  SizedBox(
                    width: 80,
                    height: 80,
                    child: CircularProgressIndicator(
                      value: _progressValue > 0 ? _progressValue : null,
                      strokeWidth: 4,
                      color: AppTheme.primaryColor,
                      backgroundColor: Colors.grey.shade200,
                    ),
                  ),
                  const Icon(
                    Icons.document_scanner,
                    size: 36,
                    color: AppTheme.primaryColor,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 32),
            Text(
              _statusText,
              style: const TextStyle(
                fontSize: 16,
                color: Colors.black87,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'This should take a few seconds',
              style: TextStyle(
                fontSize: 13,
                color: Colors.grey.shade500,
              ),
            ),
            const SizedBox(height: 32),
            OutlinedButton.icon(
              onPressed: () {
                _cancelRecognition();
                Navigator.of(context).pop();
              },
              icon: const Icon(Icons.close, size: 18),
              label: const Text('Cancel'),
              style: OutlinedButton.styleFrom(
                foregroundColor: Colors.red.shade400,
                side: BorderSide(color: Colors.red.shade200),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPreview() {
    return Column(
      children: [
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade50,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.grey.shade200),
                  ),
                  child: TextField(
                    controller: _textCtrl,
                    maxLines: null,
                    style: const TextStyle(fontSize: 15, height: 1.5),
                    decoration: const InputDecoration(
                      contentPadding: EdgeInsets.all(16),
                      border: InputBorder.none,
                      hintText: 'Edit recognized text...',
                    ),
                    onChanged: (v) => _rawText = v,
                  ),
                ),
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF0FDF4),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: const Color(0xFF86EFAC)),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.info_outline,
                          size: 18, color: Color(0xFF16A34A)),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Edit the text above, then tap "Convert to Bill" to review structured bill items.',
                          style: TextStyle(
                            fontSize: 13,
                            color: Colors.green.shade800,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surface,
            border: Border(top: BorderSide(color: Colors.grey.shade200)),
          ),
          child: SafeArea(
            top: false,
            child: Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    icon: const Icon(Icons.refresh, size: 18),
                    label: const Text('Retry'),
                    onPressed: () {
                      final service = ref.read(recognitionServiceProvider);
                      service.retry();
                      _startProcessing();
                    },
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.orange.shade700,
                      side: BorderSide(color: Colors.orange.shade200),
                      minimumSize: const Size(0, 48),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  flex: 2,
                  child: OutlinedButton.icon(
                    icon: const Icon(Icons.close, size: 18),
                    label: const Text('Back to Canvas'),
                    onPressed: () {
                      _cancelRecognition();
                      Navigator.of(context).pop();
                    },
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.grey.shade700,
                      side: BorderSide(color: Colors.grey.shade300),
                      minimumSize: const Size(0, 48),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  flex: 2,
                  child: FilledButton.icon(
                    icon: const Icon(Icons.receipt_long, size: 18),
                    label: const Text('Convert to Bill'),
                    onPressed:
                        _rawText.trim().isEmpty ? null : _convertToBill,
                    style: FilledButton.styleFrom(
                      minimumSize: const Size(0, 48),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildError() {
    final String displayMessage;
    final String displayTitle;
    final IconData icon;

    switch (_state) {
      case _OcrState.timeout:
        displayTitle = 'Recognition Timed Out';
        displayMessage =
            'Recognition took longer than expected.\nPlease try again.';
        icon = Icons.timer_off;
      case _OcrState.cancelled:
        displayTitle = 'Recognition Cancelled';
        displayMessage =
            'The recognition was cancelled.\nTap Retry to try again.';
        icon = Icons.cancel_outlined;
      case _OcrState.error:
        displayTitle = 'Unable to Recognize';
        displayMessage = _errorMessage.isNotEmpty
            ? _errorMessage
            : 'The AI model encountered an error.\nPlease try again.';
        icon = Icons.error_outline;
      default:
        displayTitle = 'Error';
        displayMessage = 'An unexpected error occurred.';
        icon = Icons.error_outline;
    }

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 64, color: Colors.red.shade400),
            const SizedBox(height: 16),
            Text(
              displayTitle,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: Colors.black87,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              displayMessage,
              style: const TextStyle(fontSize: 14, color: Colors.red),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            FilledButton.icon(
              onPressed: () {
                final service = ref.read(recognitionServiceProvider);
                service.retry();
                _startProcessing();
              },
              icon: const Icon(Icons.refresh),
              label: const Text('Retry'),
            ),
            const SizedBox(height: 8),
            TextButton(
              onPressed: () {
                _cancelRecognition();
                Navigator.of(context).pop();
              },
              child: const Text('Back to Canvas'),
            ),
          ],
        ),
      ),
    );
  }
}
