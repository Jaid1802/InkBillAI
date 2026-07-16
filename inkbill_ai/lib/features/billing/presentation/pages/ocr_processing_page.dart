import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:inkbill_ai/core/theme/app_theme.dart';
import 'package:inkbill_ai/features/ai/presentation/providers/recognition_provider.dart';
import 'package:inkbill_ai/features/handwriting/domain/entities/ink_stroke.dart';
import 'package:inkbill_ai/features/billing/presentation/pages/recognized_bill_page.dart';

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
  bool _isComplete = false;
  bool _hasError = false;
  String _statusText = 'Analyzing strokes...';
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

  Future<void> _startProcessing() async {
    await Future.delayed(const Duration(milliseconds: 500));
    if (!mounted) return;
    setState(() => _statusText = 'Detecting rows...');

    await Future.delayed(const Duration(milliseconds: 600));
    if (!mounted) return;
    setState(() => _statusText = 'Recognizing handwriting...');

    await Future.delayed(const Duration(milliseconds: 400));
    if (!mounted) return;
    setState(() => _statusText = 'Extracting bill items...');

    final pipeline = ref.read(recognitionPipelineProvider);
    final result = await pipeline.extractBillStructure(widget.strokes);

    if (!mounted) return;

    result.when(
      success: (data) {
        setState(() {
          _isComplete = true;
          _progress = 1.0;
        });
        _scanController.stop();
        Future.delayed(const Duration(milliseconds: 400), () {
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
          _statusText = failure.message;
        });
        _scanController.stop();
      },
    );
  }

  @override
  void dispose() {
    _scanController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text('Processing'),
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
                        progress: _scanAnimation.value,
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
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Please wait while we process your handwriting',
                  style: TextStyle(
                    fontSize: 13,
                    color: Colors.grey.shade500,
                  ),
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
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 16),
                FilledButton.icon(
                  onPressed: () {
                    setState(() {
                      _hasError = false;
                      _statusText = 'Retrying...';
                    });
                    _startProcessing();
                  },
                  icon: const Icon(Icons.refresh),
                  label: const Text('Retry'),
                ),
                const SizedBox(height: 8),
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Cancel'),
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
