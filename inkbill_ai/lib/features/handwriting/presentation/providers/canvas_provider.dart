import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:inkbill_ai/services/canvas_engine/canvas_engine.dart';

final canvasEngineProvider = Provider.family<CanvasEngine, String>((ref, pageId) {
  final engine = CanvasEngine(pageId: pageId);
  ref.onDispose(() => engine.dispose());
  return engine;
});

final canvasStateProvider = Provider.family<CanvasState, String>((ref, pageId) {
  final engine = ref.watch(canvasEngineProvider(pageId));
  void listener() => ref.invalidateSelf();
  engine.addListener(listener);
  ref.onDispose(() => engine.removeListener(listener));
  return engine.value;
});
