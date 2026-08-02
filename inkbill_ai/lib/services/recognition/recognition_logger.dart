import 'dart:developer' as dev;

class RecognitionLogger {
  static final List<String> _logs = [];
  static int _sequence = 0;
  static bool _enabled = true;

  static void log(String message) {
    if (!_enabled) return;
    _sequence++;
    final entry = '[OCR#${
        _sequence.toString().padLeft(4, '0')}] ${_timestamp()} $message';
    _logs.add(entry);
    if (_logs.length > 500) _logs.removeAt(0);
    dev.log(entry, name: 'OCR');
  }

  static void stage(String stage, String detail) {
    log('STAGE $stage: $detail');
  }

  static void error(String context, dynamic error, [StackTrace? stack]) {
    log('ERROR in $context: $error');
    if (stack != null) {
      final trace = stack.toString().split('\n').take(3).join('; ');
      log('  STACK: $trace');
    }
  }

  static void memory() {
    log('Memory snapshot (not available in Dart VM)');
  }

  static List<String> get logs => List.unmodifiable(_logs);

  static String get summary {
    if (_logs.isEmpty) return 'No logs';
    final errors =
        _logs.where((l) => l.contains('ERROR')).length;
    return '${_logs.length} events, $errors errors';
  }

  static void reset() {
    _logs.clear();
    _sequence = 0;
  }

  static String _timestamp() {
    final now = DateTime.now();
    return '${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}:${now.second.toString().padLeft(2, '0')}.${now.millisecond.toString().padLeft(3, '0')}';
  }
}
