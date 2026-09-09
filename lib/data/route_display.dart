// Shared helpers for corridor route labels on list cards and summaries.
// Prefer compact "City, Country" over long Google Places / street addresses.

import '../core/geo/world_airports.dart';
import '../core/geo/world_countries.dart';

String firstNonEmpty(Iterable<String?> values) {
  for (final value in values) {
    final trimmed = value?.trim();
    if (trimmed != null && trimmed.isNotEmpty) return trimmed;
  }
  return '';
}

String formatRouteArrow(String from, String to) {
  if (from.isEmpty && to.isEmpty) return '';
  if (from.isEmpty) return to;
  if (to.isEmpty) return from;
  return '$from → $to';
}

String routeLeft(String? route) {
  final raw = route?.trim() ?? '';
  if (raw.isEmpty) return '';
  if (!raw.contains('→')) return raw;
  return raw.split('→').first.trim();
}

String routeRight(String? route) {
  final raw = route?.trim() ?? '';
  if (raw.isEmpty || !raw.contains('→')) return '';
  return raw.split('→').last.trim();
}

bool _looksLikeFullAddress(String value) {
  final commas = ','.allMatches(value).length;
  return commas >= 2 || value.length > 48;
}

String? _joinCityCountry(String city, String? country) {
  final c = city.trim();
  if (c.isEmpty) return null;
  final co = country?.trim() ?? '';
  if (co.isEmpty) return c;
  if (c.toLowerCase().endsWith(co.toLowerCase())) return c;
  return '$c, $co';
}

/// Shorten Places / airport labels to list-friendly "City, Country".
///
/// Examples:
/// - `Amsterdam Airport Schiphol (AMS), Evert van de Beekstraat, …`
///   → `Amsterdam, Netherlands`
/// - `Copenhagen Airport (CPH), Lufthavnsboulevarden, …`
///   → `Copenhagen, Denmark`
String compactRouteEndpoint(String? label, {String? country}) {
  final raw = label?.trim() ?? '';
  if (raw.isEmpty) return '';

  final catalog = WorldAirports.matchFromLabel(raw);
  if (catalog != null) return catalog.locationSubtitle;

  if (!_looksLikeFullAddress(raw)) {
    return _joinCityCountry(raw, country) ?? raw;
  }

  final parts = raw
      .split(',')
      .map((p) => p.trim())
      .where((p) => p.isNotEmpty)
      .toList();
  final countryPart = (country != null && country.trim().isNotEmpty)
      ? country.trim()
      : (parts.isNotEmpty ? parts.last : '');

  final head = parts.isNotEmpty ? parts.first : raw;
  final airportCity = RegExp(
    r'^(.+?)\s+Airport\b',
    caseSensitive: false,
  ).firstMatch(head);
  if (airportCity != null && countryPart.isNotEmpty) {
    final city = airportCity.group(1)!.trim();
    if (city.isNotEmpty) return '$city, $countryPart';
  }

  if (parts.length >= 2) {
    return '${parts[parts.length - 2]}, ${parts.last}';
  }

  return raw;
}

bool _isBareCountryLabel(String value, String? country) {
  final v = value.trim();
  if (v.isEmpty) return true;
  final co = country?.trim() ?? '';
  if (co.isNotEmpty && v.toLowerCase() == co.toLowerCase()) return true;
  final lower = v.toLowerCase();
  for (final c in WorldCountries.all) {
    if (c.name.toLowerCase() == lower) return true;
  }
  return false;
}

/// Compact city / country preferred over raw Places airport strings.
///
/// For country-to-country, prefer the selected airport / map place when `city`
/// is empty or is only a bare country name (e.g. `Netherlands`).
String displayRouteEndpoint({
  String? airport,
  String? city,
  String? country,
  String? routeFallback,
}) {
  final cityTrim = city?.trim() ?? '';
  final airportTrim = airport?.trim() ?? '';

  if (airportTrim.isNotEmpty &&
      (_isBareCountryLabel(cityTrim, country) ||
          _looksLikeFullAddress(cityTrim))) {
    final fromAirport = compactRouteEndpoint(airportTrim, country: country);
    if (fromAirport.isNotEmpty) return fromAirport;
  }

  if (cityTrim.isNotEmpty && !_looksLikeFullAddress(cityTrim)) {
    return _joinCityCountry(cityTrim, country) ?? cityTrim;
  }

  final fromAirport = compactRouteEndpoint(airportTrim, country: country);
  if (fromAirport.isNotEmpty) return fromAirport;

  if (cityTrim.isNotEmpty) {
    return compactRouteEndpoint(cityTrim, country: country);
  }

  return firstNonEmpty([country, routeFallback]);
}

/// Sender-selected Google Places / airport label as stored — no City,Country
/// compaction. Prefer map place over bare country names.
String exactRouteEndpoint({
  String? airport,
  String? city,
  String? country,
  String? routeFallback,
}) {
  final airportTrim = airport?.trim() ?? '';
  if (airportTrim.isNotEmpty) return airportTrim;

  final cityTrim = city?.trim() ?? '';
  if (cityTrim.isNotEmpty && !_isBareCountryLabel(cityTrim, country)) {
    return cityTrim;
  }

  final fallback = routeFallback?.trim() ?? '';
  if (fallback.isNotEmpty && !_isBareCountryLabel(fallback, country)) {
    return fallback;
  }

  if (cityTrim.isNotEmpty) return cityTrim;
  return firstNonEmpty([country, fallback]);
}
