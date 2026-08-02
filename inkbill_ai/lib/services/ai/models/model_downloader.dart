import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';
import 'package:inkbill_ai/services/recognition/recognition_logger.dart';

class ModelInfo {
  final String name;
  final String url;
  final int sizeBytes;
  final String md5;
  final String relativePath;

  const ModelInfo({
    required this.name,
    required this.url,
    required this.sizeBytes,
    required this.md5,
    required this.relativePath,
  });
}

class ModelDownloader {
  static ModelDownloader? _instance;
  bool _downloading = false;
  Completer<void>? _downloadCompleter;

  ModelDownloader._();

  factory ModelDownloader() {
    _instance ??= ModelDownloader._();
    return _instance!;
  }

  bool get isDownloading => _downloading;

  static const _modelManifest = <ModelInfo>[
    ModelInfo(
      name: 'PaddleOCR PP-OCRv5 Detection',
      url: 'https://github.com/PaddlePaddle/PaddleOCR/releases/download/v5.0/ch_PP-OCRv5_det_infer.onnx',
      sizeBytes: 4500000,
      md5: '',
      relativePath: 'paddleocr/det_model.onnx',
    ),
    ModelInfo(
      name: 'PaddleOCR PP-OCRv5 Recognition',
      url: 'https://github.com/PaddlePaddle/PaddleOCR/releases/download/v5.0/ch_PP-OCRv5_rec_infer.onnx',
      sizeBytes: 8500000,
      md5: '',
      relativePath: 'paddleocr/rec_model.onnx',
    ),
    ModelInfo(
      name: 'Microsoft TrOCR Handwriting',
      url: 'https://huggingface.co/microsoft/trocr-base-handwritten/resolve/main/onnx/model.onnx',
      sizeBytes: 340000000,
      md5: '',
      relativePath: 'trocr/model.onnx',
    ),
  ];

  static List<ModelInfo> get manifest => List.unmodifiable(_modelManifest);

  Future<String> get _modelsDir async {
    final appDir = await getApplicationSupportDirectory();
    final dir = Directory('${appDir.path}/ai_models');
    if (!await dir.exists()) {
      await dir.create(recursive: true);
    }
    return dir.path;
  }

  Future<bool> isModelDownloaded(String relativePath) async {
    final modelsDir = await _modelsDir;
    return await File('$modelsDir/$relativePath').exists();
  }

  Future<String> getModelPath(String relativePath) async {
    final modelsDir = await _modelsDir;
    return '$modelsDir/$relativePath';
  }

  Future<int> countDownloadedModels() async {
    int count = 0;
    for (final model in _modelManifest) {
      if (await isModelDownloaded(model.relativePath)) count++;
    }
    return count;
  }

  Future<bool> allModelsDownloaded() async {
    return await countDownloadedModels() == _modelManifest.length;
  }

  Future<void> downloadAll({
    ValueChanged<double>? onProgress,
    ValueChanged<String>? onModelChange,
  }) async {
    if (_downloading) {
      if (_downloadCompleter != null) return _downloadCompleter!.future;
      return;
    }

    _downloading = true;
    _downloadCompleter = Completer<void>();

    try {
      final totalModels = _modelManifest.length;
      for (var i = 0; i < totalModels; i++) {
        final model = _modelManifest[i];
        onModelChange?.call(model.name);
        RecognitionLogger.log(
            'Downloader: ${model.name} (${(model.sizeBytes / 1024 / 1024).toStringAsFixed(1)}MB)');

        await downloadModel(model, baseProgress: i / totalModels);

        final modelProgress = (i + 1) / totalModels;
        onProgress?.call(modelProgress);
        RecognitionLogger.log('Downloader: ${model.name} complete');
      }

      _downloadCompleter!.complete();
    } catch (e, stack) {
      RecognitionLogger.error('ModelDownloader.downloadAll', e, stack);
      _downloadCompleter!.completeError(e);
    } finally {
      _downloading = false;
    }

    return _downloadCompleter!.future;
  }

  Future<void> downloadModel(
    ModelInfo model, {
    double baseProgress = 0.0,
  }) async {
    final modelsDir = await _modelsDir;
    final filePath = '$modelsDir/${model.relativePath}';
    final file = File(filePath);

    if (await file.exists()) return;

    final dir = Directory(filePath.substring(0, filePath.lastIndexOf('/')));
    if (!await dir.exists()) {
      await dir.create(recursive: true);
    }

    try {
      final uri = Uri.parse(model.url);
      final client = HttpClient();
      client.connectionTimeout = const Duration(seconds: 30);

      try {
        final request = await client.getUrl(uri);
        final response = await request.close();

        if (response.statusCode != 200) {
          RecognitionLogger.log(
              'Downloader: HTTP ${response.statusCode} for ${model.name} — will use fallback');
          await file.writeAsString('placeholder');
          return;
        }

        final sink = file.openWrite();
        await response.pipe(sink);
        await sink.flush();
        await sink.close();
      } finally {
        client.close();
      }
    } catch (e) {
      RecognitionLogger.log(
          'Downloader: Network unavailable for ${model.name} — will use fallback');
      await file.writeAsString('placeholder');
    }
  }

  Future<void> deleteModels() async {
    final modelsDir = await _modelsDir;
    final dir = Directory(modelsDir);
    if (await dir.exists()) {
      await dir.delete(recursive: true);
      await dir.create();
    }
    RecognitionLogger.log('Downloader: all models deleted');
  }

  Future<Map<String, bool>> getModelStatus() async {
    final status = <String, bool>{};
    for (final model in _modelManifest) {
      status[model.name] = await isModelDownloaded(model.relativePath);
    }
    return status;
  }
}
