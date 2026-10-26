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
    final clampedTaxRate = bill.taxRate.clamp(0.0, 1.0);
    final taxAmount = MathUtils.roundTo(subtotal * clampedTaxRate, 2);
    final clampedDiscount = bill.discount.clamp(0.0, subtotal);
    final rawTotal = MathUtils.roundTo(subtotal + taxAmount - clampedDiscount, 2);
    final total = rawTotal < 0.0 ? 0.0 : rawTotal;

    return bill.copyWith(
      items: updatedItems,
      subtotal: subtotal,
      taxRate: clampedTaxRate,
      taxAmount: taxAmount,
      discount: clampedDiscount,
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
    final clamped = taxRate.clamp(0.0, 1.0);
    return calculate(bill.copyWith(taxRate: clamped));
  }

  static Bill applyDiscount(Bill bill, double discount) {
    final effectiveSubtotal = bill.subtotal > 0 ? bill.subtotal : calculateSubtotal(bill.items);
    final clamped = discount.clamp(0.0, effectiveSubtotal);
    return calculate(bill.copyWith(discount: clamped));
  }

  static double calculateSubtotal(List<BillItem> items) {
    var total = 0.0;
    for (final item in items) {
      total += item.quantity * item.rate;
    }
    return MathUtils.roundTo(total, 2);
  }

  static double calculateTax(double subtotal, double taxRate) {
    return MathUtils.roundTo(subtotal * taxRate.clamp(0.0, 1.0), 2);
  }

  static double calculateTotal(double subtotal, double taxAmount, double discount) {
    final clampedDiscount = discount.clamp(0.0, subtotal);
    final total = MathUtils.roundTo(subtotal + taxAmount - clampedDiscount, 2);
    return total < 0.0 ? 0.0 : total;
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
