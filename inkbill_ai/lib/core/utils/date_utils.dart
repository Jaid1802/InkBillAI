import 'package:intl/intl.dart';

class DateUtils {
  DateUtils._();

  static final DateFormat _dateFormatter = DateFormat('dd/MM/yyyy');
  static final DateFormat _timeFormatter = DateFormat('HH:mm:ss');
  static final DateFormat _dateTimeFormatter = DateFormat('dd/MM/yyyy HH:mm:ss');
  static final DateFormat _isoFormatter = DateFormat("yyyy-MM-dd'T'HH:mm:ss'Z'");

  static String formatDate(DateTime date) => _dateFormatter.format(date);
  static String formatTime(DateTime date) => _timeFormatter.format(date);
  static String formatDateTime(DateTime date) => _dateTimeFormatter.format(date);
  static String toIso(DateTime date) => _isoFormatter.format(date);

  static DateTime? parseIso(String date) {
    try {
      return _isoFormatter.parse(date);
    } catch (_) {
      return null;
    }
  }

  static String formatDuration(Duration duration) {
    final hours = duration.inHours;
    final minutes = duration.inMinutes.remainder(60);
    final seconds = duration.inSeconds.remainder(60);
    final ms = duration.inMilliseconds.remainder(1000);
    if (hours > 0) {
      return '${hours}h ${minutes}m ${seconds}s';
    } else if (minutes > 0) {
      return '${minutes}m ${seconds}s';
    } else {
      return '$seconds.${ms ~/ 100}s';
    }
  }

  static String timeAgo(DateTime date) {
    final now = DateTime.now();
    final diff = now.difference(date);
    if (diff.inDays > 365) return '${diff.inDays ~/ 365}y ago';
    if (diff.inDays > 30) return '${diff.inDays ~/ 30}mo ago';
    if (diff.inDays > 0) return '${diff.inDays}d ago';
    if (diff.inHours > 0) return '${diff.inHours}h ago';
    if (diff.inMinutes > 0) return '${diff.inMinutes}m ago';
    return 'just now';
  }
}
