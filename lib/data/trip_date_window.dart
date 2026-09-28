/// Active traveler trip window shown to senders (rolling, relative to today):
/// previous 5 days + today + next 7 days.
abstract final class TripDateWindow {
  static const int pastDays = 5;
  static const int futureDays = 7;

  static DateTime _dateOnly(DateTime d) => DateTime(d.year, d.month, d.day);

  static DateTime today([DateTime? now]) {
    final n = now ?? DateTime.now();
    return _dateOnly(n);
  }

  /// Inclusive earliest travel date (today − [pastDays]).
  static DateTime earliest([DateTime? now]) =>
      today(now).subtract(const Duration(days: pastDays));

  /// Inclusive latest travel date (today + [futureDays]).
  static DateTime latest([DateTime? now]) =>
      today(now).add(const Duration(days: futureDays));

  static bool contains(DateTime travelDate, [DateTime? now]) {
    final day = _dateOnly(travelDate);
    return !day.isBefore(earliest(now)) && !day.isAfter(latest(now));
  }

  /// Keeps only items whose travel date falls in the active sender-visible window.
  static List<T> filterByTravelDate<T>(
    Iterable<T> items,
    DateTime Function(T item) travelDateOf, [
    DateTime? now,
  ]) {
    return items
        .where((item) => contains(travelDateOf(item), now))
        .toList(growable: false);
  }

  static String get outOfRangeMessage =>
      'Travel date must be within the previous $pastDays days, today, or the next $futureDays days.';

  static String get senderVisibleRangeHint =>
      'Showing active traveler trips from the previous $pastDays days through today and the next $futureDays days.';

  /// Hint on the sender Matching Travelers screen (list is not capped to the
  /// browse window — matches use destination + luggage on open trips).
  static String get matchingListHint =>
      'Matched by destination and luggage capacity on open traveler trips.';
}
