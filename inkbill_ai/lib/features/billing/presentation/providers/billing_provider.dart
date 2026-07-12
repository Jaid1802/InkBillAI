import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:inkbill_ai/features/billing/domain/entities/bill.dart';
import 'package:inkbill_ai/features/billing/domain/entities/bill_item.dart';
import 'package:inkbill_ai/features/billing/domain/repositories/billing_repository.dart';
import 'package:inkbill_ai/features/billing/data/datasources/billing_local_datasource.dart';
import 'package:inkbill_ai/features/billing/data/repositories/billing_repository_impl.dart';
import 'package:inkbill_ai/core/database/database_provider.dart';
import 'package:inkbill_ai/features/customers/domain/entities/customer.dart';
import 'package:inkbill_ai/services/billing_engine/billing_calculator.dart';

final billingRepositoryProvider = Provider<BillingRepository>((ref) {
  final db = ref.watch(databaseProvider);
  return BillingRepositoryImpl(BillingLocalDataSource(db));
});

final allBillsProvider = FutureProvider<List<Bill>>((ref) async {
  final repo = ref.watch(billingRepositoryProvider);
  final result = await repo.getAllBills();
  return result.dataOrThrow;
});

final billProvider = FutureProvider.family<Bill?, String>((ref, id) async {
  final repo = ref.watch(billingRepositoryProvider);
  final result = await repo.getBillById(id);
  return result.dataOrNull;
});

final billCountProvider = FutureProvider<int>((ref) async {
  final repo = ref.watch(billingRepositoryProvider);
  final result = await repo.getBillCount();
  return result.dataOrThrow;
});

final totalRevenueProvider = FutureProvider<double>((ref) async {
  final repo = ref.watch(billingRepositoryProvider);
  final result = await repo.getTotalRevenue();
  return result.dataOrThrow;
});

class BillEditor extends StateNotifier<Bill> {
  BillEditor(super.state);

  void addItem(BillItem item) {
    state = BillingCalculator.addItem(state, item);
  }

  void removeItem(String itemId) {
    state = BillingCalculator.removeItem(state, itemId);
  }

  void updateItem(BillItem item) {
    state = BillingCalculator.updateItem(state, item);
  }

  void setCustomer(String? customerId, String? customerName) {
    state = state.copyWith(customerId: customerId, customerName: customerName);
  }

  void setCustomerFromCustomerEntity(Customer customer) {
    state = state.copyWith(
      customerId: customer.id,
      customerName: customer.name,
    );
  }

  void setTaxRate(double rate) {
    state = BillingCalculator.applyTaxRate(state, rate);
  }

  void setDiscount(double discount) {
    state = BillingCalculator.applyDiscount(state, discount);
  }

  void setNotes(String? notes) {
    state = state.copyWith(notes: notes);
  }

  void updateItemQuantity(String itemId, double quantity) {
    final items = state.items.map((item) {
      if (item.id == itemId) {
        return item.copyWith(quantity: quantity);
      }
      return item;
    }).toList();
    state = BillingCalculator.calculate(state.copyWith(items: items));
  }

  void updateItemRate(String itemId, double rate) {
    final items = state.items.map((item) {
      if (item.id == itemId) {
        return item.copyWith(rate: rate);
      }
      return item;
    }).toList();
    state = BillingCalculator.calculate(state.copyWith(items: items));
  }

  void updateItemName(String itemId, String name) {
    final items = state.items.map((item) {
      if (item.id == itemId) {
        return item.copyWith(name: name);
      }
      return item;
    }).toList();
    state = BillingCalculator.calculate(state.copyWith(items: items));
  }
}

final billEditorProvider = StateNotifierProvider.family<BillEditor, Bill, Bill>(
  (ref, initial) => BillEditor(initial),
);

final newBillProvider = StateNotifierProvider<BillEditor, Bill>((ref) {
  final bill = Bill(
    id: 'bill_${DateTime.now().microsecondsSinceEpoch}',
    createdAt: DateTime.now(),
    updatedAt: DateTime.now(),
  );
  return BillEditor(bill);
});
