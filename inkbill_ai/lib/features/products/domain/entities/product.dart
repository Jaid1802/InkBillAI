import 'package:equatable/equatable.dart';

class Product extends Equatable {
  final String id;
  final String name;
  final String? description;
  final double price;
  final double? gstRate;
  final String? hsnCode;
  final String? unit;
  final int stock;
  final String? barcode;
  final DateTime createdAt;
  final DateTime updatedAt;

  const Product({
    required this.id,
    required this.name,
    this.description,
    this.price = 0.0,
    this.gstRate,
    this.hsnCode,
    this.unit,
    this.stock = 0,
    this.barcode,
    required this.createdAt,
    required this.updatedAt,
  });

  Product copyWith({
    String? id,
    String? name,
    String? description,
    double? price,
    double? gstRate,
    String? hsnCode,
    String? unit,
    int? stock,
    String? barcode,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Product(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      price: price ?? this.price,
      gstRate: gstRate ?? this.gstRate,
      hsnCode: hsnCode ?? this.hsnCode,
      unit: unit ?? this.unit,
      stock: stock ?? this.stock,
      barcode: barcode ?? this.barcode,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  List<Object?> get props => [
        id, name, description, price, gstRate,
        hsnCode, unit, stock, barcode, createdAt, updatedAt,
      ];
}
