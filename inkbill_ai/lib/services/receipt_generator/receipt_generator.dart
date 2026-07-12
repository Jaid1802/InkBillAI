import 'dart:typed_data';
import 'package:inkbill_ai/core/constants/app_constants.dart';
import 'package:inkbill_ai/features/billing/domain/entities/bill.dart';
import 'package:inkbill_ai/features/billing/domain/entities/bill_item.dart';

enum ReceiptTemplate { classic, modern, retail, medical, restaurant }

class ReceiptData {
  final String storeName;
  final String? storeAddress;
  final String? storePhone;
  final String? storeGstin;
  final String billNumber;
  final DateTime date;
  final String? customerName;
  final String? customerPhone;
  final String? customerGstin;
  final List<BillItem> items;
  final double subtotal;
  final double taxRate;
  final double taxAmount;
  final double discount;
  final double total;
  final String? notes;
  final String? paymentMethod;

  const ReceiptData({
    required this.storeName,
    this.storeAddress,
    this.storePhone,
    this.storeGstin,
    required this.billNumber,
    required this.date,
    this.customerName,
    this.customerPhone,
    this.customerGstin,
    required this.items,
    required this.subtotal,
    this.taxRate = 0.0,
    this.taxAmount = 0.0,
    this.discount = 0.0,
    required this.total,
    this.notes,
    this.paymentMethod,
  });

  factory ReceiptData.fromBill(Bill bill, {String storeName = 'InkBill AI Store'}) {
    return ReceiptData(
      storeName: storeName,
      billNumber: bill.id,
      date: bill.createdAt,
      customerName: bill.customerName,
      items: bill.items,
      subtotal: bill.subtotal,
      taxRate: bill.taxRate,
      taxAmount: bill.taxAmount,
      discount: bill.discount,
      total: bill.total,
      notes: bill.notes,
    );
  }
}

abstract class ReceiptExporter {
  Future<Uint8List> exportPdf(ReceiptData data, {ReceiptTemplate template = ReceiptTemplate.classic});
  Future<String> exportHtml(ReceiptData data);
  Future<String> exportText(ReceiptData data);
}

class ReceiptGenerator {
  static String generateTextReceipt(ReceiptData data) {
    final buf = StringBuffer();
    final line = '=' * 40;

    buf.writeln(line);
    buf.writeln(_center(data.storeName, 40));
    if (data.storeAddress != null) buf.writeln(_center(data.storeAddress!, 40));
    if (data.storePhone != null) buf.writeln(_center(data.storePhone!, 40));
    if (data.storeGstin != null) buf.writeln(_center('GST: ${data.storeGstin}', 40));
    buf.writeln(line);
    buf.writeln('Bill #: ${data.billNumber}');
    buf.writeln('Date: ${data.date.toIso8601String().substring(0, 10)}');
    if (data.customerName != null) buf.writeln('Customer: ${data.customerName}');
    buf.writeln(line);
    buf.writeln('${'Item'.padRight(16)} ${'Qty'.padLeft(4)} ${'Rate'.padLeft(7)} ${'Amt'.padLeft(7)}');
    buf.writeln('-' * 40);

    for (final item in data.items) {
      final name = item.name.length > 16 ? item.name.substring(0, 15) : item.name;
      buf.writeln(
        '${name.padRight(16)} '
        '${item.quantity.toString().padLeft(4)} '
        '${AppConstants.currencySymbol}${item.rate.toStringAsFixed(2).padLeft(6)} '
        '${AppConstants.currencySymbol}${item.amount.toStringAsFixed(2).padLeft(6)}',
      );
    }

    buf.writeln(line);
    buf.writeln('${'Subtotal:'.padRight(30)} ${AppConstants.currencySymbol}${data.subtotal.toStringAsFixed(2)}');
    if (data.taxAmount > 0) {
      buf.writeln('${'Tax (${(data.taxRate * 100).toStringAsFixed(1)}%):'.padRight(30)} ${AppConstants.currencySymbol}${data.taxAmount.toStringAsFixed(2)}');
    }
    if (data.discount > 0) {
      buf.writeln('${'Discount:'.padRight(30)} -${AppConstants.currencySymbol}${data.discount.toStringAsFixed(2)}');
    }
    buf.writeln('${'TOTAL:'.padRight(30)} ${AppConstants.currencySymbol}${data.total.toStringAsFixed(2)}');
    buf.writeln(line);

    if (data.notes != null) {
      buf.writeln('\n${data.notes}');
    }
    buf.writeln('\nThank you for your business!');
    buf.writeln(line);

    return buf.toString();
  }

  static String generateHtmlReceipt(ReceiptData data, {ReceiptTemplate template = ReceiptTemplate.classic}) {
    return '''<!DOCTYPE html>
<html>
<head><meta charset="UTF-8"><title>Receipt</title>
<style>
  body { font-family: 'Courier New', monospace; max-width: 320px; margin: auto; padding: 16px; }
  .header { text-align: center; margin-bottom: 16px; }
  .header h1 { margin: 0; font-size: 18px; }
  .line { border-top: 1px dashed #000; margin: 8px 0; }
  .item { display: flex; justify-content: space-between; font-size: 14px; }
  .totals { margin-top: 8px; }
  .total-row { display: flex; justify-content: space-between; }
  .grand-total { font-weight: bold; font-size: 16px; }
  .footer { text-align: center; margin-top: 16px; font-size: 12px; }
</style></head>
<body>
  <div class="header">
    <h1>${_escapeHtml(data.storeName)}</h1>
    ${data.storeAddress != null ? '<p>${_escapeHtml(data.storeAddress!)}</p>' : ''}
    ${data.storePhone != null ? '<p>${_escapeHtml(data.storePhone!)}</p>' : ''}
  </div>
  <div>Bill #: ${_escapeHtml(data.billNumber)}</div>
  <div>Date: ${data.date.toIso8601String().substring(0, 10)}</div>
  ${data.customerName != null ? '<div>Customer: ${_escapeHtml(data.customerName!)}</div>' : ''}
  <div class="line"></div>
  ${data.items.map((item) => '''
    <div class="item">
      <span>${_escapeHtml(item.name)}</span>
      <span>${item.quantity} x ${AppConstants.currencySymbol}${item.rate.toStringAsFixed(2)}</span>
      <span>${AppConstants.currencySymbol}${item.amount.toStringAsFixed(2)}</span>
    </div>''').join()}
  <div class="line"></div>
  <div class="totals">
    <div class="total-row"><span>Subtotal</span><span>${AppConstants.currencySymbol}${data.subtotal.toStringAsFixed(2)}</span></div>
    ${data.taxAmount > 0 ? '<div class="total-row"><span>Tax</span><span>${AppConstants.currencySymbol}${data.taxAmount.toStringAsFixed(2)}</span></div>' : ''}
    ${data.discount > 0 ? '<div class="total-row"><span>Discount</span><span>-${AppConstants.currencySymbol}${data.discount.toStringAsFixed(2)}</span></div>' : ''}
    <div class="total-row grand-total"><span>TOTAL</span><span>${AppConstants.currencySymbol}${data.total.toStringAsFixed(2)}</span></div>
  </div>
  ${data.notes != null ? '<div style="margin-top: 8px;">${_escapeHtml(data.notes!)}</div>' : ''}
  <div class="footer">Thank you for your business!</div>
</body></html>''';
  }

  static String _center(String text, int width) {
    if (text.length >= width) return text;
    final totalPad = width - text.length;
    final leftPad = totalPad ~/ 2;
    return text.padLeft(text.length + leftPad).padRight(width);
  }

  static String _escapeHtml(String text) {
    return text
        .replaceAll('&', '&amp;')
        .replaceAll('<', '&lt;')
        .replaceAll('>', '&gt;')
        .replaceAll('"', '&quot;');
  }
}
