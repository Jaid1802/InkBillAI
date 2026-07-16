import 'package:flutter/material.dart';

class PrintOptionsBottomSheet extends StatelessWidget {
  final VoidCallback onPrint;
  final VoidCallback onSavePdf;
  final VoidCallback onSaveHistory;

  const PrintOptionsBottomSheet({
    super.key,
    required this.onPrint,
    required this.onSavePdf,
    required this.onSaveHistory,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 24, left: 24, right: 24, top: 24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Center(
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey.shade300,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 24),
          Text(
            'Print / Save Options',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          Text(
            'Choose how you want to share this receipt.',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: Colors.grey.shade600),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          ListTile(
            leading: const Icon(Icons.print),
            title: const Text('Print via Bluetooth/Wi-Fi'),
            onTap: () {
              Navigator.of(context).pop();
              onPrint();
            },
          ),
          const Divider(),
          ListTile(
            leading: const Icon(Icons.picture_as_pdf),
            title: const Text('Save as PDF'),
            onTap: () {
              Navigator.of(context).pop();
              onSavePdf();
            },
          ),
          const Divider(),
          ListTile(
            leading: const Icon(Icons.save),
            title: const Text('Save to History only'),
            onTap: () {
              Navigator.of(context).pop();
              onSaveHistory();
            },
          ),
          const SizedBox(height: 16),
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
        ],
      ),
    );
  }
}
