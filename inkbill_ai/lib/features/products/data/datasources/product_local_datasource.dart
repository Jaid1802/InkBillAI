import 'package:drift/drift.dart';
import 'package:inkbill_ai/core/database/app_database.dart';
import 'package:inkbill_ai/core/utils/result.dart';
import 'package:inkbill_ai/core/errors/failures.dart';
import 'package:inkbill_ai/features/products/domain/entities/product.dart' as domain;

class ProductLocalDataSource {
  final AppDatabase _db;

  ProductLocalDataSource(this._db);

  Future<Result<List<domain.Product>>> getAllProducts() async {
    try {
      final rows = await _db.select(_db.products).get();
      return Result.success(rows.map(_productFromRow).toList());
    } catch (e) {
      return Result.error(DatabaseFailure(message: 'Failed to get products: $e'));
    }
  }

  Future<Result<domain.Product?>> getProductById(String id) async {
    try {
      final row = await (_db.select(_db.products)..where((p) => p.id.equals(id))).getSingleOrNull();
      return Result.success(row != null ? _productFromRow(row) : null);
    } catch (e) {
      return Result.error(DatabaseFailure(message: 'Failed to get product: $e'));
    }
  }

  Future<Result<List<domain.Product>>> searchProducts(String query) async {
    try {
      final rows = await (_db.select(_db.products)
        ..where((p) => p.name.contains(query))
        ..orderBy([(p) => OrderingTerm(expression: p.name)]))
          .get();
      return Result.success(rows.map(_productFromRow).toList());
    } catch (e) {
      return Result.error(DatabaseFailure(message: 'Failed to search products: $e'));
    }
  }

  Future<Result<domain.Product>> createProduct(domain.Product product) async {
    try {
      final now = DateTime.now().millisecondsSinceEpoch;
      await _db.into(_db.products).insert(ProductsCompanion(
        id: Value(product.id),
        name: Value(product.name),
        description: Value(product.description),
        price: Value(product.price),
        gstRate: Value(product.gstRate),
        hsnCode: Value(product.hsnCode),
        unit: Value(product.unit),
        stock: Value(product.stock),
        barcode: Value(product.barcode),
        createdAt: Value(now),
        updatedAt: Value(now),
      ));
      return Result.success(product);
    } catch (e) {
      return Result.error(DatabaseFailure(message: 'Failed to create product: $e'));
    }
  }

  Future<Result<domain.Product>> updateProduct(domain.Product product) async {
    try {
      await (_db.update(_db.products)..where((p) => p.id.equals(product.id)))
          .write(ProductsCompanion(
        name: Value(product.name),
        description: Value(product.description),
        price: Value(product.price),
        gstRate: Value(product.gstRate),
        hsnCode: Value(product.hsnCode),
        unit: Value(product.unit),
        stock: Value(product.stock),
        barcode: Value(product.barcode),
        updatedAt: Value(DateTime.now().millisecondsSinceEpoch),
      ));
      return Result.success(product);
    } catch (e) {
      return Result.error(DatabaseFailure(message: 'Failed to update product: $e'));
    }
  }

  Future<Result<void>> deleteProduct(String id) async {
    try {
      await (_db.delete(_db.products)..where((p) => p.id.equals(id))).go();
      return Result.success(null);
    } catch (e) {
      return Result.error(DatabaseFailure(message: 'Failed to delete product: $e'));
    }
  }

  Future<Result<List<domain.Product>>> getLowStockProducts(int threshold) async {
    try {
      final rows = await (_db.select(_db.products)..where((p) => p.stock.isSmallerThanValue(threshold))).get();
      return Result.success(rows.map(_productFromRow).toList());
    } catch (e) {
      return Result.error(DatabaseFailure(message: 'Failed to get low stock: $e'));
    }
  }

  Future<Result<void>> updateStock(String id, int quantity) async {
    try {
      await (_db.update(_db.products)..where((p) => p.id.equals(id)))
          .write(ProductsCompanion(stock: Value(quantity)));
      return Result.success(null);
    } catch (e) {
      return Result.error(DatabaseFailure(message: 'Failed to update stock: $e'));
    }
  }

  domain.Product _productFromRow(ProductsData row) {
    return domain.Product(
      id: row.id,
      name: row.name,
      description: row.description,
      price: row.price,
      gstRate: row.gstRate,
      hsnCode: row.hsnCode,
      unit: row.unit,
      stock: row.stock,
      barcode: row.barcode,
      createdAt: DateTime.fromMillisecondsSinceEpoch(row.createdAt),
      updatedAt: DateTime.fromMillisecondsSinceEpoch(row.updatedAt),
    );
  }
}
