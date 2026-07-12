import 'package:inkbill_ai/core/utils/result.dart';
import 'package:inkbill_ai/features/handwriting/domain/entities/ink_page.dart';
import 'package:inkbill_ai/features/handwriting/domain/entities/ink_stroke.dart';
import 'package:inkbill_ai/features/handwriting/domain/repositories/ink_repository.dart';
import 'package:inkbill_ai/features/handwriting/data/datasources/ink_local_datasource.dart';

class InkRepositoryImpl implements InkRepository {
  final InkLocalDataSource _dataSource;

  InkRepositoryImpl(this._dataSource);

  @override
  Future<Result<List<InkPage>>> getAllPages() => _dataSource.getAllPages();

  @override
  Future<Result<InkPage?>> getPageById(String id) => _dataSource.getPageById(id);

  @override
  Future<Result<InkPage>> createPage({String? billId, String? label}) =>
      _dataSource.createPage(billId: billId, label: label);

  @override
  Future<Result<void>> saveStroke(InkStroke stroke) =>
      _dataSource.saveStroke(stroke);

  @override
  Future<Result<void>> saveStrokes(List<InkStroke> strokes) =>
      _dataSource.saveStrokes(strokes);

  @override
  Future<Result<void>> deleteStroke(String strokeId) =>
      _dataSource.deleteStroke(strokeId);

  @override
  Future<Result<void>> eraseStroke(String strokeId) =>
      _dataSource.eraseStroke(strokeId);

  @override
  Future<Result<void>> clearPage(String pageId) =>
      _dataSource.clearPage(pageId);

  @override
  Future<Result<void>> deletePage(String pageId) =>
      _dataSource.deletePage(pageId);

  @override
  Future<Result<List<InkStroke>>> getStrokesForPage(String pageId) =>
      _dataSource.getStrokesForPage(pageId);

  @override
  Future<Result<List<InkStroke>>> getRecentlyModifiedStrokes(
      {int limit = 50}) async {
    return _dataSource.getStrokesForPage('');
  }
}
