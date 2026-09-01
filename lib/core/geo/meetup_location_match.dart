import 'dart:math' as math;

import '../../data/models/meetup_location.dart';
import 'world_airports.dart';
import 'world_cities.dart';
import 'world_countries.dart';

/// Shared geographic overlap checks for meetup vs route origin/destination.
abstract final class MeetupLocationMatch {
  /// Meetup is in the same metro area when within this distance of the airport
  /// / city pin. Covers airports that sit outside the urban core (CDG, LHR, LHE).
  static const metroRadiusKm = 100.0;

  /// Beyond this distance, coordinates alone reject the pin unless city names
  /// still match (geocoding error / very large metro).
  static const farRejectKm = 250.0;

  static const _noiseTokens = {
    'airport',
    'airports',
    'international',
    'intl',
    'terminal',
    'airfield',
    'aeroport',
    'aéroport',
    'aero',
    'road',
    'rd',
    'street',
    'st',
    'ave',
    'avenue',
    'blvd',
    'boulevard',
    'highway',
    'motorway',
    'drive',
    'lane',
    'way',
    'the',
    'and',
    'of',
    'near',
    'at',
    'province',
    'district',
    'division',
    'region',
    'state',
    'county',
    'city',
    'town',
    'area',
    'block',
    'sector',
    'phase',
  };

  /// True when [meetup] is in the same city/metro as [origin] (airport or city).
  ///
  /// Prefers coordinates when both pins have them, then locality / airport
  /// catalog city, then label overlap. Never treats "same country" as enough.
  static bool placesInSameArea({
    required MeetupLocation meetup,
    required MeetupLocation origin,
    String? originCityHint,
    String? originCountryCode,
  }) {
    final originCc = _realIso(originCountryCode) ?? _realIso(origin.countryCode);
    final meetupCc = _realIso(meetup.countryCode);
    if (originCc != null && meetupCc != null && originCc != meetupCc) {
      return false;
    }

    final originLat = origin.latitude;
    final originLng = origin.longitude;
    final meetupLat = meetup.latitude;
    final meetupLng = meetup.longitude;
    if (originLat != null &&
        originLng != null &&
        meetupLat != null &&
        meetupLng != null) {
      final km = distanceKm(originLat, originLng, meetupLat, meetupLng);
      if (km <= metroRadiusKm) return true;
      if (km > farRejectKm && !_citiesMatch(meetup, origin, originCityHint)) {
        return false;
      }
    }

    if (_citiesMatch(meetup, origin, originCityHint)) return true;

    final originCity = resolveCityName(origin, hint: originCityHint);
    return labelsInSameArea(
      '${meetup.name} ${meetup.address} ${meetup.locality ?? ''}',
      originCity,
      routeCountryCode: originCc,
      meetupCountryCode: meetupCc,
    );
  }

  /// True when [meetupLabel] and [routeLabel] describe the same city/area.
  static bool labelsInSameArea(
    String meetupLabel,
    String routeLabel, {
    String? routeCountryCode,
    String? meetupCountryCode,
  }) {
    final label = meetupLabel.trim().toLowerCase();
    final route = routeLabel.trim().toLowerCase();
    if (label.isEmpty || route.isEmpty) return false;

    final routeCc = _realIso(routeCountryCode);
    final meetupCc = _realIso(meetupCountryCode);
    if (routeCc != null && meetupCc != null && routeCc != meetupCc) {
      return false;
    }

    final routeCity = _cityFromRouteLabel(routeLabel);
    if (routeCity.isNotEmpty && _labelContainsCity(label, routeCity)) {
      return true;
    }

    if (label.contains(route) || route.contains(label)) {
      if (!_isNoiseToken(route) && !_isNoiseToken(label)) return true;
    }

    final routeTokens = _tokens(route);
    final labelTokens = _tokens(label);

    for (final token in routeTokens) {
      if (_isSignificantCityToken(token) && label.contains(token)) return true;
    }
    for (final token in labelTokens) {
      if (_isSignificantCityToken(token) && route.contains(token)) return true;
    }

    return false;
  }

  /// Best-effort city name for an airport or city pin.
  static String resolveCityName(MeetupLocation place, {String? hint}) {
    final locality = place.locality?.trim();
    if (locality != null && locality.isNotEmpty) return locality;

    final airport = WorldAirports.matchFromLabel(
      '${place.name} ${place.address} ${hint ?? ''}',
    );
    if (airport != null) return airport.city;

    final hinted = hint?.trim() ?? '';
    if (hinted.isNotEmpty) {
      final fromHint = _cityFromRouteLabel(hinted);
      if (fromHint.isNotEmpty) return fromHint;
    }

    final label = place.displayLabel.trim();
    final fromLabel = _cityFromRouteLabel(label);
    if (fromLabel.isNotEmpty) return fromLabel;

    return label.isNotEmpty ? label : place.name.trim();
  }

  static double distanceKm(
    double lat1,
    double lon1,
    double lat2,
    double lon2,
  ) {
    const earthKm = 6371.0;
    final dLat = _toRad(lat2 - lat1);
    final dLon = _toRad(lon2 - lon1);
    final a = math.sin(dLat / 2) * math.sin(dLat / 2) +
        math.cos(_toRad(lat1)) *
            math.cos(_toRad(lat2)) *
            math.sin(dLon / 2) *
            math.sin(dLon / 2);
    final c = 2 * math.atan2(math.sqrt(a), math.sqrt(1 - a));
    return earthKm * c;
  }

  static double _toRad(double deg) => deg * math.pi / 180;

  static bool _citiesMatch(
    MeetupLocation meetup,
    MeetupLocation origin,
    String? originCityHint,
  ) {
    final originCity = resolveCityName(origin, hint: originCityHint);
    final meetupCity = meetup.locality?.trim().isNotEmpty == true
        ? meetup.locality!.trim()
        : '';
    if (originCity.isNotEmpty && meetupCity.isNotEmpty) {
      if (_labelContainsCity(meetupCity.toLowerCase(), originCity)) return true;
      if (_labelContainsCity(originCity.toLowerCase(), meetupCity)) return true;
    }
    final meetupLabel =
        '${meetup.name} ${meetup.address} ${meetup.locality ?? ''}'.toLowerCase();
    return originCity.isNotEmpty && _labelContainsCity(meetupLabel, originCity);
  }

  static String _cityFromRouteLabel(String routeLabel) {
    final airport = WorldAirports.matchFromLabel(routeLabel);
    if (airport != null) return airport.city;

    final parts = routeLabel
        .split(RegExp(r'[,;|]'))
        .map((p) => p.trim())
        .where((p) => p.isNotEmpty)
        .toList();
    for (final part in parts) {
      final city = WorldCities.byName(part);
      if (city != null) return city.name;
      final firstWord = part.split(RegExp(r'\s+')).first;
      final byWord = WorldCities.byName(firstWord);
      if (byWord != null) return byWord.name;
    }
    return '';
  }

  static bool _labelContainsCity(String labelLower, String city) {
    final needle = city.trim().toLowerCase();
    if (needle.length < 2) return false;
    if (labelLower.contains(needle)) return true;
    final first = needle.split(RegExp(r'[\s-]')).first;
    if (first.length >= 4 && labelLower.contains(first)) return true;
    return false;
  }

  static String? _realIso(String? code) {
    final c = code?.trim().toUpperCase();
    if (c == null || c.length != 2 || c == 'XX') return null;
    if (!WorldCountries.containsIso(c)) return null;
    return c;
  }

  static List<String> _tokens(String input) {
    final tokens = <String>{};
    final normalized = input.trim().toLowerCase();
    if (normalized.isEmpty) return const [];

    for (final part in normalized.split(RegExp(r'[,;|]'))) {
      final trimmed = part.trim();
      if (trimmed.length >= 2 && !_isNoiseToken(trimmed)) {
        tokens.add(trimmed);
      }
      for (final word in trimmed.split(RegExp(r'\s+'))) {
        if (word.length >= 2 && !_isNoiseToken(word)) tokens.add(word);
      }
    }

    return tokens.toList();
  }

  static bool _isNoiseToken(String token) {
    final t = token.trim().toLowerCase();
    if (_noiseTokens.contains(t)) return true;
    if (WorldCountries.containsIso(t.toUpperCase()) && t.length == 2) {
      return true;
    }
    for (final country in WorldCountries.all) {
      if (country.name.toLowerCase() == t) return true;
    }
    return false;
  }

  static bool _isSignificantCityToken(String token) {
    if (_isNoiseToken(token)) return false;
    return token.length >= 3;
  }
}
