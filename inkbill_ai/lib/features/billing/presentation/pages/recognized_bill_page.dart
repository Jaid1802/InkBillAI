import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:inkbill_ai/core/constants/app_constants.dart';
import 'package:inkbill_ai/core/theme/app_theme.dart';
import 'package:inkbill_ai/features/ai/domain/entities/recognition_result.dart';
import 'package:inkbill_ai/features/billing/domain/entities/bill.dart';
import 'package:inkbill_ai/features/billing/domain/entities/bill_item.dart';
import 'package:inkbill_ai/features/billing/presentation/providers/billing_provider.dart';
import 'package:inkbill_ai/features/billing/presentation/pages/bill_success_page.dart';
import 'package:inkbill_ai/features/billing/presentation/pages/edit_item_sheet.dart';
import 'package:inkbill_ai/services/receipt_generator/receipt_generator.dart';
import 'package:printing/printing.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:pdf/pdf.dart';

class RecognizedBillPage extends ConsumerStatefulWidget {
  final List<LineItemData> items;
  final String? sourcePageId;
  final double confidence;

  const RecognizedBillPage({
    super.key,
    required this.items,
    this.sourcePageId,
    this.confidence = 0.0,
  });

  @override
  ConsumerState<RecognizedBillPage> createState() =>
      _RecognizedBillPageState();
}

class BillItemEditable {
  String id;
  String name;
  double quantity;
  double rate;
  double confidence;
  bool isAccepted;

  BillItemEditable({
    required this.id,
    required this.name,
    this.quantity = 1,
    this.rate = 0,
    this.confidence = 0.5,
    this.isAccepted = true,
  });

  double get amount => quantity * rate;
}

class _RecognizedBillPageState extends ConsumerState<RecognizedBillPage> {
  late List<BillItemEditable> _items;
  double _taxRate = 0;
  double _discount = 0;
  String _notes = '';
  String? _customerName;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _items = widget.items.asMap().entries.map((entry) {
      final item = entry.value;
      return BillItemEditable(
        id: 'item_${DateTime.now().microsecondsSinceEpoch}_${entry.key}',
        name: item.name,
        quantity: item.quantity ?? 1,
        rate: item.rate ?? 0,
        confidence: item.confidence,
        isAccepted: item.confidence >= 0.4,
      );
    }).toList();
  }

  double get _subtotal =>
      _items.fold(0.0, (sum, item) => sum + item.amount);
  double get _taxAmount => _subtotal * _taxRate;
  double get _total => _subtotal + _taxAmount - _discount;

  void _addItem() {
    setState(() {
      _items.add(BillItemEditable(
        id: 'item_${DateTime.now().microsecondsSinceEpoch}',
        name: '',
        quantity: 1,
        rate: 0,
        confidence: 1.0,
      ));
    });
  }

  void _removeItem(int index) {
    setState(() => _items.removeAt(index));
  }

  void _duplicateItem(int index) {
    final original = _items[index];
    setState(() {
      _items.insert(
        index + 1,
        BillItemEditable(
          id: 'item_${DateTime.now().microsecondsSinceEpoch}',
          name: original.name,
          quantity: original.quantity,
          rate: original.rate,
          confidence: original.confidence,
        ),
      );
    });
  }

  Future<void> _editItem(int index) async {
    final result = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => EditItemSheet(item: _items[index]),
    );
    if (result == true && mounted) {
      setState(() {});
    }
  }

  void _acceptItem(int index) {
    setState(() => _items[index].isAccepted = true);
  }

  void _rejectItem(int index) {
    setState(() => _items[index].isAccepted = false);
  }

  Bill _buildBill() {
    final billItems = _items
        .where((e) => e.isAccepted && e.name.isNotEmpty)
        .map((e) => BillItem(
              id: e.id,
              name: e.name,
              quantity: e.quantity,
              rate: e.rate,
              amount: e.amount,
            ))
        .toList();
    return Bill(
      id: 'bill_${DateTime.now().microsecondsSinceEpoch}',
      customerName: _customerName,
      items: billItems,
      subtotal: _subtotal,
      taxRate: _taxRate,
      taxAmount: _taxAmount,
      discount: _discount,
      total: _total,
      status: BillStatus.draft,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
      notes: _notes.isNotEmpty ? _notes : null,
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
      if (mounted) {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(
            builder: (_) => BillSuccessPage(bill: bill),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  Future<void> _printBill() async {
    final bill = _buildBill();
    final receiptData =
        ReceiptData.fromBill(bill, storeName: 'InkBill AI');

    if (bill.items.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Add items before printing.')),
      );
      return;
    }

    await Printing.layoutPdf(
      onLayout: (PdfPageFormat format) async {
        final doc = pw.Document();
        doc.addPage(
          pw.Page(
            pageFormat: PdfPageFormat.a4,
            margin: const pw.EdgeInsets.all(32),
            build: (pw.Context context) => _buildPdfReceipt(receiptData),
          ),
        );
        return doc.save();
      },
      name: 'Bill_${bill.id}',
    );
  }

  pw.Widget _buildPdfReceipt(ReceiptData data) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Center(
          child: pw.Column(
            children: [
              pw.Text(data.storeName,
                  style: pw.TextStyle(
                      fontSize: 20, fontWeight: pw.FontWeight.bold)),
              if (data.storeAddress != null)
                pw.Text(data.storeAddress!,
                    style: const pw.TextStyle(fontSize: 12)),
              if (data.storePhone != null)
                pw.Text(data.storePhone!,
                    style: const pw.TextStyle(fontSize: 12)),
            ],
          ),
        ),
        pw.SizedBox(height: 16),
        pw.Divider(),
        pw.Row(
          mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
          children: [
            pw.Text('Bill #: ${data.billNumber}',
                style: const pw.TextStyle(fontSize: 11)),
            pw.Text(
                'Date: ${data.date.toIso8601String().substring(0, 10)}',
                style: const pw.TextStyle(fontSize: 11)),
          ],
        ),
        if (data.customerName != null)
          pw.Text('Customer: ${data.customerName}',
              style: const pw.TextStyle(fontSize: 11)),
        pw.SizedBox(height: 8),
        pw.Divider(),
        pw.Row(
          mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
          children: [
            pw.Text('Item',
                style: pw.TextStyle(
                    fontWeight: pw.FontWeight.bold, fontSize: 10)),
            pw.Text('Qty',
                style: pw.TextStyle(
                    fontWeight: pw.FontWeight.bold, fontSize: 10)),
            pw.Text('Rate',
                style: pw.TextStyle(
                    fontWeight: pw.FontWeight.bold, fontSize: 10)),
            pw.Text('Amount',
                style: pw.TextStyle(
                    fontWeight: pw.FontWeight.bold, fontSize: 10)),
          ],
        ),
        pw.Divider(),
        ...data.items.map((item) => pw.Padding(
              padding: const pw.EdgeInsets.symmetric(vertical: 2),
              child: pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Text(
                      item.name.length > 20
                          ? '${item.name.substring(0, 20)}...'
                          : item.name,
                      style: const pw.TextStyle(fontSize: 10)),
                  pw.Text(item.quantity.toString(),
                      style: const pw.TextStyle(fontSize: 10)),
                  pw.Text(
                      '${AppConstants.currencySymbol}${item.rate.toStringAsFixed(2)}',
                      style: const pw.TextStyle(fontSize: 10)),
                  pw.Text(
                      '${AppConstants.currencySymbol}${item.amount.toStringAsFixed(2)}',
                      style: const pw.TextStyle(fontSize: 10)),
                ],
              ),
            )),
        pw.Divider(),
        pw.SizedBox(height: 8),
        pw.Row(
          mainAxisAlignment: pw.MainAxisAlignment.end,
          children: [
            pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.end,
              children: [
                pw.Text(
                    'Subtotal: ${AppConstants.currencySymbol}${data.subtotal.toStringAsFixed(2)}',
                    style: const pw.TextStyle(fontSize: 11)),
                if (data.taxAmount > 0)
                  pw.Text(
                      'Tax (${(data.taxRate * 100).toStringAsFixed(1)}%): ${AppConstants.currencySymbol}${data.taxAmount.toStringAsFixed(2)}',
                      style: const pw.TextStyle(fontSize: 11)),
                if (data.discount > 0)
                  pw.Text(
                      'Discount: -${AppConstants.currencySymbol}${data.discount.toStringAsFixed(2)}',
                      style: const pw.TextStyle(fontSize: 11)),
                pw.SizedBox(height: 4),
                pw.Text(
                    'TOTAL: ${AppConstants.currencySymbol}${data.total.toStringAsFixed(2)}',
                    style: pw.TextStyle(
                        fontSize: 14, fontWeight: pw.FontWeight.bold)),
              ],
            ),
          ],
        ),
        if (data.notes != null) ...[
          pw.SizedBox(height: 16),
          pw.Text(data.notes!,
              style: const pw.TextStyle(fontSize: 10)),
        ],
        pw.SizedBox(height: 24),
        pw.Center(
            child: pw.Text('Thank you for your business!',
                style: const pw.TextStyle(fontSize: 11))),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Recognized Bill'),
        backgroundColor: Colors.white,
        foregroundColor: AppTheme.primaryColor,
        elevation: 0,
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                if (widget.confidence < 0.6)
                  Container(
                    padding: const EdgeInsets.all(12),
                    margin: const EdgeInsets.only(bottom: 16),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFEF3C7),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: const Color(0xFFF59E0B)),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.warning_amber,
                            color: Color(0xFFF59E0B), size: 20),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'Some items may be incorrect. Please review before saving.',
                            style: TextStyle(
                              fontSize: 13,
                              color: Colors.brown.shade700,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ..._items.asMap().entries.map((entry) =>
                    _buildItemCard(entry.key, entry.value)),
                const SizedBox(height: 8),
                TextButton.icon(
                  onPressed: _addItem,
                  icon: const Icon(Icons.add, size: 18),
                  label: const Text('Add Item'),
                ),
                const Divider(height: 24),
                _buildTaxDiscountSection(),
                const Divider(height: 16),
                _buildTotals(),
              ],
            ),
          ),
          _buildActionButtons(),
        ],
      ),
    );
  }

  Widget _buildItemCard(int index, BillItemEditable item) {
    final isLowConfidence = item.confidence < 0.5 && item.name.isNotEmpty;

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
        side: isLowConfidence
            ? const BorderSide(color: Color(0xFFF59E0B), width: 1)
            : BorderSide.none,
      ),
      color: isLowConfidence ? const Color(0xFFFFF8E1) : null,
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: GestureDetector(
                    onTap: () => _editItem(index),
                    child: Text(
                      item.name.isNotEmpty ? item.name : 'Tap to edit',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w500,
                        color: item.name.isNotEmpty
                            ? Colors.black
                            : Colors.grey,
                      ),
                    ),
                  ),
                ),
                if (isLowConfidence)
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF59E0B).withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: const Text(
                      'May be incorrect',
                      style: TextStyle(
                        fontSize: 10,
                        color: Color(0xFF92400E),
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: _buildMiniField(
                    'Qty',
                    item.quantity.toString(),
                    () => _editItem(index),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _buildMiniField(
                    'Rate',
                    '${AppConstants.currencySymbol}${item.rate.toStringAsFixed(2)}',
                    () => _editItem(index),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _buildMiniField(
                    'Amount',
                    '${AppConstants.currencySymbol}${item.amount.toStringAsFixed(2)}',
                    null,
                    bold: true,
                  ),
                ),
                PopupMenuButton<String>(
                  onSelected: (value) {
                    if (value == 'edit') _editItem(index);
                    if (value == 'duplicate') _duplicateItem(index);
                    if (value == 'delete') _removeItem(index);
                    if (value == 'accept' && !item.isAccepted) {
                      _acceptItem(index);
                    }
                    if (value == 'reject' && item.isAccepted) {
                      _rejectItem(index);
                    }
                  },
                  itemBuilder: (ctx) => [
                    const PopupMenuItem(
                      value: 'edit',
                      child: ListTile(
                        leading: Icon(Icons.edit, size: 18),
                        title: Text('Edit'),
                        dense: true,
                        contentPadding: EdgeInsets.zero,
                      ),
                    ),
                    const PopupMenuItem(
                      value: 'duplicate',
                      child: ListTile(
                        leading: Icon(Icons.copy, size: 18),
                        title: Text('Duplicate'),
                        dense: true,
                        contentPadding: EdgeInsets.zero,
                      ),
                    ),
                    if (item.isAccepted)
                      const PopupMenuItem(
                        value: 'reject',
                        child: ListTile(
                          leading:
                              Icon(Icons.visibility_off, size: 18),
                          title: Text('Skip'),
                          dense: true,
                          contentPadding: EdgeInsets.zero,
                        ),
                      )
                    else
                      const PopupMenuItem(
                        value: 'accept',
                        child: ListTile(
                          leading: Icon(Icons.check_circle,
                              size: 18, color: Colors.green),
                          title: Text('Accept'),
                          dense: true,
                          contentPadding: EdgeInsets.zero,
                        ),
                      ),
                    const PopupMenuItem(
                      value: 'delete',
                      child: ListTile(
                        leading: Icon(Icons.delete_outline,
                            size: 18, color: Colors.red),
                        title: Text('Delete',
                            style: TextStyle(color: Colors.red)),
                        dense: true,
                        contentPadding: EdgeInsets.zero,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMiniField(
      String label, String value, VoidCallback? onTap,
      {bool bold = false}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
        decoration: BoxDecoration(
          color: Colors.grey.shade50,
          borderRadius: BorderRadius.circular(6),
          border: Border.all(color: Colors.grey.shade200),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label,
                style: TextStyle(
                    fontSize: 10, color: Colors.grey.shade500)),
            Text(
              value,
              style: TextStyle(
                fontSize: 13,
                fontWeight: bold ? FontWeight.w600 : FontWeight.normal,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTaxDiscountSection() {
    return Row(
      children: [
        Expanded(
          child: TextField(
            decoration: const InputDecoration(
              labelText: 'Tax %',
              isDense: true,
              border: OutlineInputBorder(),
            ),
            keyboardType:
                const TextInputType.numberWithOptions(decimal: true),
            onChanged: (v) {
              final rate = double.tryParse(v);
              if (rate != null && rate >= 0) {
                setState(() => _taxRate = rate / 100);
              }
            },
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: TextField(
            decoration: const InputDecoration(
              labelText: 'Discount',
              prefixText: '${AppConstants.currencySymbol} ',
              isDense: true,
              border: OutlineInputBorder(),
            ),
            keyboardType:
                const TextInputType.numberWithOptions(decimal: true),
            onChanged: (v) {
              final discount = double.tryParse(v);
              if (discount != null && discount >= 0) {
                setState(() => _discount = discount);
              }
            },
          ),
        ),
      ],
    );
  }

  Widget _buildTotals() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: Column(
        children: [
          _totalRow('Subtotal', _subtotal),
          if (_taxAmount > 0)
            _totalRow(
                'Tax (${(_taxRate * 100).toStringAsFixed(1)}%)',
                _taxAmount),
          if (_discount > 0) _totalRow('Discount', -_discount),
          const Divider(),
          _totalRow('Total', _total, bold: true, fontSize: 20),
        ],
      ),
    );
  }

  Widget _totalRow(String label, double amount,
      {bool bold = false, double fontSize = 14}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          Text(label,
              style: TextStyle(
                  fontWeight:
                      bold ? FontWeight.bold : FontWeight.normal,
                  fontSize: fontSize - 2)),
          const SizedBox(width: 16),
          SizedBox(
            width: 100,
            child: Text(
              '${AppConstants.currencySymbol}${amount.abs().toStringAsFixed(2)}',
              textAlign: TextAlign.right,
              style: TextStyle(
                fontWeight:
                    bold ? FontWeight.bold : FontWeight.normal,
                fontSize: fontSize,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButtons() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        border: Border(top: BorderSide(color: Colors.grey.shade200)),
      ),
      child: SafeArea(
        top: false,
        child: Row(
          children: [
            Expanded(
              child: OutlinedButton.icon(
                icon: const Icon(Icons.print_outlined, size: 18),
                label: const Text('Print'),
                onPressed: _printBill,
                style: OutlinedButton.styleFrom(
                  minimumSize: const Size(0, 48),
                ),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              flex: 2,
              child: FilledButton.icon(
                icon: _isSaving
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : const Icon(Icons.save, size: 18),
                label: Text(_isSaving ? 'Saving...' : 'Save Bill'),
                onPressed: _isSaving ? null : _saveBill,
                style: FilledButton.styleFrom(
                  minimumSize: const Size(0, 48),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
