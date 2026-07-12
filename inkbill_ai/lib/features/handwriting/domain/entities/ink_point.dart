import 'package:equatable/equatable.dart';

class InkPoint extends Equatable {
  final double x;
  final double y;
  final double pressure;
  final double tiltX;
  final double tiltY;
  final int timestampMs;
  final double velocity;

  const InkPoint({
    required this.x,
    required this.y,
    this.pressure = 0.5,
    this.tiltX = 0.0,
    this.tiltY = 0.0,
    required this.timestampMs,
    this.velocity = 0.0,
  });

  InkPoint copyWith({
    double? x,
    double? y,
    double? pressure,
    double? tiltX,
    double? tiltY,
    int? timestampMs,
    double? velocity,
  }) {
    return InkPoint(
      x: x ?? this.x,
      y: y ?? this.y,
      pressure: pressure ?? this.pressure,
      tiltX: tiltX ?? this.tiltX,
      tiltY: tiltY ?? this.tiltY,
      timestampMs: timestampMs ?? this.timestampMs,
      velocity: velocity ?? this.velocity,
    );
  }

  @override
  List<Object?> get props => [x, y, pressure, tiltX, tiltY, timestampMs, velocity];
}
