import 'dart:async';
import 'package:inkbill_ai/core/utils/result.dart';
import 'package:inkbill_ai/core/errors/failures.dart';
import 'package:inkbill_ai/features/handwriting/domain/entities/ink_stroke.dart';
import 'package:inkbill_ai/services/handwriting/models/handwriting_line.dart';
import 'package:inkbill_ai/services/recognition/recognition_logger.dart';
import 'package:google_mlkit_digital_ink_recognition/google_mlkit_digital_ink_recognition.dart' as mlkit;

class MLKitHandwritingRecognizer {
  mlkit.DigitalInkRecognizer? _recognizer;
  final mlkit.DigitalInkRecognizerModelManager _modelManager;
  final String _languageCode;
  bool _initialized = false;
  bool _disposed = false;
  Completer<void>? _pendingOperation;

  static const Duration _fieldTimeout = Duration(seconds: 5);
  static const Duration _modelDownloadTimeout = Duration(seconds: 15);

  MLKitHandwritingRecognizer({String languageCode = 'en-US'})
      : _languageCode = languageCode,
        _modelManager = mlkit.DigitalInkRecognizerModelManager();

  bool get isInitialized => _initialized && !_disposed;

  Future<Result<bool>> initialize() async {
    if (_initialized && !_disposed) return Result.success(true);
    if (_disposed) {
      return Result.error(
          const RecognitionFailure(message: 'Recognizer was disposed'));
    }

    RecognitionLogger.stage('ML_KIT', 'Model initialization started');
    try {
      final isDownloaded = await _modelManager
          .isModelDownloaded(_languageCode)
          .timeout(_modelDownloadTimeout);
      if (!isDownloaded) {
        RecognitionLogger.log('Model not cached, downloading...');
        await _modelManager
            .downloadModel(_languageCode)
            .timeout(_modelDownloadTimeout);
        RecognitionLogger.log('Model downloaded');
      }
      _recognizer = mlkit.DigitalInkRecognizer(languageCode: _languageCode);
      _initialized = true;
      RecognitionLogger.stage('ML_KIT', 'Model ready');
      return Result.success(true);
    } on TimeoutException {
      RecognitionLogger.error('ML Kit init', 'Model download timed out');
      return Result.error(const RecognitionFailure(
          message: 'AI model download timed out. Check your connection.'));
    } catch (e) {
      RecognitionLogger.error('ML Kit init', e);
      return Result.error(
          RecognitionFailure(message: 'AI model initialization failed: $e'));
    }
  }

  Future<Result<HandwritingLine>> recognizeLine(
    HandwritingLine line,
  ) async {
    if (_disposed) {
      return Result.error(
          const RecognitionFailure(message: 'Recognizer was disposed'));
    }
    if (!isInitialized || _recognizer == null) {
      return Result.error(const RecognitionFailure(
          message: 'AI model not initialized'));
    }
    if (line.strokes.isEmpty) {
      return Result.success(line);
    }

    final completer = Completer<void>();
    _pendingOperation = completer;

    try {
      final fields = <RecognizedField>[];
      for (var i = 0; i < line.fields.length; i++) {
        if (completer.isCompleted) break;
        final field = line.fields[i];
        final result = await _recognizeField(field, line.strokes)
            .timeout(_fieldTimeout);
        if (completer.isCompleted) break;
        result.when(
          success: (recognized) => fields.add(recognized),
          error: (_) => fields.add(field),
        );
      }

      if (completer.isCompleted) {
        return Result.error(
            const RecognitionFailure(message: 'Recognition cancelled'));
      }

      return Result.success(line.copyWith(fields: fields));
    } on TimeoutException {
      RecognitionLogger.log('Field recognition timed out (${_fieldTimeout.inSeconds}s)');
      return Result.success(line.copyWith(
        fields: line.fields
            .map((f) => RecognizedField(
                  type: f.type,
                  text: '',
                  confidence: 0.0,
                  x: f.x,
                  y: f.y,
                  width: f.width,
                  height: f.height,
                  strokeCount: f.strokeCount,
                ))
            .toList(),
      ));
    } catch (e) {
      RecognitionLogger.error('ML Kit recognizeLine', e);
      return Result.error(
          RecognitionFailure(message: 'Field recognition failed: $e'));
    } finally {
      if (!completer.isCompleted) {
        completer.complete();
      }
      _pendingOperation = null;
    }
  }

  void cancel() {
    if (_pendingOperation != null && !_pendingOperation!.isCompleted) {
      _pendingOperation!.complete();
      RecognitionLogger.log('ML Kit recognition cancelled');
    }
  }

  Future<Result<RecognizedField>> _recognizeField(
    RecognizedField field,
    List<InkStroke> allStrokes,
  ) async {
    final strokeIndices = <int>{};
    const pad = 20.0;
    final fieldMinX = field.x - pad;
    final fieldMaxX = field.x + field.width + pad;

    for (var i = 0; i < allStrokes.length; i++) {
      final s = allStrokes[i];
      if (s.points.isEmpty) continue;

      final hasIntersectingPoint = s.points.any((p) => p.x >= fieldMinX && p.x <= fieldMaxX);
      if (hasIntersectingPoint) {
        strokeIndices.add(i);
      }
    }

    if (strokeIndices.isEmpty) {
      for (var i = 0; i < allStrokes.length; i++) {
        strokeIndices.add(i);
      }
    }

    final fieldStrokes = strokeIndices.map((i) => allStrokes[i]).toList();

    try {
      final ink = mlkit.Ink();
      for (final stroke in fieldStrokes) {
        final mlStroke = mlkit.Stroke();
        for (final point in stroke.points) {
          mlStroke.points.add(mlkit.StrokePoint(
            x: point.x,
            y: point.y,
            t: point.timestampMs,
          ));
        }
        ink.strokes.add(mlStroke);
      }

      final candidates = await _recognizer!.recognize(ink);
      if (candidates.isEmpty) {
        return Result.success(RecognizedField(
          type: field.type,
          text: '',
          confidence: 0.0,
          x: field.x,
          y: field.y,
          width: field.width,
          height: field.height,
          strokeCount: fieldStrokes.length,
        ));
      }

      final best = candidates.first;
      final confidence = _mlKitScoreToConfidence(best.score);

      String text = best.text.trim();
      if (field.type == FieldType.number) {
        text = _extractDigits(text);
      }

      return Result.success(RecognizedField(
        type: field.type,
        text: text,
        confidence: confidence,
        x: field.x,
        y: field.y,
        width: field.width,
        height: field.height,
        strokeCount: fieldStrokes.length,
      ));
    } catch (e) {
      return Result.error(
          RecognitionFailure(message: 'Field recognition failed: $e'));
    }
  }

  double _mlKitScoreToConfidence(double score) {
    return (1.0 / (1.0 + score.abs())).clamp(0.0, 1.0);
  }

  String _extractDigits(String text) {
    final digits = text.replaceAll(RegExp(r'[^0-9.]'), '');
    if (digits.isEmpty) return text;
    final parts = digits.split('.');
    if (parts.length > 2) {
      return parts[0] + '.' + parts.sublist(1).join('');
    }
    return digits;
  }

  Future<Result<void>> dispose() async {
    _disposed = true;
    cancel();
    if (_recognizer != null) {
      try {
        await _recognizer!.close();
      } catch (_) {}
      _recognizer = null;
    }
    _initialized = false;
    return Result.success(null);
  }
}
