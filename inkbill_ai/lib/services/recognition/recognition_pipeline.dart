import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:inkbill_ai/core/utils/result.dart';
import 'package:inkbill_ai/features/ai/domain/entities/recognition_result.dart';
import 'package:inkbill_ai/features/ai/domain/repositories/recognition_repository.dart';
import 'package:inkbill_ai/features/handwriting/domain/entities/ink_stroke.dart';
import 'package:inkbill_ai/services/recognition/layout_analyzer.dart';
import 'package:inkbill_ai/services/recognition/bill_parser.dart';
import 'package:inkbill_ai/services/recognition/ai_validator.dart';
import 'package:inkbill_ai/services/recognition/image_preprocessor.dart';
import 'package:inkbill_ai/services/canvas_engine/canvas_renderer.dart';

enum PipelineStage {
  idle,
  preprocessing,
  layoutAnalysis,
  recognizing,
  parsing,
  validating,
  complete,
  error,
}

class RecognitionPipelineState {
  final PipelineStage stage;
  final RecognitionResult? result;
  final LayoutAnalysisResult? layoutResult;
  final BillParseResult? parseResult;
  final ValidationResult? validationResult;
  final double progress;
  final String? error;

  const RecognitionPipelineState({
    this.stage = PipelineStage.idle,
    this.result,
    this.layoutResult,
    this.parseResult,
    this.validationResult,
    this.progress = 0.0,
    this.error,
  });

  RecognitionPipelineState copyWith({
    PipelineStage? stage,
    RecognitionResult? result,
    LayoutAnalysisResult? layoutResult,
    BillParseResult? parseResult,
    ValidationResult? validationResult,
    double? progress,
    String? error,
    bool clearResult = false,
    bool clearLayout = false,
    bool clearParse = false,
    bool clearValidation = false,
  }) {
    return RecognitionPipelineState(
      stage: stage ?? this.stage,
      result: clearResult ? null : (result ?? this.result),
      layoutResult: clearLayout ? null : (layoutResult ?? this.layoutResult),
      parseResult: clearParse ? null : (parseResult ?? this.parseResult),
      validationResult:
          clearValidation ? null : (validationResult ?? this.validationResult),
      progress: progress ?? this.progress,
      error: error ?? this.error,
    );
  }
}

class RecognitionPipeline extends ValueNotifier<RecognitionPipelineState> {
  final RecognitionRepository _repository;
  final ImagePreprocessor _preprocessor;
  final LayoutAnalyzer _layoutAnalyzer;
  final BillParser _billParser;
  final AIValidator _aiValidator;
  final CanvasRenderer _renderer;

  RecognitionPipeline({
    required RecognitionRepository repository,
    ImagePreprocessor? preprocessor,
    LayoutAnalyzer? layoutAnalyzer,
    BillParser? billParser,
    AIValidator? aiValidator,
    CanvasRenderer? renderer,
  })  : _repository = repository,
        _preprocessor = preprocessor ?? ImagePreprocessor(),
        _layoutAnalyzer = layoutAnalyzer ?? LayoutAnalyzer(),
        _billParser = billParser ?? BillParser(),
        _aiValidator = aiValidator ?? AIValidator(),
        _renderer = renderer ?? CanvasRenderer(),
        super(const RecognitionPipelineState());

  Future<Result<RecognitionResult>> recognizeStrokes(
    List<InkStroke> strokes,
  ) async {
    value = value.copyWith(stage: PipelineStage.preprocessing, progress: 0.1);

    value = value.copyWith(stage: PipelineStage.layoutAnalysis, progress: 0.3);
    final layoutResult = _layoutAnalyzer.analyze(strokes);
    value = value.copyWith(
      layoutResult: layoutResult,
      progress: 0.4,
    );

    value = value.copyWith(stage: PipelineStage.recognizing, progress: 0.5);
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
          progress: 0.0,
        );
        return Result<RecognitionResult>.error(failure);
      },
    );
  }

  Future<Result<BillStructureResult>> extractBillStructure(
    List<InkStroke> strokes,
  ) async {
    value = value.copyWith(stage: PipelineStage.preprocessing, progress: 0.05);

    value = value.copyWith(stage: PipelineStage.layoutAnalysis, progress: 0.2);
    final layoutResult = _layoutAnalyzer.analyze(strokes);
    value = value.copyWith(layoutResult: layoutResult, progress: 0.25);

    value = value.copyWith(stage: PipelineStage.recognizing, progress: 0.3);
    final repoResult = await _repository.extractBillStructure(strokes);

    return repoResult.when(
      success: (data) {
        value = value.copyWith(
          progress: 0.7,
        );

        value = value.copyWith(stage: PipelineStage.parsing, progress: 0.8);
        final rawLines = data.lineItems.map((item) {
          final parts = <String>[item.name];
          if (item.quantity != null) parts.add(item.quantity.toString());
          if (item.rate != null) parts.add(item.rate.toString());
          if (item.amount != null) parts.add(item.amount.toString());
          return parts.join(' ');
        }).toList();

        final parseResult = _billParser.parse(rawLines);
        value = value.copyWith(parseResult: parseResult, progress: 0.9);

        value = value.copyWith(stage: PipelineStage.validating, progress: 0.95);
        final validationResult = _aiValidator.validate(parseResult);
        value = value.copyWith(
          validationResult: validationResult,
          progress: 1.0,
        );

        final validatedItems = parseResult.items.map((item) {
          return LineItemData(
            name: item.name,
            quantity: item.quantity,
            rate: item.rate,
            amount: item.amount ?? item.calculatedAmount,
            confidence: validationResult.overallConfidence,
          );
        }).toList();

        value = value.copyWith(
          stage: PipelineStage.complete,
          progress: 1.0,
        );

        return Result.success(BillStructureResult(
          lineItems: validatedItems,
          confidence: validationResult.overallConfidence,
        ));
      },
      error: (failure) {
        value = value.copyWith(
          stage: PipelineStage.error,
          error: failure.message,
        );
        return Result<BillStructureResult>.error(failure);
      },
    );
  }

  void reset() {
    value = const RecognitionPipelineState();
  }

  @override
  void dispose() {
    _renderer.dispose();
    super.dispose();
  }
}
