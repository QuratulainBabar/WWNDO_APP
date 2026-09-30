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

  /// Formats a stored departure time (`HH:mm`, `H:mm`, or already `h:mm a`)
  /// for sender-facing display with AM/PM (e.g. `9:00 AM`).
  static String formatDepartureTime(String? raw) {
    final value = raw?.trim() ?? '';
    if (value.isEmpty) return '';

    final withPeriod = RegExp(
      r'^(\d{1,2}):(\d{2})(?::\d{2})?\s*([AaPp][Mm])$',
    ).firstMatch(value);
    if (withPeriod != null) {
      var hour = int.parse(withPeriod.group(1)!);
      final minute = int.parse(withPeriod.group(2)!);
      final period = withPeriod.group(3)!.toUpperCase();
      if (period == 'AM') {
        if (hour == 12) hour = 0;
      } else if (hour != 12) {
        hour += 12;
      }
      if (hour > 23 || minute > 59) return value;
      return DateFormat('h:mm a').format(DateTime(2000, 1, 1, hour, minute));
    }

    final match = RegExp(r'^(\d{1,2}):(\d{2})(?::\d{2})?$').firstMatch(value);
    if (match == null) return value;

    final hour = int.tryParse(match.group(1)!);
    final minute = int.tryParse(match.group(2)!);
    if (hour == null ||
        minute == null ||
        hour < 0 ||
        hour > 23 ||
        minute < 0 ||
        minute > 59) {
      return value;
    }

    return DateFormat('h:mm a').format(DateTime(2000, 1, 1, hour, minute));
  }

  /// Inbox row: clock for today, otherwise Yesterday / weekday / date.
  static String inbox(
    DateTime value, {
    String? locale,
    String yesterdayLabel = 'Yesterday',
  }) {
    final local = value.toLocal();
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final day = DateTime(local.year, local.month, local.day);
    final diff = today.difference(day).inDays;
    if (diff <= 0) return clock(local);
    if (diff == 1) return yesterdayLabel;
    if (diff < 7) return DateFormat('EEE', locale).format(local);
    return DateFormat('MMM d', locale).format(local);
  }
}
