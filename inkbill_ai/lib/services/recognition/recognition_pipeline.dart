import 'dart:async';
import 'dart:typed_data';
import 'package:flutter/foundation.dart';
import 'package:inkbill_ai/core/utils/result.dart';
import 'package:inkbill_ai/core/errors/failures.dart';
import 'package:inkbill_ai/features/ai/domain/entities/recognition_result.dart';
import 'package:inkbill_ai/features/ai/domain/repositories/recognition_repository.dart';
import 'package:inkbill_ai/features/handwriting/domain/entities/ink_stroke.dart';
import 'package:inkbill_ai/services/recognition/layout_analyzer.dart';
import 'package:inkbill_ai/services/recognition/bill_parser.dart';
import 'package:inkbill_ai/services/recognition/ai_validator.dart';
import 'package:inkbill_ai/services/recognition/image_preprocessor.dart';
import 'package:inkbill_ai/services/recognition/shop_memory.dart';
import 'package:inkbill_ai/services/recognition/recognition_logger.dart';
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

  bool get isTerminal =>
      stage == PipelineStage.complete || stage == PipelineStage.error;

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
  final ShopMemory? _shopMemory;
  Completer<void>? _currentOperation;

  static const Duration _pipelineTimeout = Duration(seconds: 10);

  RecognitionPipeline({
    required RecognitionRepository repository,
    ImagePreprocessor? preprocessor,
    LayoutAnalyzer? layoutAnalyzer,
    BillParser? billParser,
    AIValidator? aiValidator,
    CanvasRenderer? renderer,
    ShopMemory? shopMemory,
  })  : _repository = repository,
        _preprocessor = preprocessor ?? ImagePreprocessor(),
        _layoutAnalyzer = layoutAnalyzer ?? LayoutAnalyzer(),
        _billParser = billParser ?? BillParser(shopMemory: shopMemory),
        _aiValidator = aiValidator ?? AIValidator(),
        _renderer = renderer ?? CanvasRenderer(),
        _shopMemory = shopMemory,
        super(const RecognitionPipelineState());

  bool get isBusy =>
      _currentOperation != null && !_currentOperation!.isCompleted;

  Future<Result<RecognitionResult>> recognizeStrokes(
    List<InkStroke> strokes,
  ) async {
    if (isBusy) {
      return Result.error(
          const RecognitionFailure(message: 'Pipeline is busy'));
    }

    final completer = Completer<void>();
    _currentOperation = completer;

    try {
      RecognitionLogger.stage('PIPELINE', 'recognizeStrokes: ${strokes.length} strokes');

      value = value.copyWith(
          stage: PipelineStage.preprocessing, progress: 0.1);

      value = value.copyWith(
          stage: PipelineStage.layoutAnalysis, progress: 0.3);
      final layoutResult = _layoutAnalyzer.analyze(strokes);
      value = value.copyWith(layoutResult: layoutResult, progress: 0.4);

      value = value.copyWith(
          stage: PipelineStage.recognizing, progress: 0.5);
      RecognitionLogger.stage('PIPELINE', 'Recognition Started');

      final repoResult = await _repository
          .recognizeStrokes(strokes)
          .timeout(_pipelineTimeout);

      RecognitionLogger.stage('PIPELINE', 'Recognition Completed');

      return repoResult.when(
        success: (data) {
          value = value.copyWith(
            stage: PipelineStage.complete,
            result: data,
            progress: 1.0,
          );
          RecognitionLogger.stage('PIPELINE', 'Pipeline Complete');
          return Result<RecognitionResult>.success(data);
        },
        error: (failure) {
          value = value.copyWith(
            stage: PipelineStage.error,
            error: failure.message,
            progress: 0.0,
          );
          RecognitionLogger.error('Pipeline.recognizeStrokes', failure.message);
          return Result<RecognitionResult>.error(failure);
        },
      );
    } on TimeoutException {
      RecognitionLogger.stage('PIPELINE', 'Timeout Triggered');
      cancel();
      value = value.copyWith(
        stage: PipelineStage.error,
        error: 'Recognition took longer than expected. Please try again.',
        progress: 0.0,
      );
      return Result.error(const RecognitionFailure(
          message: 'Recognition took longer than expected. Please try again.'));
    } catch (e, stack) {
      RecognitionLogger.error('Pipeline.recognizeStrokes', e, stack);
      value = value.copyWith(
        stage: PipelineStage.error,
        error: 'Recognition failed: $e',
        progress: 0.0,
      );
      return Result.error(
          RecognitionFailure(message: 'Recognition failed: $e'));
    } finally {
      if (!completer.isCompleted) completer.complete();
      _currentOperation = null;
    }
  }

  Future<Result<BillStructureResult>> extractBillStructure(
    List<InkStroke> strokes,
  ) async {
    if (isBusy) {
      return Result.error(
          const RecognitionFailure(message: 'Pipeline is busy'));
    }

    final completer = Completer<void>();
    _currentOperation = completer;

    try {
      if (strokes.isEmpty) {
        return Result.success(const BillStructureResult(
          diagnosticCategory: OcrDiagnosticCategory.noStrokes,
          warnings: ['NO_STROKES: Canvas contains zero ink strokes'],
        ));
      }

      value = value.copyWith(
          stage: PipelineStage.preprocessing, progress: 0.05);

      // 1. Preprocessing Stage & Debug Artifacts Generation
      final preprocessed = await _preprocessor.preprocessStrokesToImage(strokes);
      RecognitionLogger.stage(
          'PIPELINE',
          'Preprocessed: nonWhitePct=${preprocessed.nonWhitePixelPercentage.toStringAsFixed(2)}%, origPath=${preprocessed.debugOriginalPath}');

      // 2. Layout & Bounding Box Analysis
      value = value.copyWith(
          stage: PipelineStage.layoutAnalysis, progress: 0.2);
      final layoutResult = _layoutAnalyzer.analyze(strokes);
      value = value.copyWith(layoutResult: layoutResult, progress: 0.25);

      // 3. OCR Recognition Stage
      value = value.copyWith(
          stage: PipelineStage.recognizing, progress: 0.3);
      final repoResult = await _repository
          .extractBillStructure(strokes)
          .timeout(_pipelineTimeout);

      return repoResult.when(
        success: (data) {
          value = value.copyWith(progress: 0.7);

          final rawText = data.rawText.isNotEmpty
              ? data.rawText
              : data.lineItems.map((e) => e.name).join('\n');

          // 4. Bill Parsing Stage
          value = value.copyWith(stage: PipelineStage.parsing, progress: 0.8);
          final rawLines = rawText
              .split('\n')
              .where((l) => l.trim().isNotEmpty)
              .toList();

          final parseResult = _billParser.parse(rawLines);
          value = value.copyWith(parseResult: parseResult, progress: 0.9);

          // 5. Validation Stage
          value = value.copyWith(
              stage: PipelineStage.validating, progress: 0.95);
          final validationResult = _aiValidator.validate(parseResult);
          value = value.copyWith(
              validationResult: validationResult, progress: 1.0);

          final validatedItems = parseResult.items.map((item) {
            return LineItemData(
              name: item.name,
              quantity: item.quantity,
              rate: item.rate,
              amount: item.amount ?? item.calculatedAmount,
              confidence: validationResult.overallConfidence,
            );
          }).toList();

          OcrDiagnosticCategory category = OcrDiagnosticCategory.none;
          final warnings = List<String>.from(data.warnings);

          if (validatedItems.isEmpty && rawText.isNotEmpty) {
            category = OcrDiagnosticCategory.parserFailed;
            warnings.add('OCR detected text, but bill structure could not be determined.');
          } else if (rawText.isEmpty) {
            category = OcrDiagnosticCategory.noRawText;
            warnings.add('NO_RAW_TEXT: OCR model returned empty text.');
          }

          value = value.copyWith(
            stage: PipelineStage.complete,
            progress: 1.0,
          );

          return Result.success(BillStructureResult(
            lineItems: validatedItems,
            confidence: validationResult.overallConfidence,
            warnings: warnings,
            rawText: rawText,
            diagnosticCategory: category,
            nonWhitePixelPercentage: preprocessed.nonWhitePixelPercentage,
            debugOriginalPath: preprocessed.debugOriginalPath,
            debugPreprocessedPath: preprocessed.debugPreprocessedPath,
            detectedLines: rawLines,
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
    } on TimeoutException {
      cancel();
      value = value.copyWith(
        stage: PipelineStage.error,
        error: 'Recognition took longer than expected. Please try again.',
      );
      return Result.error(const RecognitionFailure(
          message: 'Recognition took longer than expected. Please try again.'));
    } catch (e, stack) {
      RecognitionLogger.error('Pipeline.extractBillStructure', e, stack);
      value = value.copyWith(
        stage: PipelineStage.error,
        error: 'Recognition failed: $e',
      );
      return Result.error(
          RecognitionFailure(message: 'Recognition failed: $e'));
    } finally {
      if (!completer.isCompleted) completer.complete();
      _currentOperation = null;
    }
  }

  Future<Result<BillStructureResult>> extractBillStructureFromImage(
    Uint8List imageBytes,
  ) async {
    if (isBusy) {
      return Result.error(
          const RecognitionFailure(message: 'Pipeline is busy'));
    }

    final completer = Completer<void>();
    _currentOperation = completer;

    try {
      RecognitionLogger.stage('PIPELINE', 'extractBillStructureFromImage');

      value = value.copyWith(
          stage: PipelineStage.preprocessing, progress: 0.1);

      value = value.copyWith(
          stage: PipelineStage.recognizing, progress: 0.3);
      final repoResult = await _repository
          .extractBillStructureFromImage(imageBytes)
          .timeout(_pipelineTimeout);

      return repoResult.when(
        success: (data) {
          value = value.copyWith(progress: 0.7);

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

          value = value.copyWith(
              stage: PipelineStage.validating, progress: 0.95);
          final validationResult = _aiValidator.validate(parseResult);
          value = value.copyWith(
              validationResult: validationResult, progress: 1.0);

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
    } on TimeoutException {
      RecognitionLogger.stage('PIPELINE', 'Timeout Triggered');
      cancel();
      value = value.copyWith(
        stage: PipelineStage.error,
        error: 'Recognition took longer than expected. Please try again.',
      );
      return Result.error(const RecognitionFailure(
          message: 'Recognition took longer than expected. Please try again.'));
    } catch (e, stack) {
      RecognitionLogger.error('Pipeline.extractBillStructureFromImage', e, stack);
      value = value.copyWith(
        stage: PipelineStage.error,
        error: 'Recognition failed: $e',
      );
      return Result.error(
          RecognitionFailure(message: 'Recognition failed: $e'));
    } finally {
      if (!completer.isCompleted) completer.complete();
      _currentOperation = null;
    }
  }

  void cancel() {
    if (_currentOperation != null && !_currentOperation!.isCompleted) {
      _currentOperation!.complete();
    }
    if (value.stage != PipelineStage.complete &&
        value.stage != PipelineStage.error) {
      value = value.copyWith(
        stage: PipelineStage.error,
        error: 'Recognition cancelled.',
        progress: 0.0,
      );
    }
    RecognitionLogger.log('Pipeline cancelled');
  }

  void reset() {
    value = const RecognitionPipelineState();
    _currentOperation = null;
    RecognitionLogger.log('Pipeline reset');
  }

  @override
  void dispose() {
    cancel();
    _renderer.dispose();
    super.dispose();
  }
}
