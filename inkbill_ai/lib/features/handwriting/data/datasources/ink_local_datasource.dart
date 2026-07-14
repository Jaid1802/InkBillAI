import 'dart:convert';
import 'package:drift/drift.dart';
import 'package:inkbill_ai/core/database/app_database.dart';
import 'package:inkbill_ai/core/utils/result.dart';
import 'package:inkbill_ai/core/errors/failures.dart';
import 'package:inkbill_ai/features/handwriting/domain/entities/ink_page.dart';
import 'package:inkbill_ai/features/handwriting/domain/entities/ink_stroke.dart';
import 'package:inkbill_ai/features/handwriting/data/models/ink_stroke_model.dart';

class InkLocalDataSource {
  final AppDatabase _db;

  InkLocalDataSource(this._db);

  Future<Result<List<InkPage>>> getAllPages() async {
    try {
      final pageRows = await _db.select(_db.inkPages).get();
      final pages = <InkPage>[];
      for (final row in pageRows) {
        final strokes = await _getStrokesForPage(row.id);
        pages.add(InkPage(
          id: row.id,
          billId: row.billId,
          strokes: strokes,
          createdAt: DateTime.fromMillisecondsSinceEpoch(row.createdAt),
          updatedAt: DateTime.fromMillisecondsSinceEpoch(row.updatedAt),
          label: row.label,
        ));
      }
      return Result.success(pages);
    } catch (e) {
      return Result.error(DatabaseFailure(message: 'Failed to get pages'));
    }
  }

  Future<Result<InkPage?>> getPageById(String id) async {
    try {
      final row = await (_db.select(_db.inkPages)..where((p) => p.id.equals(id))).getSingleOrNull();
      if (row == null) return Result.success(null);
      final strokes = await _getStrokesForPage(id);
      return Result.success(InkPage(
        id: row.id,
        billId: row.billId,
        strokes: strokes,
        createdAt: DateTime.fromMillisecondsSinceEpoch(row.createdAt),
        updatedAt: DateTime.fromMillisecondsSinceEpoch(row.updatedAt),
        label: row.label,
      ));
    } catch (e) {
      return Result.error(DatabaseFailure(message: 'Failed to get page'));
    }
  }

  Future<Result<InkPage>> createPage({String? billId, String? label}) async {
    try {
      final id = 'page_${DateTime.now().microsecondsSinceEpoch}';
      final now = DateTime.now().millisecondsSinceEpoch;
      await _db.into(_db.inkPages).insert(InkPagesCompanion(
        id: Value(id),
        billId: Value(billId),
        createdAt: Value(now),
        updatedAt: Value(now),
        label: Value(label),
      ));
      return Result.success(InkPage(
        id: id,
        billId: billId,
        createdAt: DateTime.fromMillisecondsSinceEpoch(now),
        updatedAt: DateTime.fromMillisecondsSinceEpoch(now),
        label: label,
      ));
    } catch (e) {
      return Result.error(DatabaseFailure(message: 'Failed to create page'));
    }
  }

  Future<Result<void>> saveStroke(InkStroke stroke) async {
    try {
      await _db.into(_db.inkStrokes).insertOnConflictUpdate(InkStrokesCompanion(
        id: Value(stroke.id),
        pageId: Value(stroke.pageId),
        color: Value(stroke.color),
        width: Value(stroke.width),
        pointsJson: Value(InkStrokeModel.pointsToJson(stroke.points)),
        createdAt: Value(stroke.createdAt.millisecondsSinceEpoch),
        isErased: Value(stroke.isErased),
      ));
      await _updatePageTimestamp(stroke.pageId);
      return Result.success(null);
    } catch (e) {
      return Result.error(DatabaseFailure(message: 'Failed to save stroke'));
    }
  }

  Future<Result<void>> saveStrokes(List<InkStroke> strokes) async {
    try {
      await _db.batch((batch) {
        for (final stroke in strokes) {
          batch.insert(_db.inkStrokes, InkStrokesCompanion(
            id: Value(stroke.id),
            pageId: Value(stroke.pageId),
            color: Value(stroke.color),
            width: Value(stroke.width),
            pointsJson: Value(InkStrokeModel.pointsToJson(stroke.points)),
            createdAt: Value(stroke.createdAt.millisecondsSinceEpoch),
            isErased: Value(stroke.isErased),
          ), mode: InsertMode.insertOrReplace);
        }
      });
      if (strokes.isNotEmpty) {
        await _updatePageTimestamp(strokes.first.pageId);
      }
      return Result.success(null);
    } catch (e) {
      return Result.error(DatabaseFailure(message: 'Failed to save strokes'));
    }
  }

  Future<Result<void>> deleteStroke(String strokeId) async {
    try {
      await (_db.delete(_db.inkStrokes)..where((s) => s.id.equals(strokeId))).go();
      return Result.success(null);
    } catch (e) {
      return Result.error(DatabaseFailure(message: 'Failed to delete stroke'));
    }
  }

  Future<Result<void>> eraseStroke(String strokeId) async {
    try {
      await (_db.update(_db.inkStrokes)..where((s) => s.id.equals(strokeId)))
          .write(InkStrokesCompanion(isErased: Value(true)));
      return Result.success(null);
    } catch (e) {
      return Result.error(DatabaseFailure(message: 'Failed to erase stroke'));
    }
  }

  Future<Result<void>> clearPage(String pageId) async {
    try {
      await (_db.delete(_db.inkStrokes)..where((s) => s.pageId.equals(pageId))).go();
      return Result.success(null);
    } catch (e) {
      return Result.error(DatabaseFailure(message: 'Failed to clear page'));
    }
  }

  Future<Result<void>> deletePage(String pageId) async {
    try {
      await (_db.delete(_db.inkStrokes)..where((s) => s.pageId.equals(pageId))).go();
      await (_db.delete(_db.inkPages)..where((p) => p.id.equals(pageId))).go();
      return Result.success(null);
    } catch (e) {
      return Result.error(DatabaseFailure(message: 'Failed to delete page'));
    }
  }

  Future<Result<List<InkStroke>>> getStrokesForPage(String pageId) async {
    try {
      return Result.success(await _getStrokesForPage(pageId));
    } catch (e) {
      return Result.error(DatabaseFailure(message: 'Failed to get strokes'));
    }
  }

  Future<List<InkStroke>> _getStrokesForPage(String pageId) async {
    final rows = await (_db.select(_db.inkStrokes)
      ..where((s) => s.pageId.equals(pageId))
      ..orderBy([(s) => OrderingTerm(expression: s.createdAt)]))
        .get();
    return rows.map((row) {
      final points = InkStrokeModel.pointsFromJson(row.pointsJson);
      return InkStroke(
        id: row.id,
        pageId: row.pageId,
        points: points,
        color: row.color,
        width: row.width,
        createdAt: DateTime.fromMillisecondsSinceEpoch(row.createdAt),
        isErased: row.isErased,
      );
    }).toList();
  }

  Future<void> _updatePageTimestamp(String pageId) async {
    await (_db.update(_db.inkPages)..where((p) => p.id.equals(pageId)))
        .write(InkPagesCompanion(updatedAt: Value(DateTime.now().millisecondsSinceEpoch)));
  }
}
