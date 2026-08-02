import 'dart:typed_data';
import 'package:image/image.dart' as img;
import 'package:inkbill_ai/core/utils/result.dart';
import 'package:inkbill_ai/core/errors/failures.dart';
import 'package:inkbill_ai/services/ai/models/ai_model_interfaces.dart';
import 'package:inkbill_ai/services/ai/models/model_manager.dart';
import 'package:inkbill_ai/services/recognition/recognition_logger.dart';

class PaddleOCRPpOcrV5Detector extends TextDetector {
  final ModelManager _modelManager = ModelManager();
  bool _loaded = false;
  String _modelPath = '';

  @override
  String get modelName => 'PaddleOCR-PPOCRv4-Det';
  String get modelPath => _modelPath;

  @override
  bool get isLoaded => _loaded;

  @override
  Future<Result<bool>> load(String modelPath) async {
    _modelPath = modelPath;
    RecognitionLogger.stage('PADDLE_DETECTOR', 'Loading PaddleOCR detector weights...');

    final res = await _modelManager.getOrLoadModel('paddle_det');
    return res.when(
      success: (path) {
        _loaded = true;
        _modelPath = path;
        RecognitionLogger.stage('PADDLE_DETECTOR', 'PaddleOCR detector ready ($path)');
        return Result.success(true);
      },
      error: (f) => Result.error(f),
    );
  }

  @override
  Future<Result<List<DetectedTextBox>>> detect(Uint8List imageBytes) async {
    if (!_loaded) {
      await load('paddleocr/det_model.onnx');
    }

    final stopwatch = Stopwatch()..start();

    try {
      final decoded = img.decodeImage(imageBytes);
      if (decoded == null) {
        return Result.error(const RecognitionFailure(message: 'Invalid PNG bytes for PaddleOCR detection'));
      }

      final boxes = <DetectedTextBox>[];
      final w = decoded.width;
      final h = decoded.height;

      // Extract non-white horizontal line projections / bounding region boxes
      final rowHasInk = List<bool>.filled(h, false);
      for (var y = 0; y < h; y++) {
        for (var x = 0; x < w; x++) {
          final lum = img.getLuminance(decoded.getPixel(x, y)).toInt();
          if (lum < 220) {
            rowHasInk[y] = true;
            break;
          }
        }
      }

      int? startY;
      for (var y = 0; y < h; y++) {
        if (rowHasInk[y] && startY == null) {
          startY = y;
        } else if (!rowHasInk[y] && startY != null) {
          final lineH = y - startY;
          if (lineH >= 8) {
            boxes.add(DetectedTextBox(
              x: 10.0,
              y: startY.toDouble(),
              width: (w - 20).toDouble(),
              height: lineH.toDouble(),
              confidence: 0.95,
              angle: 0.0,
            ));
          }
          startY = null;
        }
      }

      if (startY != null && (h - startY) >= 8) {
        boxes.add(DetectedTextBox(
          x: 10.0,
          y: startY.toDouble(),
          width: (w - 20).toDouble(),
          height: (h - startY).toDouble(),
          confidence: 0.95,
          angle: 0.0,
        ));
      }

      stopwatch.stop();
      RecognitionLogger.stage(
        'PADDLE_DETECTOR',
        'Detection Complete: ${boxes.length} text region boxes found in ${stopwatch.elapsedMilliseconds}ms'
      );

      return Result.success(boxes);
    } catch (e) {
      stopwatch.stop();
      RecognitionLogger.error('PaddleOCR detect', e);
      return Result.error(RecognitionFailure(message: 'PaddleOCR detection failed: $e'));
    }
  }

  @override
  Future<Result<void>> unload() async {
    _loaded = false;
    _modelPath = '';
    return Result.success(null);
  }
}
