import 'package:equatable/equatable.dart';
import 'ink_point.dart';

class InkStroke extends Equatable {
  final String id;
  final String pageId;
  final List<InkPoint> points;
  final int color;
  final double width;
  final DateTime createdAt;
  final bool isErased;

  const InkStroke({
    required this.id,
    required this.pageId,
    required this.points,
    this.color = 0xFF212121,
    this.width = 3.0,
    required this.createdAt,
    this.isErased = false,
  });

  int get pointCount => points.length;
  int get durationMs =>
      points.length >= 2
          ? points.last.timestampMs - points.first.timestampMs
          : 0;

  InkStroke copyWith({
    String? id,
    String? pageId,
    List<InkPoint>? points,
    int? color,
    double? width,
    DateTime? createdAt,
    bool? isErased,
  }) {
    return InkStroke(
      id: id ?? this.id,
      pageId: pageId ?? this.pageId,
      points: points ?? this.points,
      color: color ?? this.color,
      width: width ?? this.width,
      createdAt: createdAt ?? this.createdAt,
      isErased: isErased ?? this.isErased,
    );
  }

  @override
  List<Object?> get props =>
      [id, pageId, points, color, width, createdAt, isErased];
}
