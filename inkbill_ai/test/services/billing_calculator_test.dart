import 'package:flutter_test/flutter_test.dart';
import 'package:inkbill_ai/features/billing/domain/entities/bill.dart';
import 'package:inkbill_ai/features/billing/domain/entities/bill_item.dart';
import 'package:inkbill_ai/services/billing_engine/billing_calculator.dart';

void main() {
  group('BillingCalculator', () {
    test('calculates empty bill correctly', () {
      final bill = Bill(
        id: 'test_empty',
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );
      final result = BillingCalculator.calculate(bill);
      expect(result.subtotal, 0.0);
      expect(result.taxAmount, 0.0);
      expect(result.discount, 0.0);
      expect(result.total, 0.0);
    });

    test('calculates item amount from quantity and rate', () {
      const item = BillItem(
        id: 'item_1',
        name: 'Test Item',
        quantity: 2,
        rate: 100,
      );
      final calculated = BillingCalculator.calculateItem(item);
      expect(calculated.amount, 200.0);
    });

    test('calculates single item correctly', () {
      final bill = Bill(
        id: 'test_single',
        items: const [
          BillItem(id: 'item1', name: 'Tea', quantity: 2, rate: 10),
        ],
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );
      final result = BillingCalculator.calculate(bill);
      expect(result.items.first.amount, 20.0);
      expect(result.subtotal, 20.0);
      expect(result.total, 20.0);
    });

    test('calculates subtotal, tax, and total', () {
      final bill = Bill(
        id: 'bill_1',
        items: const [
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

      const newItem = BillItem(
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
        items: const [
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
        items: const [
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

    test('clamps tax rate between 0.0 and 1.0', () {
      final bill = Bill(
        id: 'bill_tax_clamp',
        items: const [
          BillItem(id: 'item_1', name: 'Item', quantity: 1, rate: 100),
        ],
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      // Negative tax rate clamped to 0.0
      final negativeTax = BillingCalculator.applyTaxRate(bill, -0.05);
      expect(negativeTax.taxRate, 0.0);
      expect(negativeTax.taxAmount, 0.0);
      expect(negativeTax.total, 100.0);

      // Excessive tax rate clamped to 1.0 (100%)
      final excessiveTax = BillingCalculator.applyTaxRate(bill, 1.5);
      expect(excessiveTax.taxRate, 1.0);
      expect(excessiveTax.taxAmount, 100.0);
      expect(excessiveTax.total, 200.0);

      // Clamping within calculate() directly
      final billWithBadTax = bill.copyWith(taxRate: -0.2);
      final calcNegative = BillingCalculator.calculate(billWithBadTax);
      expect(calcNegative.taxRate, 0.0);
      expect(calcNegative.taxAmount, 0.0);

      final billWithHighTax = bill.copyWith(taxRate: 2.0);
      final calcHigh = BillingCalculator.calculate(billWithHighTax);
      expect(calcHigh.taxRate, 1.0);
      expect(calcHigh.taxAmount, 100.0);
    });

    test('applies discount correctly', () {
      final bill = Bill(
        id: 'bill_1',
        items: const [
          BillItem(id: 'item_1', name: 'Item', quantity: 1, rate: 1000),
        ],
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      final withDiscount = BillingCalculator.applyDiscount(bill, 50);
      expect(withDiscount.discount, 50.0);
      expect(withDiscount.total, 950.0);
    });

    test('clamps discount between 0.0 and subtotal', () {
      final bill = Bill(
        id: 'bill_discount_clamp',
        items: const [
          BillItem(id: 'item_1', name: 'Item', quantity: 1, rate: 100),
        ],
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      // Negative discount clamped to 0.0
      final negativeDiscount = BillingCalculator.applyDiscount(bill, -25.0);
      expect(negativeDiscount.discount, 0.0);
      expect(negativeDiscount.total, 100.0);

      // Discount exceeding subtotal clamped to subtotal (100.0)
      final excessiveDiscount = BillingCalculator.applyDiscount(bill, 250.0);
      expect(excessiveDiscount.discount, 100.0);
      expect(excessiveDiscount.total, 0.0);
    });

    test('re-clamps discount when an item is removed and prevents negative total', () {
      // Subtotal = 150 (item_1 = 100, item_2 = 50), discount = 120
      var bill = Bill(
        id: 'bill_remove_clamp',
        items: const [
          BillItem(id: 'item_1', name: 'Item 1', quantity: 1, rate: 100),
          BillItem(id: 'item_2', name: 'Item 2', quantity: 1, rate: 50),
        ],
        discount: 120.0,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );
      bill = BillingCalculator.calculate(bill);
      expect(bill.subtotal, 150.0);
      expect(bill.discount, 120.0);
      expect(bill.total, 30.0);

      // Removing item_1 (100) drops subtotal to 50.
      // Discount (120) must now be clamped to subtotal (50), and total must be 0 (never negative).
      final afterRemoval = BillingCalculator.removeItem(bill, 'item_1');
      expect(afterRemoval.subtotal, 50.0);
      expect(afterRemoval.discount, 50.0);
      expect(afterRemoval.total, 0.0);

      // Removing the second item drops subtotal to 0. Discount clamped to 0, total 0.
      final afterRemoveAll = BillingCalculator.removeItem(afterRemoval, 'item_2');
      expect(afterRemoveAll.subtotal, 0.0);
      expect(afterRemoveAll.discount, 0.0);
      expect(afterRemoveAll.total, 0.0);
    });

    test('updates an existing item', () {
      final bill = Bill(
        id: 'bill_1',
        items: const [
          BillItem(id: 'item_1', name: 'Item 1', quantity: 1, rate: 100),
        ],
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      final updated = BillingCalculator.updateItem(
        bill,
        const BillItem(id: 'item_1', name: 'Updated Item', quantity: 3, rate: 50),
      );

      expect(updated.items.length, 1);
      expect(updated.items.first.name, 'Updated Item');
      expect(updated.items.first.amount, 150.0);
      expect(updated.subtotal, 150.0);
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
