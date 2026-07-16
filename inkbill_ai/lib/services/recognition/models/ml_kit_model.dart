import 'package:inkbill_ai/core/utils/result.dart';
import 'package:inkbill_ai/core/errors/failures.dart';
import 'package:inkbill_ai/features/ai/domain/entities/recognition_result.dart';
import 'package:inkbill_ai/features/handwriting/domain/entities/ink_stroke.dart' as domain;
import 'package:inkbill_ai/services/recognition/recognition_pipeline.dart';
import 'package:google_mlkit_digital_ink_recognition/google_mlkit_digital_ink_recognition.dart' as mlkit;

class MLKitRecognitionModel implements RecognitionModel {
  bool _initialized = false;
  final mlkit.DigitalInkRecognizerModelManager _modelManager = mlkit.DigitalInkRecognizerModelManager();
  late mlkit.DigitalInkRecognizer _recognizer;
  final String _languageCode = 'en-US';

  @override
  RecognitionModelType get modelType => RecognitionModelType.mlKit;

  @override
  Future<Result<bool>> initialize() async {
    try {
      final isDownloaded = await _modelManager.isModelDownloaded(_languageCode);
      if (!isDownloaded) {
        await _modelManager.downloadModel(_languageCode);
      }
      _recognizer = mlkit.DigitalInkRecognizer(languageCode: _languageCode);
      _initialized = true;
      return Result.success(true);
    } catch (e) {
      return Result.error(
          RecognitionFailure(message: 'ML Kit init failed: $e'));
    }
  }

  @override
  Future<Result<RecognitionResult>> recognize(
      List<domain.InkStroke> strokes) async {
    if (!_initialized) {
      return Result.error(
          const RecognitionFailure(message: 'ML Kit not initialized'));
    }
    
    try {
      final ink = mlkit.Ink();
      
      for (final stroke in strokes) {
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
      
      final candidates = await _recognizer.recognize(ink);
      
      if (candidates.isEmpty) {
        return Result.error(
            const RecognitionFailure(message: 'No text recognized'));
      }
      
      final bestText = candidates.first.text;
      final bestScore = candidates.first.score;
      final confidence = (1.0 / (1.0 + bestScore.abs())).clamp(0.0, 1.0);

      final mappedCandidates = candidates.map((c) {
        final cScore = c.score;
        final cConf = (1.0 / (1.0 + cScore.abs())).clamp(0.0, 1.0);
        return RecognizedText(text: c.text, confidence: cConf);
      }).toList();

      return Result.success(RecognitionResult(
        bestText: bestText,
        confidence: confidence,
        candidates: mappedCandidates,
      ));
    } catch (e) {
      return Result.error(
          RecognitionFailure(message: 'ML Kit recognition failed: $e'));
    }
  }

  @override
  Future<Result<void>> dispose() async {
    if (_initialized) {
      await _recognizer.close();
      _initialized = false;
    }
    return Result.success(null);
  }
}
