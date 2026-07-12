import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:inkbill_ai/core/constants/app_constants.dart';
import 'package:inkbill_ai/features/billing/domain/entities/bill.dart';
import 'package:inkbill_ai/features/billing/domain/entities/bill_item.dart';
import 'package:inkbill_ai/features/billing/presentation/providers/billing_provider.dart';
import 'package:inkbill_ai/features/customers/domain/entities/customer.dart';
import 'package:inkbill_ai/features/customers/presentation/providers/customer_provider.dart';


class BillingPage extends ConsumerWidget {
  const BillingPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final billsAsync = ref.watch(allBillsProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Bills'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () => ref.invalidate(allBillsProvider),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        heroTag: 'new_bill_fab',
        onPressed: () => _createNewBill(context),
        child: const Icon(Icons.add),
      ),
      body: billsAsync.when(
        data: (bills) => bills.isEmpty
            ? const Center(child: Text('No bills yet. Create your first bill!'))
            : ListView.builder(
                itemCount: bills.length,
                itemBuilder: (context, index) => _BillCard(bill: bills[index]),
              ),
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Error: $e')),
      ),
    );
  }

  void _createNewBill(BuildContext context) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => const BillEditorPage(),
      ),
    );
  }
}

class _BillCard extends StatelessWidget {
  final Bill bill;

  const _BillCard({required this.bill});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: ListTile(
        title: Text('Bill #${bill.id.length > 8 ? bill.id.substring(0, 8) : bill.id}'),
        subtitle: Text(
          '${AppConstants.currencySymbol}${bill.total.toStringAsFixed(2)} - ${bill.itemCount} items',
        ),
        trailing: Chip(
          label: Text(
            bill.status.name.toUpperCase(),
            style: const TextStyle(fontSize: 11),
          ),
          backgroundColor: bill.status == BillStatus.finalized
              ? Colors.green.shade100
              : Colors.orange.shade100,
        ),
        onTap: () {
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (_) => BillEditorPage(existingBill: bill),
            ),
          );
        },
      ),
    );
  }
}

class BillEditorPage extends ConsumerStatefulWidget {
  final Bill? existingBill;

  const BillEditorPage({super.key, this.existingBill});

  @override
  ConsumerState<BillEditorPage> createState() => _BillEditorPageState();
}

class _BillEditorPageState extends ConsumerState<BillEditorPage> {
  late Bill _initialBill;
  late TextEditingController _itemNameCtrl;
  late TextEditingController _qtyCtrl;
  late TextEditingController _rateCtrl;
  late TextEditingController _discountCtrl;
  late TextEditingController _taxCtrl;
  late TextEditingController _notesCtrl;
  final _formKey = GlobalKey<FormState>();

  @override
  void initState() {
    super.initState();
    _initialBill = widget.existingBill ??
        Bill(
          id: 'bill_${DateTime.now().microsecondsSinceEpoch}',
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        );
    _itemNameCtrl = TextEditingController();
    _qtyCtrl = TextEditingController(text: '1');
    _rateCtrl = TextEditingController(text: '0');
    _discountCtrl = TextEditingController(
        text: _initialBill.discount > 0 ? _initialBill.discount.toString() : '');
    _taxCtrl = TextEditingController(
        text: _initialBill.taxRate > 0
            ? (_initialBill.taxRate * 100).toStringAsFixed(1)
            : '');
    _notesCtrl = TextEditingController(text: _initialBill.notes ?? '');
  }

  @override
  void dispose() {
    _itemNameCtrl.dispose();
    _qtyCtrl.dispose();
    _rateCtrl.dispose();
    _discountCtrl.dispose();
    _taxCtrl.dispose();
    _notesCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final billState = ref.watch(billEditorProvider(_initialBill));
    final editor = ref.read(billEditorProvider(_initialBill).notifier);

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.existingBill != null ? 'Edit Bill' : 'New Bill'),
        actions: [
          _buildSaveButton(editor, billState),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: Form(
              key: _formKey,
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  _buildCustomerSection(editor),
                  const SizedBox(height: 16),
                  _buildItemsHeader(),
                  const Divider(height: 4),
                  ...billState.items.asMap().entries.map((entry) =>
                      _EditableBillItemRow(
                        item: entry.value,
                        index: entry.key,
                        onUpdate: (updated) => editor.updateItem(updated),
                        onRemove: () => editor.removeItem(entry.value.id),
                      )),
                  const SizedBox(height: 8),
                  _buildAddItemRow(editor),
                  const Divider(height: 24),
                  _buildTaxDiscountSection(editor, billState),
                  const Divider(height: 16),
                  _buildTotals(billState),
                  const SizedBox(height: 16),
                  _buildNotesField(editor),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSaveButton(BillEditor editor, Bill bill) {
    return IconButton(
      icon: const Icon(Icons.save),
      onPressed: () async {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Saving bill...')),
        );
        final repo = ref.read(billingRepositoryProvider);

        if (widget.existingBill != null) {
          await repo.updateBill(bill);
        } else {
          await repo.createBill(bill);
        }

        ref.invalidate(allBillsProvider);

        if (context.mounted) {
          ScaffoldMessenger.of(context).clearSnackBars();
          Navigator.of(context).pop();
        }
      },
    );
  }

  Widget _buildCustomerSection(BillEditor editor) {
    final billState = ref.watch(billEditorProvider(_initialBill));

    return InkWell(
      onTap: () => _openCustomerSelector(editor),
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
        decoration: BoxDecoration(
          border: Border.all(color: Colors.grey.shade400),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          children: [
            Icon(Icons.person_outline, size: 20, color: Colors.grey.shade600),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Customer',
                    style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                  ),
                  Text(
                    billState.customerName ?? 'Tap to select customer',
                    style: TextStyle(
                      fontSize: 16,
                      color: billState.customerName != null
                          ? Colors.black
                          : Colors.grey,
                    ),
                  ),
                ],
              ),
            ),
            if (billState.customerName != null)
              IconButton(
                icon: const Icon(Icons.close, size: 18),
                onPressed: () => editor.setCustomer(null, null),
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
              ),
          ],
        ),
      ),
    );
  }

  Future<void> _openCustomerSelector(BillEditor editor) async {
    final selected = await showDialog<Customer>(
      context: context,
      builder: (ctx) => const _CustomerSelectorDialog(),
    );
    if (selected != null) {
      editor.setCustomerFromCustomerEntity(selected);
    }
  }

  Widget _buildItemsHeader() {
    return const Row(
      children: [
        Expanded(flex: 3, child: Text('Item', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12))),
        Expanded(flex: 1, child: Text('Qty', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12), textAlign: TextAlign.center)),
        Expanded(flex: 2, child: Text('Rate', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12), textAlign: TextAlign.right)),
        Expanded(flex: 2, child: Text('Amount', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12), textAlign: TextAlign.right)),
        SizedBox(width: 32),
      ],
    );
  }

  Widget _buildAddItemRow(BillEditor editor) {
    return Row(
      children: [
        Expanded(
          flex: 3,
          child: TextField(
            controller: _itemNameCtrl,
            decoration: const InputDecoration(
              hintText: 'Item name or search product',
              isDense: true,
              border: OutlineInputBorder(),
              contentPadding: EdgeInsets.symmetric(horizontal: 8, vertical: 8),
            ),
          ),
        ),
        const SizedBox(width: 4),
        SizedBox(
          width: 55,
          child: TextField(
            controller: _qtyCtrl,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            decoration: const InputDecoration(isDense: true, border: OutlineInputBorder(), contentPadding: EdgeInsets.symmetric(horizontal: 4, vertical: 8)),
          ),
        ),
        const SizedBox(width: 4),
        SizedBox(
          width: 70,
          child: TextField(
            controller: _rateCtrl,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            decoration: const InputDecoration(isDense: true, border: OutlineInputBorder(), contentPadding: EdgeInsets.symmetric(horizontal: 4, vertical: 8)),
          ),
        ),
        IconButton(
          icon: const Icon(Icons.add_circle, color: Colors.green),
          onPressed: () {
            final name = _itemNameCtrl.text.trim();
            if (name.isEmpty) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Please enter an item name')),
              );
              return;
            }
            final qty = double.tryParse(_qtyCtrl.text);
            final rate = double.tryParse(_rateCtrl.text);
            if (qty == null || qty <= 0) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Please enter a valid quantity')),
              );
              return;
            }
            if (rate == null || rate < 0) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Please enter a valid rate')),
              );
              return;
            }
            editor.addItem(BillItem(
              id: 'item_${DateTime.now().microsecondsSinceEpoch}',
              name: name,
              quantity: qty,
              rate: rate,
            ));
            _itemNameCtrl.clear();
            _qtyCtrl.text = '1';
            _rateCtrl.text = '0';
          },
        ),
      ],
    );
  }

  Widget _buildTaxDiscountSection(BillEditor editor, Bill bill) {
    return Row(
      children: [
        Expanded(
          child: TextField(
            controller: _taxCtrl,
            decoration: const InputDecoration(
              labelText: 'Tax %',
              isDense: true,
              border: OutlineInputBorder(),
            ),
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            onChanged: (v) {
              final rate = double.tryParse(v);
              if (rate != null && rate >= 0) {
                editor.setTaxRate(rate / 100);
              }
            },
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: TextField(
            controller: _discountCtrl,
            decoration: const InputDecoration(
              labelText: 'Discount',
              prefixText: '${AppConstants.currencySymbol} ',
              isDense: true,
              border: OutlineInputBorder(),
            ),
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            onChanged: (v) {
              final discount = double.tryParse(v);
              if (discount != null && discount >= 0) {
                editor.setDiscount(discount);
              }
            },
          ),
        ),
      ],
    );
  }

  Widget _buildNotesField(BillEditor editor) {
    return TextField(
      controller: _notesCtrl,
      decoration: const InputDecoration(
        labelText: 'Notes',
        border: OutlineInputBorder(),
        isDense: true,
      ),
      maxLines: 2,
      onChanged: (v) => editor.setNotes(v.isEmpty ? null : v),
    );
  }

  Widget _buildTotals(Bill bill) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: Column(
        children: [
          _totalRow('Subtotal', bill.subtotal),
          if (bill.taxAmount > 0) _totalRow('Tax (${(bill.taxRate * 100).toStringAsFixed(1)}%)', bill.taxAmount),
          if (bill.discount > 0) _totalRow('Discount', -bill.discount),
          const Divider(),
          _totalRow('Total', bill.total, bold: true, fontSize: 20),
        ],
      ),
    );
  }

  Widget _totalRow(String label, double amount, {bool bold = false, double fontSize = 14}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          Text(label, style: TextStyle(fontWeight: bold ? FontWeight.bold : FontWeight.normal, fontSize: fontSize - 2)),
          const SizedBox(width: 16),
          SizedBox(
            width: 100,
            child: Text(
              '${AppConstants.currencySymbol}${amount.abs().toStringAsFixed(2)}',
              textAlign: TextAlign.right,
              style: TextStyle(
                fontWeight: bold ? FontWeight.bold : FontWeight.normal,
                fontSize: fontSize,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _CustomerSelectorDialog extends ConsumerStatefulWidget {
  const _CustomerSelectorDialog();

  @override
  ConsumerState<_CustomerSelectorDialog> createState() => _CustomerSelectorDialogState();
}

class _CustomerSelectorDialogState extends ConsumerState<_CustomerSelectorDialog> {
  final _searchCtrl = TextEditingController();
  String _searchQuery = '';

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final customersAsync = ref.watch(
      _searchQuery.isEmpty
          ? allCustomersProvider
          : customerSearchProvider(_searchQuery),
    );

    return AlertDialog(
      title: const Text('Select Customer'),
      content: SizedBox(
        width: double.maxFinite,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: _searchCtrl,
              decoration: const InputDecoration(
                hintText: 'Search customers...',
                prefixIcon: Icon(Icons.search),
                isDense: true,
                border: OutlineInputBorder(),
              ),
              onChanged: (v) => setState(() => _searchQuery = v),
            ),
            const SizedBox(height: 12),
            SizedBox(
              height: 300,
              child: customersAsync.when(
                data: (customers) => customers.isEmpty
                    ? const Center(child: Text('No customers found'))
                    : ListView.builder(
                        itemCount: customers.length,
                        itemBuilder: (context, index) => ListTile(
                          dense: true,
                          leading: CircleAvatar(
                            radius: 16,
                            child: Text(customers[index].name.isNotEmpty
                                ? customers[index].name[0].toUpperCase()
                                : '?'),
                          ),
                          title: Text(customers[index].name),
                          subtitle: Text(customers[index].phone ?? ''),
                          onTap: () => Navigator.pop(context, customers[index]),
                        ),
                      ),
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (_, __) => const Center(child: Text('Error loading customers')),
              ),
            ),
            const Divider(),
            TextButton.icon(
              icon: const Icon(Icons.person_add),
              label: const Text('Add New Customer'),
              onPressed: () => _addNewCustomer(),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
      ],
    );
  }

  void _addNewCustomer() {
    Navigator.pop(context);
  }
}

class _EditableBillItemRow extends StatefulWidget {
  final BillItem item;
  final int index;
  final ValueChanged<BillItem> onUpdate;
  final VoidCallback onRemove;

  const _EditableBillItemRow({
    required this.item,
    required this.index,
    required this.onUpdate,
    required this.onRemove,
  });

  @override
  State<_EditableBillItemRow> createState() => _EditableBillItemRowState();
}

class _EditableBillItemRowState extends State<_EditableBillItemRow> {
  late TextEditingController _nameCtrl;
  late TextEditingController _qtyCtrl;
  late TextEditingController _rateCtrl;

  @override
  void initState() {
    super.initState();
    _nameCtrl = TextEditingController(text: widget.item.name);
    _qtyCtrl = TextEditingController(text: widget.item.quantity.toString());
    _rateCtrl = TextEditingController(text: widget.item.rate.toStringAsFixed(2));
  }

  @override
  void didUpdateWidget(_EditableBillItemRow oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.item.id != widget.item.id) {
      _nameCtrl.text = widget.item.name;
      _qtyCtrl.text = widget.item.quantity.toString();
      _rateCtrl.text = widget.item.rate.toStringAsFixed(2);
    }
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _qtyCtrl.dispose();
    _rateCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Expanded(
            flex: 3,
            child: TextField(
              controller: _nameCtrl,
              decoration: const InputDecoration(isDense: true, border: OutlineInputBorder(), contentPadding: EdgeInsets.symmetric(horizontal: 4, vertical: 8)),
              onChanged: (v) => widget.onUpdate(widget.item.copyWith(name: v)),
            ),
          ),
          const SizedBox(width: 4),
          SizedBox(
            width: 55,
            child: TextField(
              controller: _qtyCtrl,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              decoration: const InputDecoration(isDense: true, border: OutlineInputBorder(), contentPadding: EdgeInsets.symmetric(horizontal: 4, vertical: 8)),
              onChanged: (v) {
                final qty = double.tryParse(v);
                if (qty != null && qty >= 0) {
                  widget.onUpdate(widget.item.copyWith(quantity: qty));
                }
              },
            ),
          ),
          const SizedBox(width: 4),
          SizedBox(
            width: 70,
            child: TextField(
              controller: _rateCtrl,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              decoration: const InputDecoration(isDense: true, border: OutlineInputBorder(), contentPadding: EdgeInsets.symmetric(horizontal: 4, vertical: 8)),
              onChanged: (v) {
                final rate = double.tryParse(v);
                if (rate != null && rate >= 0) {
                  widget.onUpdate(widget.item.copyWith(rate: rate));
                }
              },
            ),
          ),
          SizedBox(
            width: 70,
            child: Text(
              '${AppConstants.currencySymbol}${widget.item.amount.toStringAsFixed(2)}',
              textAlign: TextAlign.right,
              style: const TextStyle(fontWeight: FontWeight.w500),
            ),
          ),
          SizedBox(
            width: 32,
            child: IconButton(
              icon: const Icon(Icons.remove_circle_outline, size: 18, color: Colors.red),
              onPressed: widget.onRemove,
              padding: EdgeInsets.zero,
            ),
          ),
        ],
      ),
    );
  }
}
