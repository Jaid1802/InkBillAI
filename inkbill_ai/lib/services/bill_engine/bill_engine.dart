import 'package:flutter/foundation.dart';
import 'package:inkbill_ai/features/billing/domain/entities/bill.dart';
import 'package:inkbill_ai/features/billing/domain/entities/bill_item.dart';

class BillEngineState {
  final List<BillItem> items;
  final double taxRate;
  final double discount;
  final String? customerName;
  final String? notes;

  const BillEngineState({
    this.items = const [],
    this.taxRate = 0.0,
    this.discount = 0.0,
    this.customerName,
    this.notes,
  });

  double get subtotal => items.fold(0.0, (sum, item) => sum + item.amount);
  double get taxAmount => subtotal * taxRate;
  double get total => subtotal + taxAmount - discount;

  BillEngineState copyWith({
    List<BillItem>? items,
    double? taxRate,
    double? discount,
    String? customerName,
    String? notes,
    bool clearCustomerName = false,
    bool clearNotes = false,
  }) {
    return BillEngineState(
      items: items ?? this.items,
      taxRate: taxRate ?? this.taxRate,
      discount: discount ?? this.discount,
      customerName: clearCustomerName ? null : (customerName ?? this.customerName),
      notes: clearNotes ? null : (notes ?? this.notes),
    );
  }
}

class BillEngine extends ValueNotifier<BillEngineState> {
  final String? sourcePageId;

  BillEngine({this.sourcePageId}) : super(const BillEngineState());

  int _idCounter = 0;
  String _nextId() => 'bi_${DateTime.now().microsecondsSinceEpoch}_${_idCounter++}';

  void addItem({String name = '', double quantity = 1, double rate = 0}) {
    final item = BillItem(
      id: _nextId(),
      name: name,
      quantity: quantity,
      rate: rate,
      amount: quantity * rate,
    );
    value = value.copyWith(items: [...value.items, item]);
  }

  void updateItem(int index, {String? name, double? quantity, double? rate}) {
    if (index < 0 || index >= value.items.length) return;
    final old = value.items[index];
    final newName = name ?? old.name;
    final newQty = quantity ?? old.quantity;
    final newRate = rate ?? old.rate;
    final newItem = old.copyWith(
      name: newName,
      quantity: newQty,
      rate: newRate,
      amount: newQty * newRate,
    );
    final updated = List<BillItem>.from(value.items);
    updated[index] = newItem;
    value = value.copyWith(items: updated);
  }

  void removeItem(int index) {
    if (index < 0 || index >= value.items.length) return;
    final updated = List<BillItem>.from(value.items);
    updated.removeAt(index);
    value = value.copyWith(items: updated);
  }

  void duplicateItem(int index) {
    if (index < 0 || index >= value.items.length) return;
    final original = value.items[index];
    final dup = original.copyWith(id: _nextId());
    final updated = List<BillItem>.from(value.items);
    updated.insert(index + 1, dup);
    value = value.copyWith(items: updated);
  }

  void setTaxRate(double rate) => value = value.copyWith(taxRate: rate);
  void setDiscount(double discount) => value = value.copyWith(discount: discount);
  void setCustomerName(String? name) => value = value.copyWith(customerName: name);
  void setNotes(String? notes) => value = value.copyWith(notes: notes);

  Bill buildBill() {
    return Bill(
      id: 'bill_${DateTime.now().microsecondsSinceEpoch}',
      customerName: value.customerName,
      items: value.items,
      subtotal: value.subtotal,
      taxRate: value.taxRate,
      taxAmount: value.taxAmount,
      discount: value.discount,
      total: value.total,
      status: BillStatus.draft,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
      notes: value.notes,
      inkPageId: sourcePageId,
    );
  }

  void loadFromBill(Bill bill) {
    value = BillEngineState(
      items: bill.items,
      taxRate: bill.taxRate,
      discount: bill.discount,
      customerName: bill.customerName,
      notes: bill.notes,
    );
  }

  void loadFromItems(List<BillItem> items) {
    value = BillEngineState(items: items);
  }

  void reset() {
    value = const BillEngineState();
  }
}
