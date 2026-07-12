import 'package:flutter_test/flutter_test.dart';
import 'package:inkbill_ai/features/billing/domain/entities/bill.dart';
import 'package:inkbill_ai/features/billing/domain/entities/bill_item.dart';
import 'package:inkbill_ai/services/receipt_generator/receipt_generator.dart';

void main() {
  group('ReceiptGenerator', () {
    test('generateTextReceipt generates receipt with items', () {
      final data = ReceiptData(
        storeName: 'Test Store',
        billNumber: 'BILL-001',
        date: DateTime(2024, 1, 15),
        items: [
          const BillItem(id: '1', name: 'Tea', quantity: 2, rate: 10, amount: 20),
          const BillItem(id: '2', name: 'Coffee', quantity: 1, rate: 15, amount: 15),
        ],
        subtotal: 35,
        total: 35,
      );

      final receipt = ReceiptGenerator.generateTextReceipt(data);
      expect(receipt, contains('Test Store'));
      expect(receipt, contains('BILL-001'));
      expect(receipt, contains('Tea'));
      expect(receipt, contains('Coffee'));
      expect(receipt, contains('35'));
      expect(receipt, contains('Thank you'));
    });

    test('generateTextReceipt includes tax when provided', () {
      final data = ReceiptData(
        storeName: 'Store',
        billNumber: 'B2',
        date: DateTime.now(),
        items: [
          const BillItem(id: '1', name: 'Item', quantity: 1, rate: 100, amount: 100),
        ],
        subtotal: 100,
        taxRate: 0.18,
        taxAmount: 18,
        total: 118,
      );

      final receipt = ReceiptGenerator.generateTextReceipt(data);
      expect(receipt, contains('18'));
      expect(receipt, contains('Tax'));
    });

    test('generateTextReceipt includes discount when provided', () {
      final data = ReceiptData(
        storeName: 'Store',
        billNumber: 'B3',
        date: DateTime.now(),
        items: [
          const BillItem(id: '1', name: 'Item', quantity: 1, rate: 100, amount: 100),
        ],
        subtotal: 100,
        discount: 10,
        total: 90,
      );

      final receipt = ReceiptGenerator.generateTextReceipt(data);
      expect(receipt, contains('Discount'));
      expect(receipt, contains('90'));
    });

    test('generateHtmlReceipt generates valid HTML', () {
      final data = ReceiptData(
        storeName: 'Test Store',
        billNumber: 'B001',
        date: DateTime.now(),
        items: [
          const BillItem(id: '1', name: 'Item', quantity: 1, rate: 50, amount: 50),
        ],
        subtotal: 50,
        total: 50,
      );

      final html = ReceiptGenerator.generateHtmlReceipt(data);
      expect(html, contains('<!DOCTYPE html>'));
      expect(html, contains('<h1>Test Store</h1>'));
      expect(html, contains('B001'));
      expect(html, contains('50'));
    });

    test('ReceiptData fromBill works correctly', () {
      final bill = Bill(
        id: 'bill_001',
        customerName: 'John',
        items: const [BillItem(id: 'i1', name: 'Item', quantity: 2, rate: 25, amount: 50)],
        subtotal: 50,
        taxRate: 0.18,
        taxAmount: 9,
        discount: 5,
        total: 54,
        notes: 'Thank you',
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      final data = ReceiptData.fromBill(bill);
      expect(data.billNumber, 'bill_001');
      expect(data.customerName, 'John');
      expect(data.subtotal, 50);
      expect(data.total, 54);
      expect(data.notes, 'Thank you');
    });
  });
}
