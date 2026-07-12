import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:inkbill_ai/features/products/domain/entities/product.dart';
import 'package:inkbill_ai/features/products/domain/repositories/product_repository.dart';
import 'package:inkbill_ai/features/products/data/datasources/product_local_datasource.dart';
import 'package:inkbill_ai/features/products/data/repositories/product_repository_impl.dart';
import 'package:inkbill_ai/core/database/database_provider.dart';

final productRepositoryProvider = Provider<ProductRepository>((ref) {
  final db = ref.watch(databaseProvider);
  return ProductRepositoryImpl(ProductLocalDataSource(db));
});

final allProductsProvider = FutureProvider<List<Product>>((ref) async {
  final repo = ref.watch(productRepositoryProvider);
  final result = await repo.getAllProducts();
  return result.dataOrThrow;
});

final productProvider = FutureProvider.family<Product?, String>((ref, id) async {
  final repo = ref.watch(productRepositoryProvider);
  final result = await repo.getProductById(id);
  return result.dataOrNull;
});

final productSearchProvider = FutureProvider.family<List<Product>, String>((ref, query) async {
  if (query.isEmpty) return [];
  final repo = ref.watch(productRepositoryProvider);
  final result = await repo.searchProducts(query);
  return result.dataOrThrow;
});

final lowStockProductsProvider = FutureProvider<List<Product>>((ref) async {
  final repo = ref.watch(productRepositoryProvider);
  final result = await repo.getLowStockProducts(5);
  return result.dataOrThrow;
});
