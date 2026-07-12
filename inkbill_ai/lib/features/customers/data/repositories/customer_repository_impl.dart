import 'package:inkbill_ai/core/utils/result.dart';
import 'package:inkbill_ai/features/customers/domain/entities/customer.dart';
import 'package:inkbill_ai/features/customers/domain/repositories/customer_repository.dart';
import 'package:inkbill_ai/features/customers/data/datasources/customer_local_datasource.dart';

class CustomerRepositoryImpl implements CustomerRepository {
  final CustomerLocalDataSource _dataSource;

  CustomerRepositoryImpl(this._dataSource);

  @override
  Future<Result<List<Customer>>> getAllCustomers() =>
      _dataSource.getAllCustomers();

  @override
  Future<Result<Customer?>> getCustomerById(String id) =>
      _dataSource.getCustomerById(id);

  @override
  Future<Result<List<Customer>>> searchCustomers(String query) =>
      _dataSource.searchCustomers(query);

  @override
  Future<Result<Customer>> createCustomer(Customer customer) =>
      _dataSource.createCustomer(customer);

  @override
  Future<Result<Customer>> updateCustomer(Customer customer) =>
      _dataSource.updateCustomer(customer);

  @override
  Future<Result<void>> deleteCustomer(String id) =>
      _dataSource.deleteCustomer(id);

  @override
  Future<Result<int>> getCustomerCount() =>
      _dataSource.getCustomerCount();
}
