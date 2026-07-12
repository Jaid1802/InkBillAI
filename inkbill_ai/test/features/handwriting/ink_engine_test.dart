import 'package:flutter_test/flutter_test.dart';
import 'package:inkbill_ai/features/handwriting/domain/entities/ink_stroke.dart';
import 'package:inkbill_ai/services/ink_engine/ink_engine.dart';

InkStroke _createTestStroke(InkEngine engine) {
  engine.beginStroke(0, 0);
  engine.updateStroke(10, 10);
  engine.updateStroke(20, 20);
  engine.endStroke();
  return engine.value.completedStrokes.last;
}

void main() {
  group('InkEngine', () {
    test('begins stroke correctly', () {
      final engine = InkEngine(pageId: 'test_page');
      engine.beginStroke(100, 200, pressure: 0.5, width: 3.0);

      expect(engine.value.currentStroke, isNotNull);
      expect(engine.value.currentStroke!.points.length, 1);
      expect(engine.value.currentStroke!.points.first.x, 100);
      expect(engine.value.currentStroke!.points.first.y, 200);
      expect(engine.value.currentStroke!.points.first.pressure, 0.5);
      expect(engine.value.mode, InkEngineMode.draw);
    });

    test('updates stroke correctly', () {
      final engine = InkEngine(pageId: 'test_page');
      engine.beginStroke(100, 200, width: 3.0);
      engine.updateStroke(150, 250, pressure: 0.7);

      expect(engine.value.currentStroke!.points.length, 2);
      expect(engine.value.currentStroke!.points.last.x, 150);
      expect(engine.value.currentStroke!.points.last.y, 250);
    });

    test('ends stroke correctly and moves to completed', () {
      final engine = InkEngine(pageId: 'test_page');
      engine.beginStroke(100, 200);
      engine.updateStroke(150, 250);
      engine.endStroke();

      expect(engine.value.currentStroke, isNull);
      expect(engine.value.completedStrokes.length, 1);
      expect(engine.value.strokeCount, 1);
    });

    test('undo removes last stroke', () {
      final engine = InkEngine(pageId: 'test_page');
      engine.beginStroke(100, 200);
      engine.endStroke();
      engine.beginStroke(300, 400);
      engine.endStroke();

      expect(engine.value.strokeCount, 2);

      engine.undo();
      expect(engine.value.strokeCount, 1);
      expect(engine.value.completedStrokes.length, 1);
    });

    test('clear removes all strokes', () {
      final engine = InkEngine(pageId: 'test_page');
      engine.beginStroke(100, 200);
      engine.endStroke();
      engine.beginStroke(300, 400);
      engine.endStroke();

      engine.clear();
      expect(engine.value.strokeCount, 0);
      expect(engine.value.completedStrokes, isEmpty);
      expect(engine.value.currentStroke, isNull);
    });

    test('cancelStroke removes current stroke in progress', () {
      final engine = InkEngine(pageId: 'test_page');
      engine.beginStroke(100, 200);
      engine.cancelStroke();

      expect(engine.value.currentStroke, isNull);
      expect(engine.value.completedStrokes, isEmpty);
    });

    test('setMode changes mode', () {
      final engine = InkEngine(pageId: 'test_page');
      engine.setMode(InkEngineMode.erase);
      expect(engine.value.mode, InkEngineMode.erase);
    });

    test('loadStrokes populates completed strokes', () {
      final engine = InkEngine(pageId: 'test_page');
      final stroke = _createTestStroke(engine);
      engine.loadStrokes([stroke]);
      expect(engine.value.completedStrokes.length, 1);
      expect(engine.value.strokeCount, 1);
    });

    test('beginStroke with no pressure defaults to 0.5', () {
      final engine = InkEngine(pageId: 'test_page');
      engine.beginStroke(100, 200);
      expect(engine.value.currentStroke!.points.first.pressure, 0.5);
    });

    test('updateStroke does nothing if no current stroke', () {
      final engine = InkEngine(pageId: 'test_page');
      engine.updateStroke(100, 200);
      expect(engine.value.currentStroke, isNull);
    });

    test('endStroke does nothing if no current stroke', () {
      final engine = InkEngine(pageId: 'test_page');
      engine.endStroke();
      expect(engine.value.completedStrokes, isEmpty);
    });

    test('undo on empty strokes does nothing', () {
      final engine = InkEngine(pageId: 'test_page');
      engine.undo();
      expect(engine.value.strokeCount, 0);
    });
  });
}
