import 'package:drift/drift.dart';

@DataClassName('InkStrokeData')
class InkStrokes extends Table {
  TextColumn get id => text()();
  TextColumn get pageId => text()();
  IntColumn get color => integer()();
  RealColumn get width => real()();
  TextColumn get pointsJson => text()();
  IntColumn get createdAt => integer()();
  BoolColumn get isErased => boolean().withDefault(const Constant(false))();

  @override
  Set<Column> get primaryKey => {id};
}

@DataClassName('InkPageData')
class InkPages extends Table {
  TextColumn get id => text()();
  TextColumn? get billId => text().nullable()();
  IntColumn get createdAt => integer()();
  IntColumn get updatedAt => integer()();
  TextColumn? get label => text().nullable()();

  @override
  Set<Column> get primaryKey => {id};
}

@DataClassName('InkTimelineEventData')
class InkTimelineEvents extends Table {
  TextColumn get id => text()();
  TextColumn get type => text()();
  TextColumn get strokeId => text()();
  TextColumn get pageId => text()();
  IntColumn get timestampMs => integer()();
  TextColumn? get metadataJson => text().nullable()();

  @override
  Set<Column> get primaryKey => {id};
}
