import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:perfect_freehand/perfect_freehand.dart';
import 'package:inkbill_ai/features/handwriting/domain/entities/ink_stroke.dart';
import 'package:inkbill_ai/features/handwriting/presentation/providers/canvas_provider.dart';
import 'package:inkbill_ai/services/canvas_engine/canvas_engine.dart';

class HandwritingCanvas extends ConsumerStatefulWidget {
  final String pageId;
  final VoidCallback? onStrokeStarted;
  final TransformationController? transformationController;

  const HandwritingCanvas({
    super.key,
    required this.pageId,
    this.onStrokeStarted,
    this.transformationController,
  });

  @override
  ConsumerState<HandwritingCanvas> createState() => _HandwritingCanvasState();
}

class _HandwritingCanvasState extends ConsumerState<HandwritingCanvas>
    with TickerProviderStateMixin {
  late final TransformationController _transformCtrl;
  final Map<String, Path> _pathCache = {};

  int _activePointer = -1;
  bool _isDrawing = false;
  bool _isErasing = false;

  static const double _canvasWidth = 5000;
  static const double _canvasHeight = 5000;

  Offset? _currentEraserPos;

  CanvasEngine get _engine => ref.read(canvasEngineProvider(widget.pageId));
  bool get _isEraseMode => _engine.value.mode == CanvasMode.erase;

  @override
  void initState() {
    super.initState();
    _transformCtrl = widget.transformationController ?? TransformationController();
  }

  @override
  void dispose() {
    if (widget.transformationController == null) {
      _transformCtrl.dispose();
    }
    super.dispose();
  }

  Offset _toCanvas(Offset local) {
    final inv = Matrix4.inverted(_transformCtrl.value);
    return MatrixUtils.transformPoint(inv, local);
  }

  void _onPointerDown(PointerDownEvent e) {
    final inputMode = _engine.value.inputMode;

    if (e.kind == ui.PointerDeviceKind.touch) {
      if (inputMode == InputMode.stylus) return;
      if (e.size > 12.0) return;
      if (e.localPosition.dy > MediaQuery.of(context).size.height - 80) return;
    }

    if (_activePointer >= 0) return;
    _activePointer = e.pointer;

    widget.onStrokeStarted?.call();

    final pos = _toCanvas(e.localPosition);

    if (_isEraseMode) {
      _isErasing = true;
      _currentEraserPos = pos;
      _engine.eraseAt(pos.dx, pos.dy, pointerId: e.pointer);
      setState(() {});
      return;
    }

    _isDrawing = true;
    _engine.beginStroke(
      pos.dx,
      pos.dy,
      pressure: e.kind == ui.PointerDeviceKind.stylus
          ? e.pressure
          : (e.kind == ui.PointerDeviceKind.touch ? e.pressure * 0.8 : 0.5),
      timestampMs: e.timeStamp.inMilliseconds,
      pointerId: e.pointer,
      isStylus: e.kind == ui.PointerDeviceKind.stylus,
      isEraser: e.kind == ui.PointerDeviceKind.unknown,
    );
  }

  void _onPointerMove(PointerMoveEvent e) {
    if (e.pointer != _activePointer) return;

    final pos = _toCanvas(e.localPosition);

    if (_isEraseMode && _isErasing) {
      _currentEraserPos = pos;
      _engine.eraseAt(pos.dx, pos.dy, pointerId: e.pointer);
      setState(() {});
      return;
    }

    if (!_isDrawing) return;

    _engine.updateStroke(
      pos.dx,
      pos.dy,
      pressure: e.kind == ui.PointerDeviceKind.stylus
          ? e.pressure
          : (e.kind == ui.PointerDeviceKind.touch ? e.pressure * 0.8 : 0.5),
      timestampMs: e.timeStamp.inMilliseconds,
      pointerId: e.pointer,
      isStylus: e.kind == ui.PointerDeviceKind.stylus,
    );
  }

  void _onPointerUp(PointerUpEvent e) {
    if (e.pointer != _activePointer) return;

    _activePointer = -1;

    if (_isEraseMode && _isErasing) {
      _isErasing = false;
      _currentEraserPos = null;
      _engine.endErase();
      setState(() {});
      return;
    }

    _isDrawing = false;
    _engine.endStroke(
      timestampMs: e.timeStamp.inMilliseconds,
      pointerId: e.pointer,
    );
  }

  void _onPointerCancel(PointerCancelEvent e) {
    if (e.pointer == _activePointer || _activePointer < 0) {
      _activePointer = -1;
      _isDrawing = false;
      _isErasing = false;
      _currentEraserPos = null;
      _engine.cancelStroke(pointerId: e.pointer);
      setState(() {});
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(canvasStateProvider(widget.pageId));

    return Listener(
      onPointerDown: _onPointerDown,
      onPointerMove: _onPointerMove,
      onPointerUp: _onPointerUp,
      onPointerCancel: _onPointerCancel,
      child: InteractiveViewer(
        transformationController: _transformCtrl,
        minScale: 0.25,
        maxScale: 10.0,
        constrained: false,
        boundaryMargin: const EdgeInsets.all(double.infinity),
        panEnabled: false,
        scaleEnabled: false,
        child: SizedBox(
          width: _canvasWidth,
          height: _canvasHeight,
          child: RepaintBoundary(
            child: CustomPaint(
              size: const Size(_canvasWidth, _canvasHeight),
              painter: _InkCanvasPainter(
                state: state,
                pathCache: _pathCache,
                eraserPos: _currentEraserPos,
                isInEraseMode: _isEraseMode && _isErasing,
              ),
              isComplex: true,
              willChange: state.currentStroke != null,
            ),
          ),
        ),
      ),
    );
  }
}

class _InkCanvasPainter extends CustomPainter {
  final CanvasState state;
  final Map<String, Path> pathCache;
  final Offset? eraserPos;
  final bool isInEraseMode;

  _InkCanvasPainter({
    required this.state,
    required this.pathCache,
    this.eraserPos,
    this.isInEraseMode = false,
  });

  @override
  void paint(Canvas canvas, Size size) {
    _drawBackground(canvas, size);

    final fillPaint = Paint()
      ..style = PaintingStyle.fill
      ..isAntiAlias = true;

    for (final stroke in state.strokes) {
      final path = _buildPath(stroke);
      if (path == null) continue;
      fillPaint.color = Color(stroke.color);
      canvas.drawPath(path, fillPaint);
    }

    if (state.currentStroke != null) {
      final path = _buildPath(state.currentStroke!);
      if (path != null) {
        fillPaint.color = Color(state.currentStroke!.color);
        canvas.drawPath(path, fillPaint);
      }
    }

    if (eraserPos != null && isInEraseMode) {
      _drawEraserIndicator(canvas, eraserPos!, state.eraserSize);
    }

    if (state.strokes.isEmpty && state.currentStroke == null) {
      _drawHint(canvas, size);
    }
  }

  Path? _buildPath(InkStroke stroke) {
    final cached = pathCache[stroke.id];
    if (cached != null) return cached;

    try {
      if (stroke.points.length < 2) return null;

      final pts = stroke.points.map((p) => PointVector(
        p.x,
        p.y,
        p.pressure,
      )).toList();

      final outline = getStroke(pts, options: StrokeOptions(
        size: stroke.width * 1.5,
        thinning: 0.6,
        smoothing: 0.5,
        streamline: 0.5,
        simulatePressure: true,
        isComplete: true,
      ));

      if (outline.isEmpty) return null;

      final path = Path();
      path.moveTo(outline[0].dx, outline[0].dy);
      for (var i = 1; i < outline.length; i++) {
        path.lineTo(outline[i].dx, outline[i].dy);
      }
      path.close();

      pathCache[stroke.id] = path;
      return path;
    } catch (_) {
      return _buildSmoothFallback(stroke);
    }
  }

  Path? _buildSmoothFallback(InkStroke stroke) {
    final pts = stroke.points;
    if (pts.length < 2) return null;

    final path = Path();
    path.moveTo(pts.first.x, pts.first.y);

    for (var i = 1; i < pts.length - 1; i++) {
      final p0 = pts[i - 1];
      final p1 = pts[i];
      final p2 = pts[i + 1];
      final cp1x = p0.x + (p1.x - p0.x) * 0.5;
      final cp1y = p0.y + (p1.y - p0.y) * 0.5;
      final cp2x = p1.x + (p2.x - p1.x) * 0.5;
      final cp2y = p1.y + (p2.y - p1.y) * 0.5;
      path.cubicTo(cp1x, cp1y, cp2x, cp2y, p1.x, p1.y);
    }
    path.lineTo(pts.last.x, pts.last.y);
    return path;
  }

  void _drawBackground(Canvas canvas, Size size) {
    final bgPaint = Paint()..color = Colors.white;
    canvas.drawRect(Rect.fromLTWH(0, 0, size.width, size.height), bgPaint);

    if (state.background == CanvasBackground.grid) {
      final gridPaint = Paint()
        ..color = Colors.grey.withValues(alpha: 0.12)
        ..strokeWidth = 0.5;
      const spacing = 40.0;
      for (double x = 0; x < size.width; x += spacing) {
        canvas.drawLine(Offset(x, 0), Offset(x, size.height), gridPaint);
      }
      for (double y = 0; y < size.height; y += spacing) {
        canvas.drawLine(Offset(0, y), Offset(size.width, y), gridPaint);
      }
    } else if (state.background == CanvasBackground.ruled) {
      final rulePaint = Paint()
        ..color = Colors.blue.withValues(alpha: 0.08)
        ..strokeWidth = 0.5;
      const lineSpacing = 32.0;
      for (double y = lineSpacing; y < size.height; y += lineSpacing) {
        canvas.drawLine(Offset(0, y), Offset(size.width, y), rulePaint);
      }
    }

    _drawBillGuides(canvas, size);
  }

  void _drawBillGuides(Canvas canvas, Size size) {
    final guidePaint = Paint()
      ..color = Colors.blue.withValues(alpha: 0.15)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0;
      
    final textStyle = TextStyle(
      color: Colors.blue.withValues(alpha: 0.3),
      fontSize: 14,
      fontWeight: FontWeight.w600,
    );

    final billWidth = size.width < 800 ? size.width : 800.0;
    
    final colItem = billWidth * 0.45;
    final colQty = billWidth * 0.15;
    final colRate = billWidth * 0.20;
    
    double currentX = 0;
    
    void drawColumnLineAndTitle(String title, double width) {
      if (currentX > 0) {
        canvas.drawLine(Offset(currentX, 0), Offset(currentX, size.height), guidePaint);
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
    
    canvas.drawLine(Offset(billWidth, 0), Offset(billWidth, size.height), guidePaint);
    
    canvas.drawLine(const Offset(0, 32), Offset(billWidth, 32), guidePaint);
  }

  void _drawEraserIndicator(Canvas canvas, Offset pos, double size) {
    final fill = Paint()
      ..color = Colors.grey.withValues(alpha: 0.15)
      ..style = PaintingStyle.fill;
    canvas.drawCircle(pos, size, fill);

    final border = Paint()
      ..color = Colors.grey.withValues(alpha: 0.3)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5;
    canvas.drawCircle(pos, size, border);
  }

  void _drawHint(Canvas canvas, Size size) {
    final tp = TextPainter(
      text: TextSpan(
        text: 'Start writing here...',
        style: TextStyle(
          color: Colors.grey.shade300,
          fontSize: 16,
          fontWeight: FontWeight.w400,
        ),
      ),
      textDirection: TextDirection.ltr,
    );
    tp.layout();
    tp.paint(canvas, const Offset(24, 24));
  }

  @override
  bool shouldRepaint(covariant _InkCanvasPainter old) {
    return old.state != state ||
        old.eraserPos != eraserPos ||
        old.isInEraseMode != isInEraseMode;
  }
}
