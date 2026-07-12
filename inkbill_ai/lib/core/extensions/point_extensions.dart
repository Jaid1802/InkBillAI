import 'dart:math' show sqrt;
import 'dart:ui' show Offset;

extension OffsetExtensions on Offset {
  double distanceTo(Offset other) {
    final dx = this.dx - other.dx;
    final dy = this.dy - other.dy;
    return sqrt(dx * dx + dy * dy);
  }

  Offset midpointTo(Offset other) {
    return Offset(
      (dx + other.dx) / 2,
      (dy + other.dy) / 2,
    );
  }

  double get magnitude => sqrt(dx * dx + dy * dy);
}

extension ListOffsetExtensions on List<Offset> {
  List<Offset> simplify(double tolerance) {
    if (length <= 2) return this;
    return _ramerDouglasPeucker(this, tolerance);
  }

  List<Offset> _ramerDouglasPeucker(List<Offset> points, double epsilon) {
    if (points.length <= 2) return points;

    var dmax = 0.0;
    var index = 0;
    final end = points.length - 1;

    for (var i = 1; i < end; i++) {
      final d = _perpendicularDistance(points[i], points[0], points[end]);
      if (d > dmax) {
        index = i;
        dmax = d;
      }
    }

    if (dmax > epsilon) {
      final left = _ramerDouglasPeucker(points.sublist(0, index + 1), epsilon);
      final right =
          _ramerDouglasPeucker(points.sublist(index, points.length), epsilon);
      return [...left.sublist(0, left.length - 1), ...right];
    }

    return [points.first, points.last];
  }

  double _perpendicularDistance(Offset point, Offset lineStart, Offset lineEnd) {
    final dx = lineEnd.dx - lineStart.dx;
    final dy = lineEnd.dy - lineStart.dy;
    final mag = dx * dx + dy * dy;
    if (mag == 0) return point.distanceTo(lineStart);
    final u = ((point.dx - lineStart.dx) * dx + (point.dy - lineStart.dy) * dy) / mag;
    final clamped = u.clamp(0.0, 1.0);
    final closest = Offset(lineStart.dx + clamped * dx, lineStart.dy + clamped * dy);
    return (point.distanceTo(closest));
  }
}
