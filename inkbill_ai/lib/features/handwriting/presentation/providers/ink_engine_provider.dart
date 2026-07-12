import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:inkbill_ai/services/ink_engine/ink_engine.dart';
import 'package:inkbill_ai/features/handwriting/domain/entities/ink_stroke.dart';

final inkEngineProvider = Provider.family<InkEngine, String>((ref, pageId) {
  final engine = InkEngine(pageId: pageId);
  ref.onDispose(() => engine.dispose());
  return engine;
});

final inkEngineStateProvider = Provider.family<InkEngineState, String>((ref, pageId) {
  final engine = ref.watch(inkEngineProvider(pageId));
  return engine.value;
});

final currentStrokeProvider = Provider.family<InkStroke?, String>((ref, pageId) {
  final state = ref.watch(inkEngineStateProvider(pageId));
  return state.currentStroke;
});

final completedStrokesProvider = Provider.family<List<InkStroke>, String>((ref, pageId) {
  final state = ref.watch(inkEngineStateProvider(pageId));
  return state.completedStrokes;
});

final engineModeProvider = Provider.family<InkEngineMode, String>((ref, pageId) {
  final state = ref.watch(inkEngineStateProvider(pageId));
  return state.mode;
});
