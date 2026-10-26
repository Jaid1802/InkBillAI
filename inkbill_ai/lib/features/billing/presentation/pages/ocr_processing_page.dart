import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:inkbill_ai/core/theme/app_theme.dart';
import 'package:inkbill_ai/features/ai/presentation/providers/recognition_provider.dart';
import 'package:inkbill_ai/features/handwriting/domain/entities/ink_stroke.dart';
import 'package:inkbill_ai/features/billing/presentation/pages/recognized_bill_page.dart';
import 'package:inkbill_ai/services/recognition/recognition_pipeline.dart';

class OcrProcessingPage extends ConsumerStatefulWidget {
  final List<InkStroke> strokes;
  final String pageId;

  const OcrProcessingPage({
    super.key,
    required this.strokes,
    required this.pageId,
  });

  @override
  ConsumerState<OcrProcessingPage> createState() => _OcrProcessingPageState();
}

class _OcrProcessingPageState extends ConsumerState<OcrProcessingPage>
    with SingleTickerProviderStateMixin {
  late AnimationController _scanController;
  late Animation<double> _scanAnimation;
  RecognitionPipeline? _pipeline;
  Timer? _wakeUpTimer;
  bool _isComplete = false;
  bool _hasError = false;
  String _statusText = 'Analyzing canvas...';
  String _subStatusText = 'Preprocessing handwriting strokes';
  double _progress = 0.0;

  @override
  void initState() {
    super.initState();
    _scanController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2000),
    );
    _scanAnimation = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _scanController, curve: Curves.easeInOut),
    );
    _scanController.repeat(reverse: true);
    _startProcessing();
  }

  String _statusForStage(PipelineStage stage) {
    switch (stage) {
      case PipelineStage.idle:
        return 'Starting recognition...';
      case PipelineStage.preprocessing:
        return 'Preprocessing canvas image...';
      case PipelineStage.layoutAnalysis:
        return 'Analyzing rows and columns...';
      case PipelineStage.recognizing:
        return 'Recognizing handwriting...';
      case PipelineStage.parsing:
        return 'Extracting bill items...';
      case PipelineStage.validating:
        return 'Validating line items...';
      case PipelineStage.enhancing:
        return 'Polishing results...';
      case PipelineStage.complete:
        return 'Handwriting recognized!';
      case PipelineStage.error:
        return 'Recognition failed';
    }
  }

  void _onPipelineChanged() {
    if (!mounted || _pipeline == null) return;
    final state = _pipeline!.value;
    setState(() {
      _progress = state.progress;
      if (state.stage == PipelineStage.error) {
        _hasError = true;
        _wakeUpTimer?.cancel();
        _statusText = _formatFriendlyErrorMessage(state.error);
        _subStatusText = 'Tap Retry to try again or check your connection.';
        _scanController.stop();
      } else {
        _statusText = _statusForStage(state.stage);
      }
    });
  }

  String _formatFriendlyErrorMessage(String? rawError) {
    if (rawError == null || rawError.isEmpty) {
      return 'Recognition failed. Please try again.';
    }
    final lower = rawError.toLowerCase();
    if (lower.contains('401') || lower.contains('authentication')) {
      return 'Authentication failed: Invalid OCR API Key. Please verify your settings.';
    }
    if (lower.contains('timeout') || lower.contains('timed out')) {
      return 'Server wake-up timed out. The server is spinning up from idle state. Please tap Retry.';
    }
    if (lower.contains('socket') || lower.contains('internet') || lower.contains('connect')) {
      return 'Unable to reach OCR backend. Please check your internet connection.';
    }
    if (lower.contains('no handwriting') || lower.contains('no text')) {
      return 'No handwriting detected on canvas. Please write clearly and try again.';
    }
    return rawError;
  }

  Future<void> _startProcessing() async {
    _wakeUpTimer?.cancel();
    setState(() {
      _hasError = false;
      _isComplete = false;
      _statusText = 'Preparing recognition...';
      _subStatusText = 'Please wait while we process your handwriting';
    });

    if (!_scanController.isAnimating) {
      _scanController.repeat(reverse: true);
    }

    final pipeline = ref.read(recognitionPipelineProvider);
    _pipeline = pipeline;
    pipeline.removeListener(_onPipelineChanged);
    pipeline.addListener(_onPipelineChanged);

    _onPipelineChanged();

    // If server takes more than 4 seconds, inform the user about free-tier wake-up
    _wakeUpTimer = Timer(const Duration(seconds: 4), () {
      if (mounted && !_isComplete && !_hasError) {
        setState(() {
          _statusText = 'Waking up server...';
          _subStatusText = 'Render free instances take ~60s on cold start. Hanging tight!';
        });
      }
    });

    final result = await pipeline.extractBillStructure(
      widget.strokes,
      autoEnhance: true,
    );

    _wakeUpTimer?.cancel();
    if (!mounted) return;

    result.when(
      success: (data) {
        setState(() {
          _isComplete = true;
          _progress = 1.0;
          _statusText = 'Handwriting recognized!';
          _subStatusText = 'Redirecting to bill review...';
        });
        _scanController.stop();
        Future.delayed(const Duration(milliseconds: 300), () {
          if (mounted) {
            Navigator.of(context).pushReplacement(
              MaterialPageRoute(
                builder: (_) => RecognizedBillPage(
                  items: data.lineItems,
                  sourcePageId: widget.pageId,
                  confidence: data.confidence,
                ),
              ),
            );
          }
        });
      },
      error: (failure) {
        setState(() {
          _hasError = true;
          _statusText = _formatFriendlyErrorMessage(failure.message);
          _subStatusText = 'Tap Retry to try again.';
        });
        _scanController.stop();
      },
    );
  }

  @override
  void dispose() {
    _wakeUpTimer?.cancel();
    _pipeline?.removeListener(_onPipelineChanged);
    _scanController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text('Processing Handwriting'),
        backgroundColor: Colors.white,
        foregroundColor: AppTheme.primaryColor,
        elevation: 0,
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (!_isComplete && !_hasError) ...[
                SizedBox(
                  width: 120,
                  height: 120,
                  child: CustomPaint(
                    painter: _ScanLinePainter(
                      animation: _scanAnimation.value,
                      progress: _progress,
                    ),
                    child: const Center(
                      child: Icon(
                        Icons.document_scanner,
                        size: 48,
                        color: AppTheme.primaryColor,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 32),
                AnimatedBuilder(
                  animation: _scanAnimation,
                  builder: (context, child) {
                    return CustomPaint(
                      size: const Size(200, 4),
                      painter: _ProgressBarPainter(
                        progress: _progress > 0 ? _progress : _scanAnimation.value,
                      ),
                    );
                  },
                ),
                const SizedBox(height: 24),
                Text(
                  _statusText,
                  style: const TextStyle(
                    fontSize: 16,
                    color: Colors.black87,
                    fontWeight: FontWeight.w600,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),
                Text(
                  _subStatusText,
                  style: TextStyle(
                    fontSize: 13,
                    color: Colors.grey.shade600,
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
              if (_isComplete) ...[
                const Icon(
                  Icons.check_circle,
                  size: 64,
                  color: Color(0xFF0D9488),
                ),
                const SizedBox(height: 16),
                const Text(
                  'Handwriting recognized!',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF0D9488),
                  ),
                ),
              ],
              if (_hasError) ...[
                const Icon(
                  Icons.error_outline,
                  size: 64,
                  color: Colors.red,
                ),
                const SizedBox(height: 16),
                Text(
                  _statusText,
                  style: const TextStyle(
                    fontSize: 16,
                    color: Colors.red,
                    fontWeight: FontWeight.w600,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),
                Text(
                  _subStatusText,
                  style: TextStyle(
                    fontSize: 13,
                    color: Colors.grey.shade600,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 24),
                FilledButton.icon(
                  onPressed: () {
                    _startProcessing();
                  },
                  icon: const Icon(Icons.refresh),
                  label: const Text('Retry'),
                  style: FilledButton.styleFrom(
                    minimumSize: const Size(160, 48),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Cancel & Return to Canvas'),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _ScanLinePainter extends CustomPainter {
  final double animation;
  final double progress;

  _ScanLinePainter({required this.animation, required this.progress});

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Rect.fromLTWH(0, 0, size.width, size.height);
    final paint = Paint()
      ..color = AppTheme.primaryColor.withValues(alpha: 0.1)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;

    canvas.drawRRect(
      RRect.fromRectAndRadius(rect, const Radius.circular(16)),
      paint,
    );

    final scanY = animation * size.height;
    final scanPaint = Paint()
      ..color = AppTheme.primaryColor.withValues(alpha: 0.3)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;
    canvas.drawLine(
      Offset(0, scanY),
      Offset(size.width, scanY),
      scanPaint,
    );
  }

  @override
  bool shouldRepaint(covariant _ScanLinePainter oldDelegate) =>
      oldDelegate.animation != animation || oldDelegate.progress != progress;
}

class _ProgressBarPainter extends CustomPainter {
  final double progress;

  _ProgressBarPainter({required this.progress});

  @override
  void paint(Canvas canvas, Size size) {
    final bgPaint = Paint()
      ..color = Colors.grey.shade200
      ..style = PaintingStyle.fill;
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(0, 0, size.width, size.height),
        const Radius.circular(2),
      ),
      bgPaint,
    );

    final fgPaint = Paint()
      ..color = AppTheme.primaryColor
      ..style = PaintingStyle.fill;
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(0, 0, size.width * progress, size.height),
        const Radius.circular(2),
      ),
      fgPaint,
    );
  }

  @override
  bool shouldRepaint(covariant _ProgressBarPainter oldDelegate) =>
      oldDelegate.progress != progress;
}
