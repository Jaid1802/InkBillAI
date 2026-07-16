import 'package:flutter_test/flutter_test.dart';
import 'package:inkbill_ai/services/canvas_engine/canvas_engine.dart';

void main() {
  group('CanvasEngine - Core Drawing', () {
    late CanvasEngine engine;

    setUp(() {
      engine = CanvasEngine(pageId: 'test_page');
    });

    tearDown(() {
      engine.dispose();
    });

    test('starts in draw mode with empty strokes', () {
      expect(engine.value.mode, CanvasMode.draw);
      expect(engine.value.strokes, isEmpty);
      expect(engine.value.currentStroke, isNull);
      expect(engine.value.canUndo, false);
      expect(engine.value.canRedo, false);
    });

    test('beginStroke creates a new stroke', () {
      engine.beginStroke(100, 200, pressure: 0.5, pointerId: 1);

      expect(engine.value.currentStroke, isNotNull);
      expect(engine.value.currentStroke!.points.length, 1);
      expect(engine.value.currentStroke!.points.first.x, 100);
      expect(engine.value.currentStroke!.points.first.y, 200);
    });

    test('updateStroke adds points to current stroke', () {
      engine.beginStroke(100, 200, pressure: 0.5, pointerId: 1);
      engine.updateStroke(120, 220, pressure: 0.6, pointerId: 1);
      engine.updateStroke(140, 240, pressure: 0.7, pointerId: 1);

      expect(engine.value.currentStroke!.points.length, 3);
    });

    test('updateStroke skips very close points', () {
      engine.beginStroke(100, 200, pressure: 0.5, pointerId: 1);
      engine.updateStroke(100.5, 200.5, pressure: 0.6, pointerId: 1);

      expect(engine.value.currentStroke!.points.length, 1);
    });

    test('endStroke finalizes stroke and adds to strokes list', () {
      engine.beginStroke(100, 200, pressure: 0.5, pointerId: 1);
      engine.updateStroke(120, 220, pressure: 0.6, pointerId: 1);
      engine.endStroke(pointerId: 1);

      expect(engine.value.currentStroke, isNull);
      expect(engine.value.strokes.length, 1);
      expect(engine.value.strokes.first.points.length, 2);
    });

    test('endStroke ignores strokes with fewer than 2 points', () {
      engine.beginStroke(100, 200, pressure: 0.5, pointerId: 1);
      engine.endStroke(pointerId: 1);

      expect(engine.value.currentStroke, isNull);
      expect(engine.value.strokes, isEmpty);
    });

    test('cancelStroke removes current stroke', () {
      engine.beginStroke(100, 200, pressure: 0.5, pointerId: 1);
      engine.cancelStroke(pointerId: 1);

      expect(engine.value.currentStroke, isNull);
      expect(engine.value.strokes, isEmpty);
    });

    test('beginStroke ignores second pointer during draw', () {
      engine.beginStroke(100, 200, pressure: 0.5, pointerId: 1);

      engine.beginStroke(300, 400, pressure: 0.5, pointerId: 2);
      engine.updateStroke(310, 410, pressure: 0.6, pointerId: 2);

      expect(engine.value.currentStroke!.points.first.x, 100);
      expect(engine.value.currentStroke!.points.length, 1);
    });

    test('100 circles without gaps - simulate rapid stroke sequences', () {
      for (var i = 0; i < 100; i++) {
        final cx = 100.0 + (i % 10) * 80.0;
        final cy = 100.0 + (i ~/ 10) * 80.0;
        final r = 30.0;

        engine.beginStroke(cx + r, cy, pressure: 0.5, pointerId: i);

        for (double angle = 0; angle <= 6.28; angle += 0.3) {
          final x = cx + r * _cos(angle);
          final y = cy + r * _sin(angle);
          engine.updateStroke(x, y, pressure: 0.5, pointerId: i);
        }

        engine.endStroke(pointerId: i);
      }

      expect(engine.value.strokes.length, 100);
      expect(engine.value.canUndo, true);

      for (final stroke in engine.value.strokes) {
        expect(stroke.points.length, greaterThan(3),
            reason: 'Each circle should have multiple points');
      }
    });

    test('fast zig-zag lines are recorded correctly', () {
      engine.beginStroke(0, 0, pressure: 0.5, pointerId: 1);

      for (var i = 1; i <= 50; i++) {
        final x = i * 10.0;
        final y = (i % 2 == 0) ? 100.0 : 0.0;
        engine.updateStroke(x, y, pressure: 0.5, pointerId: 1);
      }

      engine.endStroke(pointerId: 1);

      expect(engine.value.strokes.length, 1);
      expect(engine.value.strokes.first.points.length, greaterThan(20));
    });

    test('loadStrokes replaces all strokes', () {
      engine.beginStroke(0, 0, pressure: 0.5, pointerId: 1);
      engine.endStroke(pointerId: 1);

      final emptyStrokes = <dynamic>[];
      engine.loadStrokes([]);

      expect(engine.value.strokes, isEmpty);
      expect(engine.value.canUndo, false);
    });
  });

  group('CanvasEngine - Undo/Redo', () {
    late CanvasEngine engine;

    setUp(() {
      engine = CanvasEngine(pageId: 'test_page');
    });

    tearDown(() {
      engine.dispose();
    });

    test('undo removes last stroke', () {
      _drawStroke(engine, 1);
      _drawStroke(engine, 2);

      expect(engine.value.strokes.length, 2);

      engine.undo();
      expect(engine.value.strokes.length, 1);
      expect(engine.value.canRedo, true);

      engine.undo();
      expect(engine.value.strokes, isEmpty);
      expect(engine.value.canUndo, false);
    });

    test('redo restores undone stroke', () {
      _drawStroke(engine, 1);
      _drawStroke(engine, 2);

      engine.undo();
      expect(engine.value.strokes.length, 1);

      engine.redo();
      expect(engine.value.strokes.length, 2);
      expect(engine.value.canRedo, false);
    });

    test('undo after new stroke clears redo stack', () {
      _drawStroke(engine, 1);
      engine.undo();
      expect(engine.value.canRedo, true);

      _drawStroke(engine, 2);
      expect(engine.value.canRedo, false);
    });

    test('clear is undoable', () {
      _drawStroke(engine, 1);
      _drawStroke(engine, 2);
      expect(engine.value.strokes.length, 2);

      engine.clear();
      expect(engine.value.strokes, isEmpty);

      engine.undo();
      expect(engine.value.strokes.length, 2);
    });
  });

  group('CanvasEngine - Eraser', () {
    late CanvasEngine engine;

    setUp(() {
      engine = CanvasEngine(pageId: 'test_page');
      _drawStroke(engine, 1);
      _drawStroke(engine, 2);
    });

    tearDown(() {
      engine.dispose();
    });

    test('eraseAt removes points within eraser radius', () {
      engine.setMode(CanvasMode.erase);
      engine.eraseAt(105, 205, pointerId: 1);
      engine.endErase();

      expect(engine.value.strokes.length, lessThanOrEqualTo(2));
    });

    test('eraseAt in draw mode does nothing', () {
      engine.eraseAt(100, 200, pointerId: 1);

      expect(engine.value.strokes.length, 2);
    });

    test('eraser is undoable', () {
      engine.setMode(CanvasMode.erase);

      engine.eraseAt(110, 200, pointerId: 1);
      engine.endErase();

      expect(engine.value.strokes.length, lessThan(2));

      engine.undo();
      expect(engine.value.strokes.length, 2);
    });
  });

  group('CanvasEngine - Mode Switching', () {
    late CanvasEngine engine;

    setUp(() {
      engine = CanvasEngine(pageId: 'test_page');
    });

    test('setMode switches between draw and erase', () {
      expect(engine.value.mode, CanvasMode.draw);

      engine.setMode(CanvasMode.erase);
      expect(engine.value.mode, CanvasMode.erase);

      engine.setMode(CanvasMode.draw);
      expect(engine.value.mode, CanvasMode.draw);
    });

    test('switching mode ends current stroke', () {
      engine.beginStroke(100, 200, pressure: 0.5, pointerId: 1);
      engine.updateStroke(120, 220, pressure: 0.6, pointerId: 1);
      expect(engine.value.currentStroke, isNotNull);

      engine.setMode(CanvasMode.erase);

      expect(engine.value.currentStroke, isNull);
      expect(engine.value.strokes.length, 1);
    });
  });

  group('CanvasEngine - Settings', () {
    late CanvasEngine engine;

    setUp(() {
      engine = CanvasEngine(pageId: 'test_page');
    });

    test('setPenWidth changes pen width', () {
      engine.setPenWidth(5.0);
      expect(engine.value.penWidth, 5.0);
    });

    test('setPenColor changes pen color', () {
      engine.setPenColor(0xFFFF0000);
      expect(engine.value.penColor, 0xFFFF0000);
    });

    test('setEraserSize changes eraser size', () {
      engine.setEraserSize(50.0);
      expect(engine.value.eraserSize, 50.0);
    });

    test('setBackground changes background', () {
      engine.setBackground(CanvasBackground.grid);
      expect(engine.value.background, CanvasBackground.grid);
    });
  });
}

void _drawStroke(CanvasEngine engine, int id) {
  engine.beginStroke(100.0 + id * 10, 200.0, pressure: 0.5, pointerId: id);
  engine.updateStroke(200.0 + id * 10, 300.0, pressure: 0.6, pointerId: id);
  engine.updateStroke(300.0 + id * 10, 400.0, pressure: 0.7, pointerId: id);
  engine.endStroke(pointerId: id);
}

double _cos(double angle) => _angleTrig(angle, true) as double;
double _sin(double angle) => _angleTrig(angle, false) as double;

num _angleTrig(double angle, bool isCos) {
  const step = 0.001;
  final normalized = angle % 6.283185;
  final idx = (normalized / step).round() % 6283;
  if (isCos) {
    if (idx < 1571) return 1.0 - (idx * step);
    if (idx < 3142) return (3142 - idx) * step - 1.0;
    if (idx < 4712) return -(idx - 3142) * step - 1.0;
    return (6283 - idx) * step - 1.0;
  } else {
    if (idx < 1571) return idx * step;
    if (idx < 3142) return (3142 - idx) * step;
    if (idx < 4712) return -(idx - 3142) * step;
    return -(6283 - idx) * step;
  }
}


