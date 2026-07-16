import 'package:flutter_test/flutter_test.dart';
import 'package:inkbill_ai/services/canvas_engine/canvas_engine.dart';
import 'package:inkbill_ai/features/handwriting/domain/entities/ink_stroke.dart';
import 'package:inkbill_ai/features/handwriting/domain/entities/ink_point.dart';

void main() {
  group('CanvasEngine', () {
    test('begins stroke correctly', () {
      final engine = CanvasEngine(pageId: 'test_page');
      engine.beginStroke(100, 200, pressure: 0.5);

      expect(engine.value.currentStroke, isNotNull);
      expect(engine.value.currentStroke!.points.length, 1);
      expect(engine.value.currentStroke!.points.first.x, 100);
      expect(engine.value.currentStroke!.points.first.y, 200);
      expect(engine.value.currentStroke!.points.first.pressure, 0.5);
      expect(engine.value.mode, CanvasMode.draw);
    });

    test('updates stroke correctly', () {
      final engine = CanvasEngine(pageId: 'test_page');
      engine.beginStroke(100, 200);
      engine.updateStroke(150, 250, pressure: 0.7);

      expect(engine.value.currentStroke!.points.length, 2);
      expect(engine.value.currentStroke!.points.last.x, 150);
      expect(engine.value.currentStroke!.points.last.y, 250);
    });

    test('ends stroke correctly and moves to completed', () {
      final engine = CanvasEngine(pageId: 'test_page');
      engine.beginStroke(100, 200);
      engine.updateStroke(150, 250);
      engine.endStroke();

      expect(engine.value.currentStroke, isNull);
      expect(engine.value.strokes.length, 1);
    });

    test('undo removes last stroke', () {
      final engine = CanvasEngine(pageId: 'test_page');
      engine.beginStroke(100, 200);
      engine.updateStroke(110, 210);
      engine.endStroke();
      engine.beginStroke(300, 400);
      engine.updateStroke(310, 410);
      engine.endStroke();

      expect(engine.value.strokes.length, 2);

      engine.undo();
      expect(engine.value.strokes.length, 1);
    });

    test('clear removes all strokes', () {
      final engine = CanvasEngine(pageId: 'test_page');
      engine.beginStroke(100, 200);
      engine.updateStroke(110, 210);
      engine.endStroke();
      engine.beginStroke(300, 400);
      engine.updateStroke(310, 410);
      engine.endStroke();

      engine.clear();
      expect(engine.value.strokes.length, 0);
      expect(engine.value.currentStroke, isNull);
    });

    test('cancelStroke removes current stroke in progress', () {
      final engine = CanvasEngine(pageId: 'test_page');
      engine.beginStroke(100, 200);
      engine.cancelStroke();

      expect(engine.value.currentStroke, isNull);
      expect(engine.value.strokes, isEmpty);
    });

    test('setMode changes mode', () {
      final engine = CanvasEngine(pageId: 'test_page');
      engine.setMode(CanvasMode.erase);
      expect(engine.value.mode, CanvasMode.erase);
    });

    test('loadStrokes populates completed strokes', () {
      final engine = CanvasEngine(pageId: 'test_page');
      engine.beginStroke(100, 200);
      engine.updateStroke(10, 10);
      engine.updateStroke(20, 20);
      engine.endStroke();

      final stroke = engine.value.strokes.last;
      engine.loadStrokes([stroke]);
      expect(engine.value.strokes.length, 1);
    });

    test('beginStroke with no pressure defaults to 0.5', () {
      final engine = CanvasEngine(pageId: 'test_page');
      engine.beginStroke(100, 200);
      expect(engine.value.currentStroke!.points.first.pressure, 0.5);
    });

    test('updateStroke does nothing if no current stroke', () {
      final engine = CanvasEngine(pageId: 'test_page');
      engine.updateStroke(100, 200);
      expect(engine.value.currentStroke, isNull);
    });

    test('endStroke does nothing if no current stroke', () {
      final engine = CanvasEngine(pageId: 'test_page');
      engine.endStroke();
      expect(engine.value.strokes, isEmpty);
    });

    test('undo on empty strokes does nothing', () {
      final engine = CanvasEngine(pageId: 'test_page');
      engine.undo();
      expect(engine.value.strokes.length, 0);
    });
  });
}
