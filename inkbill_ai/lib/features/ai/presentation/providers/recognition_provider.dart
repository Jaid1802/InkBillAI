import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:inkbill_ai/features/ai/domain/entities/recognition_result.dart';
import 'package:inkbill_ai/features/handwriting/domain/entities/ink_stroke.dart';
import 'package:inkbill_ai/features/products/presentation/providers/product_provider.dart';
import 'package:inkbill_ai/services/recognition/recognition_pipeline.dart';
import 'package:inkbill_ai/services/recognition/recognition_service.dart';
import 'package:inkbill_ai/services/recognition/shop_memory.dart';

final recognitionServiceProvider = Provider<RecognitionService>((ref) {
  final service = RecognitionService();
  ref.onDispose(() => service.dispose());
  return service;
});

final ensureRecognitionReadyProvider = FutureProvider<void>((ref) async {
  final service = ref.watch(recognitionServiceProvider);
  await service.ensureReady();
});

final initializeRecognitionProvider = FutureProvider<void>((ref) async {
  final service = ref.watch(recognitionServiceProvider);
  await service.ensureReady();

  try {
    final memory = ShopMemory();
    final products = await ref.watch(allProductsProvider.future);
    await memory.loadProducts(products);
    service.injectShopMemory(memory);
  } catch (_) {}
});

final recognitionServiceStateProvider =
    Provider<RecognitionServiceState>((ref) {
  final service = ref.watch(recognitionServiceProvider);
  return service.state.value;
});

final recognitionServiceStatusProvider = Provider<String>((ref) {
  final service = ref.watch(recognitionServiceProvider);
  return service.statusMessage.value;
});

final recognitionServiceIsReadyProvider = Provider<bool>((ref) {
  final service = ref.watch(recognitionServiceProvider);
  return service.isReady;
});

final pipelineStateProvider = Provider<RecognitionPipelineState?>((ref) {
  final service = ref.watch(recognitionServiceProvider);
  return service.pipeline?.value;
});

final recognitionResultProvider =
    FutureProvider.family<RecognitionResult, List<InkStroke>>(
  (ref, strokes) async {
    final service = ref.watch(recognitionServiceProvider);
    final result = await service.recognizeStrokes(strokes);
    if (result != RecognitionTaskResult.success) {
      return const RecognitionResult();
    }
    final pipeline = service.pipeline;
    if (pipeline == null || pipeline.value.result == null) {
      return const RecognitionResult();
    }
    return pipeline.value.result!;
  },
);
