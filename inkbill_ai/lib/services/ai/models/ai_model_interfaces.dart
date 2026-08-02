import 'dart:typed_data';
import 'package:inkbill_ai/core/utils/result.dart';
import 'package:inkbill_ai/features/ai/domain/entities/recognition_result.dart';

class DetectedTextBox {
  final double x, y, width, height;
  final String? text;
  final double confidence;
  final double angle;

  const DetectedTextBox({
    required this.x,
    required this.y,
    required this.width,
    required this.height,
    this.text,
    this.confidence = 0.0,
    this.angle = 0.0,
  });
}

class LayoutRegion {
  final String type;
  final double x, y, width, height;
  final List<DetectedTextBox> textBoxes;

  const LayoutRegion({
    required this.type,
    required this.x,
    required this.y,
    required this.width,
    required this.height,
    this.textBoxes = const [],
  });
}

class LineSegment {
  final Uint8List croppedImage;
  final double y, height;
  final List<DetectedTextBox> words;
  final List<DetectedTextBox> numbers;

  const LineSegment({
    required this.croppedImage,
    required this.y,
    required this.height,
    this.words = const [],
    this.numbers = const [],
  });
}

abstract class TextDetector {
  String get modelName => 'TextDetector';
  bool get isLoaded => false;

  Future<Result<bool>> load(String modelPath);
  Future<Result<List<DetectedTextBox>>> detect(Uint8List imageBytes);
  Future<Result<void>> unload();
}

abstract class TextRecognizer {
  String get modelName => 'TextRecognizer';
  bool get isLoaded => false;

  Future<Result<bool>> load(String modelPath);
  Future<Result<RecognizedText>> recognize(Uint8List imageBytes);
  Future<Result<List<RecognizedText>>> recognizeBatch(
      List<Uint8List> imageBatches);
  Future<Result<void>> unload();
}

abstract class LayoutAnalyzer {
  String get modelName => 'LayoutAnalyzer';
  bool get isLoaded => false;

  Future<Result<bool>> load(String modelPath);
  Future<Result<List<LayoutRegion>>> analyze(Uint8List imageBytes);
  Future<Result<List<LineSegment>>> segmentIntoLines(Uint8List imageBytes);
  Future<Result<void>> unload();
}
