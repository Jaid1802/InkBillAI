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

class BillStructureResult extends Equatable {
  final List<LineItemData> lineItems;
  final CustomerData? customerData;
  final double? total;
  final double confidence;

  const BillStructureResult({
    this.lineItems = const [],
    this.customerData,
    this.total,
    this.confidence = 0.0,
  });

  @override
  List<Object?> get props => [lineItems, customerData, total, confidence];
}

class LineItemData extends Equatable {
  final String name;
  final double? quantity;
  final double? rate;
  final double? amount;
  final double confidence;

  const LineItemData({
    this.name = '',
    this.quantity,
    this.rate,
    this.amount,
    this.confidence = 0.0,
  });

  @override
  List<Object?> get props => [name, quantity, rate, amount, confidence];
}

class CustomerData extends Equatable {
  final String? name;
  final String? phone;
  final String? gstin;

  const CustomerData({this.name, this.phone, this.gstin});

  @override
  List<Object?> get props => [name, phone, gstin];
}
