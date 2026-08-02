import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:inkbill_ai/core/theme/app_theme.dart';
import 'package:inkbill_ai/features/handwriting/presentation/providers/canvas_provider.dart';
import 'package:inkbill_ai/services/canvas_engine/canvas_engine.dart';

class FloatingToolbar extends ConsumerWidget {
  final String pageId;
  final VoidCallback onToggleMenu;
  final VoidCallback onRecognize;
  final VoidCallback onSave;
  final VoidCallback onZoomToggle;
  final bool isMenuOpen;
  final bool isRecognizing;

  const FloatingToolbar({
    super.key,
    required this.pageId,
    required this.onToggleMenu,
    required this.onRecognize,
    required this.onSave,
    required this.onZoomToggle,
    this.isMenuOpen = false,
    this.isRecognizing = false,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final engine = ref.read(canvasEngineProvider(pageId));
    final state = ref.watch(canvasStateProvider(pageId));

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
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
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _ToolBtn(
            icon: isMenuOpen ? Icons.menu_open : Icons.menu,
            tooltip: 'Settings Menu',
            isSelected: isMenuOpen,
            onTap: onToggleMenu,
          ),
          const _Divider(),
          _ToolBtn(
            icon: Icons.edit,
            tooltip: 'Pen',
            isSelected: state.mode == CanvasMode.draw,
            onTap: () => engine.setMode(CanvasMode.draw),
          ),
          const SizedBox(width: 4),
          _ToolBtn(
            icon: Icons.backspace_outlined,
            tooltip: 'Eraser',
            isSelected: state.mode == CanvasMode.erase,
            onTap: () => engine.setMode(CanvasMode.erase),
          ),
          const _Divider(),
          _ToolBtn(
            icon: Icons.undo,
            tooltip: 'Undo',
            enabled: state.canUndo,
            onTap: () => engine.undo(),
          ),
          const SizedBox(width: 4),
          _ToolBtn(
            icon: Icons.redo,
            tooltip: 'Redo',
            enabled: state.canRedo,
            onTap: () => engine.redo(),
          ),
          const _Divider(),
          _ToolBtn(
            icon: Icons.zoom_out_map,
            tooltip: 'Reset Zoom',
            onTap: onZoomToggle,
          ),
          const _Divider(),
          _ToolBtn(
            icon: Icons.document_scanner,
            tooltip: 'Recognize',
            enabled: state.strokes.isNotEmpty && !isRecognizing,
            showLoader: isRecognizing,
            isSelected: isRecognizing,
            onTap: onRecognize,
          ),
          const SizedBox(width: 4),
          _ToolBtn(
            icon: Icons.save_alt,
            tooltip: 'Save Bill',
            onTap: onSave,
          ),
          const _Divider(),
          _ToolBtn(
            icon: Icons.touch_app,
            tooltip: 'Finger Writing',
            isSelected: state.inputMode == InputMode.finger,
            onTap: () => engine.setInputMode(InputMode.finger),
          ),
          const SizedBox(width: 4),
          _ToolBtn(
            icon: Icons.brush,
            tooltip: 'Stylus Only',
            isSelected: state.inputMode == InputMode.stylus,
            onTap: () => engine.setInputMode(InputMode.stylus),
          ),
        ],
      ),
    );
  }
}

class _ToolBtn extends StatelessWidget {
  final IconData icon;
  final String tooltip;
  final VoidCallback? onTap;
  final bool isSelected;
  final bool enabled;
  final bool showLoader;

  const _ToolBtn({
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

class _Divider extends StatelessWidget {
  const _Divider();

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
