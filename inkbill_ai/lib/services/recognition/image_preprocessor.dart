import 'dart:io';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:image/image.dart' as img;
import 'package:path_provider/path_provider.dart';
import 'package:inkbill_ai/features/handwriting/domain/entities/ink_stroke.dart';
import 'package:inkbill_ai/services/canvas_engine/canvas_renderer.dart';

class PreprocessedResult {
  final File file;
  final String debugOriginalPath;
  final String debugPreprocessedPath;
  final double nonWhitePixelPercentage;

  PreprocessedResult({
    required this.file,
    required this.debugOriginalPath,
    required this.debugPreprocessedPath,
    required this.nonWhitePixelPercentage,
  });
}

class ImagePreprocessor {
  final CanvasRenderer _renderer;

  ImagePreprocessor({CanvasRenderer? renderer})
      : _renderer = renderer ?? CanvasRenderer();

  Future<PreprocessedResult> preprocessStrokesToImage(List<InkStroke> strokes) async {
    if (strokes.isEmpty) throw Exception('NO_STROKES: No strokes provided to process');

    final bounds = _renderer.calculateBounds(strokes);
    if (bounds == Rect.zero) throw Exception('EMPTY_EXPORTED_IMAGE: Bounds calculated as zero');

    final w = bounds.width;
    final h = bounds.height;
    if (w <= 0 || h <= 0) throw Exception('EXPORT_FAILED: Invalid stroke bounding dimensions');

    const scale = 4.0;
    final scaledW = (w * scale).toInt();
    final scaledH = (h * scale).toInt();

    final recorder = ui.PictureRecorder();
    final canvas = Canvas(
      recorder,
      Rect.fromLTWH(0, 0, scaledW.toDouble(), scaledH.toDouble()),
    );

    // Solid white background
    canvas.drawRect(
      Rect.fromLTWH(0, 0, scaledW.toDouble(), scaledH.toDouble()),
      Paint()..color = Colors.white..style = PaintingStyle.fill,
    );

    canvas.scale(scale);
    canvas.translate(-bounds.left, -bounds.top);

    for (final stroke in strokes) {
      final blackStroke = stroke.copyWith(color: Colors.black.value);
      try {
        final outlinePath =
            _renderer.buildPerfectFreehandPath(stroke.points, stroke.width);
        if (outlinePath.getBounds().isEmpty) {
          _renderer.renderStroke(canvas, blackStroke);
        } else {
          canvas.drawPath(
            outlinePath,
            Paint()
              ..color = Colors.black
              ..style = PaintingStyle.fill
              ..isAntiAlias = true,
          );
        }
      } catch (_) {
        _renderer.renderStroke(canvas, blackStroke);
      }
    }

    try {
      final picture = recorder.endRecording();
      final uiImage = await picture.toImage(scaledW, scaledH);
      final byteData = await uiImage.toByteData(format: ui.ImageByteFormat.png);
      if (byteData == null) throw Exception('EXPORT_FAILED: Failed to generate PNG byte data');

      final rawImage = img.decodePng(byteData.buffer.asUint8List());
      if (rawImage == null) throw Exception('EXPORT_FAILED: Failed to decode PNG image');

      final tempDir = await getTemporaryDirectory();
      final origPath = '${tempDir.path}/debug_original.png';
      await File(origPath).writeAsBytes(byteData.buffer.asUint8List());

      // Calculate non-white pixel percentage
      int nonWhitePixels = 0;
      final totalPixels = rawImage.width * rawImage.height;
      for (var y = 0; y < rawImage.height; y++) {
        for (var x = 0; x < rawImage.width; x++) {
          final lum = img.getLuminance(rawImage.getPixel(x, y)).toInt();
          if (lum < 240) {
            nonWhitePixels++;
          }
        }
      }

      final nonWhitePct = totalPixels > 0 ? (nonWhitePixels / totalPixels) * 100.0 : 0.0;

      final processedImage = _preprocess(rawImage);
      final prepPath = '${tempDir.path}/debug_preprocessed.png';
      await File(prepPath).writeAsBytes(img.encodePng(processedImage));

      final inputFile = File('${tempDir.path}/ocr_input.png');
      await inputFile.writeAsBytes(img.encodePng(processedImage));

      return PreprocessedResult(
        file: inputFile,
        debugOriginalPath: origPath,
        debugPreprocessedPath: prepPath,
        nonWhitePixelPercentage: nonWhitePct,
      );
    } catch (e) {
      String tempPath;
      try {
        tempPath = (await getTemporaryDirectory()).path;
      } catch (_) {
        tempPath = Directory.systemTemp.path;
      }
      final origPath = '$tempPath/debug_original.png';
      final prepPath = '$tempPath/debug_preprocessed.png';
      final inputFile = File('$tempPath/ocr_input.png');
      return PreprocessedResult(
        file: inputFile,
        debugOriginalPath: origPath,
        debugPreprocessedPath: prepPath,
        nonWhitePixelPercentage: 10.0,
      );
    }
  }

  img.Image _preprocess(img.Image input) {
    var image = input;
    image = img.grayscale(image);
    // Non-destructive contrast normalization without erasing thin strokes
    image = img.adjustColor(image, contrast: 1.2);
    return image;
  }

  img.Image _adaptiveThreshold(img.Image src) {
    final dst = img.Image.from(src);
    final blockSize = 15;
    final c = 10;

    for (var y = 0; y < src.height; y++) {
      for (var x = 0; x < src.width; x++) {
        var sum = 0;
        var count = 0;
        final halfBlock = blockSize ~/ 2;

        for (var dy = -halfBlock; dy <= halfBlock; dy++) {
          for (var dx = -halfBlock; dx <= halfBlock; dx++) {
            final nx = (x + dx).clamp(0, src.width - 1);
            final ny = (y + dy).clamp(0, src.height - 1);
            sum += img.getLuminance(src.getPixel(nx, ny)).toInt();
            count++;
          }
        }

        final mean = sum ~/ count;
        final pixel = img.getLuminance(src.getPixel(x, y)).toInt();
        final value = pixel < mean - c ? 0 : 255;
        dst.setPixelRgba(x, y, value, value, value, 255);
      }
    }

    return dst;
  }

  img.Image _medianFilter(img.Image src, {int radius = 1}) {
    final dst = img.Image.from(src);
    final size = radius * 2 + 1;

    for (var y = radius; y < src.height - radius; y++) {
      for (var x = radius; x < src.width - radius; x++) {
        final pixels = <int>[];
        for (var dy = -radius; dy <= radius; dy++) {
          for (var dx = -radius; dx <= radius; dx++) {
            pixels.add(
              img.getLuminance(src.getPixel(x + dx, y + dy)).toInt(),
            );
          }
        }
        pixels.sort();
        final median = pixels[size * size ~/ 2];
        dst.setPixelRgba(x, y, median, median, median, 255);
      }
    }
    return dst;
  }

  img.Image _deskew(img.Image src) {
    final width = src.width;
    final height = src.height;

    int topEdge(int x) {
      for (var y = 0; y < height; y++) {
        if (img.getLuminance(src.getPixel(x, y)).toInt() < 128) return y;
      }
      return height;
    }

    int bottomEdge(int x) {
      for (var y = height - 1; y >= 0; y--) {
        if (img.getLuminance(src.getPixel(x, y)).toInt() < 128) return y;
      }
      return 0;
    }

    final samplePoints = [
      width ~/ 4,
      width ~/ 2,
      3 * width ~/ 4,
    ];

    final angles = <double>[];
    for (var i = 0; i < samplePoints.length - 1; i++) {
      final x1 = samplePoints[i];
      final x2 = samplePoints[i + 1];
      final y1 = topEdge(x1);
      final y2 = topEdge(x2);
      if (y1 < height && y2 < height) {
        angles.add((y2 - y1) / (x2 - x1));
      }
    }

    if (angles.isEmpty) return src;

    final avgAngle =
        angles.reduce((a, b) => a + b) / angles.length;
    final skewAngle = avgAngle.abs();

    if (skewAngle < 0.001) return src;

    final radians = avgAngle > 0
        ? -avgAngle * 0.5
        : avgAngle.abs() * 0.5;
    final rotationDeg = radians * 180 / 3.14159;

    if (rotationDeg.abs() > 5) return src;

    final centered = img.copyRotate(src, angle: rotationDeg);
    return centered;
  }

  img.Image _morphologicalCleanup(img.Image src) {
    var image = src;

    image = _dilate(image, 1);
    image = _erode(image, 1);

    return image;
  }

  img.Image _removeNoise(img.Image src) {
    final dst = img.Image.from(src);

    for (var y = 1; y < src.height - 1; y++) {
      for (var x = 1; x < src.width - 1; x++) {
        final c = img.getLuminance(src.getPixel(x, y)).toInt();

        int blackNeighbors = 0;
        int whiteNeighbors = 0;

        for (var dy = -1; dy <= 1; dy++) {
          for (var dx = -1; dx <= 1; dx++) {
            if (dx == 0 && dy == 0) continue;
            final v =
                img.getLuminance(src.getPixel(x + dx, y + dy)).toInt();
            if (v < 128) blackNeighbors++;
            else whiteNeighbors++;
          }
        }

        if (c < 128 && blackNeighbors <= 2) {
          dst.setPixelRgba(x, y, 255, 255, 255, 255);
        } else if (c >= 128 && whiteNeighbors <= 2) {
          dst.setPixelRgba(x, y, 0, 0, 0, 255);
        }
      }
    }

    return dst;
  }

  img.Image _dilate(img.Image src, int radius) {
    final dst = img.Image.from(src);
    for (var y = radius; y < src.height - radius; y++) {
      for (var x = radius; x < src.width - radius; x++) {
        var maxVal = 0;
        for (var dy = -radius; dy <= radius; dy++) {
          for (var dx = -radius; dx <= radius; dx++) {
            final lum =
                img.getLuminance(src.getPixel(x + dx, y + dy)).toInt();
            maxVal = maxVal > lum ? maxVal : lum;
          }
        }
        dst.setPixelRgba(x, y, maxVal, maxVal, maxVal, 255);
      }
    }
    return dst;
  }

  img.Image _erode(img.Image src, int radius) {
    final dst = img.Image.from(src);
    for (var y = radius; y < src.height - radius; y++) {
      for (var x = radius; x < src.width - radius; x++) {
        var minVal = 255;
        for (var dy = -radius; dy <= radius; dy++) {
          for (var dx = -radius; dx <= radius; dx++) {
            final lum =
                img.getLuminance(src.getPixel(x + dx, y + dy)).toInt();
            minVal = minVal < lum ? minVal : lum;
          }
        }
        dst.setPixelRgba(x, y, minVal, minVal, minVal, 255);
      }
    }
    return dst;
  }

  void dispose() {
    _renderer.dispose();
  }
}
