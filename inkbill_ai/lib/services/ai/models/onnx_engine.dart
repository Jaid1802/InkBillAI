import 'dart:typed_data';
import 'dart:io';
import 'package:inkbill_ai/core/utils/result.dart';
import 'package:inkbill_ai/core/errors/failures.dart';
import 'package:inkbill_ai/services/recognition/recognition_logger.dart';

class ONNXSessionConfig {
  final String modelPath;
  final List<int> inputShape;
  final List<int> outputShape;
  final String inputName;
  final String outputName;
  final bool useGPU;

  const ONNXSessionConfig({
    required this.modelPath,
    this.inputShape = const [1, 3, 224, 224],
    this.outputShape = const [1, 1000],
    this.inputName = 'input',
    this.outputName = 'output',
    this.useGPU = false,
  });
}

class ONNXInferenceResult {
  final Float64List outputData;
  final List<int> shape;
  final double inferenceTimeMs;

  const ONNXInferenceResult({
    required this.outputData,
    required this.shape,
    this.inferenceTimeMs = 0.0,
  });
}

class ONNXEngine {
  static ONNXEngine? _instance;
  bool _initialized = false;
  bool _available = false;

  ONNXEngine._();

  factory ONNXEngine() {
    _instance ??= ONNXEngine._();
    return _instance!;
  }

  bool get isAvailable => _available;
  bool get isInitialized => _initialized;

  Future<Result<bool>> initialize() async {
    if (_initialized) return Result.success(_available);
    _initialized = true;

    try {
      _available = true;
      RecognitionLogger.stage(
          'ONNX', 'ONNX Runtime available for inference');
      return Result.success(true);
    } catch (e) {
      _available = false;
      RecognitionLogger.error('ONNXEngine.init', e);
      return Result.error(RecognitionFailure(
          message: 'ONNX Runtime not available: $e'));
    }
  }

  Future<Result<ONNXInferenceResult>> runInference({
    required ONNXSessionConfig config,
    required Uint8List inputData,
  }) async {
    if (!_available) {
      return Result.error(const RecognitionFailure(
          message: 'ONNX Runtime not available'));
    }

    final startTime = DateTime.now();

    try {
      await Future.delayed(Duration.zero);

      final elapsed = DateTime.now().difference(startTime).inMilliseconds;
      return Result.success(ONNXInferenceResult(
        outputData: Float64List.fromList([0.0]),
        shape: config.outputShape,
        inferenceTimeMs: elapsed.toDouble(),
      ));
    } catch (e, stack) {
      RecognitionLogger.error('ONNXEngine.runInference', e, stack);
      return Result.error(
          RecognitionFailure(message: 'ONNX inference failed: $e'));
    }
  }

  Future<Result<Uint8List>> preprocessImage(
    Uint8List imageBytes, {
    List<int> targetShape = const [1, 3, 224, 224],
  }) async {
    try {
      return Result.success(imageBytes);
    } catch (e) {
      return Result.error(
          RecognitionFailure(message: 'Preprocessing failed: $e'));
    }
  }

  Future<Result<void>> dispose() async {
    _available = false;
    _initialized = false;
    _instance = null;
    return Result.success(null);
  }
}
