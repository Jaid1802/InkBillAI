import 'package:flutter_test/flutter_test.dart';
import 'package:inkbill_ai/services/bill_engine/bill_engine.dart';

void main() {
  group('BillEngine', () {
    late BillEngine engine;

    setUp(() {
      engine = BillEngine();
    });

    test('starts empty', () {
      expect(engine.value.items, isEmpty);
      expect(engine.value.subtotal, 0.0);
      expect(engine.value.total, 0.0);
    });

    test('addItem creates item and recalculates', () {
      engine.addItem(name: 'Item A', quantity: 2, rate: 10);
      expect(engine.value.items.length, 1);
      expect(engine.value.items[0].name, 'Item A');
      expect(engine.value.items[0].quantity, 2);
      expect(engine.value.items[0].rate, 10);
      expect(engine.value.items[0].amount, 20);
      expect(engine.value.subtotal, 20);
    });

    test('addItem multiple items sums correctly', () {
      engine.addItem(name: 'A', quantity: 2, rate: 10);
      engine.addItem(name: 'B', quantity: 1, rate: 5);
      expect(engine.value.items.length, 2);
      expect(engine.value.subtotal, 25);
      expect(engine.value.total, 25);
    });

    test('updateItem modifies item and recalculates', () {
      engine.addItem(name: 'A', quantity: 1, rate: 10);
      engine.updateItem(0, quantity: 3, rate: 20);
      expect(engine.value.items[0].quantity, 3);
      expect(engine.value.items[0].rate, 20);
      expect(engine.value.items[0].amount, 60);
      expect(engine.value.subtotal, 60);
    });

    test('removeItem removes and updates totals', () {
      engine.addItem(name: 'A', quantity: 2, rate: 10);
      engine.addItem(name: 'B', quantity: 1, rate: 5);
      engine.removeItem(0);
      expect(engine.value.items.length, 1);
      expect(engine.value.items[0].name, 'B');
      expect(engine.value.subtotal, 5);
    });

    test('removeItem out of range does nothing', () {
      engine.addItem(name: 'A', quantity: 1, rate: 10);
      engine.removeItem(5);
      expect(engine.value.items.length, 1);
    });

    test('duplicateItem copies and inserts after', () {
      engine.addItem(name: 'A', quantity: 2, rate: 10);
      engine.duplicateItem(0);
      expect(engine.value.items.length, 2);
      expect(engine.value.items[0].name, 'A');
      expect(engine.value.items[1].name, 'A');
      expect(engine.value.items[0].id, isNot(equals(engine.value.items[1].id)));
      expect(engine.value.subtotal, 40);
    });

    test('setTaxRate calculates tax', () {
      engine.addItem(name: 'A', quantity: 1, rate: 100);
      engine.setTaxRate(0.1);
      expect(engine.value.taxRate, 0.1);
      expect(engine.value.taxAmount, 10);
      expect(engine.value.total, 110);
    });

    test('setDiscount reduces total', () {
      engine.addItem(name: 'A', quantity: 1, rate: 100);
      engine.setDiscount(15);
      expect(engine.value.discount, 15);
      expect(engine.value.total, 85);
    });

    test('setCustomerName works', () {
      engine.setCustomerName('John');
      expect(engine.value.customerName, 'John');
    });

    test('buildBill returns correct Bill', () {
      engine.addItem(name: 'A', quantity: 2, rate: 10);
      engine.setTaxRate(0.1);
      engine.setCustomerName('John');
      final bill = engine.buildBill();
      expect(bill.items.length, 1);
      expect(bill.customerName, 'John');
      expect(bill.subtotal, 20);
      expect(bill.taxRate, 0.1);
      expect(bill.taxAmount, 2);
      expect(bill.total, 22);
      expect(bill.status.name, 'draft');
    });

    test('loadFromItems populates state', () {
      engine.addItem(name: 'A', quantity: 2, rate: 10);
      final saved = engine.value.items;
      engine.reset();
      expect(engine.value.items, isEmpty);
      engine.loadFromItems(saved);
      expect(engine.value.items.length, 1);
      expect(engine.value.subtotal, 20);
    });

    test('reset clears everything', () {
      engine.addItem(name: 'A', quantity: 1, rate: 10);
      engine.setTaxRate(0.1);
      engine.setCustomerName('John');
      engine.reset();
      expect(engine.value.items, isEmpty);
      expect(engine.value.taxRate, 0.0);
      expect(engine.value.customerName, isNull);
      expect(engine.value.subtotal, 0.0);
    });

    test('notifies listeners on changes', () {
      int notifyCount = 0;
      engine.addListener(() => notifyCount++);
      engine.addItem(name: 'A', quantity: 1, rate: 10);
      expect(notifyCount, 1);
      engine.updateItem(0, name: 'B');
      expect(notifyCount, 2);
      engine.removeItem(0);
      expect(notifyCount, 3);
    });
  });
}
