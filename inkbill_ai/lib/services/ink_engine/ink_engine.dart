import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:inkbill_ai/core/constants/app_constants.dart';
import 'package:inkbill_ai/features/handwriting/domain/entities/ink_point.dart';
import 'package:inkbill_ai/features/handwriting/domain/entities/ink_stroke.dart';
import 'package:inkbill_ai/core/utils/math_utils.dart';

enum StrokePhase { begin, move, end }

enum InkEngineMode { draw, erase, pan }

class InkEngineState {
  final InkStroke? currentStroke;
  final List<InkStroke> completedStrokes;
  final InkEngineMode mode;
  final int strokeCount;
  final DateTime? lastStrokeTime;

  const InkEngineState({
    this.currentStroke,
    this.completedStrokes = const [],
    this.mode = InkEngineMode.draw,
    this.strokeCount = 0,
    this.lastStrokeTime,
  });

  InkEngineState copyWith({
    InkStroke? currentStroke,
    List<InkStroke>? completedStrokes,
    InkEngineMode? mode,
    int? strokeCount,
    DateTime? lastStrokeTime,
  }) {
    return InkEngineState(
      currentStroke: currentStroke ?? this.currentStroke,
      completedStrokes: completedStrokes ?? this.completedStrokes,
      mode: mode ?? this.mode,
      strokeCount: strokeCount ?? this.strokeCount,
      lastStrokeTime: lastStrokeTime ?? this.lastStrokeTime,
    );
  }
}

class InkEngine extends ValueNotifier<InkEngineState> {
  final String pageId;
  final StreamController<InkStroke> _strokeCompleted =
      StreamController<InkStroke>.broadcast();
  final StreamController<InkStroke> _strokeUpdated =
      StreamController<InkStroke>.broadcast();

  Stream<InkStroke> get onStrokeCompleted => _strokeCompleted.stream;
  Stream<InkStroke> get onStrokeUpdated => _strokeUpdated.stream;

  InkEngine({required this.pageId})
      : super(const InkEngineState(strokeCount: 0));

  int _startTimestamp = 0;
  int _lastTimestamp = 0;
  double _lastX = 0;
  double _lastY = 0;

  void beginStroke(
    double x,
    double y, {
    double pressure = 0.5,
    double tiltX = 0.0,
    double tiltY = 0.0,
    int? timestampMs,
    int color = 0xFF212121,
    double width = 3.0,
  }) {
    final now = timestampMs ?? DateTime.now().millisecondsSinceEpoch;
    _startTimestamp = now;
    _lastTimestamp = now;
    _lastX = x;
    _lastY = y;

    final point = InkPoint(
      x: x,
      y: y,
      pressure: pressure,
      tiltX: tiltX,
      tiltY: tiltY,
      timestampMs: now,
      velocity: 0,
    );

    final stroke = InkStroke(
      id: _generateStrokeId(),
      pageId: pageId,
      points: [point],
      color: color,
      width: width,
      createdAt: DateTime.now(),
    );

    value = value.copyWith(
      currentStroke: stroke,
      mode: InkEngineMode.draw,
    );
  }

  void updateStroke(
    double x,
    double y, {
    double pressure = 0.5,
    double tiltX = 0.0,
    double tiltY = 0.0,
    int? timestampMs,
  }) {
    final current = value.currentStroke;
    if (current == null) return;

    final now = timestampMs ?? DateTime.now().millisecondsSinceEpoch;
    final dt = now - _lastTimestamp;
    final velocity = MathUtils.calculateVelocity(_lastX, _lastY, x, y, dt.toDouble());

    final point = InkPoint(
      x: x,
      y: y,
      pressure: pressure,
      tiltX: tiltX,
      tiltY: tiltY,
      timestampMs: now,
      velocity: velocity,
    );

    _lastTimestamp = now;
    _lastX = x;
    _lastY = y;

    if (current.points.length >= AppConstants.maxPointsPerStroke) {
      endStroke(timestampMs: now);
      beginStroke(x, y, pressure: pressure, tiltX: tiltX, tiltY: tiltY,
          timestampMs: now, color: current.color, width: current.width);
      return;
    }

    final updatedStroke = current.copyWith(points: [...current.points, point]);
    value = value.copyWith(currentStroke: updatedStroke);
    _strokeUpdated.add(updatedStroke);
  }

  void endStroke({int? timestampMs}) {
    final current = value.currentStroke;
    if (current == null || current.points.isEmpty) return;

    final completedStroke = current.copyWith(
      points: _simplifyStroke(current.points),
    );

    value = value.copyWith(
      currentStroke: null,
      completedStrokes: [...value.completedStrokes, completedStroke],
      strokeCount: value.strokeCount + 1,
      lastStrokeTime: DateTime.now(),
    );

    _strokeCompleted.add(completedStroke);
  }

  void cancelStroke() {
    value = value.copyWith(currentStroke: null);
  }

  void undo() {
    if (value.completedStrokes.isEmpty) return;
    final strokes = List<InkStroke>.from(value.completedStrokes);
    strokes.removeLast();
    value = value.copyWith(
      completedStrokes: strokes,
      strokeCount: value.strokeCount - 1,
    );
  }

  void clear() {
    value = value.copyWith(
      currentStroke: null,
      completedStrokes: [],
      strokeCount: 0,
      lastStrokeTime: null,
    );
  }

  void setMode(InkEngineMode mode) {
    if (value.currentStroke != null) endStroke();
    value = value.copyWith(mode: mode);
  }

  void loadStrokes(List<InkStroke> strokes) {
    value = value.copyWith(
      completedStrokes: strokes,
      strokeCount: strokes.length,
    );
  }

  List<InkPoint> _simplifyStroke(List<InkPoint> points) {
    if (points.length <= 3) return points;
    const tolerance = 0.5;
    final simplified = <InkPoint>[];
    simplified.add(points.first);

    for (var i = 1; i < points.length - 1; i++) {
      final prev = points[i - 1];
      final curr = points[i];
      if (_isSignificantPoint(prev, curr, tolerance)) {
        simplified.add(curr);
      }
    }
    simplified.add(points.last);
    return simplified;
  }

  bool _isSignificantPoint(InkPoint a, InkPoint b, double tolerance) {
    final dx = a.x - b.x;
    final dy = a.y - b.y;
    return (dx * dx + dy * dy) > tolerance;
  }

  String _generateStrokeId() {
    final timestamp = DateTime.now().microsecondsSinceEpoch;
    final random = (timestamp % 10000).toString().padLeft(4, '0');
    return 'str_${timestamp}_$random';
  }

  @override
  void dispose() {
    _strokeCompleted.close();
    _strokeUpdated.close();
    super.dispose();
  }
}
