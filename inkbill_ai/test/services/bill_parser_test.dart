import 'package:flutter_test/flutter_test.dart';
import 'package:inkbill_ai/services/recognition/bill_parser.dart';

void main() {
  group('BillParser - Basic Parsing', () {
    late BillParser parser;

    setUp(() {
      parser = BillParser();
    });

    test('parses "Apple 2 50" correctly', () {
      final result = parser.parse(['Apple 2 50']);

      expect(result.items.length, 1);
      expect(result.items.first.name, 'Apple');
      expect(result.items.first.quantity, 2.0);
      expect(result.items.first.rate, 50.0);
      expect(result.items.first.amount, 100.0);
    });

    test('parses "Tea 2 10" correctly', () {
      final result = parser.parse(['Tea 2 10']);

      expect(result.items.length, 1);
      expect(result.items.first.name, 'Tea');
      expect(result.items.first.quantity, 2.0);
      expect(result.items.first.rate, 10.0);
      expect(result.items.first.amount, 20.0);
    });

    test('parses "Bread 1 35" correctly', () {
      final result = parser.parse(['Bread 1 35']);

      expect(result.items.length, 1);
      expect(result.items.first.name, 'Bread');
      expect(result.items.first.quantity, 1.0);
      expect(result.items.first.rate, 35.0);
      expect(result.items.first.amount, 35.0);
    });

    test('parses multiple lines', () {
      final result = parser.parse([
        'Apple 2 50',
        'Tea 1 10',
        'Milk 3 30',
      ]);

      expect(result.items.length, 3);
      expect(result.items[0].name, 'Apple');
      expect(result.items[1].name, 'Tea');
      expect(result.items[2].name, 'Milk');
    });

    test('parses with quantity words like kg', () {
      final result = parser.parse(['Rice 5kg 40']);

      expect(result.items.length, 1);
      expect(result.items.first.name, 'Rice');
      expect(result.items.first.quantity, 5.0);
      expect(result.items.first.rate, 40.0);
    });
  });

  group('BillParser - No Hallucination', () {
    late BillParser parser;

    setUp(() {
      parser = BillParser();
    });

    test('returns extracted name even when not in dictionary', () {
      final result = parser.parse(['XyzAbc 2 50']);

      expect(result.items.length, 1);
      expect(result.items.first.name, 'Xyzabc');
    });

    test('does not hallucinate common items from gibberish', () {
      final result = parser.parse(['QwErTyUiOp 1 1']);

      expect(result.items.length, 1);
      expect(result.items.first.name, isNot('Coffee'));
      expect(result.items.first.name, isNot('Tea'));
      expect(result.items.first.name, isNot('Chai'));
      expect(result.items.first.name, isNot('Milk'));
    });

    test('returns empty for completely empty input', () {
      final result = parser.parse([]);

      expect(result.items, isEmpty);
      expect(result.warnings, isNotEmpty);
    });
  });

  group('BillParser - Amount Validation', () {
    late BillParser parser;

    setUp(() {
      parser = BillParser();
    });

    test('detects amount mismatch', () {
      final result = parser.parse(['Apple 2 50']);

      expect(result.items.first.amount, 100.0);
    });

    test('handles single number as quantity when small', () {
      final result = parser.parse(['Apple 2']);

      expect(result.items.first.name, 'Apple');
      expect(result.items.first.quantity, 2.0);
      expect(result.items.first.rate, isNull);
    });
  });

  group('BillParser - Field Confidence', () {
    late BillParser parser;

    setUp(() {
      parser = BillParser();
    });

    test('high confidence for known items', () {
      final result = parser.parse(['Milk 2 25']);

      expect(result.items.first.nameConfidence, greaterThan(0.8));
    });

    test('lower confidence for unknown items', () {
      final result = parser.parse(['GadgetX 2 50']);

      expect(result.items.first.nameConfidence, lessThan(0.8));
    });
  });

  group('BillParser - Duplicate Detection', () {
    late BillParser parser;

    setUp(() {
      parser = BillParser();
    });

    test('detects duplicate items', () {
      final result = parser.parse([
        'Apple 2 50',
        'Apple 1 30',
      ]);

      expect(result.warnings.any((w) => w.contains('Duplicate')), true);
    });
  });

  group('BillParser - Edge Cases', () {
    late BillParser parser;

    setUp(() {
      parser = BillParser();
    });

    test('handles empty line', () {
      final result = parser.parse(['']);

      expect(result.items, isEmpty);
    });

    test('handles single word line', () {
      final result = parser.parse(['Hello']);

      expect(result.items.length, 1);
    });

    test('handles lines with special characters', () {
      final result = parser.parse(['M!lk 2 50']);

      expect(result.items.length, 1);
      expect(result.items.first.quantity, 2.0);
      expect(result.items.first.rate, 50.0);
    });
  });
}
