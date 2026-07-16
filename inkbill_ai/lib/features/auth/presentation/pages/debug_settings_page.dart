import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:inkbill_ai/core/constants/app_constants.dart';
import 'package:inkbill_ai/core/database/database_provider.dart';

class DebugSettingsPage extends ConsumerWidget {
  const DebugSettingsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final db = ref.read(databaseProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Debug Settings'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _SectionHeader(title: 'App Info'),
          Card(
            child: Column(
              children: [
                _InfoTile(label: 'App Version', value: AppConstants.version),
                _InfoTile(
                    label: 'Database Version',
                    value: '${AppConstants.databaseVersion}'),
              ],
            ),
          ),
          const SizedBox(height: 24),
          _SectionHeader(title: 'Developer Tools'),
          Card(
            child: Column(
              children: [
                ListTile(
                  leading: const Icon(Icons.storage),
                  title: const Text('Clear All Data'),
                  subtitle: const Text('Delete all local bills, strokes, and customers'),
                  onTap: () async {
                    final confirm = await showDialog<bool>(
                      context: context,
                      builder: (ctx) => AlertDialog(
                        title: const Text('Clear All Data'),
                        content: const Text(
                            'This will permanently delete all local data. This cannot be undone.'),
                        actions: [
                          TextButton(
                              onPressed: () => Navigator.pop(ctx, false),
                              child: const Text('Cancel')),
                          TextButton(
                              onPressed: () => Navigator.pop(ctx, true),
                              style: TextButton.styleFrom(foregroundColor: Colors.red),
                              child: const Text('Clear')),
                        ],
                      ),
                    );
                    if (confirm == true) {
                      await db.clearAllData();
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('All data cleared')),
                        );
                      }
                    }
                  },
                ),
                const Divider(height: 1, indent: 16, endIndent: 16),
                ListTile(
                  leading: const Icon(Icons.info_outline),
                  title: const Text('Database Info'),
                  subtitle: const Text('View database tables and counts'),
                  onTap: () async {
                    final bills = await db.select(db.bills).get();
                    final strokes = await db.select(db.inkStrokes).get();
                    final pages = await db.select(db.inkPages).get();
                    final customers = await db.select(db.customers).get();
                    final products = await db.select(db.products).get();
                    final billCount = bills.length;
                    final strokeCount = strokes.length;
                    final pageCount = pages.length;
                    final customerCount = customers.length;
                    final productCount = products.length;

                    if (context.mounted) {
                      showDialog(
                        context: context,
                        builder: (ctx) => AlertDialog(
                          title: const Text('Database Info'),
                          content: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              _DbInfoRow('Bills', billCount),
                              _DbInfoRow('Bill Items', 0),
                              _DbInfoRow('Customers', customerCount),
                              _DbInfoRow('Products', productCount),
                              _DbInfoRow('Ink Pages', pageCount),
                              _DbInfoRow('Ink Strokes', strokeCount),
                            ],
                          ),
                          actions: [
                            TextButton(
                                onPressed: () => Navigator.pop(ctx),
                                child: const Text('Close')),
                          ],
                        ),
                      );
                    }
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _DbInfoRow extends StatelessWidget {
  final String label;
  final int count;

  const _DbInfoRow(this.label, this.count);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label),
          Text(count.toString(),
              style: const TextStyle(fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final String title;
  const _SectionHeader({required this.title});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8, left: 4),
      child: Text(
        title,
        style: TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w600,
          color: Colors.grey.shade600,
          letterSpacing: 0.5,
        ),
      ),
    );
  }
}

class _InfoTile extends StatelessWidget {
  final String label;
  final String value;

  const _InfoTile({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return ListTile(
      title: Text(label),
      trailing: Text(value,
          style: const TextStyle(fontWeight: FontWeight.bold)),
    );
  }
}
