import 'package:flutter/material.dart';
import 'package:inkbill_ai/core/theme/app_theme.dart';

class ToolButton extends StatelessWidget {
  final IconData icon;
  final String tooltip;
  final VoidCallback? onTap;
  final bool isSelected;
  final bool enabled;
  final bool showLoader;

  const ToolButton({
    super.key,
    required this.icon,
    required this.tooltip,
    this.onTap,
    this.isSelected = false,
    this.enabled = true,
    this.showLoader = false,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    const primary = AppTheme.primaryColor;

    return Tooltip(
      message: tooltip,
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: enabled ? onTap : null,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            color: isSelected
                ? primary.withValues(alpha: 0.15)
                : Colors.transparent,
            borderRadius: BorderRadius.circular(12),
          ),
          child: showLoader
              ? const Center(
                  child: SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
                )
              : Icon(
                  icon,
                  size: 24,
                  color: isSelected
                      ? primary
                      : (enabled
                          ? colorScheme.onSurface.withValues(alpha: 0.7)
                          : colorScheme.onSurface.withValues(alpha: 0.3)),
                ),
        ),
      ),
    );
  }
}

class ToolDivider extends StatelessWidget {
  const ToolDivider({super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8),
      child: Container(
        width: 1,
        height: 24,
        color: Theme.of(context).dividerColor.withValues(alpha: 0.5),
      ),
    );
  }
}
