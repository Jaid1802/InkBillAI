import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:inkbill_ai/core/theme/app_theme.dart';
import 'package:inkbill_ai/features/billing/presentation/pages/ocr_processing_page.dart';
import 'package:inkbill_ai/features/handwriting/presentation/providers/canvas_provider.dart';
import 'package:inkbill_ai/features/handwriting/presentation/widgets/handwriting_canvas.dart';
import 'package:inkbill_ai/services/canvas_engine/canvas_engine.dart';

class InkNotePage extends ConsumerStatefulWidget {
  const InkNotePage({super.key});

  @override
  ConsumerState<InkNotePage> createState() => _InkNotePageState();
}

class _InkNotePageState extends ConsumerState<InkNotePage>
    with SingleTickerProviderStateMixin {
  late final String _pageId;
  bool _isRecognizing = false;
  bool _isFullScreen = false;
  bool _controlsVisible = true;
  late AnimationController _fadeController;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _pageId = 'page_${DateTime.now().microsecondsSinceEpoch}';
    _fadeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
    _fadeAnimation = CurvedAnimation(
      parent: _fadeController,
      curve: Curves.easeInOut,
    );
    _fadeController.value = 1.0;
  }

  @override
  void dispose() {
    _fadeController.dispose();
    super.dispose();
  }

  void _toggleFullScreen() {
    setState(() {
      _isFullScreen = !_isFullScreen;
      _controlsVisible = true;
      _fadeController.forward();
    });
  }

  void _showControls() {
    if (!_controlsVisible) {
      setState(() => _controlsVisible = true);
      _fadeController.forward();
    }
  }

  void _hideControls() {
    if (_controlsVisible && _isFullScreen) {
      setState(() => _controlsVisible = false);
      _fadeController.reverse();
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(canvasStateProvider(_pageId));

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        top: !_isFullScreen,
        bottom: !_isFullScreen,
        child: Stack(
          children: [
            GestureDetector(
              onTap: _showControls,
              onPanUpdate: (_) {
                _showControls();
                Future.delayed(const Duration(seconds: 3), () {
                  if (mounted) _hideControls();
                });
              },
              child: HandwritingCanvas(pageId: _pageId),
            ),
            if (_isFullScreen)
              Positioned(
                top: 8,
                right: 8,
                child: _MiniToolbar(state: state),
              ),
            if (!_isFullScreen)
              Positioned(
                left: 0,
                right: 0,
                bottom: 0,
                child: _buildBottomToolbar(state),
              ),
            if (_controlsVisible && _isFullScreen)
              Positioned(
                left: 0,
                right: 0,
                bottom: 0,
                child: FadeTransition(
                  opacity: _fadeAnimation,
                  child: _buildFloatingToolbar(state),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildBottomToolbar(CanvasState state) {
    final engine = ref.read(canvasEngineProvider(_pageId));

    return Container(
      margin: const EdgeInsets.fromLTRB(16, 0, 16, 16),
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.08),
            blurRadius: 12,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _ToolButton(
            icon: Icons.undo,
            tooltip: 'Undo',
            onPressed: state.canUndo ? () => engine.undo() : null,
          ),
          _ToolButton(
            icon: Icons.redo,
            tooltip: 'Redo',
            onPressed: state.canRedo ? () => engine.redo() : null,
          ),
          _ToolButton(
            icon: Icons.edit,
            tooltip: 'Pen',
            isSelected: state.mode == CanvasMode.draw,
            onPressed: () {
              if (state.mode == CanvasMode.draw) {
                _showPenSettings(engine);
              } else {
                engine.setMode(CanvasMode.draw);
              }
            },
            onLongPress: () => _showPenSettings(engine),
          ),
          _ToolButton(
            icon: Icons.backspace_outlined,
            tooltip: 'Eraser',
            isSelected: state.mode == CanvasMode.erase,
            onPressed: () {
              if (state.mode == CanvasMode.erase) {
                _showEraserSettings(engine, state);
              } else {
                engine.setMode(CanvasMode.erase);
              }
            },
            onLongPress: () => _showEraserSettings(engine, state),
          ),
          _ToolButton(
            icon: Icons.delete_sweep_outlined,
            tooltip: 'Clear',
            onPressed:
                state.strokes.isNotEmpty ? () => _confirmClear(engine) : null,
          ),
          _ToolButton(
            icon: Icons.fullscreen,
            tooltip: 'Full Screen',
            onPressed: _toggleFullScreen,
          ),
          const Spacer(),
          _RecognizeButton(
            enabled: state.strokes.isNotEmpty && !_isRecognizing,
            loading: _isRecognizing,
            onPressed: () => _recognizeInk(state),
          ),
        ],
      ),
    );
  }

  Widget _buildFloatingToolbar(CanvasState state) {
    final engine = ref.read(canvasEngineProvider(_pageId));

    return Container(
      margin: const EdgeInsets.fromLTRB(16, 0, 16, 24),
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface.withValues(alpha: 0.95),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.12),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _ToolButton(
            icon: Icons.undo,
            tooltip: 'Undo',
            onPressed: state.canUndo ? () => engine.undo() : null,
          ),
          _ToolButton(
            icon: Icons.redo,
            tooltip: 'Redo',
            onPressed: state.canRedo ? () => engine.redo() : null,
          ),
          _ToolButton(
            icon: Icons.edit,
            tooltip: 'Pen',
            isSelected: state.mode == CanvasMode.draw,
            onPressed: () {
              if (state.mode == CanvasMode.draw) {
                _showPenSettings(engine);
              } else {
                engine.setMode(CanvasMode.draw);
              }
            },
            onLongPress: () => _showPenSettings(engine),
          ),
          _ToolButton(
            icon: Icons.backspace_outlined,
            tooltip: 'Eraser',
            isSelected: state.mode == CanvasMode.erase,
            onPressed: () {
              if (state.mode == CanvasMode.erase) {
                _showEraserSettings(engine, state);
              } else {
                engine.setMode(CanvasMode.erase);
              }
            },
            onLongPress: () => _showEraserSettings(engine, state),
          ),
          _ToolButton(
            icon: Icons.delete_sweep_outlined,
            tooltip: 'Clear',
            onPressed: state.strokes.isNotEmpty
                ? () => _confirmClear(engine)
                : null,
          ),
          _ToolButton(
            icon: Icons.fullscreen_exit,
            tooltip: 'Exit Full Screen',
            onPressed: _toggleFullScreen,
          ),
          const Spacer(),
          _RecognizeButton(
            enabled: state.strokes.isNotEmpty && !_isRecognizing,
            loading: _isRecognizing,
            onPressed: () => _recognizeInk(state),
          ),
        ],
      ),
    );
  }

  Widget _MiniToolbar({required CanvasState state}) {
    final engine = ref.read(canvasEngineProvider(_pageId));

    return Container(
      padding: const EdgeInsets.all(6),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface.withValues(alpha: 0.9),
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.08),
            blurRadius: 8,
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          _ToolButton(
            icon: Icons.fullscreen_exit,
            tooltip: 'Exit Full Screen',
            onPressed: _toggleFullScreen,
          ),
          const SizedBox(height: 4),
          _ToolButton(
            icon: Icons.undo,
            tooltip: 'Undo',
            onPressed: state.canUndo ? () => engine.undo() : null,
          ),
          const SizedBox(height: 4),
          _ToolButton(
            icon: Icons.redo,
            tooltip: 'Redo',
            onPressed: state.canRedo ? () => engine.redo() : null,
          ),
        ],
      ),
    );
  }

  void _showPenSettings(CanvasEngine engine) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Pen Thickness',
                  style:
                      TextStyle(fontWeight: FontWeight.w600, fontSize: 18)),
              const SizedBox(height: 20),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  _ThicknessOption(
                    label: 'Fine',
                    size: 1.5,
                    isSelected: engine.value.penWidth == 1.5,
                    onTap: () {
                      engine.setPenWidth(1.5);
                      Navigator.pop(ctx);
                    },
                  ),
                  _ThicknessOption(
                    label: 'Medium',
                    size: 3.0,
                    isSelected: engine.value.penWidth == 3.0,
                    onTap: () {
                      engine.setPenWidth(3.0);
                      Navigator.pop(ctx);
                    },
                  ),
                  _ThicknessOption(
                    label: 'Bold',
                    size: 6.0,
                    isSelected: engine.value.penWidth == 6.0,
                    onTap: () {
                      engine.setPenWidth(6.0);
                      Navigator.pop(ctx);
                    },
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showEraserSettings(CanvasEngine engine, CanvasState state) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Eraser Size',
                  style:
                      TextStyle(fontWeight: FontWeight.w600, fontSize: 18)),
              const SizedBox(height: 20),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  _ThicknessOption(
                    label: 'Small',
                    size: 20.0,
                    isSelected: engine.value.eraserSize == 20.0,
                    onTap: () {
                      engine.setEraserSize(20.0);
                      Navigator.pop(ctx);
                    },
                  ),
                  _ThicknessOption(
                    label: 'Medium',
                    size: 40.0,
                    isSelected: engine.value.eraserSize == 40.0,
                    onTap: () {
                      engine.setEraserSize(40.0);
                      Navigator.pop(ctx);
                    },
                  ),
                  _ThicknessOption(
                    label: 'Large',
                    size: 60.0,
                    isSelected: engine.value.eraserSize == 60.0,
                    onTap: () {
                      engine.setEraserSize(60.0);
                      Navigator.pop(ctx);
                    },
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _confirmClear(CanvasEngine engine) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Clear Canvas'),
        content: const Text('Clear all handwritten content?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              engine.clear();
              Navigator.pop(ctx);
            },
            child: const Text('Clear'),
          ),
        ],
      ),
    );
  }

  void _recognizeInk(CanvasState state) async {
    final engine = ref.read(canvasEngineProvider(_pageId));

    if (state.currentStroke != null) {
      engine.endStroke();
    }

    if (state.strokes.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content:
                Text('Write at least one item before recognizing.')),
      );
      return;
    }

    setState(() => _isRecognizing = true);

    try {
      await Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => OcrProcessingPage(
            strokes: state.strokes,
            pageId: _pageId,
          ),
        ),
      );
    } finally {
      if (mounted) {
        setState(() => _isRecognizing = false);
      }
    }
  }
}

class _ToolButton extends StatelessWidget {
  final IconData icon;
  final String tooltip;
  final VoidCallback? onPressed;
  final VoidCallback? onLongPress;
  final bool isSelected;

  const _ToolButton({
    required this.icon,
    required this.tooltip,
    this.onPressed,
    this.onLongPress,
    this.isSelected = false,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 2),
      child: Tooltip(
        message: tooltip,
        child: InkWell(
          borderRadius: BorderRadius.circular(10),
          onTap: onPressed,
          onLongPress: onLongPress,
          child: Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: isSelected
                  ? AppTheme.primaryColor.withValues(alpha: 0.1)
                  : Colors.transparent,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(
              icon,
              size: 22,
              color: isSelected
                  ? AppTheme.primaryColor
                  : (onPressed == null
                      ? Colors.grey.shade300
                      : Colors.grey.shade700),
            ),
          ),
        ),
      ),
    );
  }
}

class _ThicknessOption extends StatelessWidget {
  final String label;
  final double size;
  final bool isSelected;
  final VoidCallback onTap;

  const _ThicknessOption({
    required this.label,
    required this.size,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 80,
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: isSelected
              ? AppTheme.primaryColor.withValues(alpha: 0.08)
              : Colors.grey.shade50,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? AppTheme.primaryColor : Colors.grey.shade200,
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 32,
              height: size * 2 + 4,
              decoration: BoxDecoration(
                color: AppTheme.primaryColor,
                borderRadius: BorderRadius.circular(size),
              ),
            ),
            const SizedBox(height: 6),
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                fontWeight:
                    isSelected ? FontWeight.w600 : FontWeight.normal,
                color:
                    isSelected ? AppTheme.primaryColor : Colors.grey.shade600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _RecognizeButton extends StatelessWidget {
  final bool enabled;
  final bool loading;
  final VoidCallback onPressed;

  const _RecognizeButton({
    required this.enabled,
    required this.loading,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 42,
      child: FilledButton.icon(
        onPressed: (enabled && !loading) ? onPressed : null,
        icon: loading
            ? const SizedBox(
                width: 16,
                height: 16,
                child: CircularProgressIndicator(
                    strokeWidth: 2, color: Colors.white),
              )
            : const Icon(Icons.document_scanner, size: 18),
        label: Text(loading ? 'Recognizing...' : 'Recognize'),
        style: FilledButton.styleFrom(
          backgroundColor: AppTheme.primaryColor,
          foregroundColor: Colors.white,
          disabledBackgroundColor: Colors.grey.shade200,
          disabledForegroundColor: Colors.grey.shade400,
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10)),
        ),
      ),
    );
  }
}
