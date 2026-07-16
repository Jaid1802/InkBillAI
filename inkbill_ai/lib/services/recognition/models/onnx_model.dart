import 'package:inkbill_ai/core/utils/result.dart';
import 'package:inkbill_ai/core/errors/failures.dart';
import 'package:inkbill_ai/features/ai/domain/entities/recognition_result.dart';
import 'package:inkbill_ai/features/handwriting/domain/entities/ink_stroke.dart';
import 'package:inkbill_ai/services/recognition/recognition_pipeline.dart';

class OnnxRecognitionModel implements RecognitionModel {
  bool _initialized = false;

  @override
  RecognitionModelType get modelType => RecognitionModelType.onnxRuntime;

  @override
  Future<Result<bool>> initialize() async {
    try {
      _initialized = true;
      return Result.success(true);
    } catch (e) {
      return Result.error(
          RecognitionFailure(message: 'ONNX init failed'));
    }
  }

  @override
  Future<Result<RecognitionResult>> recognize(
      List<InkStroke> strokes) async {
    if (!_initialized) {
      return Result.error(
          const RecognitionFailure(message: 'ONNX not initialized'));
    }
    try {
      return Result.success(const RecognitionResult(
        bestText: '[onnx_recognized]',
        confidence: 0.8,
        candidates: [
          RecognizedText(text: '[onnx_recognized]', confidence: 0.8),
        ],
      ));
    } catch (e) {
      return Result.error(
          RecognitionFailure(message: 'ONNX recognition failed'));
    }
  }

  @override
  Future<Result<void>> dispose() async {
    _initialized = false;
    return Result.success(null);
  }
}
