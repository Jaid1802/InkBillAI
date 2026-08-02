import 'package:equatable/equatable.dart';

class RecognizedText extends Equatable {
  final String text;
  final double confidence;

  const RecognizedText({required this.text, required this.confidence});

  @override
  List<Object?> get props => [text, confidence];
}

class RecognitionResult extends Equatable {
  final List<RecognizedText> candidates;
  final String? bestText;
  final double confidence;

  const RecognitionResult({
    this.candidates = const [],
    this.bestText,
    this.confidence = 0.0,
  });

  bool get isHighConfidence => confidence >= 0.7;
  bool get isMediumConfidence => confidence >= 0.4 && confidence < 0.7;
  bool get isLowConfidence => confidence < 0.4;

  @override
  List<Object?> get props => [candidates, bestText, confidence];
}

class LayoutRecognitionResult extends Equatable {
  final List<DetectedRow> rows;
  final double confidence;

  const LayoutRecognitionResult({
    this.rows = const [],
    this.confidence = 0.0,
  });

  @override
  List<Object?> get props => [rows, confidence];
}

class DetectedRow extends Equatable {
  final List<DetectedCell> cells;
  final String type;

  const DetectedRow({this.cells = const [], this.type = 'unknown'});

  @override
  List<Object?> get props => [cells, type];
}

class DetectedCell extends Equatable {
  final RecognitionResult text;
  final String fieldType;
  final double x;
  final double y;
  final double width;
  final double height;

  const DetectedCell({
    required this.text,
    this.fieldType = 'unknown',
    this.x = 0,
    this.y = 0,
    this.width = 0,
    this.height = 0,
  });

  @override
  List<Object?> get props => [text, fieldType, x, y, width, height];
}

enum OcrDiagnosticCategory {
  none,
  noStrokes,
  exportFailed,
  emptyExportedImage,
  imageDecodeFailed,
  preprocessingFailed,
  noTextRegions,
  modelNotLoaded,
  modelInitializationFailed,
  modelInferenceFailed,
  ocrReturnedZeroBlocks,
  ocrReturnedEmptyText,
  noRawText,
  lowConfidence,
  parserFailed,
  timeout,
}

class BillStructureResult extends Equatable {
  final List<LineItemData> lineItems;
  final CustomerData? customerData;
  final double? total;
  final double confidence;
  final List<String> warnings;
  final String rawText;
  final OcrDiagnosticCategory diagnosticCategory;
  final String? failureCode;
  final double nonWhitePixelPercentage;
  final double brightnessPercentage;
  final String? debugOriginalPath;
  final String? debugPreprocessedPath;
  final String? debugThresholdPath;
  final String? debugFinalInputPath;
  final String? debugDetectedRegionsPath;
  final List<String> detectedLines;
  final String recognizerName;
  final int blocksCount;
  final int linesCount;
  final int wordsCount;
  final int imageWidth;
  final int imageHeight;

  const BillStructureResult({
    this.lineItems = const [],
    this.customerData,
    this.total,
    this.confidence = 0.0,
    this.warnings = const [],
    this.rawText = '',
    this.diagnosticCategory = OcrDiagnosticCategory.none,
    this.failureCode,
    this.nonWhitePixelPercentage = 0.0,
    this.brightnessPercentage = 0.0,
    this.debugOriginalPath,
    this.debugPreprocessedPath,
    this.debugThresholdPath,
    this.debugFinalInputPath,
    this.debugDetectedRegionsPath,
    this.detectedLines = const [],
    this.recognizerName = 'Google ML Kit',
    this.blocksCount = 0,
    this.linesCount = 0,
    this.wordsCount = 0,
    this.imageWidth = 0,
    this.imageHeight = 0,
  });

  @override
  List<Object?> get props => [
        lineItems,
        customerData,
        total,
        confidence,
        warnings,
        rawText,
        diagnosticCategory,
        failureCode,
        nonWhitePixelPercentage,
        brightnessPercentage,
        debugOriginalPath,
        debugPreprocessedPath,
        debugThresholdPath,
        debugFinalInputPath,
        debugDetectedRegionsPath,
        detectedLines,
        recognizerName,
        blocksCount,
        linesCount,
        wordsCount,
        imageWidth,
        imageHeight,
      ];
}

class LineItemData extends Equatable {
  final String name;
  final double? quantity;
  final double? rate;
  final double? amount;
  final double confidence;
  final double nameConfidence;
  final double quantityConfidence;
  final double rateConfidence;
  final bool isMissingQuantity;
  final bool isMissingRate;
  final bool amountMismatch;

  const LineItemData({
    this.name = '',
    this.quantity,
    this.rate,
    this.amount,
    this.confidence = 0.0,
    this.nameConfidence = 0.0,
    this.quantityConfidence = 0.0,
    this.rateConfidence = 0.0,
    this.isMissingQuantity = false,
    this.isMissingRate = false,
    this.amountMismatch = false,
  });

  @override
  List<Object?> get props => [
        name,
        quantity,
        rate,
        amount,
        confidence,
        nameConfidence,
        quantityConfidence,
        rateConfidence,
        isMissingQuantity,
        isMissingRate,
        amountMismatch,
      ];
}

class CustomerData extends Equatable {
  final String? name;
  final String? phone;
  final String? gstin;

  const CustomerData({this.name, this.phone, this.gstin});

  @override
  List<Object?> get props => [name, phone, gstin];
}

class ValidationIssueData extends Equatable {
  final String field;
  final String message;
  final String severity;
  final int? itemIndex;

  const ValidationIssueData({
    required this.field,
    required this.message,
    this.severity = 'warning',
    this.itemIndex,
  });

  @override
  List<Object?> get props => [field, message, severity, itemIndex];
}
