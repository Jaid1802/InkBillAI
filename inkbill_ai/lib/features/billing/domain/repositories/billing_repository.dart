import 'package:inkbill_ai/core/utils/result.dart';
import 'package:inkbill_ai/features/billing/domain/entities/bill.dart';

abstract class BillingRepository {
  Future<Result<List<Bill>>> getAllBills({int limit = 50, int offset = 0});
  Future<Result<List<Bill>>> getBillsByDateRange(
      DateTime start, DateTime end);
  Future<Result<List<Bill>>> getBillsByCustomer(String customerId);
  Future<Result<Bill?>> getBillById(String id);
  Future<Result<Bill>> createBill(Bill bill);
  Future<Result<Bill>> updateBill(Bill bill);
  Future<Result<void>> deleteBill(String id);
  Future<Result<void>> finalizeBill(String id);
  Future<Result<int>> getBillCount();
  Future<Result<double>> getTotalRevenue(
      {DateTime? start, DateTime? end});
}
