/// Destination (To) matching — mirrors backend `destination_match.js`.
/// A traveler matches only when their To matches the sender's To.
///
/// City-to-city: compare city labels only (country ISO codes are not city ids).
/// Country-to-country: compare country ISO codes and/or country names.
abstract final class DestinationMatch {
  static String normalizePlace(String? value) {
    return (value ?? '')
        .toLowerCase()
        .replaceAll(RegExp(r'[^a-z0-9\s]'), ' ')
        .replaceAll(RegExp(r'\s+'), ' ')
        .trim();
  }

  /// Exact or containment match only (no loose token overlap).
  static bool placesMatch(String? a, String? b) {
    final left = normalizePlace(a);
    final right = normalizePlace(b);
    if (left.isEmpty || right.isEmpty) return false;
    if (left == right) return true;
    return left.contains(right) || right.contains(left);
  }

  static bool codesMatch(String? a, String? b) {
    final left = (a ?? '').trim().toUpperCase();
    final right = (b ?? '').trim().toUpperCase();
    if (left.isEmpty || right.isEmpty) return false;
    if (left == 'XX' || right == 'XX') return false;
    return left == right;
  }

  /// Hard filter: traveler destination must match sender destination.
  ///
  /// Pass [countryLevel] true for country-to-country routes. When false
  /// (city-to-city), [senderDestinationCode] / [travelerDestinationCode] are
  /// ignored because those fields store country ISO, not city identity.
  static bool destinationsMatch({
    required String senderDestination,
    required String travelerDestination,
    String? senderDestinationCode,
    String? travelerDestinationCode,
    bool countryLevel = false,
  }) {
    if (countryLevel) {
      if (codesMatch(senderDestinationCode, travelerDestinationCode)) {
        return true;
      }
      return placesMatch(senderDestination, travelerDestination);
    }
    return placesMatch(senderDestination, travelerDestination);
  }
}
