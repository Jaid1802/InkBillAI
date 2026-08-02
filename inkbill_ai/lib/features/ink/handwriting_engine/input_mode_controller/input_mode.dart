import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

enum InkInputMode { finger, stylus }

final inkInputModeProvider = StateNotifierProvider<InkInputModeNotifier, InkInputMode>((ref) {
  return InkInputModeNotifier();
});

class InkInputModeNotifier extends StateNotifier<InkInputMode> {
  static const _key = 'ink_input_mode';

  InkInputModeNotifier() : super(InkInputMode.finger) {
    _load();
  }

  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();
    final value = prefs.getString(_key);
    if (value == 'stylus') {
      state = InkInputMode.stylus;
    }
  }

  Future<void> setMode(InkInputMode mode) async {
    state = mode;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_key, mode == InkInputMode.stylus ? 'stylus' : 'finger');
  }
}
