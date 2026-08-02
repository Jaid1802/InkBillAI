import 'dart:math' as math;
import 'dart:typed_data';
import 'package:image/image.dart' as img;
import 'package:inkbill_ai/services/ai/models/ai_model_interfaces.dart';
import 'package:inkbill_ai/services/recognition/recognition_logger.dart';

class LineSegmenter {
  static const double _minLineHeight = 8.0;
  static const double _maxLineGap = 10.0;
  static const double _inkThreshold = 0.15;

  List<LineSegment> segmentIntoLines(Uint8List imageBytes) {
    final image = img.decodeImage(imageBytes);
    if (image == null) {
      RecognitionLogger.error('LineSegmenter', 'Failed to decode image');
      return [];
    }

    final gray = img.grayscale(image);
    final w = gray.width;
    final h = gray.height;

    final rowProfiles = _computeRowProfiles(gray);
    final lines = _findLineBoundaries(rowProfiles);

    if (lines.isEmpty) {
      RecognitionLogger.log('LineSegmenter: no lines found, returning full image');
      final lineSegment = LineSegment(
        croppedImage: imageBytes,
        y: 0,
        height: h.toDouble(),
      );
      return [lineSegment];
    }

    final segments = <LineSegment>[];
    for (final line in lines) {
      final startY = line['startY'] ?? 0;
      final endY = line['endY'] ?? 0;
      final lineH = endY - startY;
      if (lineH < _minLineHeight) continue;

      final cropped = img.copyCrop(
        image,
        x: 0,
        y: startY.round(),
        width: w,
        height: lineH.round(),
      );
      final croppedBytes = Uint8List.fromList(img.encodePng(cropped));

      segments.add(LineSegment(
        croppedImage: croppedBytes,
        y: startY,
        height: lineH,
      ));
    }

    RecognitionLogger.log(
        'LineSegmenter: ${segments.length} lines from ${h}px height');

    if (segments.isEmpty) {
      return [LineSegment(croppedImage: imageBytes, y: 0, height: h.toDouble())];
    }

    return segments;
  }

  List<double> _computeRowProfiles(img.Image grayImage) {
    final w = grayImage.width;
    final h = grayImage.height;
    final profiles = <double>[];

    for (var y = 0; y < h; y++) {
      var darkPixels = 0;
      for (var x = 0; x < w; x++) {
        final l = img.getLuminance(grayImage.getPixel(x, y));
        if (l < 128) darkPixels++;
      }
      profiles.add(darkPixels / w);
    }

    return profiles;
  }

  List<Map<String, double>> _findLineBoundaries(List<double> profiles) {
    final lines = <Map<String, double>>[];
    final smoothed = _smooth(profiles, 3);

    var inLine = false;
    double lineStart = 0;
    double gapCount = 0;

    for (var y = 0; y < smoothed.length; y++) {
      final isInk = smoothed[y] > _inkThreshold;

      if (isInk && !inLine) {
        inLine = true;
        lineStart = y.toDouble();
        gapCount = 0;
      } else if (!isInk && inLine) {
        gapCount++;
        if (gapCount > _maxLineGap) {
          lines.add({'startY': lineStart, 'endY': y.toDouble() - gapCount});
          inLine = false;
          gapCount = 0;
        }
      } else {
        gapCount = 0;
      }
    }

    if (inLine) {
      lines.add({'startY': lineStart, 'endY': smoothed.length.toDouble()});
    }

    return _mergeCloseLines(lines);
  }

  List<double> _smooth(List<double> data, int window) {
    if (data.length < window) return data;
    final result = List<double>.filled(data.length, 0);
    final half = window ~/ 2;

    for (var i = 0; i < data.length; i++) {
      var sum = 0.0;
      var count = 0;
      for (var j = -half; j <= half; j++) {
        final idx = i + j;
        if (idx >= 0 && idx < data.length) {
          sum += data[idx];
          count++;
        }
      }
      result[i] = count > 0 ? sum / count : 0;
    }

    return result;
  }

  List<Map<String, double>> _mergeCloseLines(List<Map<String, double>> lines) {
    if (lines.length < 2) return lines;

    final merged = <Map<String, double>>[];
    merged.add(Map.from(lines.first));

    for (var i = 1; i < lines.length; i++) {
      final last = merged.last;
      final curr = lines[i];

      if (curr['startY']! - last['endY']! < _maxLineGap * 2) {
        last['endY'] = math.max(last['endY']!, curr['endY']!);
      } else {
        merged.add(Map.from(curr));
      }
    }

    return merged;
  }
}
