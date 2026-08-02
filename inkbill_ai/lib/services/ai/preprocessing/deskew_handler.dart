import 'dart:math' as math;
import 'dart:typed_data';
import 'package:image/image.dart' as img;
import 'package:inkbill_ai/services/recognition/recognition_logger.dart';

class DeskewHandler {
  static const double _maxAngle = 15.0;
  static const double _angleStep = 0.5;
  static const double _minConfidence = 0.3;

  Uint8List deskew(Uint8List imageBytes) {
    final image = img.decodeImage(imageBytes);
    if (image == null) {
      RecognitionLogger.error('DeskewHandler', 'Failed to decode image');
      return imageBytes;
    }

    final gray = img.grayscale(image);
    final angle = _findSkewAngle(gray);

    if (angle.abs() < 0.5) {
      RecognitionLogger.log('Deskew: no correction needed');
      return imageBytes;
    }

    if (angle.abs() > _maxAngle) {
      RecognitionLogger.log(
          'Deskew: angle ${angle.toStringAsFixed(1)}° exceeds max, skipping');
      return imageBytes;
    }

    final rotated = img.copyRotate(image, angle: angle);
    final outputBytes = Uint8List.fromList(img.encodePng(rotated));

    RecognitionLogger.log(
        'Deskew: corrected ${angle.toStringAsFixed(1)}°');
    return outputBytes;
  }

  double _findSkewAngle(img.Image image) {
    final w = image.width;
    final h = image.height;
    final centerX = w / 2;
    final centerY = h / 2;

    double bestAngle = 0;
    double bestVariance = double.infinity;

    for (var angle = -_maxAngle; angle <= _maxAngle; angle += _angleStep) {
      final radians = angle * math.pi / 180;
      final cosA = math.cos(radians);
      final sinA = math.sin(radians);

      var variance = 0.0;
      var samples = 0;

      for (var y = 0; y < h; y += 8) {
        var rowSum = 0.0;
        var rowCount = 0;

        for (var x = 0; x < w; x += 4) {
          final rx = ((x - centerX) * cosA - (y - centerY) * sinA + centerX)
              .round()
              .clamp(0, w - 1);
          final ry = ((x - centerX) * sinA + (y - centerY) * cosA + centerY)
              .round()
              .clamp(0, h - 1);

          final pixel = image.getPixel(rx, ry);
          final l = img.getLuminance(pixel);
          rowSum += l;
          rowCount++;
        }

        if (rowCount > 0) {
          final mean = rowSum / rowCount;
          var rowVar = 0.0;
          for (var x = 0; x < w; x += 4) {
            final rx = ((x - centerX) * cosA - (y - centerY) * sinA + centerX)
                .round()
                .clamp(0, w - 1);
            final ry = ((x - centerX) * sinA + (y - centerY) * cosA + centerY)
                .round()
                .clamp(0, h - 1);
            final pixel = image.getPixel(rx, ry);
            final l = img.getLuminance(pixel);
            rowVar += (l - mean) * (l - mean);
          }
          variance += rowVar / rowCount;
          samples++;
        }
      }

      if (samples > 0) {
        variance /= samples;
        if (variance < bestVariance) {
          bestVariance = variance;
          bestAngle = angle;
        }
      }
    }

    if (bestVariance == double.infinity) return 0;
    return bestAngle;
  }
}
