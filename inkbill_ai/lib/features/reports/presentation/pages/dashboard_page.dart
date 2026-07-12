import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:inkbill_ai/core/constants/app_constants.dart';
import 'package:inkbill_ai/features/billing/domain/entities/bill.dart';
import 'package:inkbill_ai/features/billing/presentation/providers/billing_provider.dart';
import 'package:inkbill_ai/features/billing/presentation/pages/billing_page.dart';
import 'package:inkbill_ai/features/customers/presentation/providers/customer_provider.dart';

class DashboardPage extends ConsumerWidget {
  const DashboardPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final billCountAsync = ref.watch(billCountProvider);
    final revenueAsync = ref.watch(totalRevenueProvider);
    final customerCountAsync = ref.watch(customerCountProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text(AppConstants.appName),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () => ref.invalidate(allBillsProvider),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          GridView.count(
            crossAxisCount: 2,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
            childAspectRatio: 1.5,
            children: [
              _StatCard(
                title: 'Total Bills',
                value: billCountAsync.when(
                  data: (c) => c.toString(),
                  loading: () => '...',
                  error: (e, s) => '0',
                ),
                icon: Icons.receipt_long,
                color: Colors.blue,
              ),
              _StatCard(
                title: 'Revenue',
                value: revenueAsync.when(
                  data: (r) => '${AppConstants.currencySymbol}${r.toStringAsFixed(0)}',
                  loading: () => '...',
                  error: (e, s) => '${AppConstants.currencySymbol}0',
                ),
                icon: Icons.trending_up,
                color: Colors.green,
              ),
              _StatCard(
                title: 'Customers',
                value: customerCountAsync.when(
                  data: (c) => c.toString(),
                  loading: () => '...',
                  error: (e, s) => '0',
                ),
                icon: Icons.people,
                color: Colors.purple,
              ),
              _StatCard(
                title: 'New Bill',
                value: '+',
                icon: Icons.add,
                color: Colors.orange,
                onTap: () => _createBill(context),
              ),
            ],
          ),
          const SizedBox(height: 24),
          const Text(
            'Recent Activity',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          ref.watch(allBillsProvider).when(
            data: (bills) => bills.take(5).toList().isEmpty
                ? const Card(child: ListTile(title: Text('No recent bills')))
                : Column(
                    children: bills.take(5).map((bill) => ListTile(
                      leading: Icon(Icons.receipt, color: bill.status == BillStatus.finalized ? Colors.green : Colors.orange),
                      title: Text('Bill #${bill.id.substring(0, 8)}'),
                      subtitle: Text('${AppConstants.currencySymbol}${bill.total.toStringAsFixed(2)}'),
                      trailing: Text(bill.createdAt.toIso8601String().substring(0, 10)),
                    )).toList(),
                  ),
            loading: () => const CircularProgressIndicator(),
            error: (e, s) => const Text('Failed to load'),
          ),
        ],
      ),
    );
  }

  void _createBill(BuildContext context) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => BillEditorPage(),
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  final String title;
  final String value;
  final IconData icon;
  final Color color;
  final VoidCallback? onTap;

  const _StatCard({
    required this.title,
    required this.value,
    required this.icon,
    required this.color,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(title, style: const TextStyle(fontSize: 12, color: Colors.grey)),
                  Icon(icon, color: color, size: 20),
                ],
              ),
              Text(
                value,
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: color,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
