import 'dart:ui' as ui;
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:perfect_freehand/perfect_freehand.dart';
import 'package:inkbill_ai/features/handwriting/domain/entities/ink_stroke.dart';
import 'package:inkbill_ai/features/handwriting/domain/entities/ink_point.dart';

class CanvasExport {
  static Future<Uint8List?> exportStrokesToPng(
    List<InkStroke> strokes, {
    double scale = 4.0,
    Size canvasSize = const Size(5000, 5000),
  }) async {
    if (strokes.isEmpty) return null;

    // Find bounding box of all strokes to crop the image
    double minX = double.infinity;
    double minY = double.infinity;
    double maxX = double.negativeInfinity;
    double maxY = double.negativeInfinity;

    for (final stroke in strokes) {
      for (final p in stroke.points) {
        if (p.x < minX) minX = p.x;
        if (p.y < minY) minY = p.y;
        if (p.x > maxX) maxX = p.x;
        if (p.y > maxY) maxY = p.y;
      }
    }

    if (minX == double.infinity) return null;

    // Add some padding
    const padding = 40.0;
    minX = (minX - padding).clamp(0.0, canvasSize.width);
    minY = (minY - padding).clamp(0.0, canvasSize.height);
    maxX = (maxX + padding).clamp(0.0, canvasSize.width);
    maxY = (maxY + padding).clamp(0.0, canvasSize.height);

    final width = maxX - minX;
    final height = maxY - minY;

    final recorder = ui.PictureRecorder();
    final canvas = Canvas(recorder);

    // Draw white background
    final bgPaint = Paint()..color = Colors.white;
    canvas.drawRect(Rect.fromLTWH(0, 0, width, height), bgPaint);

    // Translate canvas to the bounding box
    canvas.translate(-minX, -minY);

    final fillPaint = Paint()
      ..style = PaintingStyle.fill
      ..isAntiAlias = true;

    for (final stroke in strokes) {
      final path = _buildPath(stroke);
      if (path != null) {
        fillPaint.color = Color(stroke.color);
        canvas.drawPath(path, fillPaint);
      }
    }

    final picture = recorder.endRecording();
    final img = await picture.toImage(
      (width * scale).toInt(),
      (height * scale).toInt(),
    );
    
    final byteData = await img.toByteData(format: ui.ImageByteFormat.png);
    return byteData?.buffer.asUint8List();
  }

  static Path? _buildPath(InkStroke stroke) {
    if (stroke.points.length < 2) return null;

    try {
      final pts = stroke.points.map((p) => PointVector(p.x, p.y, p.pressure)).toList();
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
      return path;
    } catch (_) {
      // Fallback smooth path
      final pts = stroke.points;
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
  }
}
