import 'package:flutter/material.dart';
import 'package:inkbill_ai/core/theme/app_theme.dart';

class InkOcrSheet extends StatefulWidget {
  final String recognizedText;
  final Future<void> Function(String text) onCalculateBill;
  final Future<void> Function(String text) onSaveBill;
  final Future<void> Function(String text) onPrint;

  const InkOcrSheet({
    super.key,
    required this.recognizedText,
    required this.onCalculateBill,
    required this.onSaveBill,
    required this.onPrint,
  });

  @override
  State<InkOcrSheet> createState() => _InkOcrSheetState();
}

class _InkOcrSheetState extends State<InkOcrSheet> {
  late TextEditingController _textCtrl;

  @override
  void initState() {
    super.initState();
    _textCtrl = TextEditingController(text: widget.recognizedText);
  }

  @override
  void dispose() {
    _textCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: EdgeInsets.only(
          left: 20,
          right: 20,
          top: 20,
          bottom: MediaQuery.of(context).viewInsets.bottom + 20,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Recognized Text',
                  style: TextStyle(fontWeight: FontWeight.w600, fontSize: 18),
                ),
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Container(
              width: double.infinity,
              constraints: const BoxConstraints(maxHeight: 240),
              decoration: BoxDecoration(
                color: Colors.grey.shade50,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.grey.shade200),
              ),
              child: TextField(
                controller: _textCtrl,
                maxLines: null,
                style: const TextStyle(fontSize: 15, height: 1.5),
                decoration: const InputDecoration(
                  contentPadding: EdgeInsets.all(16),
                  border: InputBorder.none,
                  hintText: 'Edit recognized text...',
                ),
              ),
            ),
            const SizedBox(height: 20),
            Row(
              children: [
                Expanded(
                  child: _ActionBtn(
                    icon: Icons.calculate_outlined,
                    label: 'Calculate Bill',
                    color: AppTheme.primaryColor,
                    onTap: () => _onAction(widget.onCalculateBill),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _ActionBtn(
                    icon: Icons.save_outlined,
                    label: 'Save Bill',
                    color: Colors.green.shade600,
                    onTap: () => _onAction(widget.onSaveBill),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(
                  child: _ActionBtn(
                    icon: Icons.edit_outlined,
                    label: 'Edit',
                    color: Colors.orange.shade600,
                    onTap: () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Edit the text above and choose an action')),
                      );
                    },
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _ActionBtn(
                    icon: Icons.print_outlined,
                    label: 'Print',
                    color: Colors.grey.shade700,
                    onTap: () => _onAction(widget.onPrint),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _onAction(Future<void> Function(String text) action) async {
    final text = _textCtrl.text.trim();
    if (text.isEmpty) return;

    final overlay = Overlay.of(context);
    late OverlayEntry entry;
    entry = OverlayEntry(
      builder: (_) => const Center(
        child: Card(
          child: Padding(
            padding: EdgeInsets.all(24),
            child: CircularProgressIndicator(),
          ),
        ),
      ),
    );
    overlay.insert(entry);

    try {
      await action(text);
      if (mounted) Navigator.pop(context);
    } finally {
      entry.remove();
    }
  }
}

class _ActionBtn extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  const _ActionBtn({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 48,
      child: OutlinedButton.icon(
        onPressed: onTap,
        icon: Icon(icon, size: 18),
        label: Text(label, style: const TextStyle(fontSize: 13)),
        style: OutlinedButton.styleFrom(
          foregroundColor: color,
          side: BorderSide(color: color.withValues(alpha: 0.3)),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
        ),
      ),
    );
  }
}
