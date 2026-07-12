import 'package:drift/drift.dart';

@DataClassName('BillsData')
class Bills extends Table {
  TextColumn get id => text()();
  TextColumn? get customerId => text().nullable()();
  TextColumn? get customerName => text().nullable()();
  RealColumn get subtotal => real().withDefault(const Constant(0.0))();
  RealColumn get taxRate => real().withDefault(const Constant(0.0))();
  RealColumn get taxAmount => real().withDefault(const Constant(0.0))();
  RealColumn get discount => real().withDefault(const Constant(0.0))();
  RealColumn get total => real().withDefault(const Constant(0.0))();
  TextColumn get status => text().withDefault(const Constant('draft'))();
  IntColumn get createdAt => integer()();
  IntColumn get updatedAt => integer()();
  TextColumn? get notes => text().nullable()();
  TextColumn? get inkPageId => text().nullable()();

  @override
  Set<Column> get primaryKey => {id};
}

@DataClassName('BillItemsData')
class BillItems extends Table {
  TextColumn get id => text()();
  TextColumn get billId => text()();
  TextColumn get name => text()();
  RealColumn get quantity => real().withDefault(const Constant(1.0))();
  RealColumn get rate => real().withDefault(const Constant(0.0))();
  RealColumn get amount => real().withDefault(const Constant(0.0))();
  TextColumn? get unit => text().nullable()();
  RealColumn? get gstRate => real().nullable()();
  TextColumn? get hsnCode => text().nullable()();

  @override
  Set<Column> get primaryKey => {id};
}
