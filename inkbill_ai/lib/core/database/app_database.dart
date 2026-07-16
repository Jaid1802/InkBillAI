import 'dart:io';
import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:sqlite3/sqlite3.dart';
import 'package:sqlite3_flutter_libs/sqlite3_flutter_libs.dart';
import 'tables/ink_strokes_table.dart';
import 'tables/bills_table.dart';
import 'tables/customers_table.dart';

part 'app_database.g.dart';

@DriftDatabase(
  tables: [
    InkStrokes,
    InkPages,
    InkTimelineEvents,
    Bills,
    BillItems,
    Customers,
    Products,
  ],
)
class AppDatabase extends _$AppDatabase {
  AppDatabase() : super(_openConnection());

  @override
  int get schemaVersion => 1;

  @override
  MigrationStrategy get migration {
    return MigrationStrategy(
      onCreate: (Migrator m) async {
        await m.createAll();
      },
      onUpgrade: (Migrator m, int from, int to) async {},
    );
  }

  Future<void> clearAllData() async {
    await transaction(() async {
      await delete(inkTimelineEvents).go();
      await delete(inkStrokes).go();
      await delete(inkPages).go();
      await delete(billItems).go();
      await delete(bills).go();
      await delete(products).go();
      await delete(customers).go();
    });
  }
}

LazyDatabase _openConnection() {
  return LazyDatabase(() async {
    final dbFolder = await getApplicationDocumentsDirectory();
    final file = File(p.join(dbFolder.path, 'inkbill.db'));

    final cachebase = await getTemporaryDirectory();
    sqlite3.tempDirectory = cachebase.path;

    return NativeDatabase.createInBackground(file);
  });
}
