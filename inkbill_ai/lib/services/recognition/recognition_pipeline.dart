import 'package:flutter/foundation.dart';
import 'package:inkbill_ai/core/utils/result.dart';
import 'package:inkbill_ai/features/ai/domain/entities/recognition_result.dart';
import 'package:inkbill_ai/features/ai/domain/repositories/recognition_repository.dart';
import 'package:inkbill_ai/features/handwriting/domain/entities/ink_stroke.dart';

enum PipelineStage { idle, capturing, preprocessing, recognizing, postprocessing, complete, error }

enum RecognitionModelType { mlKit, tensorFlowLite, onnxRuntime }

class RecognitionPipelineState {
  final PipelineStage stage;
  final RecognitionResult? result;
  final double progress;
  final String? error;

  const RecognitionPipelineState({
    this.stage = PipelineStage.idle,
    this.result,
    this.progress = 0.0,
    this.error,
  });

  RecognitionPipelineState copyWith({
    PipelineStage? stage,
    RecognitionResult? result,
    double? progress,
    String? error,
  }) {
    return RecognitionPipelineState(
      stage: stage ?? this.stage,
      result: result ?? this.result,
      progress: progress ?? this.progress,
      error: error ?? this.error,
    );
  }
}

abstract class RecognitionModel {
  Future<Result<RecognitionResult>> recognize(List<InkStroke> strokes);
  Future<Result<bool>> initialize();
  Future<Result<void>> dispose();
  RecognitionModelType get modelType;
}

class RecognitionPipeline extends ValueNotifier<RecognitionPipelineState> {
  final RecognitionRepository _repository;
  RecognitionModel? _activeModel;

  RecognitionPipeline({required RecognitionRepository repository})
      : _repository = repository,
        super(const RecognitionPipelineState());

  RecognitionModel? get activeModel => _activeModel;
  RecognitionModelType? get activeModelType => _activeModel?.modelType;

  Future<void> setModel(RecognitionModel model) async {
    await _activeModel?.dispose();
    final initResult = await model.initialize();
    if (initResult.isSuccess && initResult.dataOrThrow) {
      _activeModel = model;
    }
  }

  Future<Result<RecognitionResult>> recognizeStrokes(
      List<InkStroke> strokes) async {
    value = value.copyWith(stage: PipelineStage.recognizing, progress: 0.3);

    if (_activeModel != null) {
      final modelResult = await _activeModel!.recognize(strokes);
      if (modelResult.isSuccess && modelResult.dataOrThrow.isHighConfidence) {
        value = value.copyWith(
          stage: PipelineStage.complete,
          result: modelResult.dataOrThrow,
          progress: 1.0,
        );
        return modelResult;
      }
    }

    value = value.copyWith(progress: 0.7);
    final repoResult = await _repository.recognizeStrokes(strokes);

    return repoResult.when(
      success: (data) {
        value = value.copyWith(
          stage: PipelineStage.complete,
          result: data,
          progress: 1.0,
        );
        return Result<RecognitionResult>.success(data);
      },
      error: (failure) {
        value = value.copyWith(
          stage: PipelineStage.error,
          error: failure.message,
        );
        return Result<RecognitionResult>.error(failure);
      },
    );
  }

  Future<Result<BillStructureResult>> extractBillStructure(
      List<InkStroke> strokes) async {
    value = value.copyWith(stage: PipelineStage.recognizing, progress: 0.2);
    final layoutResult = await _repository.detectLayout(strokes);
    if (layoutResult is Error) {
      value = value.copyWith(stage: PipelineStage.error, error: layoutResult.errorOrNull?.message);
      return Result<BillStructureResult>.error(layoutResult.errorOrNull!);
    }

    value = value.copyWith(progress: 0.6);
    return _repository.extractBillStructure(strokes);
  }

  void reset() {
    value = const RecognitionPipelineState();
  }

  @override
  void dispose() {
    _activeModel?.dispose();
    super.dispose();
  }
}
