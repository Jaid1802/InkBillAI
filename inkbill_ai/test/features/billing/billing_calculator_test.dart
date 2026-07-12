import 'package:flutter_test/flutter_test.dart';
import 'package:inkbill_ai/features/billing/domain/entities/bill.dart';
import 'package:inkbill_ai/features/billing/domain/entities/bill_item.dart';
import 'package:inkbill_ai/services/billing_engine/billing_calculator.dart';

void main() {
  group('BillingCalculator', () {
    test('calculates empty bill correctly', () {
      final bill = Bill(
        id: 'test1',
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );
      final result = BillingCalculator.calculate(bill);
      expect(result.subtotal, 0.0);
      expect(result.taxAmount, 0.0);
      expect(result.total, 0.0);
    });

    test('calculates single item correctly', () {
      final bill = Bill(
        id: 'test2',
        items: const [
          BillItem(
            id: 'item1',
            name: 'Tea',
            quantity: 2,
            rate: 10,
          ),
        ],
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );
      final result = BillingCalculator.calculate(bill);
      expect(result.items.first.amount, 20.0);
      expect(result.subtotal, 20.0);
      expect(result.total, 20.0);
    });

    test('calculates tax correctly', () {
      final bill = Bill(
        id: 'test3',
        items: const [
          BillItem(id: 'item1', name: 'Item', quantity: 1, rate: 100),
        ],
        taxRate: 0.18,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );
      final result = BillingCalculator.calculate(bill);
      expect(result.subtotal, 100.0);
      expect(result.taxAmount, 18.0);
      expect(result.total, 118.0);
    });

    test('calculates discount correctly', () {
      final bill = Bill(
        id: 'test4',
        items: const [
          BillItem(id: 'item1', name: 'Item', quantity: 1, rate: 100),
        ],
        discount: 10,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );
      final result = BillingCalculator.calculate(bill);
      expect(result.total, 90.0);
    });

    test('addItem adds and recalculates', () {
      final bill = Bill(
        id: 'test5',
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );
      const item = BillItem(
        id: 'item1', name: 'Coffee', quantity: 3, rate: 15);
      final result = BillingCalculator.addItem(bill, item);
      expect(result.itemCount, 1);
      expect(result.items.first.amount, 45.0);
      expect(result.subtotal, 45.0);
    });

    test('removeItem removes and recalculates', () {
      final bill = Bill(
        id: 'test6',
        items: const [
          BillItem(id: 'a', name: 'A', quantity: 1, rate: 10),
          BillItem(id: 'b', name: 'B', quantity: 2, rate: 20),
        ],
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );
      final result = BillingCalculator.removeItem(bill, 'a');
      expect(result.itemCount, 1);
      expect(result.subtotal, 40.0);
    });

    test('applies GST breakdown correctly', () {
      final items = [
        const BillItem(id: 'a', name: 'A', quantity: 1, rate: 100, gstRate: 18),
      ];
      final breakdown = BillingCalculator.calculateGstBreakdown(items, 100);
      expect(breakdown['cgst'], 9.0);
      expect(breakdown['sgst'], 9.0);
      expect(breakdown['total_gst'], 18.0);
    });
  });
}
