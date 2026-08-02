import 'package:inkbill_ai/services/recognition/engine/ocr_engine_interface.dart';
import 'package:inkbill_ai/services/recognition/recognition_logger.dart';

class BenchmarkMetricEntry {
  final DateTime timestamp;
  final String engineName;
  final int totalTimeMs;
  final int detectionTimeMs;
  final int recognitionTimeMs;
  final double confidence;
  final int boundingBoxesCount;
  final double memoryUsageMb;
  final int charCount;
  final bool success;

  const BenchmarkMetricEntry({
    required this.timestamp,
    required this.engineName,
    required this.totalTimeMs,
    required this.detectionTimeMs,
    required this.recognitionTimeMs,
    required this.confidence,
    required this.boundingBoxesCount,
    required this.memoryUsageMb,
    required this.charCount,
    required this.success,
  });
}

class OcrBenchmarkSystem {
  static OcrBenchmarkSystem? _instance;
  final List<BenchmarkMetricEntry> _history = [];

  OcrBenchmarkSystem._();

  factory OcrBenchmarkSystem() {
    _instance ??= OcrBenchmarkSystem._();
    return _instance!;
  }

  List<BenchmarkMetricEntry> get history => List.unmodifiable(_history);

  void recordBenchmark(OcrResultPayload payload) {
    final entry = BenchmarkMetricEntry(
      timestamp: DateTime.now(),
      engineName: payload.engineName,
      totalTimeMs: payload.totalTimeMs,
      detectionTimeMs: payload.detectionTimeMs,
      recognitionTimeMs: payload.recognitionTimeMs,
      confidence: payload.confidence,
      boundingBoxesCount: payload.boundingBoxes.length,
      memoryUsageMb: payload.memoryUsageMb,
      charCount: payload.rawText.length,
      success: payload.rawText.isNotEmpty,
    );

    _history.add(entry);
    if (_history.length > 50) {
      _history.removeAt(0);
    }

    RecognitionLogger.stage(
      'BENCHMARK',
      'Benchmark recorded for ${payload.engineName}:\n'
      '  Total Time: ${payload.totalTimeMs}ms (Det: ${payload.detectionTimeMs}ms, Rec: ${payload.recognitionTimeMs}ms)\n'
      '  Boxes: ${payload.boundingBoxes.length}, Memory: ${payload.memoryUsageMb.toStringAsFixed(1)}MB'
    );
  }

  BenchmarkMetricEntry? get latest => _history.isNotEmpty ? _history.last : null;

  double get avgTotalTimeMs {
    if (_history.isEmpty) return 0.0;
    final sum = _history.fold<int>(0, (prev, e) => prev + e.totalTimeMs);
    return sum / _history.length;
  }
}
