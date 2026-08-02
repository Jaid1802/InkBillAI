import 'dart:async';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:inkbill_ai/features/billing/presentation/pages/ocr_processing_page.dart';
import 'package:inkbill_ai/features/handwriting/presentation/providers/canvas_provider.dart';
import 'package:inkbill_ai/features/handwriting/presentation/widgets/handwriting_canvas.dart';
import 'package:inkbill_ai/features/handwriting/presentation/widgets/floating_toolbar.dart';
import 'package:inkbill_ai/features/handwriting/presentation/widgets/settings_panel.dart';
import 'package:inkbill_ai/features/handwriting/presentation/utils/canvas_export.dart';


class InkNotePage extends ConsumerStatefulWidget {
  const InkNotePage({super.key});

  @override
  ConsumerState<InkNotePage> createState() => _InkNotePageState();
}

class _InkNotePageState extends ConsumerState<InkNotePage>
    with TickerProviderStateMixin {
  late final String _pageId;
  late final TransformationController _transformCtrl;
  late final AnimationController _scrollAnimCtrl;

  bool _isRecognizing = false;
  bool _isMenuOpen = true;
  Timer? _longPressTimer;

  static const double _scrollAmount = 200.0;
  static const Duration _scrollDuration = Duration(milliseconds: 250);

  @override
  void initState() {
    super.initState();
    _pageId = 'page_${DateTime.now().microsecondsSinceEpoch}';
    _transformCtrl = TransformationController();
    _scrollAnimCtrl = AnimationController(
      vsync: this,
      duration: _scrollDuration,
    );
  }

  @override
  void dispose() {
    _transformCtrl.dispose();
    _scrollAnimCtrl.dispose();
    _longPressTimer?.cancel();
    super.dispose();
  }

  void _scrollBy(double dy) {
    _scrollAnimCtrl.stop();
    _scrollAnimCtrl.reset();

    final currentY = _transformCtrl.value.getTranslation().y;
    final targetY = currentY + dy;

    _scrollAnimCtrl.addListener(() {
      if (!_scrollAnimCtrl.isAnimating) return;
      final y = currentY + (targetY - currentY) * _scrollAnimCtrl.value;
      final m = Matrix4.identity()..setTranslationRaw(0, y, 0);
      _transformCtrl.value = m;
    });

    _scrollAnimCtrl.forward();
  }

  void _startContinuousScroll(double dy) {
    _longPressTimer?.cancel();
    _longPressTimer = Timer.periodic(const Duration(milliseconds: 30), (_) {
      final currentY = _transformCtrl.value.getTranslation().y;
      final m = Matrix4.identity()..setTranslationRaw(0, currentY + dy * 0.3, 0);
      _transformCtrl.value = m;
    });
  }

  void _stopContinuousScroll() {
    _longPressTimer?.cancel();
    _longPressTimer = null;
  }

  void _onStrokeStarted() {
    if (_isMenuOpen) {
      setState(() => _isMenuOpen = false);
    }
  }

  Future<void> _recognizeInk() async {
    final engine = ref.read(canvasEngineProvider(_pageId));
    final state = engine.value;

    if (state.currentStroke != null) {
      engine.endStroke();
    }

    if (state.strokes.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Write at least one item before recognizing.')),
      );
      return;
    }

    setState(() => _isRecognizing = true);

    try {
      final Uint8List? imageBytes = await CanvasExport.exportStrokesToPng(state.strokes);

      if (imageBytes == null) {
        throw Exception('Failed to generate image from handwriting.');
      }

      if (!mounted) return;

      await Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => OcrProcessingPage(
            imageBytes: imageBytes,
            pageId: _pageId,
          ),
        ),
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isRecognizing = false);
      }
    }
  }

  void _onClearCanvas() {
    final engine = ref.read(canvasEngineProvider(_pageId));
    
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Clear Canvas'),
        content: const Text('Are you sure you want to clear all handwriting?'),
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
            child: const Text('Clear', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Stack(
          children: [
            // 1. The Canvas
            Positioned.fill(
              child: HandwritingCanvas(
                pageId: _pageId,
                onStrokeStarted: _onStrokeStarted,
                transformationController: _transformCtrl,
              ),
            ),
            
            // 2. The Settings Panel (Left)
            if (_isMenuOpen)
              Positioned(
                top: 80,
                left: 16,
                child: SettingsPanel(
                  pageId: _pageId,
                  onClear: _onClearCanvas,
                ).animate()
                 .slideX(begin: -0.2, end: 0, curve: Curves.easeOutCubic, duration: 250.ms)
                 .fade(),
              ),

            // 3. The Top Floating Toolbar
            Positioned(
              top: 16,
              left: 0,
              right: 0,
              child: Center(
                child: FloatingToolbar(
                  pageId: _pageId,
                  isMenuOpen: _isMenuOpen,
                  isRecognizing: _isRecognizing,
                  onToggleMenu: () => setState(() => _isMenuOpen = !_isMenuOpen),
                  onRecognize: _recognizeInk,
                  onSave: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Bill saved successfully!')),
                    );
                  },
                  onZoomToggle: () {
                    _transformCtrl.value = Matrix4.identity();
                  },
                ),
              ),
            ),

            // 4. Right Side Navigation Buttons
            Positioned(
              right: 12,
              top: 0,
              bottom: 0,
              child: Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _NavButton(
                      icon: Icons.keyboard_arrow_up,
                      tooltip: 'Scroll Up',
                      onTap: () => _scrollBy(-_scrollAmount),
                      onLongPressStart: () => _startContinuousScroll(-_scrollAmount),
                      onLongPressEnd: _stopContinuousScroll,
                    ),
                    const SizedBox(height: 12),
                    _NavButton(
                      icon: Icons.keyboard_arrow_down,
                      tooltip: 'Scroll Down',
                      onTap: () => _scrollBy(_scrollAmount),
                      onLongPressStart: () => _startContinuousScroll(_scrollAmount),
                      onLongPressEnd: _stopContinuousScroll,
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _NavButton extends StatelessWidget {
  final IconData icon;
  final String tooltip;
  final VoidCallback onTap;
  final VoidCallback onLongPressStart;
  final VoidCallback onLongPressEnd;

  const _NavButton({
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
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(24),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.12),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Icon(icon, size: 28, color: const Color(0xFF001F3F)),
        ),
      ),
    );
  }
}
