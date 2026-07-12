import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:inkbill_ai/features/handwriting/presentation/providers/ink_engine_provider.dart';
import 'package:inkbill_ai/features/handwriting/presentation/widgets/ink_canvas.dart';
import 'package:inkbill_ai/features/timeline/presentation/widgets/ink_timeline_widget.dart';
import 'package:inkbill_ai/services/ink_engine/ink_engine.dart';

class InkNotePage extends ConsumerStatefulWidget {
  const InkNotePage({super.key});

  @override
  ConsumerState<InkNotePage> createState() => _InkNotePageState();
}

class _InkNotePageState extends ConsumerState<InkNotePage> {
  final String _pageId = 'page_${DateTime.now().microsecondsSinceEpoch}';
  bool _showTimeline = false;
  bool _showTools = true;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Ink Note'),
        actions: [
          IconButton(
            icon: Icon(_showTimeline ? Icons.timeline : Icons.timeline_outlined),
            tooltip: 'Ink Timeline',
            onPressed: () => setState(() => _showTimeline = !_showTimeline),
          ),
        ],
      ),
      body: Column(
        children: [
          if (_showTools) _buildToolbar(),
          Expanded(
            child: _showTimeline
                ? const Padding(
                    padding: EdgeInsets.all(16),
                    child: InkTimelineWidget(),
                  )
                : InkCanvas(
                    pageId: _pageId,
                    width: MediaQuery.of(context).size.width,
                    height: MediaQuery.of(context).size.height - 200,
                  ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        mini: true,
        onPressed: () => setState(() => _showTools = !_showTools),
        child: Icon(_showTools ? Icons.touch_app : Icons.tune),
      ),
    );
  }

  Widget _buildToolbar() {
    final engine = ref.read(inkEngineProvider(_pageId));
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        border: Border(bottom: BorderSide(color: Colors.grey.shade200)),
      ),
      child: Row(
        children: [
          _ToolButton(
            icon: Icons.undo,
            tooltip: 'Undo',
            onPressed: engine.undo,
          ),
          _ToolButton(
            icon: Icons.clear_all,
            tooltip: 'Clear',
            onPressed: engine.clear,
          ),
          const VerticalDivider(),
          _ToolButton(
            icon: Icons.edit,
            tooltip: 'Draw mode',
            isSelected: engine.value.mode == InkEngineMode.draw,
            onPressed: () => engine.setMode(InkEngineMode.draw),
          ),
          _ToolButton(
            icon: Icons.auto_fix_high,
            tooltip: 'Recognize',
            onPressed: () => _recognizeInk(engine),
          ),
          const Spacer(),
          Text('${engine.value.strokeCount} strokes',
              style: const TextStyle(fontSize: 12, color: Colors.grey)),
        ],
      ),
    );
  }

  void _recognizeInk(InkEngine engine) {
    if (engine.value.completedStrokes.isEmpty) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('AI Recognition triggered')),
    );
  }
}

class _ToolButton extends StatelessWidget {
  final IconData icon;
  final String tooltip;
  final VoidCallback onPressed;
  final bool isSelected;

  const _ToolButton({
    required this.icon,
    required this.tooltip,
    required this.onPressed,
    this.isSelected = false,
  });

  @override
  Widget build(BuildContext context) {
    return IconButton(
      icon: Icon(icon),
      tooltip: tooltip,
      isSelected: isSelected,
      onPressed: onPressed,
      style: IconButton.styleFrom(
        backgroundColor: isSelected ? Theme.of(context).colorScheme.primaryContainer : null,
      ),
    );
  }
}
