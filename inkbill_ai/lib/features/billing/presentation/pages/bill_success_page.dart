import 'package:flutter/material.dart';
import 'package:inkbill_ai/core/constants/app_constants.dart';
import 'package:inkbill_ai/features/billing/domain/entities/bill.dart';
import 'package:inkbill_ai/features/billing/presentation/pages/print_options_sheet.dart';
import 'package:inkbill_ai/widgets/shared/app_shell.dart';

class BillSuccessPage extends StatelessWidget {
  final Bill bill;

  const BillSuccessPage({super.key, required this.bill});

  @override
  Widget build(BuildContext context) {
    final billRef = bill.id.length > 8
        ? bill.id.substring(bill.id.length - 8)
        : bill.id;

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Spacer(flex: 2),
              Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  color: const Color(0xFF0D9488).withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.check_circle,
                  size: 48,
                  color: Color(0xFF0D9488),
                ),
              ),
              const SizedBox(height: 24),
              const Text(
                'Bill Saved!',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF0D9488),
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Receipt #$billRef',
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.grey.shade600,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                '${AppConstants.currencySymbol}${bill.total.toStringAsFixed(2)}',
                style: const TextStyle(
                  fontSize: 36,
                  fontWeight: FontWeight.bold,
                  color: Colors.black,
                ),
              ),
              const SizedBox(height: 8),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                decoration: BoxDecoration(
                  color: const Color(0xFF0D9488).withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: const Text(
                  'AI Accuracy: High',
                  style: TextStyle(
                    fontSize: 12,
                    color: Color(0xFF0D9488),
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
              const Spacer(),
              SizedBox(
                width: double.infinity,
                child: FilledButton.icon(
                  onPressed: () {
                    showModalBottomSheet(
                      context: context,
                      shape: const RoundedRectangleBorder(
                        borderRadius:
                            BorderRadius.vertical(top: Radius.circular(20)),
                      ),
                      builder: (_) => PrintOptionsSheet(bill: bill),
                    );
                  },
                  icon: const Icon(Icons.print),
                  label: const Text('Print Bill'),
                  style: FilledButton.styleFrom(
                    minimumSize: const Size(0, 52),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: () {
                    Navigator.of(context).pushAndRemoveUntil(
                      MaterialPageRoute(
                        builder: (_) => const AppShell(initialIndex: 0),
                      ),
                      (route) => false,
                    );
                  },
                  icon: const Icon(Icons.dashboard_outlined),
                  label: const Text('Dashboard'),
                  style: OutlinedButton.styleFrom(
                    minimumSize: const Size(0, 52),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 8),
              TextButton(
                onPressed: () {
                  Navigator.of(context).pushAndRemoveUntil(
                    MaterialPageRoute(
                      builder: (_) => const AppShell(initialIndex: 2),
                    ),
                    (route) => false,
                  );
                },
                child: const Text('Create New Bill'),
              ),
              const Spacer(),
            ],
          ),
        ),
      ),
    );
  }
}
