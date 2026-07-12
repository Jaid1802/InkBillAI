import 'package:equatable/equatable.dart';

enum TimelineEventType { strokeBegin, strokeMove, strokeEnd, strokeErase, undo, redo, pageClear, pageChange }

class InkTimelineEvent extends Equatable {
  final String id;
  final TimelineEventType type;
  final String strokeId;
  final String pageId;
  final int timestampMs;
  final Map<String, dynamic> metadata;

  const InkTimelineEvent({
    required this.id,
    required this.type,
    required this.strokeId,
    required this.pageId,
    required this.timestampMs,
    this.metadata = const {},
  });

  @override
  List<Object?> get props =>
      [id, type, strokeId, pageId, timestampMs, metadata];
}
