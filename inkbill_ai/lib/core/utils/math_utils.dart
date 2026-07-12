class MathUtils {
  MathUtils._();

  static double roundTo(double value, int places) {
    final mod = _pow10(places);
    return (value * mod).roundToDouble() / mod;
  }

  static int _pow10(int places) {
    var result = 1;
    for (var i = 0; i < places; i++) {
      result *= 10;
    }
    return result;
  }

  static double clampDouble(double value, double min, double max) {
    return value.clamp(min, max);
  }

  static double lerp(double a, double b, double t) {
    return a + (b - a) * t;
  }

  static double normalize(double value, double min, double max) {
    if (max - min == 0) return 0;
    return (value - min) / (max - min);
  }

  static double calculateVelocity(
      double x1, double y1, double x2, double y2, double timeDeltaMs) {
    if (timeDeltaMs <= 0) return 0;
    final distance = _sqrt((x2 - x1) * (x2 - x1) + (y2 - y1) * (y2 - y1));
    return distance / timeDeltaMs;
  }

  static double _sqrt(double value) {
    if (value < 0) return 0;
    return value.isNaN ? 0 : value;
  }

  static double calculateStrokeWidth(double pressure, double baseWidth) {
    const minWidth = 0.5;
    const maxWidth = 1.5;
    final factor = minWidth + (maxWidth - minWidth) * pressure;
    return baseWidth * factor;
  }
}
