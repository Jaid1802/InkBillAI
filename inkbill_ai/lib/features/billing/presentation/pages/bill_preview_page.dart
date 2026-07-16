import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:inkbill_ai/core/constants/app_constants.dart';
import 'package:inkbill_ai/core/theme/app_theme.dart';
import 'package:inkbill_ai/features/ai/domain/entities/recognition_result.dart';
import 'package:inkbill_ai/features/billing/domain/entities/bill.dart';
import 'package:inkbill_ai/features/billing/domain/entities/bill_item.dart';
import 'package:inkbill_ai/features/billing/presentation/pages/save_success_page.dart';
import 'package:inkbill_ai/features/billing/presentation/providers/billing_provider.dart';
import 'package:inkbill_ai/features/billing/presentation/widgets/print_options_bottom_sheet.dart';
import 'package:inkbill_ai/features/auth/presentation/providers/auth_provider.dart';

class BillPreviewPage extends ConsumerStatefulWidget {
  final List<LineItemData> items;
  final String? sourcePageId;

  const BillPreviewPage({
    super.key,
    required this.items,
    this.sourcePageId,
  });

  @override
  ConsumerState<BillPreviewPage> createState() => _BillPreviewPageState();
}

class _BillPreviewPageState extends ConsumerState<BillPreviewPage> {
  final double _taxRate = 0;
  final double _discount = 0;
  bool _isSaving = false;

  double get _subtotal =>
      widget.items.fold(0, (sum, item) => sum + ((item.quantity ?? 1) * (item.rate ?? 0)));
  double get _taxAmount => _subtotal * _taxRate;
  double get _total => _subtotal + _taxAmount - _discount;

  Bill _buildBill() {
    final billItems = widget.items
        .where((e) => e.name.isNotEmpty)
        .map((e) => BillItem(
              id: 'item_${DateTime.now().microsecondsSinceEpoch}_${e.hashCode}',
              name: e.name,
              quantity: e.quantity ?? 1,
              rate: e.rate ?? 0,
              amount: (e.quantity ?? 1) * (e.rate ?? 0),
            ))
        .toList();

    return Bill(
      id: 'bill_${DateTime.now().microsecondsSinceEpoch}',
      customerName: 'Walk-in Customer',
      items: billItems,
      subtotal: _subtotal,
      taxRate: _taxRate,
      taxAmount: _taxAmount,
      discount: _discount,
      total: _total,
      status: BillStatus.finalized,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
      inkPageId: widget.sourcePageId,
    );
  }

  Future<void> _saveBill() async {
    if (_isSaving) return;
    setState(() => _isSaving = true);
    try {
      final repo = ref.read(billingRepositoryProvider);
      final bill = _buildBill();
      await repo.createBill(bill);
      ref.invalidate(allBillsProvider);
      if (context.mounted) {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(
            builder: (_) => SaveSuccessPage(bill: bill),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  void _showPrintOptions() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) => PrintOptionsBottomSheet(
        onPrint: () {
          // Implement print
          _saveBill();
        },
        onSavePdf: () {
          // Implement save as pdf
          _saveBill();
        },
        onSaveHistory: () {
          _saveBill();
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authStateProvider);
    final shopName = authState.shop?.shopName ?? 'InkBill AI Store';

    return Scaffold(
      backgroundColor: Colors.grey.shade100,
      appBar: AppBar(
        title: const Text('Receipt Preview'),
        backgroundColor: Colors.white,
      ),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(24),
                child: Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.05),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Text(
                        'RECEIPT',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 4,
                          color: Colors.grey.shade800,
                        ),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        shopName,
                        textAlign: TextAlign.center,
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
                      ),
                      const SizedBox(height: 24),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text('Date:', style: TextStyle(color: Colors.grey)),
                          Text(
                            '${DateTime.now().day}/${DateTime.now().month}/${DateTime.now().year}',
                            style: const TextStyle(fontWeight: FontWeight.w500),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text('Time:', style: TextStyle(color: Colors.grey)),
                          Text(
                            '${DateTime.now().hour}:${DateTime.now().minute.toString().padLeft(2, '0')}',
                            style: const TextStyle(fontWeight: FontWeight.w500),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: const [
                          Text('Customer:', style: TextStyle(color: Colors.grey)),
                          Text('Walk-in Customer', style: TextStyle(fontWeight: FontWeight.w500)),
                        ],
                      ),
                      const SizedBox(height: 24),
                      _buildDashedLine(),
                      const SizedBox(height: 16),
                      Row(
                        children: const [
                          Expanded(flex: 3, child: Text('ITEM', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.grey))),
                          Expanded(flex: 1, child: Text('QTY', textAlign: TextAlign.right, style: TextStyle(fontWeight: FontWeight.bold, color: Colors.grey))),
                          Expanded(flex: 2, child: Text('RATE', textAlign: TextAlign.right, style: TextStyle(fontWeight: FontWeight.bold, color: Colors.grey))),
                          Expanded(flex: 2, child: Text('AMT', textAlign: TextAlign.right, style: TextStyle(fontWeight: FontWeight.bold, color: Colors.grey))),
                        ],
                      ),
                      const SizedBox(height: 16),
                      ...widget.items.map((item) => Padding(
                        padding: const EdgeInsets.only(bottom: 12.0),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(
                              flex: 3,
                              child: Text(item.name, style: const TextStyle(fontWeight: FontWeight.w500)),
                            ),
                            Expanded(
                              flex: 1,
                              child: Text((item.quantity ?? 1).toStringAsFixed(0), textAlign: TextAlign.right),
                            ),
                            Expanded(
                              flex: 2,
                              child: Text((item.rate ?? 0).toStringAsFixed(0), textAlign: TextAlign.right),
                            ),
                            Expanded(
                              flex: 2,
                              child: Text(((item.quantity ?? 1) * (item.rate ?? 0)).toStringAsFixed(0), textAlign: TextAlign.right),
                            ),
                          ],
                        ),
                      )),
                      const SizedBox(height: 4),
                      _buildDashedLine(),
                      const SizedBox(height: 16),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text('Subtotal', style: TextStyle(color: Colors.grey)),
                          Text('${AppConstants.currencySymbol}${_subtotal.toStringAsFixed(2)}'),
                        ],
                      ),
                      if (_taxAmount > 0) ...[
                        const SizedBox(height: 8),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text('Tax (${(_taxRate * 100).toStringAsFixed(0)}%)', style: const TextStyle(color: Colors.grey)),
                            Text('${AppConstants.currencySymbol}${_taxAmount.toStringAsFixed(2)}'),
                          ],
                        ),
                      ],
                      const SizedBox(height: 16),
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.grey.shade50,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text('TOTAL', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                            Text(
                              '${AppConstants.currencySymbol}${_total.toStringAsFixed(2)}',
                              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 20, color: AppTheme.primaryDark),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 32),
                      const Text(
                        'Thank you for visiting!',
                        textAlign: TextAlign.center,
                        style: TextStyle(fontStyle: FontStyle.italic, color: Colors.grey),
                      ),
                      const SizedBox(height: 16),
                    ],
                  ),
                ),
              ),
            ),
            Container(
              padding: const EdgeInsets.all(16),
              color: Colors.white,
              child: FilledButton(
                onPressed: _isSaving ? null : _showPrintOptions,
                style: FilledButton.styleFrom(
                  minimumSize: const Size.fromHeight(56),
                  backgroundColor: AppTheme.primaryDark,
                ),
                child: _isSaving
                    ? const SizedBox(
                        width: 24,
                        height: 24,
                        child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                      )
                    : const Text('Print / Save', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDashedLine() {
    return LayoutBuilder(
      builder: (BuildContext context, BoxConstraints constraints) {
        final boxWidth = constraints.constrainWidth();
        const dashWidth = 5.0;
        const dashHeight = 1.0;
        final dashCount = (boxWidth / (2 * dashWidth)).floor();
        return Flex(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          direction: Axis.horizontal,
          children: List.generate(dashCount, (_) {
            return const SizedBox(
              width: dashWidth,
              height: dashHeight,
              child: DecoratedBox(
                decoration: BoxDecoration(color: Colors.grey),
              ),
            );
          }),
        );
      },
    );
  }
}
