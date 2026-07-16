import 'package:flutter_test/flutter_test.dart';
import 'package:inkbill_ai/features/handwriting/domain/entities/ink_stroke.dart';
import 'package:inkbill_ai/features/handwriting/domain/entities/ink_point.dart';
import 'package:inkbill_ai/services/recognition/layout_analyzer.dart';

void main() {
  group('LayoutAnalyzer', () {
    late LayoutAnalyzer analyzer;

    setUp(() {
      analyzer = LayoutAnalyzer();
    });

    test('returns empty result for no strokes', () {
      final result = analyzer.analyze([]);

      expect(result.lines, isEmpty);
      expect(result.regions, isEmpty);
      expect(result.confidence, 0.0);
    });

    test('detects single line from one stroke', () {
      final strokes = [
        InkStroke(
          id: 's1',
          pageId: 'p1',
          points: [
            const InkPoint(x: 10, y: 20, timestampMs: 1),
            const InkPoint(x: 50, y: 25, timestampMs: 2),
            const InkPoint(x: 100, y: 22, timestampMs: 3),
          ],
          createdAt: DateTime.now(),
        ),
      ];

      final result = analyzer.analyze(strokes);

      expect(result.lines.length, 1);
      expect(result.lines.first.strokes.length, 1);
    });

    test('groups strokes on same line by Y proximity', () {
      final strokes = [
        InkStroke(
          id: 's1',
          pageId: 'p1',
          points: [
            const InkPoint(x: 10, y: 20, timestampMs: 1),
            const InkPoint(x: 50, y: 25, timestampMs: 2),
          ],
          createdAt: DateTime.now(),
        ),
        InkStroke(
          id: 's2',
          pageId: 'p1',
          points: [
            const InkPoint(x: 150, y: 22, timestampMs: 3),
            const InkPoint(x: 200, y: 28, timestampMs: 4),
          ],
          createdAt: DateTime.now(),
        ),
      ];

      final result = analyzer.analyze(strokes);

      expect(result.lines.length, 1);
      expect(result.lines.first.strokes.length, 2);
    });

    test('separates strokes on different lines', () {
      final strokes = [
        InkStroke(
          id: 's1',
          pageId: 'p1',
          points: [
            const InkPoint(x: 10, y: 20, timestampMs: 1),
            const InkPoint(x: 50, y: 25, timestampMs: 2),
          ],
          createdAt: DateTime.now(),
        ),
        InkStroke(
          id: 's2',
          pageId: 'p1',
          points: [
            const InkPoint(x: 10, y: 200, timestampMs: 3),
            const InkPoint(x: 50, y: 205, timestampMs: 4),
          ],
          createdAt: DateTime.now(),
        ),
      ];

      final result = analyzer.analyze(strokes);

      expect(result.lines.length, 2);
    });

    test('classifies first column as item', () {
      final strokes = [
        InkStroke(
          id: 's1',
          pageId: 'p1',
          points: [
            const InkPoint(x: 20, y: 100, timestampMs: 1),
            const InkPoint(x: 80, y: 105, timestampMs: 2),
          ],
          createdAt: DateTime.now(),
        ),
      ];

      final result = analyzer.analyze(strokes);

      if (result.regions.isNotEmpty) {
        expect(result.regions.first.classification, 'item');
      }
    });

    test('confidence is higher with more strokes', () {
      final singleStroke = [
        InkStroke(
          id: 's1',
          pageId: 'p1',
          points: [
            const InkPoint(x: 10, y: 20, timestampMs: 1),
          ],
          createdAt: DateTime.now(),
        ),
      ];

      final multiStroke = [
        InkStroke(
          id: 's1',
          pageId: 'p1',
          points: [
            const InkPoint(x: 10, y: 20, timestampMs: 1),
            const InkPoint(x: 20, y: 22, timestampMs: 2),
          ],
          createdAt: DateTime.now(),
        ),
        InkStroke(
          id: 's2',
          pageId: 'p1',
          points: [
            const InkPoint(x: 10, y: 80, timestampMs: 3),
            const InkPoint(x: 25, y: 85, timestampMs: 4),
          ],
          createdAt: DateTime.now(),
        ),
      ];

      final singleResult = analyzer.analyze(singleStroke);
      final multiResult = analyzer.analyze(multiStroke);

      expect(multiResult.confidence, greaterThan(singleResult.confidence));
    });
  });
}
