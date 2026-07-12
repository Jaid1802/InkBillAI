import 'package:inkbill_ai/core/utils/math_utils.dart';
import 'package:inkbill_ai/features/billing/domain/entities/bill.dart';
import 'package:inkbill_ai/features/billing/domain/entities/bill_item.dart';

class BillingCalculator {
  static Bill calculate(Bill bill) {
    var subtotal = 0.0;
    final updatedItems = <BillItem>[];

    for (final item in bill.items) {
      final amount = MathUtils.roundTo(item.quantity * item.rate, 2);
      updatedItems.add(item.copyWith(amount: amount));
      subtotal += amount;
    }

    subtotal = MathUtils.roundTo(subtotal, 2);
    final taxAmount = MathUtils.roundTo(subtotal * bill.taxRate, 2);
    final total = MathUtils.roundTo(subtotal + taxAmount - bill.discount, 2);

    return bill.copyWith(
      items: updatedItems,
      subtotal: subtotal,
      taxAmount: taxAmount,
      total: total,
    );
  }

  static BillItem calculateItem(BillItem item) {
    final amount = MathUtils.roundTo(item.quantity * item.rate, 2);
    return item.copyWith(amount: amount);
  }

  static Bill addItem(Bill bill, BillItem item) {
    final calculated = calculateItem(item);
    return calculate(bill.copyWith(items: [...bill.items, calculated]));
  }

  static Bill removeItem(Bill bill, String itemId) {
    return calculate(
      bill.copyWith(items: bill.items.where((i) => i.id != itemId).toList()),
    );
  }

  static Bill updateItem(Bill bill, BillItem updatedItem) {
    final calculated = calculateItem(updatedItem);
    return calculate(
      bill.copyWith(
        items: bill.items.map((i) => i.id == updatedItem.id ? calculated : i).toList(),
      ),
    );
  }

  static Bill applyTaxRate(Bill bill, double taxRate) {
    return calculate(bill.copyWith(taxRate: taxRate));
  }

  static Bill applyDiscount(Bill bill, double discount) {
    return calculate(bill.copyWith(discount: discount));
  }

  static double calculateSubtotal(List<BillItem> items) {
    var total = 0.0;
    for (final item in items) {
      total += item.quantity * item.rate;
    }
    return MathUtils.roundTo(total, 2);
  }

  static double calculateTax(double subtotal, double taxRate) {
    return MathUtils.roundTo(subtotal * taxRate, 2);
  }

  static double calculateTotal(double subtotal, double taxAmount, double discount) {
    return MathUtils.roundTo(subtotal + taxAmount - discount, 2);
  }

  static Map<String, double> calculateGstBreakdown(
      List<BillItem> items, double subtotal) {
    var cgst = 0.0;
    var sgst = 0.0;
    var igst = 0.0;

    for (final item in items) {
      if (item.gstRate != null && item.gstRate! > 0) {
        final halfGst = item.gstRate! / 2;
        final itemAmount = item.quantity * item.rate;
        cgst += itemAmount * halfGst / 100;
        sgst += itemAmount * halfGst / 100;
      }
    }

    return {
      'cgst': MathUtils.roundTo(cgst, 2),
      'sgst': MathUtils.roundTo(sgst, 2),
      'igst': MathUtils.roundTo(igst, 2),
      'total_gst': MathUtils.roundTo(cgst + sgst + igst, 2),
    };
  }
}
