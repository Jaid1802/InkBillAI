import 'package:flutter/material.dart';
import 'package:inkbill_ai/core/theme/app_theme.dart';

class NavButton extends StatelessWidget {
  final IconData icon;
  final String tooltip;
  final VoidCallback onTap;
  final VoidCallback onLongPressStart;
  final VoidCallback onLongPressEnd;

  const NavButton({
    super.key,
    required this.icon,
    required this.tooltip,
    required this.onTap,
    required this.onLongPressStart,
    required this.onLongPressEnd,
  });

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tooltip,
      child: GestureDetector(
        onTap: onTap,
        onLongPressStart: (_) => onLongPressStart(),
        onLongPressEnd: (_) => onLongPressEnd(),
        onLongPressCancel: onLongPressEnd,
        child: Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.12),
                blurRadius: 6,
                offset: const Offset(0, 1),
              ),
            ],
          ),
          child: Icon(icon, size: 22, color: AppTheme.primaryColor),
        ),
      ),
    );
  }
}
