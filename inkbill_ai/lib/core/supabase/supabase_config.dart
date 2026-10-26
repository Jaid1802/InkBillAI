import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class SupabaseConfig {
  static const String url = String.fromEnvironment(
    'SUPABASE_URL',
    defaultValue: '',
  );

  static const String anonKey = String.fromEnvironment(
    'SUPABASE_ANON_KEY',
    defaultValue: '',
  );

  static bool get isConfigured => url.isNotEmpty && anonKey.isNotEmpty;

  static SupabaseClient get client => Supabase.instance.client;

  static Future<void> initialize() async {
    final effectiveUrl =
        isConfigured ? url : 'https://placeholder.supabase.co';
    final effectiveKey = isConfigured
        ? anonKey
        : 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InBsYWNlaG9sZGVyIiwicm9sZSI6ImFub24iLCJpYXQiOjE2MDAwMDAwMDAsImV4cCI6MTkwMDAwMDAwMH0.placeholder';

    await Supabase.initialize(
      url: effectiveUrl,
      anonKey: effectiveKey,
      debug: kDebugMode && isConfigured,
    );

    if (kDebugMode) {
      if (isConfigured) {
        debugPrint('Supabase initialized with target URL: $url');
      } else {
        debugPrint(
          'Supabase credentials not supplied via --dart-define. '
          'Initialized in local offline/guest fallback mode.',
        );
      }
    }
  }
}

final supabaseClientProvider = Provider<SupabaseClient>((ref) {
  return SupabaseConfig.client;
});
