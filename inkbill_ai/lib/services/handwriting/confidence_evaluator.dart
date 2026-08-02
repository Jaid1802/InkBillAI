import 'package:inkbill_ai/services/handwriting/models/handwriting_line.dart';

class ConfidenceEvaluator {
  final double _highThreshold;
  final double _reliableThreshold;
  final double _uncertainThreshold;
  final double _minimumStrokeQuality;

  const ConfidenceEvaluator({
    double highThreshold = 0.7,
    double reliableThreshold = 0.5,
    double uncertainThreshold = 0.3,
    double minimumStrokeQuality = 0.25,
  })  : _highThreshold = highThreshold,
        _reliableThreshold = reliableThreshold,
        _uncertainThreshold = uncertainThreshold,
        _minimumStrokeQuality = minimumStrokeQuality;

  HandwritingRecognitionResult evaluate(
      List<HandwritingLine> lines) {
    if (lines.isEmpty) {
      return const HandwritingRecognitionResult(
        overallConfidence: 0.0,
        warnings: ['No lines detected'],
      );
    }

    final warnings = <String>[];
    final result = <HandwritingLine>[];
    double totalConfidence = 0.0;
    int totalFields = 0;

    for (final line in lines) {
      final cleanFields = <RecognizedField>[];
      for (final field in line.fields) {
        final evaluated = _evaluateField(field, warnings, line.index);
        cleanFields.add(evaluated);
      }

      final cleanedLine = line.copyWith(fields: cleanFields);
      result.add(cleanedLine);

      for (final field in cleanFields) {
        if (field.isReliable) {
          totalConfidence += field.confidence;
          totalFields++;
        }
      }
    }

    final overallConfidence =
        totalFields > 0 ? totalConfidence / totalFields : 0.0;

    return HandwritingRecognitionResult(
      lines: result,
      overallConfidence: overallConfidence,
      warnings: warnings,
    );
  }

  RecognizedField _evaluateField(
    RecognizedField field,
    List<String> warnings,
    int lineIndex,
  ) {
    if (field.strokeCount == 0) {
      return field;
    }

    if (field.confidence < _minimumStrokeQuality) {
      warnings.add('Line ${lineIndex + 1}: Very low quality recognition - field discarded');
      return RecognizedField(
        type: field.type,
        text: '',
        confidence: 0.0,
        x: field.x,
        y: field.y,
        width: field.width,
        height: field.height,
        strokeCount: field.strokeCount,
      );
    }

    if (field.text.isEmpty && field.confidence < _uncertainThreshold) {
      return field;
    }

    if (field.text.isEmpty && field.confidence >= _uncertainThreshold) {
      warnings.add('Line ${lineIndex + 1}: Text recognized but empty after filtering');
      return field;
    }

    if (field.confidence < _reliableThreshold && field.text.isNotEmpty) {
      warnings.add('Line ${lineIndex + 1}: Low confidence field "${field.text}" - verify manually');
    }

    if (field.type == FieldType.number && field.text.isNotEmpty) {
      final numeric = double.tryParse(field.text);
      if (numeric == null) {
        warnings.add('Line ${lineIndex + 1}: Number field "${field.text}" is not a valid number');
      }
    }

    return field;
  }

  bool shouldAcceptField(RecognizedField field) {
    if (field.text.isEmpty) return false;
    if (field.confidence < _minimumStrokeQuality) return false;
    return true;
  }

  bool shouldRejectLine(HandwritingLine line) {
    if (line.fields.isEmpty) return true;
    return line.fields.every((f) => !shouldAcceptField(f));
  }
}
