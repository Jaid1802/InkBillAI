import 'dart:io';
import 'dart:typed_data';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:image/image.dart' as img;
import 'package:path_provider/path_provider.dart';
import 'package:scribble/scribble.dart';
import 'package:inkbill_ai/services/recognition/recognition_logger.dart';

class CanvasExporter {
  static const double _maxDimension = 1024.0;
  static const double _padding = 40.0;

  static Future<Uint8List?> exportSketchToPng({
    required Sketch sketch,
    double scale = 4.0,
    double? maxDimension,
  }) async {
    RecognitionLogger.stage('EXPORT', 'Canvas Export Started');

    if (sketch.lines.isEmpty) {
      RecognitionLogger.log('Export skipped: no strokes');
      return null;
    }

    final bounds = _computeBounds(sketch);
    if (bounds == null) {
      RecognitionLogger.log('Export skipped: bounds computation failed');
      return null;
    }

    double minX = bounds['minX'] as double;
    double minY = bounds['minY'] as double;
    double maxX = bounds['maxX'] as double;
    double maxY = bounds['maxY'] as double;

    minX = (minX - _padding).clamp(0.0, double.infinity);
    minY = (minY - _padding).clamp(0.0, double.infinity);
    maxX = maxX + _padding;
    maxY = maxY + _padding;

    double width = maxX - minX;
    double height = maxY - minY;

    final effectiveMax = maxDimension ?? _maxDimension;

    double renderScale = scale;
    if (width * scale > effectiveMax || height * scale > effectiveMax) {
      final factor = effectiveMax / (width > height ? width : height);
      renderScale = factor < scale ? factor : scale;
      RecognitionLogger.log(
          'Image cropped & resized: ${width.toInt()}x${height.toInt()} -> ${(width * renderScale).toInt()}x${(height * renderScale).toInt()}');
    }


    try {
      final scaledWidth = (width * renderScale).toInt().clamp(1, effectiveMax.toInt());
      final scaledHeight = (height * renderScale).toInt().clamp(1, effectiveMax.toInt());

      final recorder = ui.PictureRecorder();
      final canvas = Canvas(
        recorder,
        Rect.fromLTWH(0, 0, scaledWidth.toDouble(), scaledHeight.toDouble()),
      );

      final bgPaint = Paint()..color = Colors.white;
      canvas.drawRect(
        Rect.fromLTWH(0, 0, scaledWidth.toDouble(), scaledHeight.toDouble()),
        bgPaint,
      );

      // Apply scaling transform then translate in logical units
      canvas.scale(renderScale);
      canvas.translate(-minX, -minY);

      for (final line in sketch.lines) {
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
        RecognitionLogger.error('CanvasExporter', 'byteData is null');
        return null;
      }

      final bytes = byteData.buffer.asUint8List();

      // Write debug_original.png to Android application cache storage
      try {
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
            final total = decoded.width * decoded.height;
            for (var y = 0; y < decoded.height; y++) {
              for (var x = 0; x < decoded.width; x++) {
                final lum = img.getLuminance(decoded.getPixel(x, y)).toInt();
                if (lum < 240) nonWhitePixels++;
              }
            }
            final density = total > 0 ? (nonWhitePixels / total) * 100.0 : 0.0;
            RecognitionLogger.stage(
                'EXPORT',
                'Canvas Export Verified: ${scaledWidth}x${scaledHeight}px, '
                '${(bytes.length / 1024).toStringAsFixed(1)}KB, Ink Density: ${density.toStringAsFixed(2)}%');
          }
        }
      } catch (e) {
        RecognitionLogger.log('debug_original.png save warning: $e');
      }

      return bytes;
    } catch (e, stack) {
      RecognitionLogger.error('CanvasExporter.exportSketchToPng', e, stack);
      return null;
    }
  }

  static Map<String, double>? _computeBounds(Sketch sketch) {
    double minX = double.infinity;
    double minY = double.infinity;
    double maxX = double.negativeInfinity;
    double maxY = double.negativeInfinity;

    for (final line in sketch.lines) {
      for (final p in line.points) {
        if (p.x < minX) minX = p.x;
        if (p.y < minY) minY = p.y;
        if (p.x > maxX) maxX = p.x;
        if (p.y > maxY) maxY = p.y;
      }
    }

    if (minX == double.infinity) return null;

    return {
      'minX': minX,
      'minY': minY,
      'maxX': maxX,
      'maxY': maxY,
    };
  }
}
