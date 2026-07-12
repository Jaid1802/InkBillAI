import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:inkbill_ai/features/handwriting/domain/entities/ink_page.dart';
import 'package:inkbill_ai/features/handwriting/domain/entities/ink_stroke.dart';
import 'package:inkbill_ai/features/handwriting/domain/repositories/ink_repository.dart';
import 'package:inkbill_ai/features/handwriting/data/datasources/ink_local_datasource.dart';
import 'package:inkbill_ai/features/handwriting/data/repositories/ink_repository_impl.dart';
import 'package:inkbill_ai/core/database/database_provider.dart';

final inkRepositoryProvider = Provider<InkRepository>((ref) {
  final db = ref.watch(databaseProvider);
  return InkRepositoryImpl(InkLocalDataSource(db));
});

final inkPagesProvider = FutureProvider<List<InkPage>>((ref) async {
  final repo = ref.watch(inkRepositoryProvider);
  final result = await repo.getAllPages();
  return result.dataOrThrow;
});

final inkPageProvider = FutureProvider.family<InkPage?, String>((ref, id) async {
  final repo = ref.watch(inkRepositoryProvider);
  final result = await repo.getPageById(id);
  return result.dataOrNull;
});

final pageStrokesProvider = FutureProvider.family<List<InkStroke>, String>((ref, pageId) async {
  final repo = ref.watch(inkRepositoryProvider);
  final result = await repo.getStrokesForPage(pageId);
  return result.dataOrNull ?? [];
});
