import 'dart:io';
import 'dart:typed_data';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:image/image.dart' as img;
import 'package:path_provider/path_provider.dart';
import 'package:scribble/scribble.dart';
import 'package:inkbill_ai/services/recognition/recognition_logger.dart';

class StrokeBitmapRenderer {
  static Future<Uint8List?> render(
    List<SketchLine> strokes, {
    double padding = 30.0,
    double scale = 2.5,
    double maxDimension = 1024.0,
  }) async {
    print("====================");
    print("Renderer Called");
    print("Stroke Count: ${strokes.length}");
    print("====================");

    final lines = strokes;
    int totalPoints = 0;
    for (final l in lines) {
      totalPoints += l.points.length;
    }

    RecognitionLogger.stage(
      'STROKE_RENDERER',
      '=== STROKE BITMAP RENDERER ===\n'
      'received strokes = ${lines.length}, received points = $totalPoints',
    );

    if (lines.isEmpty || totalPoints == 0) {
      RecognitionLogger.error('STROKE_RENDERER', 'CANVAS_STATE_EMPTY: 0 strokes/points');
      return null;
    }

    // 1. Calculate tight handwriting bounds across all points
    double minX = double.infinity;
    double minY = double.infinity;
    double maxX = double.negativeInfinity;
    double maxY = double.negativeInfinity;

    for (final line in lines) {
      for (final p in line.points) {
        if (p.x < minX) minX = p.x;
        if (p.y < minY) minY = p.y;
        if (p.x > maxX) maxX = p.x;
        if (p.y > maxY) maxY = p.y;
      }
    }

    if (minX == double.infinity) {
      RecognitionLogger.error('STROKE_RENDERER', 'Invalid bounds computation');
      return null;
    }

    // 2. Add padding around tight handwriting bounds
    final rawWidth = (maxX - minX) + (padding * 2.0);
    final rawHeight = (maxY - minY) + (padding * 2.0);

    // 3. Compute scale for clean OCR resolution while preserving aspect ratio
    double renderScale = scale;
    if (rawWidth * scale > maxDimension || rawHeight * scale > maxDimension) {
      final factor = maxDimension / (rawWidth > rawHeight ? rawWidth : rawHeight);
      renderScale = factor < scale ? factor : scale;
    }

    final scaledWidth = (rawWidth * renderScale).round().clamp(1, maxDimension.toInt());
    final scaledHeight = (rawHeight * renderScale).round().clamp(1, maxDimension.toInt());

    try {
      // 4. Create offscreen canvas bitmap
      final recorder = ui.PictureRecorder();
      final canvas = Canvas(
        recorder,
        Rect.fromLTWH(0, 0, scaledWidth.toDouble(), scaledHeight.toDouble()),
      );

      // Draw pure white background
      final bgPaint = Paint()..color = const Color(0xFFFFFFFF);
      canvas.drawRect(
        Rect.fromLTWH(0, 0, scaledWidth.toDouble(), scaledHeight.toDouble()),
        bgPaint,
      );

      // Translate coordinates directly from document space into padded bitmap space
      canvas.scale(renderScale);
      canvas.translate(-minX + padding, -minY + padding);

      // 5. Draw every stroke in pure black with round caps/joins
      for (final line in lines) {
        if (line.points.isEmpty) continue;

        final paint = Paint()
          ..color = const Color(0xFF000000)
          ..strokeWidth = line.width
          ..strokeCap = StrokeCap.round
          ..strokeJoin = StrokeJoin.round
          ..style = PaintingStyle.stroke
          ..isAntiAlias = true;

        if (line.points.length == 1) {
          paint.style = PaintingStyle.fill;
          canvas.drawCircle(
            Offset(line.points.first.x, line.points.first.y),
            line.width / 2.0,
            paint,
          );
        } else {
          final path = Path();
          path.moveTo(line.points.first.x, line.points.first.y);
          for (var i = 1; i < line.points.length; i++) {
            path.lineTo(line.points[i].x, line.points[i].y);
          }
          canvas.drawPath(path, paint);
        }
      }

      final picture = recorder.endRecording();
      final imgObject = await picture.toImage(scaledWidth, scaledHeight);
      picture.dispose();

      final byteData = await imgObject.toByteData(format: ui.ImageByteFormat.png);
      imgObject.dispose();

      if (byteData == null) {
        RecognitionLogger.error('STROKE_RENDERER', 'byteData is null');
        return null;
      }

      final bytes = byteData.buffer.asUint8List();

      // 6. Save debug_original.png to Android application cache storage and verify
      Directory tempDir;
      try {
        tempDir = await getTemporaryDirectory();
      } catch (_) {
        tempDir = await getApplicationCacheDirectory();
      }

      final file = File('${tempDir.path}/debug_original.png');
      await file.writeAsBytes(bytes);

      if (await file.exists() && await file.length() > 0) {
        final decoded = img.decodePng(bytes);
        if (decoded != null) {
          int nonWhitePixels = 0;
          final totalPixels = decoded.width * decoded.height;
          for (var y = 0; y < decoded.height; y++) {
            for (var x = 0; x < decoded.width; x++) {
              final lum = img.getLuminance(decoded.getPixel(x, y)).toInt();
              if (lum < 240) nonWhitePixels++;
            }
          }
          final density = totalPixels > 0 ? (nonWhitePixels / totalPixels) * 100.0 : 0.0;
          RecognitionLogger.stage(
            'STROKE_RENDERER',
            'DIRECT STROKE RENDER VERIFIED:\n'
            'File: ${file.path}\n'
            'Dimensions: ${scaledWidth}x${scaledHeight}px, Size: ${(bytes.length / 1024).toStringAsFixed(1)}KB\n'
            'Handwriting Ink Density: ${density.toStringAsFixed(2)}%',
          );
        }
      }

      return bytes;
    } catch (e, stack) {
      RecognitionLogger.error('StrokeBitmapRenderer.render', e, stack);
      return null;
    }
  }
}
