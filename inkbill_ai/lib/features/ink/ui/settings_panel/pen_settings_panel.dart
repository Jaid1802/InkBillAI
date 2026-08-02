import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:scribble/scribble.dart';
import 'package:inkbill_ai/core/theme/app_theme.dart';
import 'package:inkbill_ai/features/ink/handwriting_engine/scribble_adapter/ink_controller.dart';

class PenSettingsPanel extends ConsumerWidget {
  final VoidCallback onClear;

  const PenSettingsPanel({super.key, required this.onClear});

  static const _colors = [
    Color(0xFF212121),
    Color(0xFF1A237E),
    Color(0xFFB71C1C),
    Color(0xFF1B5E20),
    Color(0xFFE65100),
    Color(0xFF4A148C),
    Color(0xFF01579B),
    Color(0xFF33691E),
  ];

  static const _widths = [2.0, 3.0, 5.0, 8.0, 12.0];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final notifier = ref.read(inkControllerProvider);
    final state = notifier.value;
    final currentColor = state is Drawing ? Color(state.selectedColor) : Colors.black;
    final currentWidth = state.selectedWidth;

    return Container(
      width: 220,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Pen Color', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
            const SizedBox(height: 8),
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: _colors.map((c) {
                final isSelected = currentColor.toARGB32() == c.toARGB32();
                return GestureDetector(
                  onTap: () => notifier.setColor(c),
                  child: Container(
                    width: 32,
                    height: 32,
                    decoration: BoxDecoration(
                      color: c,
                      borderRadius: BorderRadius.circular(8),
                      border: isSelected
                          ? Border.all(color: AppTheme.primaryColor, width: 2.5)
                          : null,
                      boxShadow: isSelected
                          ? [BoxShadow(color: AppTheme.primaryColor.withValues(alpha: 0.3), blurRadius: 4)]
                          : null,
                    ),
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 16),
            const Text('Thickness', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
            const SizedBox(height: 8),
            Row(
              children: _widths.map((w) {
                final isSelected = currentWidth == w;
                return Expanded(
                  child: GestureDetector(
                    onTap: () => notifier.setStrokeWidth(w),
                    child: Container(
                      height: 36,
                      margin: const EdgeInsets.symmetric(horizontal: 2),
                      decoration: BoxDecoration(
                        color: isSelected
                            ? AppTheme.primaryColor.withValues(alpha: 0.12)
                            : Colors.grey.withValues(alpha: 0.08),
                        borderRadius: BorderRadius.circular(8),
                        border: isSelected
                            ? Border.all(color: AppTheme.primaryColor, width: 1.5)
                            : null,
                      ),
                      child: Center(
                        child: Container(
                          width: 20,
                          height: w.clamp(1.0, 12.0),
                          decoration: BoxDecoration(
                            color: currentColor,
                            borderRadius: BorderRadius.circular(w),
                          ),
                        ),
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: onClear,
                icon: const Icon(Icons.delete_outline, size: 18),
                label: const Text('Clear All'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: Colors.red.shade700,
                  side: BorderSide(color: Colors.red.shade200),
                  minimumSize: const Size(0, 40),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
