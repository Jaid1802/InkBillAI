import 'package:equatable/equatable.dart';
import 'package:inkbill_ai/features/handwriting/domain/entities/ink_stroke.dart';

enum FieldType { word, number, unknown }

class RecognizedField extends Equatable {
  final FieldType type;
  final String text;
  final double confidence;
  final double x;
  final double y;
  final double width;
  final double height;
  final int strokeCount;

  bool get isHighConfidence => confidence >= 0.7;
  bool get isReliable => confidence >= 0.5;
  bool get isUncertain => confidence < 0.5;
  bool get isLowQuality => confidence < 0.3;

  const RecognizedField({
    required this.type,
    required this.text,
    required this.confidence,
    required this.x,
    required this.y,
    required this.width,
    required this.height,
    this.strokeCount = 0,
  });

  @override
  List<Object?> get props =>
      [type, text, confidence, x, y, width, height, strokeCount];
}

class HandwritingLine extends Equatable {
  final int index;
  final List<InkStroke> strokes;
  final List<RecognizedField> fields;
  final double y;
  final double height;
  final double lineSpacing;

  bool get isEmpty => strokes.isEmpty;
  bool get hasText => fields.any((f) => f.text.isNotEmpty);
  bool get isHighConfidence => fields.isNotEmpty && fields.every((f) => f.isHighConfidence);
  bool get hasReliableFields => fields.isNotEmpty && fields.any((f) => f.isReliable);

  int get totalStrokes => strokes.length;
  int get reliableFieldCount => fields.where((f) => f.isReliable).length;
  double get averageConfidence {
    if (fields.isEmpty) return 0.0;
    return fields.map((f) => f.confidence).reduce((a, b) => a + b) / fields.length;
  }

  const HandwritingLine({
    this.index = 0,
    this.strokes = const [],
    this.fields = const [],
    this.y = 0,
    this.height = 0,
    this.lineSpacing = 0,
  });

  HandwritingLine copyWith({List<RecognizedField>? fields}) {
    return HandwritingLine(
      index: index,
      strokes: strokes,
      fields: fields ?? this.fields,
      y: y,
      height: height,
      lineSpacing: lineSpacing,
    );
  }

  @override
  List<Object?> get props => [index, strokes, fields, y, height, lineSpacing];
}

class HandwritingRecognitionResult extends Equatable {
  final List<HandwritingLine> lines;
  final double overallConfidence;
  final List<String> warnings;

  bool get isComplete => lines.isNotEmpty && lines.every((l) => l.isHighConfidence);
  bool get hasUncertainLines => lines.any((l) => l.fields.any((f) => f.isUncertain));
  int get totalReliableFields => lines.fold(0, (sum, l) => sum + l.reliableFieldCount);

  const HandwritingRecognitionResult({
    this.lines = const [],
    this.overallConfidence = 0.0,
    this.warnings = const [],
  });

  @override
  List<Object?> get props => [lines, overallConfidence, warnings];
}
