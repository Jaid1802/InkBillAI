import 'dart:math' as math;
import 'package:inkbill_ai/features/handwriting/domain/entities/ink_stroke.dart';
import 'package:inkbill_ai/features/handwriting/domain/entities/ink_point.dart';

class DetectedLine {
  final double y;
  final double height;
  final List<InkStroke> strokes;

  const DetectedLine({
    required this.y,
    required this.height,
    required this.strokes,
  });
}

class TextRegion {
  final double x;
  final double y;
  final double width;
  final double height;
  final String classification;
  final double confidence;

  const TextRegion({
    required this.x,
    required this.y,
    required this.width,
    required this.height,
    this.classification = 'unknown',
    this.confidence = 0.0,
  });
}

class LayoutAnalysisResult {
  final List<DetectedLine> lines;
  final List<TextRegion> regions;
  final double confidence;

  const LayoutAnalysisResult({
    this.lines = const [],
    this.regions = const [],
    this.confidence = 0.0,
  });
}

class LayoutAnalyzer {
  static const double _lineHeightThreshold = 30.0;
  static const double _lineGapThreshold = 15.0;
  static const double _wordGapThreshold = 20.0;
  static const double _columnThreshold = 40.0;

  LayoutAnalysisResult analyze(List<InkStroke> strokes) {
    if (strokes.isEmpty) {
      return const LayoutAnalysisResult();
    }

    final lines = _detectLines(strokes);
    final regions = _detectRegions(lines);
    final confidence = _calculateConfidence(lines, strokes.length);

    return LayoutAnalysisResult(
      lines: lines,
      regions: regions,
      confidence: confidence,
    );
  }

  List<DetectedLine> _detectLines(List<InkStroke> strokes) {
    final sorted = List<InkStroke>.from(strokes)
      ..sort((a, b) => a.points.first.y.compareTo(b.points.first.y));

    final lines = <List<InkStroke>>[];

    for (final stroke in sorted) {
      bool added = false;
      final strokeMidY = _strokeMidY(stroke);

      for (var i = 0; i < lines.length; i++) {
        final lineMidY = _lineMidY(lines[i]);
        if ((strokeMidY - lineMidY).abs() <= _lineHeightThreshold) {
          lines[i].add(stroke);
          added = true;
          break;
        }
      }

      if (!added) {
        lines.add([stroke]);
      }
    }

    for (final line in lines) {
      line.sort((a, b) => a.points.first.x.compareTo(b.points.first.x));
    }

    return lines.map((strokes) {
      final minY = strokes
          .expand((s) => s.points)
          .map((p) => p.y)
          .reduce((a, b) => a < b ? a : b);
      final maxY = strokes
          .expand((s) => s.points)
          .map((p) => p.y)
          .reduce((a, b) => a > b ? a : b);
      return DetectedLine(
        y: minY,
        height: (maxY - minY).clamp(10, _lineHeightThreshold * 2),
        strokes: strokes,
      );
    }).toList();
  }

  List<TextRegion> _detectRegions(List<DetectedLine> lines) {
    final regions = <TextRegion>[];

    for (final line in lines) {
      final columns = _splitIntoColumns(line.strokes);

      for (var colIdx = 0; colIdx < columns.length; colIdx++) {
        final colStrokes = columns[colIdx];
        if (colStrokes.isEmpty) continue;

        var minX = double.infinity, maxX = double.negativeInfinity;
        var minY = double.infinity, maxY = double.negativeInfinity;
        for (final s in colStrokes) {
          for (final p in s.points) {
            if (p.x < minX) minX = p.x;
            if (p.x > maxX) maxX = p.x;
            if (p.y < minY) minY = p.y;
            if (p.y > maxY) maxY = p.y;
          }
        }

        final classification = _classifyColumn(colIdx, columns.length, minX);

        regions.add(TextRegion(
          x: minX,
          y: minY,
          width: (maxX - minX).clamp(5, double.infinity),
          height: (maxY - minY).clamp(5, double.infinity),
          classification: classification,
          confidence: 0.7,
        ));
      }
    }

    return regions;
  }

  List<List<InkStroke>> _splitIntoColumns(List<InkStroke> rowStrokes) {
    if (rowStrokes.isEmpty) return [];

    final groups = <List<InkStroke>>[];
    for (final stroke in rowStrokes) {
      bool grouped = false;
      for (final group in groups) {
        final lastX = group.last.points.last.x;
        if ((stroke.points.first.x - lastX).abs() <= _wordGapThreshold) {
          group.add(stroke);
          grouped = true;
          break;
        }
      }
      if (!grouped) groups.add([stroke]);
    }

    final columns = <List<InkStroke>>[];
    for (final group in groups) {
      if (group.isEmpty) continue;
      bool merged = false;
      for (final col in columns) {
        final colEndX = col.last.points.last.x;
        final groupStartX = group.first.points.first.x;
        if ((groupStartX - colEndX).abs() <= _columnThreshold) {
          col.addAll(group);
          merged = true;
          break;
        }
      }
      if (!merged) columns.add(group);
    }

    return columns;
  }

  String _classifyColumn(int colIdx, int totalCols, double avgX) {
    if (totalCols <= 1) return 'item';

    final ratio = colIdx / (totalCols - 1);

    if (ratio < 0.33) return 'item';
    if (ratio < 0.66) return 'quantity';
    return 'rate';
  }

  double _calculateConfidence(List<DetectedLine> lines, int totalStrokes) {
    if (lines.isEmpty || totalStrokes == 0) return 0.0;

    final lineDensity = totalStrokes / lines.length;
    double confidence = 0.5;

    if (lineDensity >= 2) confidence += 0.15;
    if (lines.length >= 1 && lines.length <= 20) confidence += 0.1;
    if (lines.every((l) => l.height > 5 && l.height < 100)) confidence += 0.1;

    bool hasConsistentGaps = true;
    for (var i = 1; i < lines.length; i++) {
      final gap = lines[i].y - (lines[i - 1].y + lines[i - 1].height);
      if (gap < 0 || gap > _lineHeightThreshold * 3) {
        hasConsistentGaps = false;
        break;
      }
    }
    if (hasConsistentGaps && lines.length > 1) confidence += 0.15;

    return confidence.clamp(0.0, 1.0);
  }

  double _strokeMidY(InkStroke stroke) {
    if (stroke.points.isEmpty) return 0;
    var sum = 0.0;
    for (final p in stroke.points) sum += p.y;
    return sum / stroke.points.length;
  }

  double _lineMidY(List<InkStroke> strokes) {
    if (strokes.isEmpty) return 0;
    var sum = 0.0;
    var count = 0;
    for (final s in strokes) {
      for (final p in s.points) {
        sum += p.y;
        count++;
      }
    }
    return count > 0 ? sum / count : 0;
  }
}
