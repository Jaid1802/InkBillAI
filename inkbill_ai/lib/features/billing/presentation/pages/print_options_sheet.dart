import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:inkbill_ai/core/theme/app_theme.dart';
import 'package:inkbill_ai/core/constants/app_constants.dart';
import 'package:inkbill_ai/features/billing/domain/entities/bill.dart';
import 'package:inkbill_ai/services/receipt_generator/receipt_generator.dart';
import 'package:printing/printing.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:pdf/pdf.dart';
import 'package:share_plus/share_plus.dart';
import 'package:path_provider/path_provider.dart';

class PrintOptionsSheet extends StatefulWidget {
  final Bill bill;

  const PrintOptionsSheet({super.key, required this.bill});

  @override
  State<PrintOptionsSheet> createState() => _PrintOptionsSheetState();
}

class _PrintOptionsSheetState extends State<PrintOptionsSheet> {
  bool _hasThermalPrinter = false;

  @override
  void initState() {
    super.initState();
    _checkThermalPrinter();
  }

  Future<void> _checkThermalPrinter() async {
    try {
      final result = await const MethodChannel('inkbill/printer')
          .invokeMethod('isThermalPrinterAvailable');
      if (mounted) {
        setState(() => _hasThermalPrinter = result == true);
      }
    } catch (_) {}
  }

  Future<Uint8List> _generatePdf(
      ReceiptData data, PdfPageFormat format) async {
    final doc = pw.Document();
    doc.addPage(
      pw.Page(
        pageFormat: format,
        margin: const pw.EdgeInsets.all(32),
        build: (pw.Context context) => _buildPdfReceipt(data),
      ),
    );
    return doc.save();
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
        pw.SizedBox(height: 8),
        pw.Divider(),
        ...data.items.map((item) => pw.Padding(
              padding: const pw.EdgeInsets.symmetric(vertical: 2),
              child: pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Text(item.name,
                      style: const pw.TextStyle(fontSize: 10)),
                  pw.Text('${item.quantity}',
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
                      'Tax: ${AppConstants.currencySymbol}${data.taxAmount.toStringAsFixed(2)}',
                      style: const pw.TextStyle(fontSize: 11)),
                if (data.discount > 0)
                  pw.Text(
                      'Discount: -${AppConstants.currencySymbol}${data.discount.toStringAsFixed(2)}',
                      style: const pw.TextStyle(fontSize: 11)),
                pw.SizedBox(height: 4),
                pw.Text(
                    'TOTAL: ${AppConstants.currencySymbol}${data.total.toStringAsFixed(2)}',
                    style: pw.TextStyle(
                        fontSize: 14,
                        fontWeight: pw.FontWeight.bold)),
              ],
            ),
          ],
        ),
      ],
    );
  }

  Future<void> _printThermal() async {
    try {
      await const MethodChannel('inkbill/printer')
          .invokeMethod('printThermal', {'billId': widget.bill.id});
      if (mounted) Navigator.pop(context);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Print failed: $e')),
        );
      }
    }
  }

  Future<void> _printPdf() async {
    final receiptData =
        ReceiptData.fromBill(widget.bill, storeName: 'InkBill AI');
    await Printing.layoutPdf(
      onLayout: (format) => _generatePdf(receiptData, format),
      name: 'Bill_${widget.bill.id}',
    );
  }

  Future<void> _savePdf() async {
    final receiptData =
        ReceiptData.fromBill(widget.bill, storeName: 'InkBill AI');
    final pdfBytes = await _generatePdf(receiptData, PdfPageFormat.a4);
    final dir = await getApplicationDocumentsDirectory();
    final file = File('${dir.path}/Bill_${widget.bill.id}.pdf');
    await file.writeAsBytes(pdfBytes);
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('PDF saved to ${file.path}')),
      );
      Navigator.pop(context);
    }
  }

  Future<void> _sharePdf() async {
    final receiptData =
        ReceiptData.fromBill(widget.bill, storeName: 'InkBill AI');
    final pdfBytes = await _generatePdf(receiptData, PdfPageFormat.a4);
    final dir = await getApplicationDocumentsDirectory();
    final file = File('${dir.path}/Bill_${widget.bill.id}.pdf');
    await file.writeAsBytes(pdfBytes);
    await Share.shareXFiles(
      [XFile(file.path)],
      subject: 'Bill ${widget.bill.id}',
    );
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Print Bill',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 20),
            if (_hasThermalPrinter) ...[
              _PrintOption(
                icon: Icons.print,
                title: 'Thermal Printer',
                subtitle: 'Print on 80mm or 58mm thermal paper',
                onTap: _printThermal,
              ),
              const SizedBox(height: 8),
            ],
            _PrintOption(
              icon: Icons.picture_as_pdf,
              title: 'Android Print',
              subtitle: 'Print via system printing service',
              onTap: _printPdf,
            ),
            const SizedBox(height: 8),
            _PrintOption(
              icon: Icons.save_alt,
              title: 'Save PDF',
              subtitle: 'Save bill as PDF document',
              onTap: _savePdf,
            ),
            const SizedBox(height: 8),
            _PrintOption(
              icon: Icons.share,
              title: 'Share PDF',
              subtitle: 'Share via email or other apps',
              onTap: _sharePdf,
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton(
                onPressed: () => Navigator.pop(context),
                style: OutlinedButton.styleFrom(
                  minimumSize: const Size(0, 48),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: const Text('Cancel'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _PrintOption extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  const _PrintOption({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: ListTile(
        leading: Icon(icon, color: AppTheme.primaryColor),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.w500)),
        subtitle: Text(subtitle, style: const TextStyle(fontSize: 12)),
        trailing: const Icon(Icons.chevron_right),
        onTap: onTap,
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      ),
    );
  }
}
