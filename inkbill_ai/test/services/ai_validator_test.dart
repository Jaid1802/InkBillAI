import 'package:flutter_test/flutter_test.dart';
import 'package:inkbill_ai/services/recognition/ai_validator.dart';
import 'package:inkbill_ai/services/recognition/bill_parser.dart';

void main() {
  group('AIValidator', () {
    late AIValidator validator;

    setUp(() {
      validator = AIValidator();
    });

    test('validates clean parse result as trusted', () {
      final parser = BillParser();
      final parseResult = parser.parse(['Apple 2 50']);

      final result = validator.validate(parseResult);

      expect(result.issues.where((i) => i.severity == ValidationSeverity.error),
          isEmpty);
    });

    test('detects low confidence items', () {
      final items = [
        ParsedItem(
          name: 'Unknown Item',
          nameConfidence: 0.3,
        ),
      ];
      final parseResult = BillParseResult(
        items: items,
        overallConfidence: 0.3,
      );

      final result = validator.validate(parseResult);

      expect(
          result.issues.any(
              (i) => i.field == 'name' && i.severity == ValidationSeverity.error),
          true);
    });

    test('detects missing quantity', () {
      final items = [
        ParsedItem(
          name: 'Apple',
          nameConfidence: 0.9,
          rate: 50.0,
          rateConfidence: 0.9,
        ),
      ];
      final parseResult = BillParseResult(
        items: items,
        overallConfidence: 0.6,
      );

      final result = validator.validate(parseResult);

      expect(
          result.issues.any((i) =>
              i.field == 'quantity' &&
              i.severity == ValidationSeverity.error &&
              i.message.contains('Missing')),
          true);
    });

    test('detects missing rate', () {
      final items = [
        ParsedItem(
          name: 'Apple',
          nameConfidence: 0.9,
          quantity: 2.0,
          quantityConfidence: 0.9,
        ),
      ];
      final parseResult = BillParseResult(
        items: items,
        overallConfidence: 0.6,
      );

      final result = validator.validate(parseResult);

      expect(
          result.issues.any((i) =>
              i.field == 'rate' &&
              i.severity == ValidationSeverity.error &&
              i.message.contains('Missing')),
          true);
    });

    test('detects amount mismatch', () {
      final items = [
        ParsedItem(
          name: 'Apple',
          nameConfidence: 0.9,
          quantity: 2.0,
          rate: 50.0,
          amount: 80.0,
          quantityConfidence: 0.9,
          rateConfidence: 0.9,
          amountConfidence: 0.9,
        ),
      ];
      final parseResult = BillParseResult(
        items: items,
        overallConfidence: 0.8,
      );

      final result = validator.validate(parseResult);

      expect(
          result.issues.any((i) =>
              i.field == 'amount' &&
              i.severity == ValidationSeverity.error &&
              i.message.contains('mismatch')),
          true);
    });

    test('detects duplicate items via warnings', () {
      final parser = BillParser();
      final parseResult = parser.parse(['Apple 2 50', 'Apple 1 30']);

      final result = validator.validate(parseResult);

      expect(result.issues.any((i) => i.field == 'duplicate'), true);
    });

    test('warns when overall confidence is low', () {
      final items = [
        ParsedItem(
          name: 'Apple',
          nameConfidence: 0.9,
          quantity: 2.0,
          rate: 50.0,
          quantityConfidence: 0.4,
          rateConfidence: 0.4,
        ),
      ];
      final parseResult = BillParseResult(
        items: items,
        overallConfidence: 0.4,
      );

      final result = validator.validate(parseResult);

      expect(
          result.issues.any((i) =>
              i.field == 'general' &&
              i.message.contains('confidence is low')),
          true);
    });

    test('issues proper severity labels', () {
      expect(AIValidator.severityLabel(ValidationSeverity.error), 'Error');
      expect(AIValidator.severityLabel(ValidationSeverity.warning), 'Warning');
      expect(AIValidator.severityLabel(ValidationSeverity.info), 'Info');
    });
  });
}
