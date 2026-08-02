import 'dart:math' as math;
import 'package:inkbill_ai/features/handwriting/domain/entities/ink_stroke.dart';
import 'package:inkbill_ai/services/handwriting/models/handwriting_line.dart';

class FieldClassifier {
  final double _gapThreshold;

  const FieldClassifier({double gapThreshold = 25.0})
      : _gapThreshold = gapThreshold;

  List<RecognizedField> classify(HandwritingLine line) {
    if (line.strokes.isEmpty) return [];

    final sorted = List<InkStroke>.from(line.strokes)
      ..sort((a, b) => a.points.first.x.compareTo(b.points.first.x));

    final segments = _segmentByGap(sorted);

    return segments.map((segment) {
      final type = _detectFieldType(segment);
      final bounds = _computeBounds(segment);
      return RecognizedField(
        type: type,
        text: '',
        confidence: 0.0,
        x: bounds['minX'] as double,
        y: bounds['minY'] as double,
        width: bounds['width'] as double,
        height: bounds['height'] as double,
        strokeCount: segment.length,
      );
    }).toList();
  }

  List<List<InkStroke>> _segmentByGap(List<InkStroke> strokes) {
    final segments = <List<InkStroke>>[];
    List<InkStroke>? current;

    for (final stroke in strokes) {
      if (current == null || current.isEmpty) {
        current = [stroke];
      } else {
        final lastX = current.last.points.last.x;
        final firstX = stroke.points.first.x;
        if ((firstX - lastX).abs() <= _gapThreshold) {
          current.add(stroke);
        } else {
          segments.add(current);
          current = [stroke];
        }
      }
    }
    if (current != null && current.isNotEmpty) {
      segments.add(current);
    }

    return segments;
  }

  FieldType _detectFieldType(List<InkStroke> strokes) {
    if (strokes.isEmpty) return FieldType.unknown;

    int numericStrokes = 0;
    int alphaStrokes = 0;

    for (final stroke in strokes) {
      final bounds = _computeBoundsFromPoints(stroke.points);
      final w = bounds['width'] as double;
      final h = bounds['height'] as double;
      final aspect = h > 0 ? w / h : (w > 0 ? 1.0 : 0.0);

      final pointCount = stroke.points.length;
      if (pointCount < 3) continue;

      if (_looksLikeDigitStroke(stroke, aspect)) {
        numericStrokes++;
      } else {
        alphaStrokes++;
      }
    }

    if (numericStrokes > 0 && alphaStrokes == 0) return FieldType.number;
    if (alphaStrokes > 0 && numericStrokes == 0) return FieldType.word;
    if (numericStrokes >= alphaStrokes && numericStrokes > 0) {
      return FieldType.number;
    }
    return FieldType.word;
  }

  bool _looksLikeDigitStroke(InkStroke stroke, double aspect) {
    final bounds = _computeBoundsFromPoints(stroke.points);
    final w = bounds['width'] as double;
    final h = bounds['height'] as double;

    if (h <= 0) return false;

    if (aspect > 0.4 && aspect < 3.0) {
      final strokeLen = _strokeLength(stroke);
      final diag = math.sqrt(w * w + h * h);
      final density = diag > 0 ? strokeLen / diag : 0;

      if (density > 2.0) return false;

      if (stroke.points.length <= 6 && density < 1.5) {
        return true;
      }
    }

    return false;
  }

  double _strokeLength(InkStroke stroke) {
    double len = 0;
    for (var i = 1; i < stroke.points.length; i++) {
      final dx = stroke.points[i].x - stroke.points[i - 1].x;
      final dy = stroke.points[i].y - stroke.points[i - 1].y;
      len += math.sqrt(dx * dx + dy * dy);
    }
    return len;
  }

  Map<String, dynamic> _computeBounds(List<InkStroke> strokes) {
    var minX = double.infinity, minY = double.infinity;
    var maxX = double.negativeInfinity, maxY = double.negativeInfinity;
    for (final stroke in strokes) {
      for (final p in stroke.points) {
        if (p.x < minX) minX = p.x;
        if (p.y < minY) minY = p.y;
        if (p.x > maxX) maxX = p.x;
        if (p.y > maxY) maxY = p.y;
      }
    }
    return {'minX': minX, 'minY': minY, 'width': maxX - minX, 'height': maxY - minY};
  }

  Map<String, dynamic> _computeBoundsFromPoints(List points) {
    var minX = double.infinity, minY = double.infinity;
    var maxX = double.negativeInfinity, maxY = double.negativeInfinity;
    for (final p in points) {
      if (p.x < minX) minX = p.x;
      if (p.y < minY) minY = p.y;
      if (p.x > maxX) maxX = p.x;
      if (p.y > maxY) maxY = p.y;
    }
    return {'minX': minX, 'minY': minY, 'width': maxX - minX, 'height': maxY - minY};
  }
}
