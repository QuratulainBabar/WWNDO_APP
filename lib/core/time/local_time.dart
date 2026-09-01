import 'package:intl/intl.dart';

/// Converts backend timestamps to the device timezone and formats them locally.
abstract final class LocalTime {
  static final _offsetSuffix = RegExp(r'[+-]\d{2}:?\d{2}$');

  /// Parses an API timestamp and returns device-local time.
  ///
  /// ISO strings with `Z` or an offset are converted with [DateTime.toLocal].
  /// Naive strings (no timezone) are treated as UTC, then converted locally.
  static DateTime? parse(dynamic value) {
    if (value == null) return null;
    if (value is DateTime) return value.toLocal();
    final raw = value.toString().trim();
    if (raw.isEmpty) return null;
    final parsed = DateTime.tryParse(raw);
    if (parsed == null) return null;
    if (parsed.isUtc) return parsed.toLocal();

    final hasOffset = raw.endsWith('Z') ||
        raw.endsWith('z') ||
        _offsetSuffix.hasMatch(raw);
    if (!hasOffset) {
      return DateTime.utc(
        parsed.year,
        parsed.month,
        parsed.day,
        parsed.hour,
        parsed.minute,
        parsed.second,
        parsed.millisecond,
        parsed.microsecond,
      ).toLocal();
    }
    return parsed.toLocal();
  }

  static String clock(DateTime value) =>
      DateFormat('h:mm a').format(value.toLocal());

  /// Inbox row: clock for today, otherwise Yesterday / weekday / date.
  static String inbox(DateTime value) {
    final local = value.toLocal();
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final day = DateTime(local.year, local.month, local.day);
    final diff = today.difference(day).inDays;
    if (diff <= 0) return clock(local);
    if (diff == 1) return 'Yesterday';
    if (diff < 7) return DateFormat('EEE').format(local);
    return DateFormat('MMM d').format(local);
  }
}
