import 'package:inkbill_ai/core/utils/result.dart';
import 'package:inkbill_ai/features/products/domain/entities/product.dart';

abstract class ProductRepository {
  Future<Result<List<Product>>> getAllProducts();
  Future<Result<Product?>> getProductById(String id);
  Future<Result<List<Product>>> searchProducts(String query);
  Future<Result<Product>> createProduct(Product product);
  Future<Result<Product>> updateProduct(Product product);
  Future<Result<void>> deleteProduct(String id);
  Future<Result<List<Product>>> getLowStockProducts(int threshold);
  Future<Result<void>> updateStock(String id, int quantity);
}
