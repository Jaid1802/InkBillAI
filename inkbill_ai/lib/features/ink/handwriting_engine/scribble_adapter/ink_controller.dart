import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:scribble/scribble.dart';

import '../input_mode_controller/input_mode.dart';

final inkControllerProvider = Provider<ScribbleNotifier>((ref) {
  final notifier = ScribbleNotifier(
    widths: const [2, 3, 5, 8, 12],
    allowedPointersMode: ScribblePointerMode.all,
    maxHistoryLength: 50,
  );

  ref.onDispose(() => notifier.dispose());

  ref.listen<InkInputMode>(inkInputModeProvider, (prev, mode) {
    notifier.setAllowedPointersMode(_modeToScribble(mode));
  });

  final initialMode = ref.read(inkInputModeProvider);
  notifier.setAllowedPointersMode(_modeToScribble(initialMode));

  return notifier;
});

ScribblePointerMode _modeToScribble(InkInputMode mode) {
  switch (mode) {
    case InkInputMode.finger:
      return ScribblePointerMode.all;
    case InkInputMode.stylus:
      return ScribblePointerMode.penOnly;
  }
}

final inkSketchProvider = Provider<Sketch>((ref) {
  return ref.watch(inkControllerProvider).currentSketch;
});
