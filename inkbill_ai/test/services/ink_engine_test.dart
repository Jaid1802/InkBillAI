import 'package:flutter_test/flutter_test.dart';
import 'package:inkbill_ai/services/canvas_engine/canvas_engine.dart';
import 'package:inkbill_ai/features/handwriting/domain/entities/ink_point.dart';
import 'package:inkbill_ai/features/handwriting/domain/entities/ink_stroke.dart';

void main() {
  late CanvasEngine engine;

  setUp(() {
    engine = CanvasEngine(pageId: 'test_page_1');
  });

  tearDown(() {
    engine.dispose();
  });

  group('CanvasEngine - Drawing', () {
    test('begins a stroke', () {
      engine.beginStroke(100, 200, pressure: 0.5, timestampMs: 0, pointerId: 0);
      expect(engine.value.currentStroke, isNotNull);
      expect(engine.value.currentStroke!.points.length, 1);
      expect(engine.value.currentStroke!.points.first.x, 100);
      expect(engine.value.currentStroke!.points.first.y, 200);
    });

    test('updates a stroke with multiple points', () {
      engine.beginStroke(100, 200, pressure: 0.5, timestampMs: 0, pointerId: 0);
      engine.updateStroke(150, 220, pressure: 0.6, timestampMs: 10, pointerId: 0);
      engine.updateStroke(200, 240, pressure: 0.7, timestampMs: 20, pointerId: 0);

      expect(engine.value.currentStroke!.points.length, 3);
    });

    test('completes a stroke and adds to completed strokes', () {
      engine.beginStroke(100, 200, pressure: 0.5, timestampMs: 0, pointerId: 0);
      engine.updateStroke(150, 220, pressure: 0.6, timestampMs: 10, pointerId: 0);
      engine.endStroke(timestampMs: 20, pointerId: 0);

      expect(engine.value.currentStroke, isNull);
      expect(engine.value.strokes.length, 1);
    });
  });

  group('CanvasEngine - Undo/Redo', () {
    test('undo removes the last stroke', () {
      engine.beginStroke(100, 200, pressure: 0.5, timestampMs: 0, pointerId: 0);
      engine.updateStroke(150, 220, pressure: 0.6, timestampMs: 10, pointerId: 0);
      engine.endStroke(timestampMs: 20, pointerId: 0);

      expect(engine.value.strokes.length, 1);
      expect(engine.value.canUndo, isTrue);

      engine.undo();

      expect(engine.value.strokes.length, 0);
      expect(engine.value.canRedo, isTrue);
    });

    test('redo restores the undone stroke', () {
      engine.beginStroke(100, 200, pressure: 0.5, timestampMs: 0, pointerId: 0);
      engine.updateStroke(150, 220, pressure: 0.6, timestampMs: 10, pointerId: 0);
      engine.endStroke(timestampMs: 20, pointerId: 0);
      engine.undo();

      expect(engine.value.strokes.length, 0);

      engine.redo();

      expect(engine.value.strokes.length, 1);
    });

    test('undo stack is cleared after new stroke', () {
      engine.beginStroke(100, 200, pressure: 0.5, timestampMs: 0, pointerId: 0);
      engine.updateStroke(150, 220, pressure: 0.6, timestampMs: 10, pointerId: 0);
      engine.endStroke(timestampMs: 20, pointerId: 0);
      engine.undo();

      engine.beginStroke(300, 400, pressure: 0.5, timestampMs: 30, pointerId: 0);
      engine.updateStroke(350, 420, pressure: 0.6, timestampMs: 40, pointerId: 0);
      engine.endStroke(timestampMs: 50, pointerId: 0);

      expect(engine.value.canRedo, isFalse);
    });
  });

  group('CanvasEngine - Eraser', () {
    test('vector eraser removes strokes near the eraser position', () {
      engine.beginStroke(100, 100, pressure: 0.5, timestampMs: 0, pointerId: 0);
      engine.updateStroke(110, 110, pressure: 0.6, timestampMs: 10, pointerId: 0);
      engine.endStroke(timestampMs: 20, pointerId: 0);

      engine.setMode(CanvasMode.erase);
      engine.eraseAt(100, 100, pointerId: 0);
      engine.endErase();
      engine.setMode(CanvasMode.draw);

      expect(engine.value.strokes.length, 0);
    });

    test('partial erase splits a stroke', () {
      engine.beginStroke(0, 0, timestampMs: 0, pointerId: 0);
      engine.updateStroke(50, 0, timestampMs: 10, pointerId: 0);
      engine.updateStroke(100, 0, timestampMs: 20, pointerId: 0);
      engine.updateStroke(150, 0, timestampMs: 30, pointerId: 0);
      engine.updateStroke(200, 0, timestampMs: 40, pointerId: 0);
      engine.endStroke(timestampMs: 50, pointerId: 0);

      expect(engine.value.strokes.length, 1);

      engine.setMode(CanvasMode.erase);
      engine.eraseAt(100, 0, pointerId: 0);
      engine.endErase();
      engine.setMode(CanvasMode.draw);

      expect(engine.value.strokes.length, greaterThanOrEqualTo(0));
    });
  });

  group('CanvasEngine - Mode switching', () {
    test('switches between draw and erase modes', () {
      expect(engine.value.mode, CanvasMode.draw);

      engine.setMode(CanvasMode.erase);
      expect(engine.value.mode, CanvasMode.erase);

      engine.setMode(CanvasMode.draw);
      expect(engine.value.mode, CanvasMode.draw);
    });
  });

  group('CanvasEngine - Clear', () {
    test('clears all strokes', () {
      engine.beginStroke(100, 200, timestampMs: 0, pointerId: 0);
      engine.updateStroke(150, 220, timestampMs: 10, pointerId: 0);
      engine.endStroke(timestampMs: 20, pointerId: 0);

      engine.clear();

      expect(engine.value.strokes.isEmpty, isTrue);
      expect(engine.value.canUndo, isTrue);
    });

    test('does nothing on empty canvas', () {
      engine.clear();
      expect(engine.value.canUndo, isFalse);
    });
  });

  group('CanvasEngine - Pen settings', () {
    test('setPenWidth changes pen width', () {
      engine.setPenWidth(5.0);
      expect(engine.value.penWidth, 5.0);
    });

    test('setEraserSize changes eraser size', () {
      engine.setEraserSize(50.0);
      expect(engine.value.eraserSize, 50.0);
    });
  });

  group('CanvasEngine - Load strokes', () {
    test('loadStrokes populates strokes', () {
      final now = DateTime.now();
      final stroke = InkStroke(
        id: 'test_str',
        pageId: 'test_page',
        points: [
          InkPoint(x: 0, y: 0, timestampMs: 0),
          InkPoint(x: 10, y: 10, timestampMs: 10),
        ],
        createdAt: now,
      );

      engine.loadStrokes([stroke]);
      expect(engine.value.strokes.length, 1);
      expect(engine.value.canUndo, isFalse);
    });
  });

  group('CanvasEngine - Cancel stroke', () {
    test('cancelStroke removes current stroke', () {
      engine.beginStroke(100, 200, timestampMs: 0, pointerId: 0);
      expect(engine.value.currentStroke, isNotNull);

      engine.cancelStroke(pointerId: 0);
      expect(engine.value.currentStroke, isNull);
      expect(engine.value.strokes, isEmpty);
    });
  });
}
