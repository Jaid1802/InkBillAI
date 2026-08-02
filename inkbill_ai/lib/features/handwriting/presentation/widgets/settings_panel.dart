import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:inkbill_ai/core/theme/app_theme.dart';
import 'package:inkbill_ai/features/handwriting/presentation/providers/canvas_provider.dart';
import 'package:inkbill_ai/services/canvas_engine/canvas_engine.dart';

class SettingsPanel extends ConsumerWidget {
  final String pageId;
  final VoidCallback onClear;

  const SettingsPanel({
    super.key,
    required this.pageId,
    required this.onClear,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final engine = ref.read(canvasEngineProvider(pageId));
    final state = ref.watch(canvasStateProvider(pageId));

    return Container(
      width: 280,
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
            _SectionTitle(title: 'Stroke Color'),
            const SizedBox(height: 8),
            _ColorPicker(
              selectedColor: state.penColor,
              onColorSelected: engine.setPenColor,
            ),
            const SizedBox(height: 20),
            
            _SectionTitle(title: 'Stroke Width'),
            const SizedBox(height: 8),
            _WidthPicker(
              selectedWidth: state.penWidth,
              onWidthSelected: engine.setPenWidth,
            ),
            const SizedBox(height: 20),

            _SectionTitle(title: 'Opacity'),
            Slider(
              value: state.penOpacity,
              min: 0.1,
              max: 1.0,
              activeColor: AppTheme.primaryColor,
              onChanged: engine.setPenOpacity,
            ),
            const SizedBox(height: 10),

            _SectionTitle(title: 'Eraser Size'),
            Slider(
              value: state.eraserSize,
              min: 10.0,
              max: 100.0,
              activeColor: AppTheme.primaryColor,
              onChanged: engine.setEraserSize,
            ),
            const SizedBox(height: 10),

            _SectionTitle(title: 'Background'),
            const SizedBox(height: 8),
            _BackgroundPicker(
              selectedBg: state.background,
              onBgSelected: engine.setBackground,
            ),
            
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                icon: const Icon(Icons.delete_outline),
                label: const Text('Clear Canvas'),
                onPressed: state.strokes.isEmpty ? null : onClear,
                style: OutlinedButton.styleFrom(
                  foregroundColor: Colors.red,
                  side: BorderSide(color: state.strokes.isEmpty ? Colors.grey.shade300 : Colors.red.shade200),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  final String title;
  const _SectionTitle({required this.title});

  @override
  Widget build(BuildContext context) {
    return Text(
      title,
      style: TextStyle(
        fontSize: 12,
        fontWeight: FontWeight.w600,
        color: Colors.grey.shade600,
        letterSpacing: 0.5,
      ),
    );
  }
}

class _ColorPicker extends StatelessWidget {
  final int selectedColor;
  final ValueChanged<int> onColorSelected;

  const _ColorPicker({
    required this.selectedColor,
    required this.onColorSelected,
  });

  static const _colors = [
    0xFF121212, // Black
    0xFFE53935, // Red
    0xFF43A047, // Green
    0xFF1E88E5, // Blue
    0xFFFFB300, // Amber
  ];

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: _colors.map((c) {
        final isSelected = c == selectedColor;
        return GestureDetector(
          onTap: () => onColorSelected(c),
          child: Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: Color(c),
              shape: BoxShape.circle,
              border: Border.all(
                color: isSelected ? AppTheme.primaryColor : Colors.transparent,
                width: 3,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.1),
                  blurRadius: 4,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }
}

class _WidthPicker extends StatelessWidget {
  final double selectedWidth;
  final ValueChanged<double> onWidthSelected;

  const _WidthPicker({
    required this.selectedWidth,
    required this.onWidthSelected,
  });

  static const _widths = [2.0, 4.0, 8.0, 12.0];

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: _widths.map((w) {
        final isSelected = w == selectedWidth;
        return GestureDetector(
          onTap: () => onWidthSelected(w),
          child: Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: isSelected ? AppTheme.primaryColor.withValues(alpha: 0.1) : Colors.grey.shade50,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: isSelected ? AppTheme.primaryColor : Colors.grey.shade200,
              ),
            ),
            child: Center(
              child: Container(
                width: w * 2,
                height: w * 2,
                decoration: BoxDecoration(
                  color: isSelected ? AppTheme.primaryColor : Colors.grey.shade800,
                  shape: BoxShape.circle,
                ),
              ),
            ),
          ),
        );
      }).toList(),
    );
  }
}

class _BackgroundPicker extends StatelessWidget {
  final CanvasBackground selectedBg;
  final ValueChanged<CanvasBackground> onBgSelected;

  const _BackgroundPicker({
    required this.selectedBg,
    required this.onBgSelected,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        _BgOption(
          label: 'Blank',
          icon: Icons.crop_square,
          isSelected: selectedBg == CanvasBackground.blank,
          onTap: () => onBgSelected(CanvasBackground.blank),
        ),
        const SizedBox(width: 8),
        _BgOption(
          label: 'Ruled',
          icon: Icons.notes,
          isSelected: selectedBg == CanvasBackground.ruled,
          onTap: () => onBgSelected(CanvasBackground.ruled),
        ),
        const SizedBox(width: 8),
        _BgOption(
          label: 'Grid',
          icon: Icons.grid_on,
          isSelected: selectedBg == CanvasBackground.grid,
          onTap: () => onBgSelected(CanvasBackground.grid),
        ),
      ],
    );
  }
}

class _BgOption extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool isSelected;
  final VoidCallback onTap;

  const _BgOption({
    required this.label,
    required this.icon,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: isSelected ? AppTheme.primaryColor.withValues(alpha: 0.1) : Colors.grey.shade50,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isSelected ? AppTheme.primaryColor : Colors.grey.shade200,
            ),
          ),
          child: Column(
            children: [
              Icon(
                icon,
                size: 20,
                color: isSelected ? AppTheme.primaryColor : Colors.grey.shade600,
              ),
              const SizedBox(height: 4),
              Text(
                label,
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                  color: isSelected ? AppTheme.primaryColor : Colors.grey.shade700,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
