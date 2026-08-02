import 'dart:math' as math;
import 'package:flutter/foundation.dart';
import 'package:inkbill_ai/features/handwriting/domain/entities/ink_point.dart';
import 'package:inkbill_ai/features/handwriting/domain/entities/ink_stroke.dart';

enum CanvasMode { draw, erase }
enum EraseMode { stroke, pixel }
enum CanvasBackground { blank, ruled, grid }
enum InputMode { finger, stylus }

class CanvasEngine extends ValueNotifier<CanvasState> {
  final String pageId;
  final VoidCallback? onAutoSave;

  CanvasEngine({required this.pageId, this.onAutoSave})
      : super(CanvasState(pageId: pageId));

  final List<CanvasAction> _undoStack = [];
  final List<CanvasAction> _redoStack = [];
  int _pointerId = -1;
  int _drawFinger = -1;
  int _lastTimestamp = 0;
  bool _skipNextMove = false;

  static const double _minStrokeDistance = 2.0;
  static const int _maxPointsPerStroke = 30000;

  int get undoCount => _undoStack.length;
  int get redoCount => _redoStack.length;

  void beginStroke(
    double x,
    double y, {
    double pressure = 0.5,
    int? timestampMs,
    int pointerId = 0,
    bool isStylus = false,
    bool isEraser = false,
  }) {
    if (isEraser) {
      _pointerId = pointerId;
      return;
    }

    if (isStylus) {
      _drawFinger = -1;
    } else {
      if (_drawFinger >= 0) return;
      _drawFinger = pointerId;
    }

    if (_pointerId >= 0 && pointerId != _pointerId) return;
    _pointerId = pointerId;

    if (value.mode == CanvasMode.erase) return;

    final now = timestampMs ?? DateTime.now().millisecondsSinceEpoch;
    _lastTimestamp = now;

    final point = InkPoint(x: x, y: y, pressure: pressure, timestampMs: now);

    final stroke = InkStroke(
      id: _nextId(),
      pageId: pageId,
      points: [point],
      color: value.penColor,
      width: value.penWidth * value.penOpacity, // Or apply opacity as alpha to color. Let's do it via color.
      createdAt: DateTime.now(),
    );

    // Apply opacity to color
    int r = (value.penColor >> 16) & 0xFF;
    int g = (value.penColor >> 8) & 0xFF;
    int b = value.penColor & 0xFF;
    int a = (value.penOpacity * 255).round();
    int finalColor = (a << 24) | (r << 16) | (g << 8) | b;

    final adjustedStroke = stroke.copyWith(color: finalColor, width: value.penWidth);
    
    value = value.copyWith(currentStroke: adjustedStroke);
  }

  void updateStroke(
    double x,
    double y, {
    double pressure = 0.5,
    int? timestampMs,
    int pointerId = 0,
    bool isStylus = false,
    bool isEraser = false,
  }) {
    if (_skipNextMove) {
      _skipNextMove = false;
      return;
    }

    if (isEraser) {
      if (pointerId != _pointerId) return;
      if (value.mode != CanvasMode.erase) return;
      eraseAt(x, y, pointerId: pointerId);
      return;
    }

    if (!isStylus) {
      if (_drawFinger != pointerId) return;
    }
    if (pointerId != _pointerId) return;

    final cs = value.currentStroke;
    if (cs == null) return;
    if (value.mode == CanvasMode.erase) return;

    final lastPt = cs.points.last;
    final dx = x - lastPt.x;
    final dy = y - lastPt.y;
    final dist = dx * dx + dy * dy;

    if (dist < _minStrokeDistance) return;

    final now = timestampMs ?? DateTime.now().millisecondsSinceEpoch;
    final dt = now - _lastTimestamp;
    final velocity = dt > 0 ? math.sqrt(dist) / dt : 0.0;
    _lastTimestamp = now;

    final point = InkPoint(
      x: x,
      y: y,
      pressure: pressure,
      timestampMs: now,
      velocity: velocity,
    );

    if (cs.points.length >= _maxPointsPerStroke) {
      endStroke(timestampMs: now, pointerId: pointerId);
      beginStroke(x, y,
          pressure: pressure, timestampMs: now, pointerId: pointerId);
      return;
    }

    value = value.copyWith(
      currentStroke: cs.copyWith(points: [...cs.points, point]),
    );
  }

  void endStroke({int? timestampMs, int pointerId = 0}) {
    if (pointerId != _pointerId && value.currentStroke != null) return;
    _pointerId = -1;
    _drawFinger = -1;

    final cs = value.currentStroke;
    if (cs == null || cs.points.length < 2) {
      value = value.copyWith(currentStroke: null);
      return;
    }

    final finalStroke = cs.copyWith(points: _simplify(cs.points));
    value = value.copyWith(
      currentStroke: null,
      strokes: [...value.strokes, finalStroke],
    );

    _undoStack.add(CanvasAction(type: CanvasActionType.addStroke, stroke: finalStroke));
    _redoStack.clear();
    _syncUndoRedo();
    onAutoSave?.call();
  }

  void cancelStroke({int pointerId = 0}) {
    if (_pointerId < 0 || pointerId == _pointerId) {
      _pointerId = -1;
      _drawFinger = -1;
      value = value.copyWith(currentStroke: null);
    }
  }

  void setEraseMode(EraseMode mode) => value = value.copyWith(eraseMode: mode);

  void eraseAt(double x, double y, {int pointerId = 0}) {
    if (value.mode != CanvasMode.erase) return;
    if (_pointerId < 0) _pointerId = pointerId;
    if (pointerId != _pointerId) return;

    if (value.eraseMode == EraseMode.stroke) {
      _eraseStrokeAt(x, y);
    } else {
      _erasePixelAt(x, y);
    }
  }

  void _eraseStrokeAt(double x, double y) {
    final es = value.eraserSize;
    final esSq = es * es;

    final List<InkStroke> erased = [];
    final List<InkStroke> surviving = [];

    for (final stroke in value.strokes) {
      bool hit = false;
      for (final p in stroke.points) {
        final dx = p.x - x;
        final dy = p.y - y;
        if (dx * dx + dy * dy <= esSq) {
          hit = true;
          break;
        }
      }
      if (hit) {
        erased.add(stroke);
      } else {
        surviving.add(stroke);
      }
    }

    if (erased.isEmpty) return;

    value = value.copyWith(strokes: surviving);

    _undoStack.add(CanvasAction(
      type: CanvasActionType.erase,
      erased: erased,
      restored: [...erased],
    ));
    _redoStack.clear();
    _syncUndoRedo();
    onAutoSave?.call();
  }

  void _erasePixelAt(double x, double y) {
    final es = value.eraserSize / 2;
    final esSq = es * es;

    final List<InkStroke> surviving = [];
    final List<InkStroke> erased = [];
    final List<InkStroke> partials = [];

    for (final stroke in value.strokes) {
      final removed = <int>{};
      for (var i = 0; i < stroke.points.length; i++) {
        final dx = stroke.points[i].x - x;
        final dy = stroke.points[i].y - y;
        if (dx * dx + dy * dy <= esSq) removed.add(i);
      }

      if (removed.isEmpty) {
        surviving.add(stroke);
      } else if (removed.length == stroke.points.length) {
        erased.add(stroke);
      } else {
        final kept = <InkPoint>[];
        for (var i = 0; i < stroke.points.length; i++) {
          if (!removed.contains(i)) kept.add(stroke.points[i]);
        }
        if (kept.length >= 2) {
          int startIdx = 0;
          for (var i = 0; i < kept.length; i++) {
            if (i == kept.length - 1 || kept[i + 1].x - kept[i].x > 20) {
              final segment = kept.sublist(startIdx, i + 1);
              if (segment.length >= 2) {
                partials.add(stroke.copyWith(
                  id: _nextId(title: 'seg'),
                  points: segment,
                  createdAt: DateTime.now(),
                ));
              }
              startIdx = i + 1;
            }
          }
        }
        erased.add(stroke);
      }
    }

    if (erased.isEmpty) return;

    final newStrokes = [...surviving, ...partials];
    value = value.copyWith(strokes: newStrokes);

    _undoStack.add(CanvasAction(
      type: CanvasActionType.erase,
      erased: erased,
      restored: [...erased],
      partials: partials,
    ));
    _redoStack.clear();
    _syncUndoRedo();
    onAutoSave?.call();
  }

  void endErase() {
    _pointerId = -1;
  }

  void undo() {
    if (_undoStack.isEmpty) return;
    final action = _undoStack.removeLast();

    switch (action.type) {
      case CanvasActionType.addStroke:
        value = value.copyWith(
          strokes: value.strokes.where((s) => s.id != action.stroke!.id).toList(),
        );
        break;
      case CanvasActionType.erase:
        final removedIds = action.erased!.map((e) => e.id).toSet();
        final partialIds = action.partials.map((e) => e.id).toSet();
        final filtered = value.strokes
            .where((s) => !removedIds.contains(s.id) && !partialIds.contains(s.id))
            .toList();
        value = value.copyWith(
          strokes: [...filtered, ...action.restored],
        );
        break;
      case CanvasActionType.clearCanvas:
        value = value.copyWith(strokes: action.restored);
        break;
    }

    _redoStack.add(action);
    _syncUndoRedo();
  }

  void redo() {
    if (_redoStack.isEmpty) return;
    final action = _redoStack.removeLast();

    switch (action.type) {
      case CanvasActionType.addStroke:
        value = value.copyWith(strokes: [...value.strokes, action.stroke!]);
        break;
      case CanvasActionType.erase:
        final restoredIds = action.restored.map((e) => e.id).toSet();
        value = value.copyWith(
          strokes: [
            ...value.strokes.where((s) => !restoredIds.contains(s.id)),
            ...action.partials,
          ],
        );
        break;
      case CanvasActionType.clearCanvas:
        value = value.copyWith(strokes: []);
        break;
    }

    _undoStack.add(action);
    _syncUndoRedo();
  }

  void clear() {
    if (value.strokes.isEmpty && value.currentStroke == null) return;
    final prev = List<InkStroke>.from(value.strokes);

    value = value.copyWith(currentStroke: null, strokes: []);
    _undoStack.add(CanvasAction(
      type: CanvasActionType.clearCanvas,
      restored: prev,
    ));
    _redoStack.clear();
    _syncUndoRedo();
    onAutoSave?.call();
  }

  void setMode(CanvasMode mode) {
    final cs = value.currentStroke;
    if (cs != null && value.mode == CanvasMode.draw) {
      _pointerId = -1;
      _drawFinger = -1;
      if (cs.points.length >= 2) {
        value = value.copyWith(
          currentStroke: null,
          strokes: [...value.strokes, cs.copyWith(points: _simplify(cs.points))],
        );
        _undoStack.add(CanvasAction(type: CanvasActionType.addStroke, stroke: cs));
        _redoStack.clear();
        _syncUndoRedo();
      } else {
        value = value.copyWith(currentStroke: null);
      }
    }
    _pointerId = -1;
    _drawFinger = -1;
    value = value.copyWith(mode: mode);
  }

  void setPenWidth(double w) => value = value.copyWith(penWidth: w);
  void setPenColor(int c) => value = value.copyWith(penColor: c);
  void setPenOpacity(double o) => value = value.copyWith(penOpacity: o);
  void setEraserSize(double s) => value = value.copyWith(eraserSize: s);
  void setBackground(CanvasBackground bg) => value = value.copyWith(background: bg);
  void setInputMode(InputMode mode) => value = value.copyWith(inputMode: mode);

  void loadStrokes(List<InkStroke> strokes) {
    value = value.copyWith(strokes: strokes);
    _undoStack.clear();
    _redoStack.clear();
    _syncUndoRedo();
  }

  void _syncUndoRedo() {
    value = value.copyWith(
      canUndo: _undoStack.isNotEmpty,
      canRedo: _redoStack.isNotEmpty,
    );
  }

  int _idCounter = 0;
  String _nextId({String title = 'str'}) =>
      '${title}_${DateTime.now().microsecondsSinceEpoch}_${_idCounter++}';

  List<InkPoint> _simplify(List<InkPoint> points) {
    if (points.length <= 3) return points;
    const tol = 0.5;
    final result = <InkPoint>[points.first];
    for (var i = 1; i < points.length - 1; i++) {
      final dx = points[i - 1].x - points[i].x;
      final dy = points[i - 1].y - points[i].y;
      if (dx * dx + dy * dy > tol) result.add(points[i]);
    }
    result.add(points.last);
    return result;
  }


}

class CanvasState {
  final String pageId;
  final InkStroke? currentStroke;
  final List<InkStroke> strokes;
  final CanvasMode mode;
  final EraseMode eraseMode;
  final double penWidth;
  final int penColor;
  final double penOpacity;
  final double eraserSize;
  final CanvasBackground background;
  final InputMode inputMode;
  final double canvasWidth;
  final double canvasHeight;
  final bool canUndo;
  final bool canRedo;

  const CanvasState({
    required this.pageId,
    this.currentStroke,
    this.strokes = const [],
    this.mode = CanvasMode.draw,
    this.eraseMode = EraseMode.stroke,
    this.penWidth = 3.0,
    this.penColor = 0xFF212121,
    this.penOpacity = 1.0,
    this.eraserSize = 40.0,
    this.background = CanvasBackground.blank,
    this.inputMode = InputMode.finger,
    this.canvasWidth = 800,
    this.canvasHeight = 2000,
    this.canUndo = false,
    this.canRedo = false,
  });

  CanvasState copyWith({
    Object? currentStroke = _null,
    List<InkStroke>? strokes,
    CanvasMode? mode,
    EraseMode? eraseMode,
    double? penWidth,
    int? penColor,
    double? penOpacity,
    double? eraserSize,
    CanvasBackground? background,
    InputMode? inputMode,
    double? canvasWidth,
    double? canvasHeight,
    bool? canUndo,
    bool? canRedo,
  }) {
    return CanvasState(
      currentStroke: identical(currentStroke, _null)
          ? this.currentStroke
          : currentStroke as InkStroke?,
      strokes: strokes ?? this.strokes,
      mode: mode ?? this.mode,
      eraseMode: eraseMode ?? this.eraseMode,
      penWidth: penWidth ?? this.penWidth,
      penColor: penColor ?? this.penColor,
      penOpacity: penOpacity ?? this.penOpacity,
      eraserSize: eraserSize ?? this.eraserSize,
      background: background ?? this.background,
      inputMode: inputMode ?? this.inputMode,
      canvasWidth: canvasWidth ?? this.canvasWidth,
      canvasHeight: canvasHeight ?? this.canvasHeight,
      canUndo: canUndo ?? this.canUndo,
      canRedo: canRedo ?? this.canRedo,
      pageId: pageId,
    );
  }

  static const _null = Object();
}

enum CanvasActionType { addStroke, erase, clearCanvas }

class CanvasAction {
  final CanvasActionType type;
  final InkStroke? stroke;
  final List<InkStroke>? erased;
  final List<InkStroke> restored;
  final List<InkStroke> partials;

  const CanvasAction({
    required this.type,
    this.stroke,
    this.erased,
    this.restored = const [],
    this.partials = const [],
  });
}
