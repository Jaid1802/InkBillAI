import 'dart:async';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:scribble/scribble.dart';
import 'package:inkbill_ai/features/ink/handwriting_engine/scribble_adapter/ink_controller.dart';
import 'package:inkbill_ai/features/ink/handwriting_engine/export_engine/canvas_exporter.dart';
import 'package:inkbill_ai/features/ink/ui/toolbar/ink_toolbar.dart';
import 'package:inkbill_ai/features/ink/ui/settings_panel/pen_settings_panel.dart';
import 'package:inkbill_ai/features/ink/ui/common/nav_button.dart';
import 'package:inkbill_ai/features/billing/presentation/pages/ocr_processing_page.dart';
import 'package:inkbill_ai/features/billing/presentation/pages/ml_model_lab_page.dart';
import 'package:inkbill_ai/features/billing/presentation/pages/canvas_state_inspector_page.dart';
import 'package:inkbill_ai/services/recognition/stroke_bitmap_renderer.dart';
import 'package:inkbill_ai/core/theme/app_theme.dart';
import 'package:inkbill_ai/services/recognition/recognition_logger.dart';

class InkCanvasScreen extends ConsumerStatefulWidget {
  final String? pageId;

  const InkCanvasScreen({super.key, this.pageId});

  @override
  ConsumerState<InkCanvasScreen> createState() => _InkCanvasScreenState();
}

class _InkCanvasScreenState extends ConsumerState<InkCanvasScreen>
    with TickerProviderStateMixin {
  late final TransformationController _transformCtrl;
  late final AnimationController _scrollAnimCtrl;
  late final String _pageId;

  bool _isMenuOpen = false;
  bool _isRecognizing = false;
  Timer? _longPressTimer;

  static const double _canvasWidth = 5000;
  static const double _canvasHeight = 5000;
  static const double _scrollAmount = 200.0;

  @override
  void initState() {
    super.initState();
    _pageId = widget.pageId ??
        'page_${DateTime.now().microsecondsSinceEpoch}';
    _transformCtrl = TransformationController();
    _scrollAnimCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 250),
    );
  }

  @override
  void dispose() {
    _transformCtrl.dispose();
    _scrollAnimCtrl.dispose();
    _longPressTimer?.cancel();
    super.dispose();
  }

  void _scrollBy(double dy) {
    _scrollAnimCtrl.stop();
    _scrollAnimCtrl.reset();
    final currentY = _transformCtrl.value.getTranslation().y;
    final targetY = currentY + dy;

    _scrollAnimCtrl.addListener(() {
      if (!_scrollAnimCtrl.isAnimating) return;
      final y = currentY + (targetY - currentY) * _scrollAnimCtrl.value;
      final m = Matrix4.identity()..setTranslationRaw(0, y, 0);
      _transformCtrl.value = m;
    });
    _scrollAnimCtrl.forward();
  }

  void _startContinuousScroll(double dy) {
    _longPressTimer?.cancel();
    _longPressTimer =
        Timer.periodic(const Duration(milliseconds: 30), (_) {
      if (!mounted) return;
      final currentY = _transformCtrl.value.getTranslation().y;
      final m = Matrix4.identity()
        ..setTranslationRaw(0, currentY + dy * 0.3, 0);
      _transformCtrl.value = m;
    });
  }

  void _stopContinuousScroll() {
    _longPressTimer?.cancel();
    _longPressTimer = null;
  }

  Future<void> _recognize() async {
    if (_isRecognizing) return;
    setState(() => _isRecognizing = true);

    try {
      final controller = ref.read(inkControllerProvider);

      print("====================");
      print("Recognition Starting");
      print("Controller Hash: ${identityHashCode(controller)}");
      print("Stroke Count: ${controller.sketch.lines.length}");
      print("====================");

      final sketch = controller.currentSketch;

      RecognitionLogger.reset();
      RecognitionLogger.stage('CANVAS_HANDOFF', '=== RECOGNITION HANDOFF ===');
      RecognitionLogger.log('controllerId: ${controller.hashCode}');
      RecognitionLogger.log('strokeCount: ${sketch.lines.length}');
      RecognitionLogger.log('canvasSize: ${_canvasWidth}x${_canvasHeight}');
      RecognitionLogger.log('pageId: $_pageId');

      if (sketch.lines.isEmpty) {
        RecognitionLogger.error('CANVAS_HANDOFF', 'CANVAS_STATE_EMPTY: strokeCount == 0');
        _showSnack('Write at least one item before recognizing.');
        return;
      }

      RecognitionLogger.stage('CANVAS', 'Direct Stroke Render Started');

      final Uint8List? pngBytes = await StrokeBitmapRenderer.render(sketch.lines);

      if (pngBytes == null) {
        _showSnack('Failed to generate image from handwriting.');
        return;
      }

      print("====================");
      print("PNG Bytes: ${pngBytes.length}");
      print("====================");

      RecognitionLogger.stage('CANVAS', 'Direct Stroke Render Complete');

      if (!mounted) return;

      await Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => OcrProcessingPage(
            imageBytes: pngBytes,
            pageId: _pageId,
          ),
        ),
      );
    } catch (e, stack) {
      RecognitionLogger.error('InkCanvasScreen._recognize', e, stack);
      if (mounted) {
        _showSnack('An error occurred: $e');
      }
    } finally {
      if (mounted) {
        setState(() => _isRecognizing = false);
      }
    }
  }

  void _showSnack(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  void _clearCanvas() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Clear Canvas'),
        content: const Text(
            'Are you sure you want to clear all handwriting?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              ref.read(inkControllerProvider).clear();
              Navigator.pop(ctx);
            },
            child: const Text('Clear',
                style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final notifier = ref.watch(inkControllerProvider);
    final sketchNotEmpty = notifier.currentSketch.lines.isNotEmpty;
    final screenHeight = MediaQuery.of(context).size.height;

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back,
              color: AppTheme.primaryColor),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: const Text(
          'New Bill',
          style: TextStyle(
            color: AppTheme.primaryColor,
            fontSize: 18,
            fontWeight: FontWeight.w600,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.science, color: AppTheme.primaryColor),
            tooltip: 'ML Model Lab',
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const MlModelLabPage()),
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.analytics, color: AppTheme.primaryColor),
            tooltip: 'Canvas State Inspector',
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const CanvasStateInspectorPage()),
              );
            },
          ),
        ],
      ),
      body: Column(
        children: [
          InkToolbar(
            isMenuOpen: _isMenuOpen,
            onToggleMenu: () =>
                setState(() => _isMenuOpen = !_isMenuOpen),
          ),
          Expanded(
            child: Stack(
              children: [
                Listener(
                  onPointerDown: (_) {
                    if (_isMenuOpen) {
                      setState(() => _isMenuOpen = false);
                    }
                  },
                  child: InteractiveViewer(
                    transformationController: _transformCtrl,
                    minScale: 0.25,
                    maxScale: 3.0,
                    constrained: false,
                    boundaryMargin:
                        const EdgeInsets.all(double.infinity),
                    panEnabled: false,
                    scaleEnabled: false,
                    child: SizedBox(
                      width: _canvasWidth,
                      height: _canvasHeight,
                      child: Stack(
                        children: [
                          CustomPaint(
                            size: const Size(_canvasWidth,
                                _canvasHeight),
                            painter: const _BackgroundPainter(),
                            isComplex: true,
                          ),
                          Scribble(
                            notifier: notifier,
                            drawPen: true,
                            drawEraser: true,
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                if (_isMenuOpen)
                  Positioned(
                    top: 8,
                    left: 16,
                    child: PenSettingsPanel(
                        onClear: _clearCanvas),
                  ),
                Positioned(
                  right: 8,
                  top: 0,
                  bottom: 0,
                  child: Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        NavButton(
                          icon: Icons.keyboard_arrow_up,
                          tooltip: 'Scroll Up',
                          onTap: () =>
                              _scrollBy(-_scrollAmount),
                          onLongPressStart: () =>
                              _startContinuousScroll(
                                  -_scrollAmount),
                          onLongPressEnd:
                              _stopContinuousScroll,
                        ),
                        const SizedBox(height: 8),
                        NavButton(
                          icon: Icons.keyboard_arrow_down,
                          tooltip: 'Scroll Down',
                          onTap: () =>
                              _scrollBy(_scrollAmount),
                          onLongPressStart: () =>
                              _startContinuousScroll(
                                  _scrollAmount),
                          onLongPressEnd:
                              _stopContinuousScroll,
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
          SafeArea(
            top: false,
            child: Container(
              width: double.infinity,
              padding: EdgeInsets.only(
                left: 16,
                right: 16,
                bottom: screenHeight > 600 ? 8 : 4,
                top: 8,
              ),
              decoration: BoxDecoration(
                color: Colors.white,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.06),
                    blurRadius: 8,
                    offset: const Offset(0, -2),
                  ),
                ],
              ),
              child: SizedBox(
                height: 52,
                child: FilledButton.icon(
                  onPressed:
                      sketchNotEmpty && !_isRecognizing
                          ? _recognize
                          : null,
                  icon: _isRecognizing
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : const Icon(Icons.document_scanner,
                          size: 22),
                  label: Text(
                    _isRecognizing
                        ? 'Recognizing...'
                        : 'Recognize Bill',
                    style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600),
                  ),
                  style: FilledButton.styleFrom(
                    backgroundColor: AppTheme.primaryColor,
                    disabledBackgroundColor:
                        Colors.grey.shade300,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius:
                          BorderRadius.circular(26),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _BackgroundPainter extends CustomPainter {
  const _BackgroundPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final bgPaint = Paint()..color = Colors.white;
    canvas.drawRect(
        Rect.fromLTWH(0, 0, size.width, size.height), bgPaint);

    final rulePaint = Paint()
      ..color = Colors.blue.withValues(alpha: 0.06)
      ..strokeWidth = 0.5;
    const lineSpacing = 32.0;
    for (double y = lineSpacing; y < size.height;
        y += lineSpacing) {
      canvas.drawLine(
          Offset(0, y), Offset(size.width, y), rulePaint);
    }

    _drawBillGuides(canvas, size);
  }

  void _drawBillGuides(Canvas canvas, Size size) {
    final guidePaint = Paint()
      ..color = Colors.grey.withValues(alpha: 0.12)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 0.5;

    final textStyle = TextStyle(
      color: Colors.grey.withValues(alpha: 0.4),
      fontSize: 12,
      fontWeight: FontWeight.w500,
    );

    final billWidth = size.width < 800 ? size.width : 800.0;
    final colItem = billWidth * 0.45;
    final colQty = billWidth * 0.15;
    final colRate = billWidth * 0.20;

    double currentX = 0;
    void drawColumnLineAndTitle(String title, double width) {
      if (currentX > 0) {
        canvas.drawLine(Offset(currentX, 0),
            Offset(currentX, size.height), guidePaint);
      }
      final tp = TextPainter(
        text: TextSpan(text: title, style: textStyle),
        textDirection: TextDirection.ltr,
      );
      tp.layout();
      tp.paint(canvas, Offset(currentX + 8, 8));
      currentX += width;
    }

    drawColumnLineAndTitle('Item Name', colItem);
    drawColumnLineAndTitle('Qty', colQty);
    drawColumnLineAndTitle('Rate', colRate);
    drawColumnLineAndTitle('Amount', billWidth - currentX);

    canvas.drawLine(Offset(billWidth, 0),
        Offset(billWidth, size.height), guidePaint);
    canvas.drawLine(
        const Offset(0, 32), Offset(billWidth, 32), guidePaint);
  }

  @override
  bool shouldRepaint(covariant _BackgroundPainter old) => false;
}

extension ScribbleNotifierX on ScribbleNotifier {
  Sketch get sketch => currentSketch;
}

