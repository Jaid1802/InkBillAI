import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:inkbill_ai/features/customers/domain/entities/customer.dart';
import 'package:inkbill_ai/features/customers/domain/repositories/customer_repository.dart';
import 'package:inkbill_ai/features/customers/data/datasources/customer_local_datasource.dart';
import 'package:inkbill_ai/features/customers/data/repositories/customer_repository_impl.dart';
import 'package:inkbill_ai/core/database/database_provider.dart';

final customerRepositoryProvider = Provider<CustomerRepository>((ref) {
  final db = ref.watch(databaseProvider);
  return CustomerRepositoryImpl(CustomerLocalDataSource(db));
});

final allCustomersProvider = FutureProvider<List<Customer>>((ref) async {
  final repo = ref.watch(customerRepositoryProvider);
  final result = await repo.getAllCustomers();
  return result.dataOrThrow;
});

final customerProvider = FutureProvider.family<Customer?, String>((ref, id) async {
  final repo = ref.watch(customerRepositoryProvider);
  final result = await repo.getCustomerById(id);
  return result.dataOrNull;
});

final customerSearchProvider = FutureProvider.family<List<Customer>, String>((ref, query) async {
  if (query.isEmpty) return [];
  final repo = ref.watch(customerRepositoryProvider);
  final result = await repo.searchCustomers(query);
  return result.dataOrThrow;
});

final customerCountProvider = FutureProvider<int>((ref) async {
  final repo = ref.watch(customerRepositoryProvider);
  final result = await repo.getCustomerCount();
  return result.dataOrThrow;
});
