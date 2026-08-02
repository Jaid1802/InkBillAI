import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:scribble/scribble.dart';
import 'package:inkbill_ai/features/ink/handwriting_engine/input_mode_controller/input_mode.dart';
import 'package:inkbill_ai/features/ink/handwriting_engine/scribble_adapter/ink_controller.dart';
import 'package:inkbill_ai/features/ink/ui/common/tool_button.dart';

class InkToolbar extends ConsumerWidget {
  final VoidCallback onToggleMenu;
  final bool isMenuOpen;

  const InkToolbar({
    super.key,
    required this.onToggleMenu,
    this.isMenuOpen = false,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final notifier = ref.read(inkControllerProvider);
    final state = notifier.value;
    final inputMode = ref.watch(inkInputModeProvider);

    return Container(
      height: 52,
      padding: const EdgeInsets.symmetric(horizontal: 4),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        border: Border(
          bottom: BorderSide(color: Colors.grey.withValues(alpha: 0.12)),
        ),
      ),
      child: Row(
        children: [
          ToolButton(
            icon: isMenuOpen ? Icons.menu_open : Icons.menu,
            tooltip: 'Pen Settings',
            isSelected: isMenuOpen,
            onTap: onToggleMenu,
          ),
          const ToolDivider(),
          ToolButton(
            icon: Icons.edit,
            tooltip: 'Pen',
            isSelected: state is Drawing,
            onTap: () => notifier.setColor(
              state is Drawing ? Color(state.selectedColor) : Colors.black,
            ),
          ),
          const ToolDivider(),
          ToolButton(
            icon: Icons.touch_app,
            tooltip: 'Finger Writing',
            isSelected: inputMode == InkInputMode.finger,
            onTap: () => ref.read(inkInputModeProvider.notifier).setMode(InkInputMode.finger),
          ),
          ToolButton(
            icon: Icons.brush,
            tooltip: 'Stylus Only',
            isSelected: inputMode == InkInputMode.stylus,
            onTap: () => ref.read(inkInputModeProvider.notifier).setMode(InkInputMode.stylus),
          ),
          const ToolDivider(),
          ToolButton(
            icon: Icons.backspace_outlined,
            tooltip: 'Eraser',
            isSelected: state is Erasing,
            onTap: () {
              if (state is Erasing) {
                notifier.setColor(Colors.black);
              } else {
                notifier.setEraser();
              }
            },
          ),
          const Spacer(),
          ToolButton(
            icon: Icons.undo,
            tooltip: 'Undo',
            enabled: notifier.canUndo,
            onTap: () => notifier.undo(),
          ),
          ToolButton(
            icon: Icons.redo,
            tooltip: 'Redo',
            enabled: notifier.canRedo,
            onTap: () => notifier.redo(),
          ),
          const SizedBox(width: 4),
        ],
      ),
    );
  }
}
