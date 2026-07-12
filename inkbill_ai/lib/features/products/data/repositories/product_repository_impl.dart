import 'package:inkbill_ai/core/utils/result.dart';
import 'package:inkbill_ai/features/products/domain/entities/product.dart';
import 'package:inkbill_ai/features/products/domain/repositories/product_repository.dart';
import 'package:inkbill_ai/features/products/data/datasources/product_local_datasource.dart';

class ProductRepositoryImpl implements ProductRepository {
  final ProductLocalDataSource _dataSource;

  ProductRepositoryImpl(this._dataSource);

  @override
  Future<Result<List<Product>>> getAllProducts() =>
      _dataSource.getAllProducts();

  @override
  Future<Result<Product?>> getProductById(String id) =>
      _dataSource.getProductById(id);

  @override
  Future<Result<List<Product>>> searchProducts(String query) =>
      _dataSource.searchProducts(query);

  @override
  Future<Result<Product>> createProduct(Product product) =>
      _dataSource.createProduct(product);

  @override
  Future<Result<Product>> updateProduct(Product product) =>
      _dataSource.updateProduct(product);

  @override
  Future<Result<void>> deleteProduct(String id) =>
      _dataSource.deleteProduct(id);

  @override
  Future<Result<List<Product>>> getLowStockProducts(int threshold) =>
      _dataSource.getLowStockProducts(threshold);

  @override
  Future<Result<void>> updateStock(String id, int quantity) =>
      _dataSource.updateStock(id, quantity);
}
