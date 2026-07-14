import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class SupabaseConfig {
  static final String _url = const String.fromEnvironment(
    'SUPABASE_URL',
    defaultValue: 'https://rzgeniuyavrljqkafwyn.supabase.co',
  );

  static final String _anonKey = const String.fromEnvironment(
    'SUPABASE_ANON_KEY',
    defaultValue: 'sb_publishable_57GRPFwcgLw4l7qO1W-N6w_j3NpPGvE',
  );

  static SupabaseClient get client => Supabase.instance.client;

  static Future<void> initialize() async {
    await Supabase.initialize(
      url: _url,
      anonKey: _anonKey,
      debug: kDebugMode,
    );
    if (kDebugMode) debugPrint('Supabase initialized: $_url');
  }
}

final supabaseClientProvider = Provider<SupabaseClient>((ref) {
  return SupabaseConfig.client;
});
