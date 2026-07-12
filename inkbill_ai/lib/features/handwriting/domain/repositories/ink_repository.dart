import 'package:inkbill_ai/core/utils/result.dart';
import 'package:inkbill_ai/features/handwriting/domain/entities/ink_page.dart';
import 'package:inkbill_ai/features/handwriting/domain/entities/ink_stroke.dart';

abstract class InkRepository {
  Future<Result<List<InkPage>>> getAllPages();
  Future<Result<InkPage?>> getPageById(String id);
  Future<Result<InkPage>> createPage({String? billId, String? label});
  Future<Result<void>> saveStroke(InkStroke stroke);
  Future<Result<void>> saveStrokes(List<InkStroke> strokes);
  Future<Result<void>> deleteStroke(String strokeId);
  Future<Result<void>> eraseStroke(String strokeId);
  Future<Result<void>> clearPage(String pageId);
  Future<Result<void>> deletePage(String pageId);
  Future<Result<List<InkStroke>>> getStrokesForPage(String pageId);
  Future<Result<List<InkStroke>>> getRecentlyModifiedStrokes(
      {int limit = 50});
}
