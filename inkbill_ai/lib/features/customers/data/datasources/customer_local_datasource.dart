import 'package:drift/drift.dart';
import 'package:inkbill_ai/core/database/app_database.dart';
import 'package:inkbill_ai/core/database/tables/customers_table.dart';
import 'package:inkbill_ai/core/utils/result.dart';
import 'package:inkbill_ai/core/errors/failures.dart';
import 'package:inkbill_ai/features/customers/domain/entities/customer.dart' as domain;

class CustomerLocalDataSource {
  final AppDatabase _db;

  CustomerLocalDataSource(this._db);

  Future<Result<List<domain.Customer>>> getAllCustomers() async {
    try {
      final rows = await _db.select(_db.customers).get();
      return Result.success(rows.map(_customerFromRow).toList());
    } catch (e) {
      return Result.error(DatabaseFailure(message: 'Failed to get customers'));
    }
  }

  Future<Result<domain.Customer?>> getCustomerById(String id) async {
    try {
      final row = await (_db.select(_db.customers)..where((c) => c.id.equals(id))).getSingleOrNull();
      return Result.success(row != null ? _customerFromRow(row) : null);
    } catch (e) {
      return Result.error(DatabaseFailure(message: 'Failed to get customer'));
    }
  }

  Future<Result<List<domain.Customer>>> searchCustomers(String query) async {
    try {
      final rows = await (_db.select(_db.customers)
        ..where((c) => c.name.contains(query) | c.phone.contains(query))
        ..orderBy([(c) => OrderingTerm(expression: c.name)]))
          .get();
      return Result.success(rows.map(_customerFromRow).toList());
    } catch (e) {
      return Result.error(DatabaseFailure(message: 'Failed to search customers'));
    }
  }

  Future<Result<domain.Customer>> createCustomer(domain.Customer customer) async {
    try {
      final now = DateTime.now().millisecondsSinceEpoch;
      await _db.into(_db.customers).insert(CustomersCompanion(
        id: Value(customer.id),
        name: Value(customer.name),
        phone: Value(customer.phone),
        email: Value(customer.email),
        address: Value(customer.address),
        gstin: Value(customer.gstin),
        balance: Value(customer.balance),
        totalPurchases: Value(customer.totalPurchases),
        createdAt: Value(now),
        updatedAt: Value(now),
      ));
      return Result.success(customer);
    } catch (e) {
      return Result.error(DatabaseFailure(message: 'Failed to create customer'));
    }
  }

  Future<Result<domain.Customer>> updateCustomer(domain.Customer customer) async {
    try {
      await (_db.update(_db.customers)..where((c) => c.id.equals(customer.id)))
          .write(CustomersCompanion(
        name: Value(customer.name),
        phone: Value(customer.phone),
        email: Value(customer.email),
        address: Value(customer.address),
        gstin: Value(customer.gstin),
        balance: Value(customer.balance),
        totalPurchases: Value(customer.totalPurchases),
        updatedAt: Value(DateTime.now().millisecondsSinceEpoch),
      ));
      return Result.success(customer);
    } catch (e) {
      return Result.error(DatabaseFailure(message: 'Failed to update customer'));
    }
  }

  Future<Result<void>> deleteCustomer(String id) async {
    try {
      await (_db.delete(_db.customers)..where((c) => c.id.equals(id))).go();
      return Result.success(null);
    } catch (e) {
      return Result.error(DatabaseFailure(message: 'Failed to delete customer'));
    }
  }

  Future<Result<int>> getCustomerCount() async {
    try {
      final countExp = _db.customers.id.count();
      final query = _db.selectOnly(_db.customers)..addColumns([countExp]);
      final result = await query.map((row) => row.read(countExp)).getSingle();
      return Result.success(result ?? 0);
    } catch (e) {
      return Result.error(DatabaseFailure(message: 'Failed to count customers'));
    }
  }

  domain.Customer _customerFromRow(CustomersData row) {
    return domain.Customer(
      id: row.id,
      name: row.name,
      phone: row.phone ?? '',
      email: row.email ?? '',
      address: row.address ?? '',
      gstin: row.gstin ?? '',
      balance: row.balance,
      totalPurchases: row.totalPurchases,
      createdAt: DateTime.fromMillisecondsSinceEpoch(row.createdAt),
      updatedAt: DateTime.fromMillisecondsSinceEpoch(row.updatedAt),
    );
  }
}
