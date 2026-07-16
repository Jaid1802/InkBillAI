import 'dart:ui' as ui show PointerDeviceKind;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:inkbill_ai/features/handwriting/presentation/providers/canvas_provider.dart';
import 'package:inkbill_ai/services/canvas_engine/canvas_engine.dart';
import 'package:inkbill_ai/services/canvas_engine/canvas_renderer.dart';

class HandwritingCanvas extends ConsumerStatefulWidget {
  final String pageId;

  const HandwritingCanvas({super.key, required this.pageId});

  @override
  ConsumerState<HandwritingCanvas> createState() => _HandwritingCanvasState();
}

class _HandwritingCanvasState extends ConsumerState<HandwritingCanvas>
    with TickerProviderStateMixin {
  final CanvasRenderer _renderer = CanvasRenderer();
  final TransformationController _transformController =
      TransformationController();

  Offset? _eraserPos;
  int _activePointer = -1;
  int _touchDrawPointer = -1;
  bool _isZooming = false;
  double _baseScale = 1.0;
  Offset _lastFocalPoint = Offset.zero;
  bool _showEraserIndicator = false;

  double _canvasHeight = 2000;
  static const double _maxHeight = 20000;
  static const double _growMargin = 600;

  bool get _isErasing => _showEraserIndicator;

  @override
  void dispose() {
    _renderer.dispose();
    _transformController.dispose();
    super.dispose();
  }

  void _growCanvas(double y) {
    final needed = y + _growMargin;
    if (needed > _canvasHeight && _canvasHeight < _maxHeight) {
      setState(
        () => _canvasHeight = (needed + 500).clamp(0, _maxHeight),
      );
    }
  }

  Offset _toCanvasCoords(Offset localPos) {
    final matrix = _transformController.value;
    final inv = Matrix4.inverted(matrix);
    return MatrixUtils.transformPoint(inv, localPos);
  }

  void _onPointerDown(PointerDownEvent e) {
    if (_isZooming) return;

    final engine = ref.read(canvasEngineProvider(widget.pageId));
    final pos = _toCanvasCoords(e.localPosition);
    final isTouch = e.kind == ui.PointerDeviceKind.touch;
    final isStylus = e.kind == ui.PointerDeviceKind.stylus;
    final isMouse = e.kind == ui.PointerDeviceKind.mouse;

    if (_activePointer >= 0) {
      if (isTouch || isMouse) {
        _isZooming = true;
        _baseScale = _transformController.value.getMaxScaleOnAxis();
        _lastFocalPoint = e.localPosition;
      }
      return;
    }

    _activePointer = e.pointer;

    if (isStylus) {
      _touchDrawPointer = -1;
    } else if (isTouch) {
      if (_touchDrawPointer >= 0) return;
      _touchDrawPointer = e.pointer;
    }

    _growCanvas(pos.dy);

    if (engine.value.mode == CanvasMode.erase) {
      setState(() => _showEraserIndicator = true);
      _eraserPos = pos;
      engine.eraseAt(pos.dx, pos.dy, pointerId: e.pointer);
      return;
    }

    engine.beginStroke(
      pos.dx,
      pos.dy,
      pressure: isStylus
          ? e.pressure
          : (isTouch ? e.pressure * 0.8 : 0.5),
      timestampMs: e.timeStamp.inMilliseconds,
      pointerId: e.pointer,
      isStylus: isStylus,
      isEraser: e.kind == ui.PointerDeviceKind.unknown,
    );
  }

  void _onPointerMove(PointerMoveEvent e) {
    if (_isZooming) {
      final focalDelta = e.localPosition - _lastFocalPoint;
      final scale =
          _baseScale * (1.0 + (focalDelta.dy / 300 - focalDelta.dx / 1000));
      final clamped = scale.clamp(0.3, 8.0);
      final newMatrix = Matrix4.identity()
        ..translate(e.localPosition.dx, e.localPosition.dy)
        ..scale(clamped)
        ..translate(-e.localPosition.dx, -e.localPosition.dy);
      _transformController.value = newMatrix;
      return;
    }

    if (e.pointer != _activePointer) return;

    final engine = ref.read(canvasEngineProvider(widget.pageId));
    final pos = _toCanvasCoords(e.localPosition);

    _growCanvas(pos.dy);

    if (engine.value.mode == CanvasMode.erase) {
      setState(() => _showEraserIndicator = true);
      _eraserPos = pos;
      engine.eraseAt(pos.dx, pos.dy, pointerId: e.pointer);
      return;
    }

    final isStylus = e.kind == ui.PointerDeviceKind.stylus;
    final isTouch = e.kind == ui.PointerDeviceKind.touch;

    engine.updateStroke(
      pos.dx,
      pos.dy,
      pressure: isStylus
          ? e.pressure
          : (isTouch ? e.pressure * 0.8 : 0.5),
      timestampMs: e.timeStamp.inMilliseconds,
      pointerId: e.pointer,
      isStylus: isStylus,
    );
  }

  void _onPointerUp(PointerUpEvent e) {
    if (_isZooming) {
      _isZooming = false;
      return;
    }

    if (e.pointer != _activePointer) {
      if (e.pointer == _touchDrawPointer) _touchDrawPointer = -1;
      return;
    }

    _activePointer = -1;
    _touchDrawPointer = -1;

    final engine = ref.read(canvasEngineProvider(widget.pageId));

    if (engine.value.mode == CanvasMode.erase) {
      setState(() => _showEraserIndicator = false);
      _eraserPos = null;
      engine.endErase();
      return;
    }

    setState(() => _showEraserIndicator = false);
    engine.endStroke(
      timestampMs: e.timeStamp.inMilliseconds,
      pointerId: e.pointer,
    );
  }

  void _onPointerCancel(PointerCancelEvent e) {
    if (e.pointer == _activePointer || _activePointer < 0) {
      _activePointer = -1;
      _touchDrawPointer = -1;
      setState(() => _showEraserIndicator = false);
      _eraserPos = null;
      ref
          .read(canvasEngineProvider(widget.pageId))
          .cancelStroke(pointerId: e.pointer);
    }
  }

  void _onScaleStart(ScaleStartDetails details) {
    if (details.pointerCount >= 2) {
      _isZooming = true;
      _baseScale = _transformController.value.getMaxScaleOnAxis();
    }
  }

  void _onScaleUpdate(ScaleUpdateDetails details) {
    if (_isZooming && details.pointerCount >= 2) {
      final scale = (_baseScale * details.scale).clamp(0.3, 8.0);
      final newMatrix = Matrix4.identity()
        ..translate(details.focalPoint.dx, details.focalPoint.dy)
        ..scale(scale)
        ..translate(-details.focalPoint.dx, -details.focalPoint.dy);
      _transformController.value = newMatrix;
    }
  }

  void _onScaleEnd(ScaleEndDetails details) {
    _isZooming = false;
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(canvasStateProvider(widget.pageId));
    final canvasWidth = MediaQuery.of(context).size.width;

    return RepaintBoundary(
      child: Listener(
        onPointerDown: _onPointerDown,
        onPointerMove: _onPointerMove,
        onPointerUp: _onPointerUp,
        onPointerCancel: _onPointerCancel,
        child: GestureDetector(
          onScaleStart: _onScaleStart,
          onScaleUpdate: _onScaleUpdate,
          onScaleEnd: _onScaleEnd,
          child: InteractiveViewer(
            transformationController: _transformController,
            minScale: 0.3,
            maxScale: 8.0,
            panEnabled: false,
            scaleEnabled: false,
            constrained: false,
            boundaryMargin: const EdgeInsets.all(double.infinity),
            child: SizedBox(
              width: canvasWidth,
              height: _canvasHeight,
              child: RepaintBoundary(
                child: CustomPaint(
                  size: Size(canvasWidth, _canvasHeight),
                  painter: _CanvasPainter(
                    renderer: _renderer,
                    state: state,
                    eraserPos: _eraserPos,
                    showEraser: _showEraserIndicator,
                  ),
                  isComplex: true,
                  willChange: false,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _CanvasPainter extends CustomPainter {
  final CanvasRenderer renderer;
  final CanvasState state;
  final Offset? eraserPos;
  final bool showEraser;

  _CanvasPainter({
    required this.renderer,
    required this.state,
    this.eraserPos,
    this.showEraser = false,
  });

  @override
  void paint(Canvas canvas, Size size) {
    canvas.clipRect(Rect.fromLTWH(0, 0, size.width, size.height));

    renderer.renderBackground(canvas, size, state.background, 1.0);

    for (final stroke in state.strokes) {
      renderer.renderStroke(canvas, stroke);
    }

    if (state.currentStroke != null) {
      try {
        final outlinePath = renderer.buildPerfectFreehandPath(
          state.currentStroke!.points,
          state.currentStroke!.width,
        );
        if (outlinePath.getBounds().isEmpty) {
          renderer.renderStrokeSmooth(canvas, state.currentStroke!);
        } else {
          canvas.drawPath(
            outlinePath,
            Paint()
              ..color = Color(state.currentStroke!.color)
              ..style = PaintingStyle.fill
              ..isAntiAlias = true,
          );
        }
      } catch (_) {
        renderer.renderStrokeSmooth(canvas, state.currentStroke!);
      }
    }

    if (eraserPos != null && showEraser && state.mode == CanvasMode.erase) {
      renderer.renderEraserIndicator(canvas, eraserPos!, state.eraserSize);
    }

    if (state.strokes.isEmpty && state.currentStroke == null) {
      renderer.renderHint(canvas, size, 1.0);
    }
  }

  @override
  bool shouldRepaint(covariant _CanvasPainter old) {
    return old.state != state || old.eraserPos != eraserPos ||
        old.showEraser != showEraser;
  }
}
