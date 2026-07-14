import 'package:drift/drift.dart';
import 'package:inkbill_ai/core/database/app_database.dart';
import 'package:inkbill_ai/core/utils/result.dart';
import 'package:inkbill_ai/core/errors/failures.dart';
import 'package:inkbill_ai/features/billing/domain/entities/bill.dart' as domain;
import 'package:inkbill_ai/features/billing/domain/entities/bill_item.dart' as domain;

class BillingLocalDataSource {
  final AppDatabase _db;

  BillingLocalDataSource(this._db);

  Future<Result<List<domain.Bill>>> getAllBills({int limit = 50, int offset = 0}) async {
    try {
      final billRows = await (_db.select(_db.bills)
        ..orderBy([(b) => OrderingTerm(expression: b.createdAt, mode: OrderingMode.desc)])
        ..limit(limit, offset: offset))
          .get();
      final bills = <domain.Bill>[];
      for (final row in billRows) {
        final items = await _getItemsForBill(row.id);
        bills.add(_billFromRowTyped(row, items));
      }
      return Result.success(bills);
    } catch (e) {
      return Result.error(DatabaseFailure(message: 'Failed to get bills'));
    }
  }

  Future<Result<domain.Bill?>> getBillById(String id) async {
    try {
      final row = await (_db.select(_db.bills)..where((b) => b.id.equals(id))).getSingleOrNull();
      if (row == null) return Result.success(null);
      final items = await _getItemsForBill(id);
      return Result.success(_billFromRowTyped(row, items));
    } catch (e) {
      return Result.error(DatabaseFailure(message: 'Failed to get bill'));
    }
  }

  Future<Result<domain.Bill>> createBill(domain.Bill bill) async {
    try {
      final now = DateTime.now().millisecondsSinceEpoch;
      await _db.into(_db.bills).insert(BillsCompanion(
        id: Value(bill.id),
        customerId: Value(bill.customerId),
        customerName: Value(bill.customerName),
        subtotal: Value(bill.subtotal),
        taxRate: Value(bill.taxRate),
        taxAmount: Value(bill.taxAmount),
        discount: Value(bill.discount),
        total: Value(bill.total),
        status: Value(bill.status.name),
        createdAt: Value(now),
        updatedAt: Value(now),
        notes: Value(bill.notes),
        inkPageId: Value(bill.inkPageId),
      ));
      for (final item in bill.items) {
        await _insertItem(item, bill.id);
      }
      return Result.success(bill);
    } catch (e) {
      return Result.error(DatabaseFailure(message: 'Failed to create bill'));
    }
  }

  Future<Result<domain.Bill>> updateBill(domain.Bill bill) async {
    try {
      await (_db.update(_db.bills)..where((b) => b.id.equals(bill.id)))
          .write(BillsCompanion(
        customerId: Value(bill.customerId),
        customerName: Value(bill.customerName),
        subtotal: Value(bill.subtotal),
        taxRate: Value(bill.taxRate),
        taxAmount: Value(bill.taxAmount),
        discount: Value(bill.discount),
        total: Value(bill.total),
        status: Value(bill.status.name),
        updatedAt: Value(DateTime.now().millisecondsSinceEpoch),
        notes: Value(bill.notes),
        inkPageId: Value(bill.inkPageId),
      ));
      await (_db.delete(_db.billItems)..where((i) => i.billId.equals(bill.id))).go();
      for (final item in bill.items) {
        await _insertItem(item, bill.id);
      }
      return Result.success(bill);
    } catch (e) {
      return Result.error(DatabaseFailure(message: 'Failed to update bill'));
    }
  }

  Future<Result<void>> deleteBill(String id) async {
    try {
      await (_db.delete(_db.billItems)..where((i) => i.billId.equals(id))).go();
      await (_db.delete(_db.bills)..where((b) => b.id.equals(id))).go();
      return Result.success(null);
    } catch (e) {
      return Result.error(DatabaseFailure(message: 'Failed to delete bill'));
    }
  }

  Future<Result<void>> finalizeBill(String id) async {
    try {
      await (_db.update(_db.bills)..where((b) => b.id.equals(id)))
          .write(BillsCompanion(status: Value('finalized')));
      return Result.success(null);
    } catch (e) {
      return Result.error(DatabaseFailure(message: 'Failed to finalize bill'));
    }
  }

  Future<Result<int>> getBillCount() async {
    try {
      final count = await _db.bills.count().getSingle();
      return Result.success(count);
    } catch (e) {
      return Result.error(DatabaseFailure(message: 'Failed to count bills'));
    }
  }

  Future<Result<double>> getTotalRevenue({DateTime? start, DateTime? end}) async {
    try {
      var query = _db.select(_db.bills)..where((b) => b.status.equals('finalized'));
      if (start != null) {
        query.where((b) => b.createdAt.isBiggerThan(Variable(start.millisecondsSinceEpoch)));
      }
      if (end != null) {
        query.where((b) => b.createdAt.isSmallerThan(Variable(end.millisecondsSinceEpoch)));
      }
      final rows = await query.get();
      final total = rows.fold<double>(0, (sum, row) => sum + row.total);
      return Result.success(total);
    } catch (e) {
      return Result.error(DatabaseFailure(message: 'Failed to get revenue'));
    }
  }

  Future<List<domain.BillItem>> _getItemsForBill(String billId) async {
    final rows = await (_db.select(_db.billItems)..where((i) => i.billId.equals(billId))).get();
    return rows.map((row) => domain.BillItem(
      id: row.id,
      name: row.name,
      quantity: row.quantity,
      rate: row.rate,
      amount: row.amount,
      unit: row.unit,
      gstRate: row.gstRate,
      hsnCode: row.hsnCode,
    )).toList();
  }

  Future<void> _insertItem(domain.BillItem item, String billId) async {
    await _db.into(_db.billItems).insert(BillItemsCompanion(
      id: Value(item.id),
      billId: Value(billId),
      name: Value(item.name),
      quantity: Value(item.quantity),
      rate: Value(item.rate),
      amount: Value(item.amount),
      unit: Value(item.unit),
      gstRate: Value(item.gstRate),
      hsnCode: Value(item.hsnCode),
    ));
  }

  domain.Bill _billFromRowTyped(BillsData row, List<domain.BillItem> items) {
    return domain.Bill(
      id: row.id,
      customerId: row.customerId,
      customerName: row.customerName,
      items: items,
      subtotal: row.subtotal,
      taxRate: row.taxRate,
      taxAmount: row.taxAmount,
      discount: row.discount,
      total: row.total,
      status: domain.BillStatus.values.firstWhere(
        (s) => s.name == row.status,
        orElse: () => domain.BillStatus.draft,
      ),
      createdAt: DateTime.fromMillisecondsSinceEpoch(row.createdAt),
      updatedAt: DateTime.fromMillisecondsSinceEpoch(row.updatedAt),
      notes: row.notes,
      inkPageId: row.inkPageId,
    );
  }
}
