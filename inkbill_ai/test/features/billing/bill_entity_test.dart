import 'package:flutter_test/flutter_test.dart';
import 'package:inkbill_ai/features/billing/domain/entities/bill.dart';

void main() {
  // A minimal Bill used as the base for all tests.
  final _base = Bill(
    id: 'bill_test',
    customerId: 'cust_001',
    customerName: 'Alice',
    notes: 'Please deliver by Friday',
    createdAt: DateTime(2024, 1, 1),
    updatedAt: DateTime(2024, 1, 1),
  );

  group('Bill.copyWith – clearCustomer flag', () {
    test('clearCustomer: true nulls both customerId and customerName', () {
      final cleared = _base.copyWith(clearCustomer: true);

      expect(cleared.customerId, isNull,
          reason: 'customerId must be null after clearCustomer');
      expect(cleared.customerName, isNull,
          reason: 'customerName must be null after clearCustomer');
    });

    test('clearCustomer: true does not affect other fields', () {
      final cleared = _base.copyWith(clearCustomer: true);

      expect(cleared.id, equals(_base.id));
      expect(cleared.notes, equals(_base.notes));
    });

    test('clearCustomer: false (default) preserves existing customer', () {
      final copy = _base.copyWith(id: 'bill_copy');

      expect(copy.customerId, equals(_base.customerId));
      expect(copy.customerName, equals(_base.customerName));
    });

    test('clearCustomer: true takes precedence over provided customerId', () {
      // Even if both clearCustomer and a new customerId are passed,
      // clearCustomer wins and nulls both fields.
      final cleared = _base.copyWith(
        clearCustomer: true,
        customerId: 'cust_new',
        customerName: 'Bob',
      );

      expect(cleared.customerId, isNull);
      expect(cleared.customerName, isNull);
    });
  });

  group('Bill.copyWith – clearNotes flag', () {
    test('clearNotes: true nulls notes', () {
      final cleared = _base.copyWith(clearNotes: true);

      expect(cleared.notes, isNull,
          reason: 'notes must be null after clearNotes');
    });

    test('clearNotes: true does not affect customer fields', () {
      final cleared = _base.copyWith(clearNotes: true);

      expect(cleared.customerId, equals(_base.customerId));
      expect(cleared.customerName, equals(_base.customerName));
    });

    test('clearNotes: false (default) preserves existing notes', () {
      final copy = _base.copyWith(id: 'bill_copy2');

      expect(copy.notes, equals(_base.notes));
    });

    test('clearNotes: true takes precedence over provided notes value', () {
      final cleared = _base.copyWith(
        clearNotes: true,
        notes: 'This should be ignored',
      );

      expect(cleared.notes, isNull);
    });
  });
}
