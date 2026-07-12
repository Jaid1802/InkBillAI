import 'package:inkbill_ai/core/utils/result.dart';
import 'package:inkbill_ai/features/billing/domain/entities/bill.dart';
import 'package:inkbill_ai/features/billing/domain/repositories/billing_repository.dart';
import 'package:inkbill_ai/features/billing/data/datasources/billing_local_datasource.dart';

class BillingRepositoryImpl implements BillingRepository {
  final BillingLocalDataSource _dataSource;

  BillingRepositoryImpl(this._dataSource);

  @override
  Future<Result<List<Bill>>> getAllBills({int limit = 50, int offset = 0}) =>
      _dataSource.getAllBills(limit: limit, offset: offset);

  @override
  Future<Result<List<Bill>>> getBillsByDateRange(DateTime start, DateTime end) {
    throw UnimplementedError();
  }

  @override
  Future<Result<List<Bill>>> getBillsByCustomer(String customerId) {
    throw UnimplementedError();
  }

  @override
  Future<Result<Bill?>> getBillById(String id) => _dataSource.getBillById(id);

  @override
  Future<Result<Bill>> createBill(Bill bill) => _dataSource.createBill(bill);

  @override
  Future<Result<Bill>> updateBill(Bill bill) => _dataSource.updateBill(bill);

  @override
  Future<Result<void>> deleteBill(String id) => _dataSource.deleteBill(id);

  @override
  Future<Result<void>> finalizeBill(String id) => _dataSource.finalizeBill(id);

  @override
  Future<Result<int>> getBillCount() => _dataSource.getBillCount();

  @override
  Future<Result<double>> getTotalRevenue({DateTime? start, DateTime? end}) =>
      _dataSource.getTotalRevenue(start: start, end: end);
}
