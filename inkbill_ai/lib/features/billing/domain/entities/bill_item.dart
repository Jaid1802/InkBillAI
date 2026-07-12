import 'package:equatable/equatable.dart';

class BillItem extends Equatable {
  final String id;
  final String name;
  final double quantity;
  final double rate;
  final double amount;
  final String? unit;
  final double? gstRate;
  final String? hsnCode;

  const BillItem({
    required this.id,
    required this.name,
    this.quantity = 1.0,
    this.rate = 0.0,
    this.amount = 0.0,
    this.unit,
    this.gstRate,
    this.hsnCode,
  });

  BillItem copyWith({
    String? id,
    String? name,
    double? quantity,
    double? rate,
    double? amount,
    String? unit,
    double? gstRate,
    String? hsnCode,
  }) {
    return BillItem(
      id: id ?? this.id,
      name: name ?? this.name,
      quantity: quantity ?? this.quantity,
      rate: rate ?? this.rate,
      amount: amount ?? this.amount,
      unit: unit ?? this.unit,
      gstRate: gstRate ?? this.gstRate,
      hsnCode: hsnCode ?? this.hsnCode,
    );
  }

  @override
  List<Object?> get props => [id, name, quantity, rate, amount, unit, gstRate, hsnCode];
}
