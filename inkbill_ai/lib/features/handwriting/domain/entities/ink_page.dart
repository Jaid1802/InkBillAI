import 'package:equatable/equatable.dart';
import 'ink_stroke.dart';

class InkPage extends Equatable {
  final String id;
  final String? billId;
  final List<InkStroke> strokes;
  final DateTime createdAt;
  final DateTime updatedAt;
  final String? label;

  const InkPage({
    required this.id,
    this.billId,
    this.strokes = const [],
    required this.createdAt,
    required this.updatedAt,
    this.label,
  });

  int get strokeCount => strokes.length;
  int get totalPoints =>
      strokes.fold(0, (sum, stroke) => sum + stroke.pointCount);

  InkPage copyWith({
    String? id,
    String? billId,
    List<InkStroke>? strokes,
    DateTime? createdAt,
    DateTime? updatedAt,
    String? label,
  }) {
    return InkPage(
      id: id ?? this.id,
      billId: billId ?? this.billId,
      strokes: strokes ?? this.strokes,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      label: label ?? this.label,
    );
  }

  @override
  List<Object?> get props =>
      [id, billId, strokes, createdAt, updatedAt, label];
}
