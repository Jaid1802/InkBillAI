import 'dart:convert';

import 'package:inkbill_ai/features/handwriting/domain/entities/ink_point.dart';

class InkPointModel {
  static Map<String, dynamic> toJson(InkPoint point) {
    return {
      'x': point.x,
      'y': point.y,
      'pressure': point.pressure,
      'tiltX': point.tiltX,
      'tiltY': point.tiltY,
      'timestampMs': point.timestampMs,
      'velocity': point.velocity,
    };
  }

  static InkPoint fromJson(Map<String, dynamic> json) {
    return InkPoint(
      x: (json['x'] as num).toDouble(),
      y: (json['y'] as num).toDouble(),
      pressure: (json['pressure'] as num?)?.toDouble() ?? 0.5,
      tiltX: (json['tiltX'] as num?)?.toDouble() ?? 0.0,
      tiltY: (json['tiltY'] as num?)?.toDouble() ?? 0.0,
      timestampMs: json['timestampMs'] as int,
      velocity: (json['velocity'] as num?)?.toDouble() ?? 0.0,
    );
  }

  static String listToJson(List<InkPoint> points) {
    return jsonEncode(points.map((p) => InkPointModel.toJson(p)).toList());
  }

  static List<InkPoint> listFromJson(String json) {
    try {
      final list = jsonDecode(json) as List;
      return list.map((e) => InkPointModel.fromJson(e as Map<String, dynamic>)).toList();
    } catch (_) {
      return [];
    }
  }
}
