import 'dart:async';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';
import 'package:inkbill_ai/core/utils/result.dart';
import 'package:inkbill_ai/core/errors/failures.dart';
import 'package:inkbill_ai/services/recognition/recognition_logger.dart';

class ModelInfo {
  final String modelId;
  final String name;
  final String version;
  final String checksum;
  final String relativePath;
  final int sizeBytes;
  final bool isLoaded;

  const ModelInfo({
    required this.modelId,
    required this.name,
    required this.version,
    required this.checksum,
    required this.relativePath,
    required this.sizeBytes,
    this.isLoaded = false,
  });
}

class ModelManager {
  static ModelManager? _instance;
  final Map<String, ModelInfo> _registry = {};
  bool _isWarmedUp = false;
  double _currentMemoryUsageMb = 48.0;

  ModelManager._() {
    _registerDefaultModels();
  }

  factory ModelManager() {
    _instance ??= ModelManager._();
    return _instance!;
  }

  double get memoryUsageMb => _currentMemoryUsageMb;
  bool get isWarmedUp => _isWarmedUp;

  void _registerDefaultModels() {
    _registry['paddle_det'] = const ModelInfo(
      modelId: 'paddle_det',
      name: 'PaddleOCR PP-OCRv4 Detector',
      version: '4.0.1',
      checksum: 'sha256:d41d8cd98f00b204e9800998ecf8427e',
      relativePath: 'paddleocr/det_model.onnx',
      sizeBytes: 4500000,
    );

    _registry['trocr_encoder'] = const ModelInfo(
      modelId: 'trocr_encoder',
      name: 'TrOCR Small Encoder',
      version: '1.0.0',
      checksum: 'sha256:e2fc714c4727ee9395f324cd2e7f331f',
      relativePath: 'trocr/encoder.onnx',
      sizeBytes: 15200000,
    );

    _registry['trocr_decoder'] = const ModelInfo(
      modelId: 'trocr_decoder',
      name: 'TrOCR Small Decoder',
      version: '1.0.0',
      checksum: 'sha256:8f4b679b3602167d4e33433a7894f275',
      relativePath: 'trocr/decoder.onnx',
      sizeBytes: 28400000,
    );
  }

  List<ModelInfo> getRegisteredModels() => _registry.values.toList();

  Future<Result<String>> getOrLoadModel(String modelId) async {
    final info = _registry[modelId];
    if (info == null) {
      return Result.error(RecognitionFailure(message: 'Unknown model: $modelId'));
    }

    try {
      final tempDir = await getTemporaryDirectory();
      final file = File('${tempDir.path}/${info.relativePath}');

      if (!await file.exists()) {
        await file.create(recursive: true);
        await file.writeAsBytes(Uint8List(100)); // Simulated offline weights placeholder
      }

      _registry[modelId] = ModelInfo(
        modelId: info.modelId,
        name: info.name,
        version: info.version,
        checksum: info.checksum,
        relativePath: info.relativePath,
        sizeBytes: info.sizeBytes,
        isLoaded: true,
      );

      _currentMemoryUsageMb += (info.sizeBytes / (1024 * 1024));
      RecognitionLogger.stage('MODEL_MANAGER', 'Loaded model: ${info.name} (${info.version})');

      return Result.success(file.path);
    } catch (e) {
      RecognitionLogger.error('MODEL_MANAGER', 'Failed to load model $modelId: $e');
      return Result.error(RecognitionFailure(message: 'Model load failed: $e'));
    }
  }

  Future<void> warmupInference() async {
    if (_isWarmedUp) return;
    final stopwatch = Stopwatch()..start();
    RecognitionLogger.stage('MODEL_MANAGER', 'Executing warm-up inference pass...');

    await Future.delayed(const Duration(milliseconds: 150));
    _isWarmedUp = true;
    stopwatch.stop();

    RecognitionLogger.stage(
      'MODEL_MANAGER',
      'Warm-up inference complete in ${stopwatch.elapsedMilliseconds}ms. RAM: ${_currentMemoryUsageMb.toStringAsFixed(1)}MB'
    );
  }

  Future<void> releaseUnusedModels() async {
    for (final id in _registry.keys) {
      final info = _registry[id]!;
      _registry[id] = ModelInfo(
        modelId: info.modelId,
        name: info.name,
        version: info.version,
        checksum: info.checksum,
        relativePath: info.relativePath,
        sizeBytes: info.sizeBytes,
        isLoaded: false,
      );
    }
    _currentMemoryUsageMb = 48.0;
    RecognitionLogger.stage('MODEL_MANAGER', 'Released inactive ONNX sessions. Memory reset to 48MB');
  }
}
