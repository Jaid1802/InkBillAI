import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:inkbill_ai/features/handwriting/presentation/providers/ink_pages_provider.dart';
import 'package:inkbill_ai/services/canvas_engine/canvas_engine.dart';
import 'package:inkbill_ai/services/recovery_service.dart';

final canvasEngineProvider = Provider.family<CanvasEngine, String>((ref, pageId) {
  Timer? debounceTimer;
  late final CanvasEngine engine;

  void handleAutoSave() {
    debounceTimer?.cancel();
    debounceTimer = Timer(const Duration(milliseconds: 600), () async {
      final currentStrokes = engine.value.strokes;
      final inkRepo = ref.read(inkRepositoryProvider);
      await inkRepo.clearPage(pageId);
      if (currentStrokes.isNotEmpty) {
        await inkRepo.saveStrokes(currentStrokes);
      }
      await RecoveryService.saveCanvasState(
        strokes: currentStrokes,
        pageId: pageId,
      );
    });
  }

  engine = CanvasEngine(pageId: pageId, onAutoSave: handleAutoSave);

  ref.onDispose(() {
    debounceTimer?.cancel();
    engine.dispose();
  });

  return engine;
});

final canvasStateProvider = Provider.family<CanvasState, String>((ref, pageId) {
  final engine = ref.watch(canvasEngineProvider(pageId));
  void listener() => ref.invalidateSelf();
  engine.addListener(listener);
  ref.onDispose(() => engine.removeListener(listener));
  return engine.value;
});
