import 'package:flutter_test/flutter_test.dart';
import 'package:inkbill_ai/features/billing/domain/entities/bill.dart';
import 'package:inkbill_ai/features/billing/domain/entities/bill_item.dart';
import 'package:inkbill_ai/services/billing_engine/billing_calculator.dart';

void main() {
  group('BillingCalculator', () {
    test('calculates item amount from quantity and rate', () {
      final item = BillItem(
        id: 'item_1',
        name: 'Test Item',
        quantity: 2,
        rate: 100,
      );
      final calculated = BillingCalculator.calculateItem(item);
      expect(calculated.amount, 200.0);
    });

    test('calculates subtotal, tax, and total', () {
      final bill = Bill(
        id: 'bill_1',
        items: [
          BillItem(id: 'item_1', name: 'Item 1', quantity: 2, rate: 100),
          BillItem(id: 'item_2', name: 'Item 2', quantity: 3, rate: 50),
        ],
        taxRate: 0.18,
        discount: 20,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      final calculated = BillingCalculator.calculate(bill);

      expect(calculated.subtotal, 350.0);
      expect(calculated.taxAmount, 63.0);
      expect(calculated.discount, 20.0);
      expect(calculated.total, 393.0);
    });

    test('adds an item to the bill', () {
      final bill = Bill(
        id: 'bill_1',
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      final newItem = BillItem(
        id: 'item_1',
        name: 'New Item',
        quantity: 1,
        rate: 50,
      );

      final updated = BillingCalculator.addItem(bill, newItem);
      expect(updated.items.length, 1);
      expect(updated.items.first.name, 'New Item');
      expect(updated.subtotal, 50.0);
    });

    test('removes an item from the bill', () {
      final bill = Bill(
        id: 'bill_1',
        items: [
          BillItem(id: 'item_1', name: 'Item 1', quantity: 1, rate: 100),
          BillItem(id: 'item_2', name: 'Item 2', quantity: 1, rate: 50),
        ],
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      final updated = BillingCalculator.removeItem(bill, 'item_1');
      expect(updated.items.length, 1);
      expect(updated.items.first.id, 'item_2');
      expect(updated.subtotal, 50.0);
    });

    test('applies tax rate correctly', () {
      final bill = Bill(
        id: 'bill_1',
        items: [
          BillItem(id: 'item_1', name: 'Item', quantity: 1, rate: 1000),
        ],
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      final withTax = BillingCalculator.applyTaxRate(bill, 0.12);
      expect(withTax.taxRate, 0.12);
      expect(withTax.taxAmount, 120.0);
      expect(withTax.total, 1120.0);
    });

    test('applies discount correctly', () {
      final bill = Bill(
        id: 'bill_1',
        items: [
          BillItem(id: 'item_1', name: 'Item', quantity: 1, rate: 1000),
        ],
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      final withDiscount = BillingCalculator.applyDiscount(bill, 50);
      expect(withDiscount.discount, 50.0);
      expect(withDiscount.total, 950.0);
    });

    test('updates an existing item', () {
      final bill = Bill(
        id: 'bill_1',
        items: [
          BillItem(id: 'item_1', name: 'Item 1', quantity: 1, rate: 100),
        ],
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      final updated = BillingCalculator.updateItem(
        bill,
        BillItem(id: 'item_1', name: 'Updated Item', quantity: 3, rate: 50),
      );

      expect(updated.items.length, 1);
      expect(updated.items.first.name, 'Updated Item');
      expect(updated.items.first.amount, 150.0);
      expect(updated.subtotal, 150.0);
    });
  });
}
