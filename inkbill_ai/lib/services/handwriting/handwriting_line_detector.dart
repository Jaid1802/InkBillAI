import 'dart:math' as math;
import 'package:inkbill_ai/features/handwriting/domain/entities/ink_stroke.dart';
import 'package:inkbill_ai/services/handwriting/models/handwriting_line.dart';

class HandwritingLineDetector {
  final double _rowThreshold;
  final double _columnGap;
  final double _padding;

  const HandwritingLineDetector({
    double rowThreshold = 30.0,
    double columnGap = 50.0,
    double padding = 8.0,
  })  : _rowThreshold = rowThreshold,
        _columnGap = columnGap,
        _padding = padding;

  List<HandwritingLine> detectLines(List<InkStroke> strokes) {
    if (strokes.isEmpty) return [];

    final sorted = List<InkStroke>.from(strokes)
      ..sort((a, b) => a.points.first.y.compareTo(b.points.first.y));

    final bounded = sorted.map((s) => _StrokeBounds.from(s)).toList();
    final rows = _clusterByY(bounded);

    _sortRowsByPosition(rows);
    final lines = <HandwritingLine>[];

    for (var i = 0; i < rows.length; i++) {
      final rowBounds = rows[i];
      final rowStrokes = rowBounds.map((b) => b.stroke).toList();
      _sortStrokesByX(rowStrokes);

      final lineY = rowBounds.map((b) => b.minY).reduce(math.min);
      final lineMaxY = rowBounds.map((b) => b.maxY).reduce(math.max);
      final lineHeight = lineMaxY - lineY;

      final lineSpacing = _computeLineSpacing(i, rows);

      lines.add(HandwritingLine(
        index: i,
        strokes: rowStrokes,
        y: lineY,
        height: lineHeight,
        lineSpacing: lineSpacing,
      ));
    }

    return lines;
  }

  List<List<_StrokeBounds>> _clusterByY(List<_StrokeBounds> bounded) {
    final clusters = <List<_StrokeBounds>>[];

    for (final b in bounded) {
      bool added = false;
      for (final cluster in clusters) {
        final clusterMinY = cluster.map((cb) => cb.minY).reduce(math.min);
        final clusterMaxY = cluster.map((cb) => cb.maxY).reduce(math.max);
        final clusterMid = (clusterMinY + clusterMaxY) / 2;

        if ((b.midY - clusterMid).abs() <= _rowThreshold + (clusterMaxY - clusterMinY) / 2) {
          cluster.add(b);
          added = true;
          break;
        }
      }
      if (!added) {
        clusters.add([b]);
      }
    }

    _mergeOverlappingClusters(clusters);

    return clusters;
  }

  void _mergeOverlappingClusters(List<List<_StrokeBounds>> clusters) {
    bool merged;
    do {
      merged = false;
      for (var i = 0; i < clusters.length; i++) {
        for (var j = i + 1; j < clusters.length; j++) {
          if (_clustersOverlap(clusters[i], clusters[j])) {
            clusters[i].addAll(clusters[j]);
            clusters.removeAt(j);
            merged = true;
            break;
          }
        }
        if (merged) break;
      }
    } while (merged);
  }

  bool _clustersOverlap(
      List<_StrokeBounds> a, List<_StrokeBounds> b) {
    final aMinY = a.map((cb) => cb.minY).reduce(math.min);
    final aMaxY = a.map((cb) => cb.maxY).reduce(math.max);
    final bMinY = b.map((cb) => cb.minY).reduce(math.min);
    final bMaxY = b.map((cb) => cb.maxY).reduce(math.max);
    return aMinY <= bMaxY && bMinY <= aMaxY;
  }

  void _sortRowsByPosition(List<List<_StrokeBounds>> rows) {
    rows.sort((a, b) {
      final aY = a.map((cb) => cb.minY).reduce(math.min);
      final bY = b.map((cb) => cb.minY).reduce(math.min);
      return aY.compareTo(bY);
    });
  }

  void _sortStrokesByX(List<InkStroke> strokes) {
    strokes.sort((a, b) => a.points.first.x.compareTo(b.points.first.x));
  }

  double _computeLineSpacing(int index, List<List<_StrokeBounds>> rows) {
    if (index == rows.length - 1) return 0.0;
    final currentMaxY = rows[index].map((b) => b.maxY).reduce(math.max);
    final nextMinY = rows[index + 1].map((b) => b.minY).reduce(math.min);
    return (nextMinY - currentMaxY).clamp(0.0, double.infinity);
  }
}

class _StrokeBounds {
  final InkStroke stroke;
  final double minX, minY, maxX, maxY;

  double get midX => (minX + maxX) / 2;
  double get midY => (minY + maxY) / 2;
  double get width => maxX - minX;
  double get height => maxY - minY;
  double get aspect => height > 0 ? width / height : 0;

  _StrokeBounds._({
    required this.stroke,
    required this.minX,
    required this.minY,
    required this.maxX,
    required this.maxY,
  });

  factory _StrokeBounds.from(InkStroke stroke) {
    var minX = double.infinity, minY = double.infinity;
    var maxX = double.negativeInfinity, maxY = double.negativeInfinity;
    for (final p in stroke.points) {
      if (p.x < minX) minX = p.x;
      if (p.y < minY) minY = p.y;
      if (p.x > maxX) maxX = p.x;
      if (p.y > maxY) maxY = p.y;
    }
    return _StrokeBounds._(
      stroke: stroke,
      minX: minX,
      minY: minY,
      maxX: maxX,
      maxY: maxY,
    );
  }
}
