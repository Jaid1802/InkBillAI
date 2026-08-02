import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:inkbill_ai/features/ai/domain/entities/recognition_result.dart';
import 'package:inkbill_ai/features/handwriting/domain/entities/ink_stroke.dart';
import 'package:inkbill_ai/services/recognition/recognition_pipeline.dart';
import 'package:inkbill_ai/services/recognition/recognition_logger.dart';
import 'package:inkbill_ai/services/recognition/shop_memory.dart';
import 'package:inkbill_ai/features/ai/data/datasources/recognition_local_datasource.dart';
import 'package:inkbill_ai/features/ai/data/repositories/recognition_repository_impl.dart';
import 'package:inkbill_ai/services/ai/pipeline/ai_recognition_pipeline.dart';
import 'package:inkbill_ai/services/handwriting/handwriting_engine.dart';
import 'package:inkbill_ai/services/recognition/engine/ocr_engine_interface.dart';
import 'package:inkbill_ai/services/recognition/engine/production_ocr_pipeline.dart';
import 'package:inkbill_ai/services/recognition/engine/ml_kit_ocr_engine.dart';
import 'package:inkbill_ai/services/recognition/benchmark/ocr_benchmark_system.dart';
import 'package:inkbill_ai/services/ai/models/model_manager.dart';
import 'package:inkbill_ai/services/recognition/engine/pipeline_stage.dart' hide PipelineStage;

enum RecognitionServiceState {
  notInitialized,
  initializing,
  ready,
  processing,
  success,
  error,
  disposed,
}

enum RecognitionTaskResult {
  success,
  failed,
  timedOut,
  cancelled,
}

class RecognitionService {
  static RecognitionService? _instance;

  // Dependencies
  HandwritingEngine? _handwritingEngine;
  RecognitionPipeline? _pipeline;
  AiRecognitionPipeline? _aiPipeline;
  ShopMemory? _shopMemory;

  OcrEngine _activeOcrEngine = ProductionOcrEngine();
  OcrEngineMode _engineMode = OcrEngineMode.paddleOcrTrOcr;
  OcrLanguage _language = OcrLanguage.english;
  final OcrBenchmarkSystem _benchmarkSystem = OcrBenchmarkSystem();
  final ModelManager _modelManager = ModelManager();

  Completer<void>? _initCompleter;
  CancellationToken? _currentTaskToken;
  
  bool _disposed = false;
  bool _processing = false;

  final ValueNotifier<RecognitionServiceState> state =
      ValueNotifier(RecognitionServiceState.notInitialized);
  final ValueNotifier<String> statusMessage =
      ValueNotifier('Recognition Service Created');
  final ValueNotifier<double> progress = ValueNotifier(0.0);
  final ValueNotifier<RecognitionTaskResult?> lastResult =
      ValueNotifier(null);
  final ValueNotifier<String> lastError = ValueNotifier('');

  BillStructureResult? lastBillResult;

  RecognitionService._() {
    RecognitionLogger.stage('SERVICE', 'RecognitionService Created (Engine: $activeEngineName)');
  }

  factory RecognitionService() {
    _instance ??= RecognitionService._();
    return _instance!;
  }

  String get activeEngineName => _activeOcrEngine.engineName;
  OcrEngineMode get engineMode => _engineMode;
  OcrLanguage get language => _language;
  OcrBenchmarkSystem get benchmarkSystem => _benchmarkSystem;
  ModelManager get modelManager => _modelManager;

  Future<void> setEngineMode(OcrEngineMode mode) async {
    _engineMode = mode;
    if (mode == OcrEngineMode.mlKitDebug) {
      _activeOcrEngine = MlKitOcrEngine();
    } else {
      _activeOcrEngine = ProductionOcrEngine();
    }
    await _activeOcrEngine.initialize(language: _language);
    RecognitionLogger.stage('SERVICE', 'Switched OCR Engine Mode to: ${_activeOcrEngine.engineName}');
  }

  Future<void> setLanguage(OcrLanguage lang) async {
    _language = lang;
    await _activeOcrEngine.initialize(language: lang);
    RecognitionLogger.stage('SERVICE', 'Switched OCR Language to: ${lang.name}');
  }

  bool get isReady => (_pipeline != null || _aiPipeline != null || _activeOcrEngine.isReady) && !_disposed;
  bool get isProcessing => _processing;
  bool get isDisposed => _disposed;
  bool get isInitializing => state.value == RecognitionServiceState.initializing;
  bool get hasError =>
      state.value == RecognitionServiceState.error ||
      state.value == RecognitionServiceState.disposed;
  String get lastErrorMessage => lastError.value;

  RecognitionPipeline? get pipeline => _disposed ? null : _pipeline;

  Future<void> ensureReady() async {
    if (_disposed) throw StateError('Recognition service was disposed');
    if (isReady) return;

    if (_initCompleter != null) {
      state.value = RecognitionServiceState.initializing;
      await _initCompleter!.future;
      if (!isReady) throw StateError('Initialization completed but pipeline is not ready');
      return;
    }

    _initCompleter = Completer<void>();
    state.value = RecognitionServiceState.initializing;
    statusMessage.value = 'Loading AI models...';

    try {
      final startTime = DateTime.now();
      RecognitionLogger.stage('SERVICE', 'Loading Recognition Engine...');

      // Load AI Pipeline (Optional)
      try {
        _aiPipeline = AiRecognitionPipeline();
        await _aiPipeline!.initialize(legacyShopMemory: _shopMemory);
        RecognitionLogger.stage('SERVICE', 'AI Pipeline created');
      } catch (e) {
        _aiPipeline = null;
        RecognitionLogger.log('Service: AI pipeline init failed, falling back: $e');
      }

      // Load ML Kit Handwriting Engine
      _handwritingEngine = HandwritingEngine();
      final initResult = await _handwritingEngine!.initialize();
      initResult.when(
        success: (_) {
          // Construct Pipeline
          final dataSource = RecognitionLocalDataSource(handwritingEngine: _handwritingEngine);
          final repository = RecognitionRepositoryImpl(dataSource);
          _pipeline = RecognitionPipeline(repository: repository, shopMemory: _shopMemory);
          
          final elapsed = DateTime.now().difference(startTime).inMilliseconds;
          state.value = RecognitionServiceState.ready;
          statusMessage.value = 'Recognition Service Ready';
          RecognitionLogger.stage('SERVICE', 'Recognition Service Ready (${elapsed}ms)');
        },
        error: (failure) {
          throw Exception('Handwriting Engine failed to initialize: ${failure.message}');
        }
      );

      if (!_initCompleter!.isCompleted) _initCompleter!.complete();
    } catch (e, stack) {
      state.value = RecognitionServiceState.error;
      statusMessage.value = 'Recognition Engine failed to initialize.';
      lastError.value = 'Recognition Engine failed to initialize.\n$e';
      RecognitionLogger.error('Service.ensureReady', e, stack);

      if (!_initCompleter!.isCompleted) _initCompleter!.completeError(e);
    }
  }

  Future<RecognitionTaskResult> recognizeStrokes(
    List<InkStroke> strokes, {
    Duration timeout = const Duration(seconds: 10),
  }) async {
    try {
      await ensureReady();
    } catch (e) {
      _setError('$e');
      return RecognitionTaskResult.failed;
    }

    if (_processing) {
      RecognitionLogger.log('Service: duplicate request rejected');
      return RecognitionTaskResult.cancelled;
    }

    if (_pipeline == null) {
      _setError('Pipeline not available');
      return RecognitionTaskResult.failed;
    }

    _processing = true;
    _currentTaskToken = CancellationToken();
    state.value = RecognitionServiceState.processing;
    statusMessage.value = 'Recognizing strokes...';
    progress.value = 0.1;
    lastResult.value = null;
    RecognitionLogger.stage('SERVICE', 'Stroke Recognition Started');

    try {
      _currentTaskToken?.throwIfCancelled();

      // Listen to internal pipeline progress
      void onPipelineChange() {
         progress.value = 0.4 + (_pipeline!.value.progress * 0.5);
         if (_pipeline!.value.stage == PipelineStage.parsing) {
            statusMessage.value = 'Extracting bill items...';
         }
      }
      _pipeline!.addListener(onPipelineChange);

      final result = await _pipeline!.recognizeStrokes(strokes).timeout(timeout);

      _pipeline!.removeListener(onPipelineChange);
      _currentTaskToken?.throwIfCancelled();

      return result.when(
        success: (data) {
          progress.value = 1.0;
          state.value = RecognitionServiceState.success;
          statusMessage.value = 'Recognition complete';
          lastResult.value = RecognitionTaskResult.success;
          RecognitionLogger.stage('SERVICE', 'Recognition Completed');
          _processing = false;
          return RecognitionTaskResult.success;
        },
        error: (failure) {
          _setError(failure.message);
          RecognitionLogger.error('Service.recognizeStrokes', failure.message);
          _processing = false;
          return RecognitionTaskResult.failed;
        },
      );
    } on TimeoutException {
      _processing = false;
      state.value = RecognitionServiceState.error;
      statusMessage.value = 'Recognition timed out';
      lastResult.value = RecognitionTaskResult.timedOut;
      lastError.value = 'Recognition took longer than expected.\nPlease try again.';
      RecognitionLogger.stage('SERVICE', 'Timeout Triggered');
      return RecognitionTaskResult.timedOut;
    } on CancellationException {
      _processing = false;
      state.value = RecognitionServiceState.ready;
      statusMessage.value = 'Cancelled';
      lastResult.value = RecognitionTaskResult.cancelled;
      RecognitionLogger.stage('SERVICE', 'Cancelled');
      return RecognitionTaskResult.cancelled;
    } catch (e, stack) {
      _processing = false;
      if (_disposed) return RecognitionTaskResult.cancelled;
      _setError('Recognition error: $e');
      RecognitionLogger.error('Service.recognizeStrokes', e, stack);
      return RecognitionTaskResult.failed;
    } finally {
      _currentTaskToken = null;
    }
  }

  Future<RecognitionTaskResult> recognizeImage(
    Uint8List imageBytes, {
    Duration timeout = const Duration(seconds: 15),
  }) async {
    try {
      await ensureReady();
    } catch (e) {
      _setError('$e');
      return RecognitionTaskResult.failed;
    }

    if (_processing) {
      RecognitionLogger.log('Service: duplicate request rejected');
      return RecognitionTaskResult.cancelled;
    }

    _processing = true;
    _currentTaskToken = CancellationToken();
    state.value = RecognitionServiceState.processing;
    statusMessage.value = 'Recognizing...';
    progress.value = 0.1;
    lastResult.value = null;
    RecognitionLogger.stage('SERVICE', 'Recognition Started');

    try {
      _currentTaskToken?.throwIfCancelled();

      // Execute Active OcrEngine (PaddleOCR + TrOCR Production or ML Kit Debug)
      final ocrPayload = await _activeOcrEngine.recognize(imageBytes).timeout(timeout);
      _currentTaskToken?.throwIfCancelled();
      _benchmarkSystem.recordBenchmark(ocrPayload);

      final billResult = BillStructureResult(
        lineItems: ocrPayload.lineItems,
        confidence: ocrPayload.confidence,
        rawText: ocrPayload.rawText,
        diagnosticCategory: ocrPayload.category,
        failureCode: ocrPayload.failureCode,
        warnings: ocrPayload.warnings,
        recognizerName: ocrPayload.engineName,
        blocksCount: ocrPayload.boundingBoxes.length,
        linesCount: ocrPayload.lineItems.length,
        wordsCount: ocrPayload.rawText.split(RegExp(r'\s+')).where((w) => w.isNotEmpty).length,
      );

      _completeSuccess(billResult);
      return RecognitionTaskResult.success;
    } on TimeoutException {
      _processing = false;
      state.value = RecognitionServiceState.error;
      statusMessage.value = 'Recognition timed out';
      lastResult.value = RecognitionTaskResult.timedOut;
      lastError.value = 'Recognition took longer than expected.\nPlease try again.';
      RecognitionLogger.stage('SERVICE', 'Timeout Triggered');
      return RecognitionTaskResult.timedOut;
    } on CancellationException {
      _processing = false;
      state.value = RecognitionServiceState.ready;
      statusMessage.value = 'Cancelled';
      lastResult.value = RecognitionTaskResult.cancelled;
      RecognitionLogger.stage('SERVICE', 'Cancelled');
      return RecognitionTaskResult.cancelled;
    } catch (e, stack) {
      _processing = false;
      if (_disposed) return RecognitionTaskResult.cancelled;
      _setError('Recognition error: $e');
      RecognitionLogger.error('Service.recognizeImage', e, stack);
      return RecognitionTaskResult.failed;
    } finally {
      _currentTaskToken = null;
    }
  }

  void _completeSuccess(BillStructureResult data) {
      lastBillResult = data;
      progress.value = 1.0;
      state.value = RecognitionServiceState.success;
      statusMessage.value = 'Recognition complete';
      lastResult.value = RecognitionTaskResult.success;
      RecognitionLogger.stage('SERVICE', 'Recognition Completed');
      _processing = false;
  }

  void cancel() {
    _currentTaskToken?.cancel();
    if (_pipeline != null && !_disposed) _pipeline!.cancel();
    if (!_disposed) {
      _processing = false;
      state.value = RecognitionServiceState.ready;
      statusMessage.value = 'Cancelled';
    }
    RecognitionLogger.log('Service: recognition cancelled');
  }

  Future<void> retry() async {
    if (_disposed) return;
    cancel();

    _initCompleter = null;
    if (isReady) {
      state.value = RecognitionServiceState.ready;
      statusMessage.value = 'Ready to retry';
      lastResult.value = null;
      lastError.value = '';
      lastBillResult = null;
      progress.value = 0.0;
      return;
    }

    state.value = RecognitionServiceState.notInitialized;
    statusMessage.value = 'Re-initializing...';
    lastResult.value = null;
    lastError.value = '';
    lastBillResult = null;
    progress.value = 0.0;
    await ensureReady();
  }

  void injectShopMemory(ShopMemory memory) {
    _shopMemory = memory;
    _pipeline?.dispose();
    _pipeline = null;
    _initCompleter = null;
    ensureReady(); // Re-initialize with new shop memory
  }

  void _setError(String message) {
    _processing = false;
    state.value = RecognitionServiceState.error;
    statusMessage.value = message;
    lastResult.value = RecognitionTaskResult.failed;
    lastError.value = message;
    progress.value = 0.0;
  }

  void dispose() {
    if (_disposed) return;
    _disposed = true;
    _processing = false;
    _currentTaskToken?.cancel();

    _pipeline?.dispose();
    _aiPipeline?.dispose();
    
    if (_initCompleter != null && !_initCompleter!.isCompleted) {
      _initCompleter!.completeError(StateError('Service disposed'));
    }
    
    state.value = RecognitionServiceState.disposed;
    statusMessage.value = 'Disposed';
    _instance = null;

    state.dispose();
    statusMessage.dispose();
    progress.dispose();
    lastResult.dispose();
    lastError.dispose();
  }
}
