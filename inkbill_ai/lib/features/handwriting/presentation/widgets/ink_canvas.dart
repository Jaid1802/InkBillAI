import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:inkbill_ai/features/handwriting/domain/entities/ink_stroke.dart';
import 'package:inkbill_ai/features/handwriting/presentation/providers/ink_engine_provider.dart';
import 'package:inkbill_ai/services/ink_engine/stroke_renderer.dart';

class InkCanvas extends ConsumerStatefulWidget {
  final String pageId;
  final double width;
  final double height;

  const InkCanvas({
    super.key,
    required this.pageId,
    this.width = double.infinity,
    this.height = double.infinity,
  });

  @override
  ConsumerState<InkCanvas> createState() => _InkCanvasState();
}

class _InkCanvasState extends ConsumerState<InkCanvas>
    with SingleTickerProviderStateMixin {
  final StrokeRenderer _renderer = StrokeRenderer();
  late AnimationController _animController;
  bool _isDrawing = false;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 1),
    )..addListener(() => setState(() {}));
    _animController.repeat();
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

  void _onPointerDown(PointerDownEvent event) {
    final engine = ref.read(inkEngineProvider(widget.pageId));
    final renderBox = context.findRenderObject() as RenderBox;
    final localPos = renderBox.globalToLocal(event.position);

    engine.beginStroke(
      localPos.dx,
      localPos.dy,
      pressure: event.pressure,
      tiltX: 0.0,
      tiltY: 0.0,
      timestampMs: event.timeStamp.inMilliseconds,
    );
    _isDrawing = true;
  }

  void _onPointerMove(PointerMoveEvent event) {
    if (!_isDrawing) return;
    final engine = ref.read(inkEngineProvider(widget.pageId));
    final renderBox = context.findRenderObject() as RenderBox;
    final localPos = renderBox.globalToLocal(event.position);

    engine.updateStroke(
      localPos.dx,
      localPos.dy,
      pressure: event.pressure,
      tiltX: 0.0,
      tiltY: 0.0,
      timestampMs: event.timeStamp.inMilliseconds,
    );
  }

  void _onPointerUp(PointerUpEvent event) {
    if (!_isDrawing) return;
    final engine = ref.read(inkEngineProvider(widget.pageId));
    engine.endStroke(timestampMs: event.timeStamp.inMilliseconds);
    _isDrawing = false;
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(inkEngineStateProvider(widget.pageId));

    return Listener(
      onPointerDown: _onPointerDown,
      onPointerMove: _onPointerMove,
      onPointerUp: _onPointerUp,
      child: CustomPaint(
        size: Size(widget.width, widget.height),
        painter: _InkPainter(
          completedStrokes: state.completedStrokes,
          currentStroke: state.currentStroke,
          renderer: _renderer,
        ),
      ),
    );
  }
}

class _InkPainter extends CustomPainter {
  final List<InkStroke> completedStrokes;
  final InkStroke? currentStroke;
  final StrokeRenderer renderer;

  _InkPainter({
    required this.completedStrokes,
    this.currentStroke,
    required this.renderer,
  });

  @override
  void paint(Canvas canvas, Size size) {
    canvas.clipRect(Rect.fromLTWH(0, 0, size.width, size.height));

    for (final stroke in completedStrokes) {
      renderer.renderStrokeWithPressure(canvas, stroke);
    }

    if (currentStroke != null) {
      renderer.renderStrokeWithPressure(canvas, currentStroke!, isActive: true);
    }
  }

  @override
  bool shouldRepaint(covariant _InkPainter oldDelegate) {
    return oldDelegate.completedStrokes != completedStrokes ||
        oldDelegate.currentStroke != currentStroke;
  }
}
