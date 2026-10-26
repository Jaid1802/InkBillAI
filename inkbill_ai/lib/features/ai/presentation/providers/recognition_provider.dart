import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;
import 'package:inkbill_ai/features/ai/domain/repositories/recognition_repository.dart';
import 'package:inkbill_ai/features/ai/data/datasources/paddle_ocr_datasource.dart';
import 'package:inkbill_ai/features/ai/data/repositories/recognition_repository_impl.dart';
import 'package:inkbill_ai/features/ai/domain/entities/recognition_result.dart';
import 'package:inkbill_ai/features/handwriting/domain/entities/ink_stroke.dart';
import 'package:inkbill_ai/services/recognition/recognition_pipeline.dart';

final httpClientProvider = Provider<http.Client>((ref) {
  final client = http.Client();
  ref.onDispose(() => client.close());
  return client;
});

final paddleOcrDataSourceProvider = Provider<PaddleOcrDataSource>((ref) {
  final client = ref.watch(httpClientProvider);
  return PaddleOcrDataSource(client: client);
});

final recognitionRepositoryProvider = Provider<RecognitionRepository>((ref) {
  final dataSource = ref.watch(paddleOcrDataSourceProvider);
  return RecognitionRepositoryImpl(dataSource);
});

final recognitionPipelineProvider = Provider<RecognitionPipeline>((ref) {
  final repo = ref.watch(recognitionRepositoryProvider);
  final pipeline = RecognitionPipeline(repository: repo);
  ref.onDispose(() => pipeline.dispose());
  return pipeline;
});

final pipelineStateProvider = Provider<RecognitionPipelineState>((ref) {
  final pipeline = ref.watch(recognitionPipelineProvider);
  return pipeline.value;
});

final recognitionResultProvider =
    FutureProvider.family<RecognitionResult, List<InkStroke>>((ref, strokes) async {
  final pipeline = ref.watch(recognitionPipelineProvider);
  final result = await pipeline.recognizeStrokes(strokes);
  return result.dataOrNull ?? const RecognitionResult();
});
