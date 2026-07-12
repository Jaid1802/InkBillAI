import 'package:drift/drift.dart';

@DataClassName('CustomersData')
class Customers extends Table {
  TextColumn get id => text()();
  TextColumn get name => text()();
  TextColumn? get phone => text().nullable()();
  TextColumn? get email => text().nullable()();
  TextColumn? get address => text().nullable()();
  TextColumn? get gstin => text().nullable()();
  RealColumn get balance => real().withDefault(const Constant(0.0))();
  RealColumn get totalPurchases => real().withDefault(const Constant(0.0))();
  IntColumn get createdAt => integer()();
  IntColumn get updatedAt => integer()();

  @override
  Set<Column> get primaryKey => {id};
}

@DataClassName('ProductsData')
class Products extends Table {
  TextColumn get id => text()();
  TextColumn get name => text()();
  TextColumn? get description => text().nullable()();
  RealColumn get price => real().withDefault(const Constant(0.0))();
  RealColumn? get gstRate => real().nullable()();
  TextColumn? get hsnCode => text().nullable()();
  TextColumn? get unit => text().nullable()();
  IntColumn get stock => integer().withDefault(const Constant(0))();
  TextColumn? get barcode => text().nullable()();
  IntColumn get createdAt => integer()();
  IntColumn get updatedAt => integer()();

  @override
  Set<Column> get primaryKey => {id};
}
