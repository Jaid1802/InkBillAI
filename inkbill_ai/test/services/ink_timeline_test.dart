import 'package:flutter_test/flutter_test.dart';
import 'package:inkbill_ai/services/ink_engine/ink_timeline.dart';
import 'package:inkbill_ai/features/handwriting/domain/entities/ink_stroke.dart';
import 'package:inkbill_ai/features/handwriting/domain/entities/ink_point.dart';

void main() {
  group('InkTimeline', () {
    late InkTimeline timeline;

    setUp(() {
      timeline = InkTimeline();
    });

    tearDown(() {
      timeline.dispose();
    });

    test('starts in stopped state', () {
      expect(timeline.value, PlaybackState.stopped);
    });

    test('loadFromStrokes populates events', () {
      final strokes = [
        InkStroke(
          id: 's1',
          pageId: 'p1',
          points: const [
            InkPoint(x: 0, y: 0, timestampMs: 0),
          ],
          createdAt: DateTime.now(),
        ),
      ];
      timeline.loadFromStrokes(strokes);
      expect(timeline.events.length, 2);
      expect(timeline.totalEvents, 2);
    });

    test('play sets state to playing', () {
      timeline.loadFromStrokes([
        InkStroke(
          id: 's1',
          pageId: 'p1',
          points: const [InkPoint(x: 0, y: 0, timestampMs: 0)],
          createdAt: DateTime.now(),
        ),
      ]);
      timeline.play();
      expect(timeline.value, PlaybackState.playing);
    });

    test('pause sets state to paused', () {
      timeline.loadFromStrokes([
        InkStroke(
          id: 's1',
          pageId: 'p1',
          points: const [InkPoint(x: 0, y: 0, timestampMs: 0)],
          createdAt: DateTime.now(),
        ),
      ]);
      timeline.play();
      timeline.pause();
      expect(timeline.value, PlaybackState.paused);
    });

    test('stop resets to stopped state', () {
      timeline.loadFromStrokes([
        InkStroke(
          id: 's1',
          pageId: 'p1',
          points: const [InkPoint(x: 0, y: 0, timestampMs: 0)],
          createdAt: DateTime.now(),
        ),
      ]);
      timeline.play();
      timeline.stop();
      expect(timeline.value, PlaybackState.stopped);
      expect(timeline.currentIndex, 0);
    });

    test('clear removes all state', () {
      timeline.loadFromStrokes([
        InkStroke(
          id: 's1',
          pageId: 'p1',
          points: const [InkPoint(x: 0, y: 0, timestampMs: 0)],
          createdAt: DateTime.now(),
        ),
      ]);
      timeline.clear();
      expect(timeline.events, isEmpty);
      expect(timeline.allStrokes, isEmpty);
      expect(timeline.value, PlaybackState.stopped);
    });

    test('progress is 0 when no events', () {
      expect(timeline.progress, 0.0);
    });

    test('recordStrokeEnd adds stroke', () {
      final stroke = InkStroke(
        id: 's1',
        pageId: 'p1',
        points: const [InkPoint(x: 0, y: 0, timestampMs: 100)],
        createdAt: DateTime.now(),
      );
      timeline.recordStrokeEnd(stroke);
      expect(timeline.allStrokes.length, 1);
      expect(timeline.events.length, 1);
    });

    test('recordStrokeErase removes stroke', () {
      final stroke = InkStroke(
        id: 's1',
        pageId: 'p1',
        points: const [InkPoint(x: 0, y: 0, timestampMs: 100)],
        createdAt: DateTime.now(),
      );
      timeline.recordStrokeEnd(stroke);
      timeline.recordStrokeErase('s1', 'p1');
      expect(timeline.allStrokes, isEmpty);
    });
  });
}
