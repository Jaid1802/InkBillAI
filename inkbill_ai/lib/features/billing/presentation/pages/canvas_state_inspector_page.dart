import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:scribble/scribble.dart';
import 'package:inkbill_ai/features/ink/handwriting_engine/scribble_adapter/ink_controller.dart';
import 'package:inkbill_ai/core/theme/app_theme.dart';

class CanvasStateInspectorPage extends ConsumerStatefulWidget {
  const CanvasStateInspectorPage({super.key});

  @override
  ConsumerState<CanvasStateInspectorPage> createState() => _CanvasStateInspectorPageState();
}

class _CanvasStateInspectorPageState extends ConsumerState<CanvasStateInspectorPage> {
  bool _showPreview = false;

  @override
  Widget build(BuildContext context) {
    final notifier = ref.watch(inkControllerProvider);
    final sketch = notifier.currentSketch;
    final strokeCount = sketch.lines.length;

    int totalPoints = 0;
    for (final l in sketch.lines) {
      totalPoints += l.points.length;
    }

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: const Text('Canvas State Inspector'),
        backgroundColor: AppTheme.primaryColor,
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildOverviewCard(notifier.hashCode, strokeCount, totalPoints),
            const SizedBox(height: 16),
            _buildPreviewSection(sketch),
            const SizedBox(height: 16),
            _buildPerStrokeListCard(sketch),
          ],
        ),
      ),
    );
  }

  Widget _buildOverviewCard(int controllerHash, int strokeCount, int totalPoints) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Production Canvas Controller State',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            const SizedBox(height: 8),
            Text('Controller Identity Hash: $controllerHash'),
            Text('Total Stroke Count: $strokeCount',
                style: TextStyle(
                    color: strokeCount > 0 ? Colors.green.shade800 : Colors.red,
                    fontWeight: FontWeight.bold)),
            Text('Total Point Count: $totalPoints'),
            const Text('Canvas Dimensions: 5000 x 5000 px'),
          ],
        ),
      ),
    );
  }

  Widget _buildPreviewSection(Sketch sketch) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Reconstructed Stored Strokes Preview',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                ElevatedButton.icon(
                  onPressed: () => setState(() => _showPreview = !_showPreview),
                  icon: Icon(_showPreview ? Icons.visibility_off : Icons.visibility, size: 16),
                  label: Text(_showPreview ? 'Hide Preview' : 'Preview Stored Strokes'),
                ),
              ],
            ),
            const SizedBox(height: 6),
            const Text(
              'Reconstructs canvas directly from stored sketch.lines data onto an isolated CustomPaint widget.',
              style: TextStyle(fontSize: 12, color: Colors.black54),
            ),
            if (_showPreview) ...[
              const SizedBox(height: 12),
              Container(
                height: 250,
                width: double.infinity,
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey.shade400),
                  borderRadius: BorderRadius.circular(8),
                  color: Colors.white,
                ),
                child: sketch.lines.isEmpty
                    ? const Center(
                        child: Text('BLANK (No stored strokes)',
                            style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold)))
                    : CustomPaint(
                        painter: _StoredStrokesPainter(sketch),
                        child: Container(),
                      ),
              ),
              const SizedBox(height: 8),
              Text(
                'Stored-stroke preview status: ${sketch.lines.isNotEmpty ? "VISIBLE" : "BLANK"}',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: sketch.lines.isNotEmpty ? Colors.green.shade800 : Colors.red,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildPerStrokeListCard(Sketch sketch) {
    if (sketch.lines.isEmpty) {
      return Card(
        elevation: 2,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        child: const Padding(
          padding: EdgeInsets.all(16),
          child: Text('No strokes recorded in production canvas state.',
              style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold)),
        ),
      );
    }

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Per-Stroke Details (${sketch.lines.length} strokes)',
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            const SizedBox(height: 8),
            ...sketch.lines.asMap().entries.map((e) {
              final idx = e.key;
              final line = e.value;
              double minX = double.infinity;
              double maxX = double.negativeInfinity;
              double minY = double.infinity;
              double maxY = double.negativeInfinity;

              for (final p in line.points) {
                if (p.x < minX) minX = p.x;
                if (p.x > maxX) maxX = p.x;
                if (p.y < minY) minY = p.y;
                if (p.y > maxY) maxY = p.y;
              }

              return Container(
                margin: const EdgeInsets.only(bottom: 6),
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.grey.shade100,
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Row(
                  children: [
                    Text('Stroke #$idx', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                    const SizedBox(width: 12),
                    Text('Pts: ${line.points.length} | Bounds: (${minX.toStringAsFixed(1)}, ${minY.toStringAsFixed(1)}) -> (${maxX.toStringAsFixed(1)}, ${maxY.toStringAsFixed(1)})',
                        style: const TextStyle(fontFamily: 'monospace', fontSize: 11)),
                  ],
                ),
              );
            }),
          ],
        ),
      ),
    );
  }
}

class _StoredStrokesPainter extends CustomPainter {
  final Sketch sketch;

  _StoredStrokesPainter(this.sketch);

  @override
  void paint(Canvas canvas, Size size) {
    if (sketch.lines.isEmpty) return;

    double minX = double.infinity;
    double minY = double.infinity;
    double maxX = double.negativeInfinity;
    double maxY = double.negativeInfinity;

    for (final l in sketch.lines) {
      for (final p in l.points) {
        if (p.x < minX) minX = p.x;
        if (p.x > maxX) maxX = p.x;
        if (p.y < minY) minY = p.y;
        if (p.y > maxY) maxY = p.y;
      }
    }

    if (minX == double.infinity) return;

    const pad = 20.0;
    double w = maxX - minX + (pad * 2);
    double h = maxY - minY + (pad * 2);
    if (w <= 0) w = 1.0;
    if (h <= 0) h = 1.0;

    final scaleX = size.width / w;
    final scaleY = size.height / h;
    final scale = scaleX < scaleY ? scaleX : scaleY;

    canvas.scale(scale);
    canvas.translate(-minX + pad, -minY + pad);

    for (final line in sketch.lines) {
      if (line.points.isEmpty) continue;
      final paint = Paint()
        ..color = Colors.black
        ..strokeWidth = line.width
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round
        ..style = PaintingStyle.stroke;

      if (line.points.length == 1) {
        paint.style = PaintingStyle.fill;
        canvas.drawCircle(Offset(line.points.first.x, line.points.first.y), line.width / 2, paint);
      } else {
        final path = Path();
        path.moveTo(line.points.first.x, line.points.first.y);
        for (var i = 1; i < line.points.length; i++) {
          path.lineTo(line.points[i].x, line.points[i].y);
        }
        canvas.drawPath(path, paint);
      }
    }
  }

  @override
  bool shouldRepaint(covariant _StoredStrokesPainter old) => true;
}
