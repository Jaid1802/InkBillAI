import 'package:inkbill_ai/core/utils/result.dart';
import 'package:inkbill_ai/features/customers/domain/entities/customer.dart';

abstract class CustomerRepository {
  Future<Result<List<Customer>>> getAllCustomers();
  Future<Result<Customer?>> getCustomerById(String id);
  Future<Result<List<Customer>>> searchCustomers(String query);
  Future<Result<Customer>> createCustomer(Customer customer);
  Future<Result<Customer>> updateCustomer(Customer customer);
  Future<Result<void>> deleteCustomer(String id);
  Future<Result<int>> getCustomerCount();
}
