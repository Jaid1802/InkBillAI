import 'dart:convert';
import 'package:inkbill_ai/features/handwriting/domain/entities/ink_stroke.dart';
import 'package:inkbill_ai/features/handwriting/domain/entities/ink_point.dart';
import 'ink_point_model.dart';

class InkStrokeModel {
  static Map<String, dynamic> toJson(InkStroke stroke) {
    return {
      'id': stroke.id,
      'pageId': stroke.pageId,
      'points': stroke.points.map((p) => InkPointModel.toJson(p)).toList(),
      'color': stroke.color,
      'width': stroke.width,
      'createdAt': stroke.createdAt.millisecondsSinceEpoch,
      'isErased': stroke.isErased,
    };
  }

  static InkStroke fromJson(Map<String, dynamic> json) {
    final pointsList = (json['points'] as List)
        .map((e) => InkPointModel.fromJson(e as Map<String, dynamic>))
        .toList();
    return InkStroke(
      id: json['id'] as String,
      pageId: json['pageId'] as String,
      points: pointsList,
      color: json['color'] as int? ?? 0xFF212121,
      width: (json['width'] as num?)?.toDouble() ?? 3.0,
      createdAt: DateTime.fromMillisecondsSinceEpoch(json['createdAt'] as int),
      isErased: json['isErased'] as bool? ?? false,
    );
  }

  static String pointsToJson(List<InkPoint> points) {
    return jsonEncode(points.map((p) => InkPointModel.toJson(p)).toList());
  }

  static List<InkPoint> pointsFromJson(String json) {
    final list = jsonDecode(json) as List;
    return list
        .map((e) => InkPointModel.fromJson(e as Map<String, dynamic>))
        .toList();
  }
}
