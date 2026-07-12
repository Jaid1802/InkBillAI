import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:inkbill_ai/services/ink_engine/ink_timeline.dart';
import 'package:inkbill_ai/features/handwriting/domain/entities/ink_stroke.dart';

final timelineProvider = Provider<InkTimeline>((ref) {
  final timeline = InkTimeline();
  ref.onDispose(() => timeline.dispose());
  return timeline;
});

final playbackStateProvider = Provider<PlaybackState>((ref) {
  final timeline = ref.watch(timelineProvider);
  return timeline.value;
});

final timelineProgressProvider = Provider<double>((ref) {
  final timeline = ref.watch(timelineProvider);
  return timeline.progress;
});

final timelineFrameProvider = StreamProvider<List<InkStroke>>((ref) {
  final timeline = ref.watch(timelineProvider);
  return timeline.onFrame;
});
