import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:inkbill_ai/features/handwriting/domain/entities/ink_stroke.dart';
import 'package:inkbill_ai/features/handwriting/domain/entities/ink_point.dart';

class StrokeRenderer {
  final Paint _paint = Paint()
    ..style = PaintingStyle.stroke
    ..strokeCap = StrokeCap.round
    ..strokeJoin = StrokeJoin.round
    ..isAntiAlias = true;

  final Paint _eraserPaint = Paint()
    ..style = PaintingStyle.stroke
    ..strokeCap = StrokeCap.round
    ..blendMode = BlendMode.srcOut
    ..strokeWidth = 30;

  void renderStroke(Canvas canvas, InkStroke stroke, {bool isActive = false}) {
    if (stroke.points.isEmpty || stroke.isErased) return;

    _paint.color = Color(stroke.color);
    _paint.strokeWidth = stroke.width;

    final path = _buildPath(stroke.points);
    canvas.drawPath(path, _paint);
  }

  void renderStrokeWithPressure(
      Canvas canvas, InkStroke stroke, {bool isActive = false}) {
    if (stroke.points.isEmpty || stroke.isErased) return;

    final points = stroke.points;
    for (var i = 1; i < points.length; i++) {
      final p0 = points[i - 1];
      final p1 = points[i];

      final width = _interpolateWidth(p0, p1, stroke.width);
      _paint.color = Color(stroke.color);
      _paint.strokeWidth = width;

      canvas.drawLine(
        Offset(p0.x, p0.y),
        Offset(p1.x, p1.y),
        _paint,
      );
    }
  }

  void renderStrokeWithHighlight(
      Canvas canvas, InkStroke stroke, Color highlightColor) {
    if (stroke.points.isEmpty) return;

    _paint.color = highlightColor;
    _paint.strokeWidth = stroke.width + 2;

    final path = _buildPath(stroke.points);
    canvas.drawPath(path, _paint);
  }

  void renderEraser(Canvas canvas, Offset position, double size) {
    canvas.drawCircle(
      position,
      size / 2,
      Paint()
        ..color = Colors.grey.withValues(alpha: 0.3)
        ..style = PaintingStyle.fill,
    );
    canvas.drawCircle(
      position,
      size / 2,
      Paint()
        ..color = Colors.grey.withValues(alpha: 0.6)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.5,
    );
  }

  Path _buildPath(List<InkPoint> points) {
    final path = Path();
    if (points.isEmpty) return path;

    path.moveTo(points.first.x, points.first.y);

    for (var i = 1; i < points.length; i++) {
      final p0 = points[i - 1];
      final p1 = points[i];
      final midX = (p0.x + p1.x) / 2;
      final midY = (p0.y + p1.y) / 2;
      path.quadraticBezierTo(p0.x, p0.y, midX, midY);
    }

    path.lineTo(points.last.x, points.last.y);
    return path;
  }

  double _interpolateWidth(InkPoint a, InkPoint b, double baseWidth) {
    final avgPressure = (a.pressure + b.pressure) / 2;
    return baseWidth * (0.5 + avgPressure);
  }

  ui.Image? _renderToImage(List<InkStroke> strokes, Size size) {
    throw UnimplementedError('Use renderToPicture instead');
  }

  ui.Picture renderToPicture(List<InkStroke> strokes, Size size) {
    final recorder = ui.PictureRecorder();
    final canvas = Canvas(recorder, Rect.fromLTWH(0, 0, size.width, size.height));
    for (final stroke in strokes) {
      renderStroke(canvas, stroke);
    }
    return recorder.endRecording();
  }
}
