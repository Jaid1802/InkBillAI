import 'package:flutter_test/flutter_test.dart';
import 'package:inkbill_ai/features/billing/domain/entities/bill.dart';
import 'package:inkbill_ai/features/billing/domain/entities/bill_item.dart';
import 'package:inkbill_ai/services/receipt_generator/receipt_generator.dart';

void main() {
  group('ReceiptData', () {
    test('fromBill creates correct data', () {
      final bill = Bill(
        id: 'bill_123',
        items: [BillItem(id: 'i1', name: 'A', quantity: 2, rate: 10, amount: 20)],
        subtotal: 20,
        taxRate: 0.1,
        taxAmount: 2,
        discount: 0,
        total: 22,
        createdAt: DateTime(2026, 7, 17),
        updatedAt: DateTime(2026, 7, 17),
      );
      final data = ReceiptData.fromBill(bill, storeName: 'Test Store');
      expect(data.storeName, 'Test Store');
      expect(data.billNumber, 'bill_123');
      expect(data.items.length, 1);
      expect(data.total, 22);
    });
  });

  group('ReceiptGenerator', () {
    final data = ReceiptData(
      storeName: 'Test Store',
      billNumber: 'B001',
      date: DateTime(2026, 7, 17),
      items: [
        BillItem(id: 'i1', name: 'Item A', quantity: 2, rate: 10, amount: 20),
      ],
      subtotal: 20,
      taxRate: 0.1,
      taxAmount: 2,
      discount: 5,
      total: 17,
      notes: 'Thank you',
    );

    test('generateTextReceipt contains required fields', () {
      final text = ReceiptGenerator.generateTextReceipt(data);
      expect(text, contains('Test Store'));
      expect(text, contains('B001'));
      expect(text, contains('Item A'));
      expect(text, contains('20.00'));
      expect(text, contains('17.00'));
      expect(text, contains('Thank you'));
      expect(text, contains('Discount'));
    });

    test('generateTextReceipt handles empty items', () {
      final empty = ReceiptData(
        storeName: 'Empty',
        billNumber: 'B000',
        date: DateTime.now(),
        items: [],
        subtotal: 0,
        total: 0,
      );
      final text = ReceiptGenerator.generateTextReceipt(empty);
      expect(text, contains('Empty'));
      expect(text, contains('B000'));
    });

    test('generateHtmlReceipt contains required fields', () {
      final html = ReceiptGenerator.generateHtmlReceipt(data);
      expect(html, contains('Test Store'));
      expect(html, contains('B001'));
      expect(html, contains('Item A'));
      expect(html, contains('<div'));
      expect(html, contains('Thank you'));
    });

    test('generateHtmlReceipt handles custom template', () {
      final html = ReceiptGenerator.generateHtmlReceipt(data, template: ReceiptTemplate.modern);
      expect(html, contains('Test Store'));
    });
  });
}
