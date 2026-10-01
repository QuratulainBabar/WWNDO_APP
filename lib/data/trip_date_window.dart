/// Travel-date windows for traveler trips shown to senders.
///
/// Discover / trip posting (relative to today):
/// previous 5 days + today + next 7 days.
///
/// Matching Travelers (relative to the delivery travel date):
/// delivery − 5 days through delivery + 7 days (inclusive).
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

  /// Inclusive earliest matching trip date for a delivery (delivery − [pastDays]).
  static DateTime earliestForDelivery(DateTime deliveryTravelDate) =>
      _dateOnly(deliveryTravelDate).subtract(const Duration(days: pastDays));

  /// Inclusive latest matching trip date for a delivery (delivery + [futureDays]).
  static DateTime latestForDelivery(DateTime deliveryTravelDate) =>
      _dateOnly(deliveryTravelDate).add(const Duration(days: futureDays));

  /// True when [tripTravelDate] is in the matching window for [deliveryTravelDate].
  static bool containsForDelivery(
    DateTime tripTravelDate,
    DateTime deliveryTravelDate,
  ) {
    final day = _dateOnly(tripTravelDate);
    return !day.isBefore(earliestForDelivery(deliveryTravelDate)) &&
        !day.isAfter(latestForDelivery(deliveryTravelDate));
  }

  /// Keeps only items whose travel date falls in the today-relative discover window.
  static List<T> filterByTravelDate<T>(
    Iterable<T> items,
    DateTime Function(T item) travelDateOf, [
    DateTime? now,
  ]) {
    return items
        .where((item) => contains(travelDateOf(item), now))
        .toList(growable: false);
  }

  /// Keeps only items whose travel date falls in the delivery matching window.
  static List<T> filterByDeliveryTravelDate<T>(
    Iterable<T> items,
    DateTime Function(T item) travelDateOf,
    DateTime deliveryTravelDate,
  ) {
    return items
        .where(
          (item) => containsForDelivery(travelDateOf(item), deliveryTravelDate),
        )
        .toList(growable: false);
  }

  static String get outOfRangeMessage =>
      'Travel date must be within the previous $pastDays days, today, or the next $futureDays days.';

  static String get senderVisibleRangeHint =>
      'Showing active traveler trips from the previous $pastDays days through today and the next $futureDays days.';

  /// Hint on the sender Matching Travelers screen (delivery-relative window).
  static String get matchingListHint =>
      'Matched by destination and luggage capacity on open traveler trips within $pastDays days before through $futureDays days after your delivery date.';
}
