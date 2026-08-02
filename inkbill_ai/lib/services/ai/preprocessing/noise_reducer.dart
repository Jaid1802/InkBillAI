import 'dart:typed_data';
import 'package:image/image.dart' as img;
import 'package:inkbill_ai/services/recognition/recognition_logger.dart';

class NoiseReducer {
  static const double _contrastClip = 2.0;
  static const int _medianRadius = 1;

  Uint8List denoise(Uint8List imageBytes) {
    final image = img.decodeImage(imageBytes);
    if (image == null) {
      RecognitionLogger.error('NoiseReducer', 'Failed to decode image');
      return imageBytes;
    }

    final gray = img.grayscale(image);

    final equalized = _adaptiveEqualize(gray);

    final smoothed = _medianFilter(equalized, radius: _medianRadius);

    final contrast = _adjustContrast(smoothed);

    final outputBytes = Uint8List.fromList(img.encodePng(contrast));
    RecognitionLogger.log('NoiseReducer: denoise complete');

    return outputBytes;
  }

  img.Image _adaptiveEqualize(img.Image image) {
    final result = img.Image.from(image);

    final histogram = List.filled(256, 0);
    for (var y = 0; y < image.height; y++) {
      for (var x = 0; x < image.width; x++) {
        final l = img.getLuminance(image.getPixel(x, y));
        histogram[l.round().clamp(0, 255)]++;
      }
    }

    final total = image.width * image.height;
    final cdf = List.filled(256, 0.0);
    var sum = 0;
    for (var i = 0; i < 256; i++) {
      sum += histogram[i];
      cdf[i] = sum / total;
    }

    final clipLimit = (total / 256 * _contrastClip).round();
    var excess = 0;
    for (var i = 0; i < 256; i++) {
      if (histogram[i] > clipLimit) {
        excess += histogram[i] - clipLimit;
        histogram[i] = clipLimit;
      }
    }
    final redistribute = excess ~/ 256;
    for (var i = 0; i < 256; i++) {
      histogram[i] += redistribute;
    }

    for (var y = 0; y < image.height; y++) {
      for (var x = 0; x < image.width; x++) {
        final l = img.getLuminance(image.getPixel(x, y));
        final newL = (cdf[l.round().clamp(0, 255)] * 255).round().clamp(0, 255);
        result.setPixel(x, y, img.ColorRgb8(newL, newL, newL));
      }
    }

    return result;
  }

  img.Image _adjustContrast(img.Image image) {
    final mean = _computeMean(image);
    final result = img.Image.from(image);

    for (var y = 0; y < image.height; y++) {
      for (var x = 0; x < image.width; x++) {
        final l = img.getLuminance(image.getPixel(x, y));
        final adjusted = ((l - mean) * 1.2 + mean).round().clamp(0, 255);
        result.setPixel(x, y, img.ColorRgb8(adjusted, adjusted, adjusted));
      }
    }

    return result;
  }

  double _computeMean(img.Image image) {
    var sum = 0.0;
    var count = 0;
    for (var y = 0; y < image.height; y++) {
      for (var x = 0; x < image.width; x++) {
        sum += img.getLuminance(image.getPixel(x, y));
        count++;
      }
    }
    return count > 0 ? sum / count : 128.0;
  }

  img.Image _medianFilter(img.Image src, {int radius = 1}) {
    final result = img.Image.from(src);
    final half = radius;

    for (var y = 0; y < src.height; y++) {
      for (var x = 0; x < src.width; x++) {
        final neighbors = <int>[];
        for (var ky = -half; ky <= half; ky++) {
          for (var kx = -half; kx <= half; kx++) {
            final nx = (x + kx).clamp(0, src.width - 1);
            final ny = (y + ky).clamp(0, src.height - 1);
            neighbors.add(img.getLuminance(src.getPixel(nx, ny)).round());
          }
        }
        neighbors.sort();
        final median = neighbors[neighbors.length ~/ 2];
        result.setPixel(x, y, img.ColorRgb8(median, median, median));
      }
    }

    return result;
  }
}
