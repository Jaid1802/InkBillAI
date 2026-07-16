import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:inkbill_ai/features/handwriting/domain/entities/ink_stroke.dart';
import 'package:inkbill_ai/features/timeline/presentation/providers/timeline_provider.dart';
import 'package:inkbill_ai/services/ink_engine/ink_timeline.dart';
import 'package:inkbill_ai/services/canvas_engine/canvas_renderer.dart';

class InkTimelineWidget extends ConsumerStatefulWidget {
  final double width;
  final double height;

  const InkTimelineWidget({
    super.key,
    this.width = double.infinity,
    this.height = 300,
  });

  @override
  ConsumerState<InkTimelineWidget> createState() => _InkTimelineWidgetState();
}

class _InkTimelineWidgetState extends ConsumerState<InkTimelineWidget> {
  final CanvasRenderer _renderer = CanvasRenderer();
  List<InkStroke> _currentFrame = [];

  @override
  Widget build(BuildContext context) {
    final playbackState = ref.watch(playbackStateProvider);
    final progress = ref.watch(timelineProgressProvider);
    final timeline = ref.watch(timelineProvider);

    ref.listen<AsyncValue<List<InkStroke>>>(
      timelineFrameProvider,
      (_, next) {
        next.whenData((value) => setState(() => _currentFrame = value));
      },
    );

    return Column(
      children: [
        Expanded(
          child: Container(
            decoration: BoxDecoration(
              border: Border.all(color: Colors.grey.shade300),
              borderRadius: BorderRadius.circular(8),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: CustomPaint(
                size: Size(widget.width, widget.height),
                painter: _TimelinePainter(
                  strokes: _currentFrame,
                  renderer: _renderer,
                ),
              ),
            ),
          ),
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            _PlayButton(
              icon: playbackState == PlaybackState.playing
                  ? Icons.pause
                  : Icons.play_arrow,
              onPressed: () {
                if (playbackState == PlaybackState.playing) {
                  timeline.pause();
                } else if (playbackState == PlaybackState.paused) {
                  timeline.resume();
                } else {
                  timeline.play();
                }
              },
            ),
            _PlayButton(
              icon: Icons.stop,
              onPressed: () => timeline.stop(),
            ),
            Expanded(
              child: Slider(
                value: progress,
                onChanged: (v) => timeline.seekTo(v),
              ),
            ),
            Text('${(progress * 100).toInt()}%'),
          ],
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Text(
            '${timeline.currentIndex} / ${timeline.totalEvents} events',
            style: Theme.of(context).textTheme.bodySmall,
          ),
        ),
      ],
    );
  }
}

class _PlayButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onPressed;

  const _PlayButton({required this.icon, required this.onPressed});

  @override
  Widget build(BuildContext context) {
    return IconButton(
      icon: Icon(icon),
      onPressed: onPressed,
      tooltip: icon == Icons.play_arrow
          ? 'Play'
          : icon == Icons.pause
              ? 'Pause'
              : 'Stop',
    );
  }
}

class _TimelinePainter extends CustomPainter {
  final List<InkStroke> strokes;
  final CanvasRenderer renderer;

  _TimelinePainter({required this.strokes, required this.renderer});

  @override
  void paint(Canvas canvas, Size size) {
    canvas.clipRect(Rect.fromLTWH(0, 0, size.width, size.height));
    for (final stroke in strokes) {
      renderer.renderStroke(canvas, stroke);
    }
  }

  @override
  bool shouldRepaint(covariant _TimelinePainter oldDelegate) {
    return oldDelegate.strokes != strokes;
  }
}
