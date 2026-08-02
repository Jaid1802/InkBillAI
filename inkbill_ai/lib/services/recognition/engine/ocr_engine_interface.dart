import 'dart:typed_data';
import 'package:inkbill_ai/features/ai/domain/entities/recognition_result.dart';
import 'package:inkbill_ai/services/ai/models/ai_model_interfaces.dart';

enum OcrEngineMode {
  paddleOcrTrOcr,
  mlKitDebug,
  auto,
}

enum OcrLanguage {
  english,
  hindi,
  marathi,
}

class OcrResultPayload {
  final String rawText;
  final List<LineItemData> lineItems;
  final List<DetectedTextBox> boundingBoxes;
  final String engineName;
  final double confidence;
  final int detectionTimeMs;
  final int recognitionTimeMs;
  final int totalTimeMs;
  final double memoryUsageMb;
  final OcrDiagnosticCategory category;
  final String? failureCode;
  final List<String> warnings;
  final Map<String, dynamic> metadata;

  const OcrResultPayload({
    required this.rawText,
    this.lineItems = const [],
    this.boundingBoxes = const [],
    required this.engineName,
    this.confidence = 0.9,
    this.detectionTimeMs = 0,
    this.recognitionTimeMs = 0,
    this.totalTimeMs = 0,
    this.memoryUsageMb = 45.0,
    this.category = OcrDiagnosticCategory.none,
    this.failureCode,
    this.warnings = const [],
    this.metadata = const {},
  });
}

abstract class OcrEngine {
  String get engineName;
  bool get isReady;
  OcrEngineMode get mode;

  Future<void> initialize({OcrLanguage language = OcrLanguage.english});
  Future<OcrResultPayload> recognize(Uint8List imageBytes);
  Future<void> dispose();
}
