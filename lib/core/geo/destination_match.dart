/// Destination (To) matching — mirrors backend `destination_match.js`.
/// A traveler matches only when their To matches the sender's To.
///
/// City-to-city: compare city labels only (country ISO codes are not city ids).
/// Country-to-country air: compare country ISO codes and/or country names.
/// Country-to-country land: traveler To city must match the sender airport city.
abstract final class DestinationMatch {
  static String normalizePlace(String? value) {
    return (value ?? '')
        .toLowerCase()
        .replaceAll(RegExp(r'[^a-z0-9\s]'), ' ')
        .replaceAll(RegExp(r'\s+'), ' ')
        .trim();
  }

  /// Primary place token — usually the city (text before the first comma).
  /// Lets "Paris, France" match "Paris, Île-de-France, France".
  static String placeHead(String? value) {
    final raw = (value ?? '').trim();
    if (raw.isEmpty) return '';
    final head = raw.split(',').first;
    return normalizePlace(head);
  }

  /// Best-effort city from an airport / Places label.
  static String cityFromAirportOrPlaceLabel(String? value) {
    final raw = (value ?? '').trim();
    if (raw.isEmpty) return '';

    final parts = raw
        .split(RegExp(r'[,;|]'))
        .map((p) => p.trim())
        .where((p) => p.isNotEmpty)
        .toList();

    // "Airport, District, City, Country" → City (second-to-last)
    if (parts.length >= 4) return parts[parts.length - 2];
    // "Airport, City, Country" → City
    if (parts.length == 3) return parts[1];

    if (parts.length == 2) {
      final first = parts[0].replaceAll(RegExp(r'\([^)]*\)'), '').trim();
      if (!RegExp(r'\bairport\b', caseSensitive: false).hasMatch(first)) {
        return first;
      }
    }

    final cleaned = raw
        .replaceAll(RegExp(r'\([^)]*\)'), ' ')
        .replaceAll(
          RegExp(
            r'\b(international|intl|airport|aeroport|aéroport)\b',
            caseSensitive: false,
          ),
          ' ',
        )
        .replaceAll(RegExp(r'\s+'), ' ')
        .trim();
    return cleaned.isNotEmpty ? cleaned : (parts.isNotEmpty ? parts.first : raw);
  }

  /// Exact, containment, or matching city-head labels.
  static bool placesMatch(String? a, String? b) {
    final left = normalizePlace(a);
    final right = normalizePlace(b);
    if (left.isEmpty || right.isEmpty) return false;
    if (left == right) return true;
    if (left.contains(right) || right.contains(left)) return true;

    final leftHead = placeHead(a);
    final rightHead = placeHead(b);
    if (leftHead.isEmpty || rightHead.isEmpty) return false;
    if (leftHead == rightHead) return true;

    // Avoid ultra-short heads ("san", "st") causing false positives.
    if (leftHead.length < 4 || rightHead.length < 4) return false;
    return leftHead.contains(rightHead) || rightHead.contains(leftHead);
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
  ///
  /// When [landTraveler] is true with [countryLevel], match the traveler city
  /// against [senderAirportCity] (preferred explicit city of the sender's
  /// selected airport). Callers should pass the stored airport city when
  /// available rather than re-parsing the Places airport label.
  static bool destinationsMatch({
    required String senderDestination,
    required String travelerDestination,
    String? senderDestinationCode,
    String? travelerDestinationCode,
    bool countryLevel = false,
    bool landTraveler = false,
    String? senderAirportCity,
  }) {
    if (countryLevel && landTraveler) {
      final explicit = (senderAirportCity ?? '').trim();
      final String senderCity;
      if (explicit.isNotEmpty) {
        final fromExplicit = cityFromAirportOrPlaceLabel(explicit);
        final head = placeHead(explicit);
        senderCity = fromExplicit.isNotEmpty
            ? fromExplicit
            : (head.isNotEmpty ? head : explicit);
      } else {
        senderCity = cityFromAirportOrPlaceLabel(senderDestination);
      }
      final travelerCity = cityFromAirportOrPlaceLabel(travelerDestination);
      if (senderCity.isEmpty || travelerCity.isEmpty) return false;
      return placesMatch(senderCity, travelerCity);
    }

    if (countryLevel) {
      if (codesMatch(senderDestinationCode, travelerDestinationCode)) {
        return true;
      }
      return placesMatch(senderDestination, travelerDestination);
    }
    return placesMatch(senderDestination, travelerDestination);
  }
}
