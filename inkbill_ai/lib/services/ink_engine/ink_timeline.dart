import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:inkbill_ai/features/handwriting/domain/entities/ink_stroke.dart';
import 'package:inkbill_ai/features/handwriting/domain/entities/ink_timeline_event.dart';

enum PlaybackState { stopped, playing, paused }

class InkTimeline extends ValueNotifier<PlaybackState> {
  final List<InkTimelineEvent> _events = [];
  final List<InkStroke> _strokes = [];
  int _currentEventIndex = 0;
  Timer? _playbackTimer;
  double _playbackSpeed = 1.0;

  final StreamController<List<InkStroke>> _frameController =
      StreamController<List<InkStroke>>.broadcast();

  Stream<List<InkStroke>> get onFrame => _frameController.stream;
  List<InkTimelineEvent> get events => List.unmodifiable(_events);
  List<InkStroke> get allStrokes => List.unmodifiable(_strokes);
  int get currentIndex => _currentEventIndex;
  int get totalEvents => _events.length;
  double get progress => totalEvents > 0 ? _currentEventIndex / totalEvents : 0;

  InkTimeline() : super(PlaybackState.stopped);

  void recordEvent(InkTimelineEvent event, InkStroke stroke) {
    _events.add(event);
    if (event.type == TimelineEventType.strokeEnd) {
      _strokes.add(stroke);
    }
    notifyListeners();
  }

  void recordStrokeBegin(InkStroke stroke) {
    _events.add(InkTimelineEvent(
      id: 'evt_${stroke.id}_begin',
      type: TimelineEventType.strokeBegin,
      strokeId: stroke.id,
      pageId: stroke.pageId,
      timestampMs: stroke.points.isNotEmpty ? stroke.points.first.timestampMs : 0,
    ));
    notifyListeners();
  }

  void recordStrokeEnd(InkStroke stroke) {
    _events.add(InkTimelineEvent(
      id: 'evt_${stroke.id}_end',
      type: TimelineEventType.strokeEnd,
      strokeId: stroke.id,
      pageId: stroke.pageId,
      timestampMs: stroke.points.isNotEmpty ? stroke.points.last.timestampMs : 0,
    ));
    _strokes.add(stroke);
    notifyListeners();
  }

  void recordStrokeErase(String strokeId, String pageId) {
    _events.add(InkTimelineEvent(
      id: 'evt_erase_$strokeId',
      type: TimelineEventType.strokeErase,
      strokeId: strokeId,
      pageId: pageId,
      timestampMs: DateTime.now().millisecondsSinceEpoch,
    ));
    _strokes.removeWhere((s) => s.id == strokeId);
    notifyListeners();
  }

  void recordUndo(InkStroke undoneStroke) {
    _events.add(InkTimelineEvent(
      id: 'evt_undo_${DateTime.now().microsecondsSinceEpoch}',
      type: TimelineEventType.undo,
      strokeId: undoneStroke.id,
      pageId: undoneStroke.pageId,
      timestampMs: DateTime.now().millisecondsSinceEpoch,
    ));
    _strokes.removeWhere((s) => s.id == undoneStroke.id);
    notifyListeners();
  }

  void play({double speed = 1.0}) {
    if (_events.isEmpty) return;
    _playbackSpeed = speed;
    _currentEventIndex = 0;

    value = PlaybackState.playing;

    _startPlayback();
  }

  void _startPlayback() {
    _playbackTimer?.cancel();
    _scheduleNextFrame();
  }

  void _scheduleNextFrame() {
    if (_currentEventIndex >= _events.length) {
      value = PlaybackState.stopped;
      return;
    }

    final event = _events[_currentEventIndex];
    final currentStrokes = List<InkStroke>.from(_strokes);

    _processEvent(event, currentStrokes);
    _currentEventIndex++;

    _playbackTimer = Timer(
      Duration(milliseconds: (16 / _playbackSpeed).round()),
      _scheduleNextFrame,
    );
  }

  void _processEvent(InkTimelineEvent event, List<InkStroke> currentStrokes) {
    switch (event.type) {
      case TimelineEventType.strokeEnd:
        _frameController.add([...currentStrokes.where((s) => !s.isErased)]);
        break;
      case TimelineEventType.strokeErase:
        _frameController.add([
          ...currentStrokes.where((s) => s.id != event.strokeId),
        ]);
        break;
      default:
        _frameController.add([...currentStrokes.where((s) => !s.isErased)]);
    }
  }

  void pause() {
    _playbackTimer?.cancel();
    value = PlaybackState.paused;
  }

  void resume() {
    if (value == PlaybackState.paused) {
      value = PlaybackState.playing;
      _scheduleNextFrame();
    }
  }

  void stop() {
    _playbackTimer?.cancel();
    value = PlaybackState.stopped;
    _currentEventIndex = 0;
    _frameController.add([]);
  }

  void seekTo(double progress) {
    if (_events.isEmpty) return;
    final paused = value == PlaybackState.paused;
    stop();
    _currentEventIndex = (progress * _events.length).round();
    if (paused) {
      value = PlaybackState.paused;
      _frameController.add(_getStrokesUpTo(_currentEventIndex));
    }
  }

  List<InkStroke> _getStrokesUpTo(int index) {
    final strokes = <InkStroke>[];
    for (var i = 0; i < index && i < _events.length; i++) {
      final event = _events[i];
      if (event.type == TimelineEventType.strokeEnd) {
        final stroke = _strokes.firstWhere(
          (s) => s.id == event.strokeId,
          orElse: () => _strokes.last,
        );
        strokes.add(stroke);
      } else if (event.type == TimelineEventType.strokeErase) {
        strokes.removeWhere((s) => s.id == event.strokeId);
      }
    }
    return strokes;
  }

  void loadFromStrokes(List<InkStroke> strokes) {
    _events.clear();
    _strokes.clear();

    for (final stroke in strokes) {
      if (stroke.points.isEmpty) continue;
      _events.add(InkTimelineEvent(
        id: 'evt_${stroke.id}_begin',
        type: TimelineEventType.strokeBegin,
        strokeId: stroke.id,
        pageId: stroke.pageId,
        timestampMs: stroke.points.first.timestampMs,
      ));
      _events.add(InkTimelineEvent(
        id: 'evt_${stroke.id}_end',
        type: TimelineEventType.strokeEnd,
        strokeId: stroke.id,
        pageId: stroke.pageId,
        timestampMs: stroke.points.last.timestampMs,
      ));
    }
    _strokes.addAll(strokes);
    notifyListeners();
  }

  void clear() {
    stop();
    _events.clear();
    _strokes.clear();
    _currentEventIndex = 0;
    _frameController.add([]);
    notifyListeners();
  }

  @override
  void dispose() {
    _playbackTimer?.cancel();
    _frameController.close();
    super.dispose();
  }
}
