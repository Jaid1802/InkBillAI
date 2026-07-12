import 'package:equatable/equatable.dart';
import 'bill_item.dart';

enum BillStatus { draft, finalized, paid, cancelled }

class Bill extends Equatable {
  final String id;
  final String? customerId;
  final String? customerName;
  final List<BillItem> items;
  final double subtotal;
  final double taxRate;
  final double taxAmount;
  final double discount;
  final double total;
  final BillStatus status;
  final DateTime createdAt;
  final DateTime updatedAt;
  final String? notes;
  final String? inkPageId;

  const Bill({
    required this.id,
    this.customerId,
    this.customerName,
    this.items = const [],
    this.subtotal = 0.0,
    this.taxRate = 0.0,
    this.taxAmount = 0.0,
    this.discount = 0.0,
    this.total = 0.0,
    this.status = BillStatus.draft,
    required this.createdAt,
    required this.updatedAt,
    this.notes,
    this.inkPageId,
  });

  int get itemCount => items.length;

  Bill copyWith({
    String? id,
    String? customerId,
    String? customerName,
    List<BillItem>? items,
    double? subtotal,
    double? taxRate,
    double? taxAmount,
    double? discount,
    double? total,
    BillStatus? status,
    DateTime? createdAt,
    DateTime? updatedAt,
    String? notes,
    String? inkPageId,
  }) {
    return Bill(
      id: id ?? this.id,
      customerId: customerId ?? this.customerId,
      customerName: customerName ?? this.customerName,
      items: items ?? this.items,
      subtotal: subtotal ?? this.subtotal,
      taxRate: taxRate ?? this.taxRate,
      taxAmount: taxAmount ?? this.taxAmount,
      discount: discount ?? this.discount,
      total: total ?? this.total,
      status: status ?? this.status,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      notes: notes ?? this.notes,
      inkPageId: inkPageId ?? this.inkPageId,
    );
  }

  @override
  List<Object?> get props => [
        id,
        customerId,
        customerName,
        items,
        subtotal,
        taxRate,
        taxAmount,
        discount,
        total,
        status,
        createdAt,
        updatedAt,
        notes,
        inkPageId,
      ];
}
