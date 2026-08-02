import 'dart:async';
import 'package:inkbill_ai/core/utils/result.dart';
import 'package:inkbill_ai/core/errors/failures.dart';
import 'package:inkbill_ai/features/handwriting/domain/entities/ink_stroke.dart';
import 'package:inkbill_ai/services/handwriting/models/handwriting_line.dart';
import 'package:inkbill_ai/services/handwriting/handwriting_line_detector.dart';
import 'package:inkbill_ai/services/handwriting/field_classifier.dart';
import 'package:inkbill_ai/services/handwriting/ml_kit_handwriting_recognizer.dart';
import 'package:inkbill_ai/services/handwriting/confidence_evaluator.dart';
import 'package:inkbill_ai/services/recognition/recognition_logger.dart';

class HandwritingEngineResult {
  final HandwritingRecognitionResult recognition;
  final bool mlKitAvailable;
  final int totalStrokes;
  final int totalLines;
  final Duration processingTime;
  final List<String> errors;

  const HandwritingEngineResult({
    required this.recognition,
    this.mlKitAvailable = false,
    this.totalStrokes = 0,
    this.totalLines = 0,
    this.processingTime = Duration.zero,
    this.errors = const [],
  });
}

class HandwritingEngine {
  final HandwritingLineDetector _lineDetector;
  final FieldClassifier _fieldClassifier;
  final MLKitHandwritingRecognizer _mlKitRecognizer;
  final ConfidenceEvaluator _confidenceEvaluator;
  bool _initialized = false;
  bool _running = false;

  static const Duration _engineTimeout = Duration(seconds: 10);

  HandwritingEngine({
    HandwritingLineDetector? lineDetector,
    FieldClassifier? fieldClassifier,
    MLKitHandwritingRecognizer? mlKitRecognizer,
    ConfidenceEvaluator? confidenceEvaluator,
  })  : _lineDetector = lineDetector ?? const HandwritingLineDetector(),
        _fieldClassifier = fieldClassifier ?? const FieldClassifier(),
        _mlKitRecognizer =
            mlKitRecognizer ?? MLKitHandwritingRecognizer(),
        _confidenceEvaluator =
            confidenceEvaluator ?? const ConfidenceEvaluator();

  bool get isInitialized => _initialized;
  bool get isRunning => _running;

  Future<Result<bool>> initialize() async {
    if (_initialized) return Result.success(true);
    RecognitionLogger.stage('ENGINE', 'HandwritingEngine init');
    final result = await _mlKitRecognizer.initialize();
    return result.when(
      success: (_) {
        _initialized = true;
        RecognitionLogger.stage('ENGINE', 'HandwritingEngine ready');
        return Result.success(true);
      },
      error: (failure) {
        RecognitionLogger.error('HandwritingEngine.initialize', failure.message);
        return Result.error(failure);
      },
    );
  }

  Future<HandwritingEngineResult> recognize(
    List<InkStroke> strokes, {
    Duration? timeout,
  }) async {
    if (_running) {
      return HandwritingEngineResult(
        recognition: const HandwritingRecognitionResult(
          warnings: ['Recognition already in progress'],
        ),
        totalStrokes: strokes.length,
        errors: ['Duplicate recognition request rejected'],
      );
    }

    _running = true;
    final effectiveTimeout = timeout ?? _engineTimeout;
    final startTime = DateTime.now();
    final errors = <String>[];
    RecognitionLogger.stage('ENGINE', 'Recognition Started: ${strokes.length} strokes');

    try {
      final result = await _runPipeline(strokes, errors)
          .timeout(effectiveTimeout);
      return result;
    } on TimeoutException {
      RecognitionLogger.stage('ENGINE', 'Timeout Triggered after ${effectiveTimeout.inSeconds}s');
      cancel();
      return HandwritingEngineResult(
        recognition: HandwritingRecognitionResult(
          warnings: ['Recognition timed out after ${effectiveTimeout.inSeconds} seconds'],
        ),
        totalStrokes: strokes.length,
        processingTime: DateTime.now().difference(startTime),
        errors: ['Timeout: recognition exceeded ${effectiveTimeout.inSeconds}s'],
      );
    } finally {
      _running = false;
    }
  }

  Future<HandwritingEngineResult> _runPipeline(
    List<InkStroke> strokes,
    List<String> errors,
  ) async {
    if (strokes.isEmpty) {
      return HandwritingEngineResult(
        recognition: const HandwritingRecognitionResult(
          warnings: ['No strokes provided'],
        ),
        processingTime: Duration.zero,
      );
    }

    List<HandwritingLine> lines;
    try {
      lines = _lineDetector.detectLines(strokes);
      RecognitionLogger.stage('LAYOUT', 'Detected ${lines.length} lines');
    } catch (e) {
      RecognitionLogger.error('Line detection', e);
      return HandwritingEngineResult(
        recognition: HandwritingRecognitionResult(
          warnings: ['Line detection failed: $e'],
        ),
        totalStrokes: strokes.length,
        errors: ['$e'],
      );
    }

    if (lines.isEmpty) {
      return HandwritingEngineResult(
        recognition: const HandwritingRecognitionResult(
          warnings: ['No lines detected'],
        ),
        totalStrokes: strokes.length,
        processingTime: DateTime.now().difference(DateTime.now()),
      );
    }

    for (var i = 0; i < lines.length; i++) {
      try {
        final fields = _fieldClassifier.classify(lines[i]);
        lines[i] = lines[i].copyWith(fields: fields);
      } catch (e) {
        errors.add('Field classification failed for line ${i + 1}: $e');
      }
    }

    bool mlKitAvailable = _initialized;
    if (mlKitAvailable) {
      RecognitionLogger.stage('RECOGNITION', 'ML Kit recognizing ${lines.length} lines');
      for (var i = 0; i < lines.length; i++) {
        final result = await _mlKitRecognizer.recognizeLine(lines[i]);
        result.when(
          success: (recognized) => lines[i] = recognized,
          error: (failure) {
            errors.add('ML Kit failed on line ${i + 1}: ${failure.message}');
          },
        );
      }
      RecognitionLogger.stage('RECOGNITION', 'ML Kit recognition completed');
    }

    HandwritingRecognitionResult recognition;
    try {
      recognition = _confidenceEvaluator.evaluate(lines);
    } catch (e) {
      recognition = HandwritingRecognitionResult(
        lines: lines,
        overallConfidence: 0.3,
        warnings: ['Confidence evaluation failed: $e'],
      );
    }

    final processingTime = DateTime.now().difference(DateTime.now());

    return HandwritingEngineResult(
      recognition: recognition,
      mlKitAvailable: mlKitAvailable,
      totalStrokes: strokes.length,
      totalLines: lines.length,
      processingTime: processingTime,
      errors: errors,
    );
  }

  void cancel() {
    _mlKitRecognizer.cancel();
    RecognitionLogger.log('HandwritingEngine cancelled');
  }

  String toRawText(HandwritingRecognitionResult result) {
    final buffer = StringBuffer();
    for (final line in result.lines) {
      if (buffer.isNotEmpty) buffer.write('\n');
      final lineText = line.fields
          .where((f) => f.text.isNotEmpty)
          .map((f) => f.text)
          .join(' ');
      buffer.write(lineText);
    }
    return buffer.toString().trim();
  }

  Future<Result<void>> dispose() async {
    cancel();
    return _mlKitRecognizer.dispose();
  }
}
