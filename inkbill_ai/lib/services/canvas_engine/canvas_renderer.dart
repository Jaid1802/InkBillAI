import 'dart:math' as math;
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:perfect_freehand/perfect_freehand.dart';
import 'package:inkbill_ai/features/handwriting/domain/entities/ink_stroke.dart';
import 'package:inkbill_ai/features/handwriting/domain/entities/ink_point.dart';
import 'package:inkbill_ai/services/canvas_engine/canvas_engine.dart';

class CanvasRenderer extends ChangeNotifier {
  final Paint _strokePaint = Paint()
    ..style = PaintingStyle.stroke
    ..strokeCap = StrokeCap.round
    ..strokeJoin = StrokeJoin.round
    ..isAntiAlias = true;

  final Map<String, Path> _pathCache = {};
  final Set<String> _dirtyStrokes = {};
  bool _allDirty = false;

  void markDirty(String strokeId) => _dirtyStrokes.add(strokeId);

  void markAllDirty() {
    _allDirty = true;
    notifyListeners();
  }

  void invalidateAll() {
    _pathCache.clear();
    _dirtyStrokes.clear();
    _allDirty = false;
    notifyListeners();
  }

  void invalidateStroke(String id) {
    _pathCache.remove(id);
  }

  Path buildSmoothPath(List<InkPoint> points) {
    final path = Path();
    if (points.isEmpty) return path;
    if (points.length == 1) {
      path.addOval(Rect.fromCircle(
        center: Offset(points[0].x, points[0].y),
        radius: 1.0,
      ));
      return path;
    }

    path.moveTo(points.first.x, points.first.y);

    if (points.length == 2) {
      path.lineTo(points.last.x, points.last.y);
      return path;
    }

    for (var i = 1; i < points.length - 1; i++) {
      final p0 = points[i - 1];
      final p1 = points[i];
      final p2 = points[i + 1];

      final cp1x = p0.x + (p1.x - p0.x) * 0.5;
      final cp1y = p0.y + (p1.y - p0.y) * 0.5;
      final cp2x = p1.x + (p2.x - p1.x) * 0.5;
      final cp2y = p1.y + (p2.y - p1.y) * 0.5;

      path.cubicTo(cp1x, cp1y, cp2x, cp2y, p1.x, p1.y);
    }

    path.lineTo(points.last.x, points.last.y);
    return path;
  }

  Path buildPerfectFreehandPath(List<InkPoint> points, double strokeWidth) {
    if (points.isEmpty) return Path();

    final strokePoints = points.map((p) => PointVector(
      p.x,
      p.y,
      p.pressure,
    )).toList();

    final outlineOffsets = getStroke(
      strokePoints,
      options: StrokeOptions(
        size: strokeWidth * 3.5,
        thinning: 0.6,
        streamline: 0.5,
        smoothing: 0.5,
        simulatePressure: true,
        isComplete: true,
      ),
    );

    if (outlineOffsets.isEmpty) return Path();

    return _buildPathFromOffsets(outlineOffsets);
  }

  Path _buildPathFromOffsets(List<Offset> offsets) {
    final path = Path();
    if (offsets.isEmpty) return path;

    path.moveTo(offsets.first.dx, offsets.first.dy);

    for (var i = 1; i < offsets.length; i++) {
      path.lineTo(offsets[i].dx, offsets[i].dy);
    }

    path.close();
    return path;
  }

  void renderStroke(Canvas canvas, InkStroke stroke) {
    if (stroke.points.isEmpty) return;

    if (_allDirty || _dirtyStrokes.remove(stroke.id)) {
      _pathCache.remove(stroke.id);
    }

    var path = _pathCache[stroke.id];
    if (path == null) {
      try {
        path = buildPerfectFreehandPath(stroke.points, stroke.width);
        if (path.getBounds().isEmpty) {
          path = buildSmoothPath(stroke.points);
        }
      } catch (_) {
        path = buildSmoothPath(stroke.points);
      }
      _pathCache[stroke.id] = path;
    }

    _strokePaint.color = Color(stroke.color);
    _strokePaint.style = PaintingStyle.fill;
    _strokePaint.strokeWidth = 0;
    canvas.drawPath(path, _strokePaint);
    _strokePaint.style = PaintingStyle.stroke;
  }

  void renderStrokeSmooth(Canvas canvas, InkStroke stroke) {
    final pts = stroke.points;
    if (pts.length < 2) return;

    _strokePaint.color = Color(stroke.color);
    _strokePaint.style = PaintingStyle.stroke;

    for (var i = 0; i < pts.length - 1; i++) {
      final p0 = pts[i];
      final p1 = pts[i + 1];

      final v = math.max(p1.velocity, 0.001);
      final width = stroke.width *
          (0.3 + 0.7 * math.min(1.0, 1.0 / math.sqrt(v * 100 + 1)));
      _strokePaint.strokeWidth = width.clamp(0.5, stroke.width * 1.5);

      canvas.drawLine(Offset(p0.x, p0.y), Offset(p1.x, p1.y), _strokePaint);
    }
  }

  void renderBackground(
      Canvas canvas, Size size, CanvasBackground bg, double scale) {
    final gridPaint = Paint()
      ..color = Colors.grey.withValues(alpha: 0.08)
      ..strokeWidth = 0.5;

    if (bg == CanvasBackground.grid) {
      for (double x = 0; x <= size.width; x += 32 * scale) {
        canvas.drawLine(Offset(x, 0), Offset(x, size.height), gridPaint);
      }
      for (double y = 0; y <= size.height; y += 32 * scale) {
        canvas.drawLine(Offset(0, y), Offset(size.width, y), gridPaint);
      }
    } else if (bg == CanvasBackground.ruled) {
      for (double y = 32 * scale; y < size.height; y += 32 * scale) {
        canvas.drawLine(Offset(0, y), Offset(size.width, y), gridPaint);
      }
    }
  }

  void renderHint(Canvas canvas, Size size, double scale) {
    final tp = TextPainter(
      text: TextSpan(
        text: 'Write bill items here',
        style: TextStyle(
            color: Colors.grey.withValues(alpha: 0.35), fontSize: 16 * scale),
      ),
      textDirection: TextDirection.ltr,
    )..layout(maxWidth: size.width);
    tp.paint(
      canvas,
      Offset(
        (size.width - tp.width) / 2,
        size.height / 2 - tp.height / 2,
      ),
    );
  }

  void renderEraserIndicator(Canvas canvas, Offset pos, double size) {
    canvas.drawCircle(
      pos,
      size / 2,
      Paint()
        ..color = Colors.grey.withValues(alpha: 0.15)
        ..style = PaintingStyle.fill,
    );
    canvas.drawCircle(
      pos,
      size / 2,
      Paint()
        ..color = Colors.grey.withValues(alpha: 0.5)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.5,
    );
  }

  ui.Picture renderToPicture(List<InkStroke> strokes, Size size,
      {double scale = 1.0, Rect? cropRect}) {
    final recorder = ui.PictureRecorder();
    final renderSize =
        cropRect ?? Offset.zero & size;
    final canvas = Canvas(
        recorder, Rect.fromLTWH(0, 0, renderSize.width, renderSize.height));
    canvas.scale(scale);

    canvas.drawRect(
      Rect.fromLTWH(0, 0, renderSize.width, renderSize.height),
      Paint()..color = Colors.white,
    );

    if (cropRect != null) {
      canvas.translate(-cropRect.left, -cropRect.top);
    }

    for (final stroke in strokes) {
      _strokePaint.color = const Color(0xFF000000);
      _strokePaint.style = PaintingStyle.fill;
      _strokePaint.strokeWidth = 0;

      try {
        final outlinePath =
            buildPerfectFreehandPath(stroke.points, stroke.width);
        if (outlinePath.getBounds().isEmpty) {
          _strokePaint.style = PaintingStyle.stroke;
          _strokePaint.strokeWidth = stroke.width;
          canvas.drawPath(buildSmoothPath(stroke.points), _strokePaint);
        } else {
          canvas.drawPath(outlinePath, _strokePaint);
        }
      } catch (_) {
        _strokePaint.style = PaintingStyle.stroke;
        _strokePaint.strokeWidth = stroke.width;
        canvas.drawPath(buildSmoothPath(stroke.points), _strokePaint);
      }
    }

    return recorder.endRecording();
  }

  Rect calculateBounds(List<InkStroke> strokes) {
    if (strokes.isEmpty) return Rect.zero;
    var minX = double.infinity, minY = double.infinity;
    var maxX = double.negativeInfinity, maxY = double.negativeInfinity;
    for (final stroke in strokes) {
      for (final point in stroke.points) {
        if (point.x < minX) minX = point.x;
        if (point.y < minY) minY = point.y;
        if (point.x > maxX) maxX = point.x;
        if (point.y > maxY) maxY = point.y;
      }
    }
    if (minX == double.infinity) return Rect.zero;
    const pad = 20.0;
    return Rect.fromLTRB(
      (minX - pad).clamp(0, double.infinity),
      (minY - pad).clamp(0, double.infinity),
      maxX + pad,
      maxY + pad,
    );
  }

  @override
  void dispose() {
    _pathCache.clear();
    _dirtyStrokes.clear();
    super.dispose();
  }
}
