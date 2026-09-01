import 'world_countries.dart';

/// Shared geographic overlap checks for meetup vs route labels.
abstract final class MeetupLocationMatch {
  /// True when [meetupLabel] and [routeLabel] describe the same area.
  ///
  /// Uses bidirectional substring checks and token overlap so Google Places
  /// labels (e.g. "London, England, UK" vs "Canary Wharf, London, UK") match.
  static bool labelsInSameArea(
    String meetupLabel,
    String routeLabel, {
    String? routeCountryCode,
    String? meetupCountryCode,
  }) {
    final label = meetupLabel.trim().toLowerCase();
    final route = routeLabel.trim().toLowerCase();
    if (label.isEmpty || route.isEmpty) return false;

    final routeCc = routeCountryCode?.trim().toUpperCase();
    final meetupCc = meetupCountryCode?.trim().toUpperCase();
    if (routeCc != null &&
        routeCc.length == 2 &&
        meetupCc != null &&
        meetupCc.length == 2 &&
        routeCc != meetupCc) {
      return false;
    }

    if (label.contains(route) || route.contains(label)) return true;

    final routeTokens = _tokens(route, countryCode: routeCc);
    final labelTokens = _tokens(label, countryCode: meetupCc);

    for (final token in routeTokens) {
      if (_isSignificantToken(token) && label.contains(token)) return true;
    }
    for (final token in labelTokens) {
      if (_isSignificantToken(token) && route.contains(token)) return true;
    }

    if (routeCc != null &&
        routeCc.length == 2 &&
        meetupCc != null &&
        meetupCc.length == 2 &&
        routeCc == meetupCc) {
      final country = WorldCountries.byIso(routeCc);
      final countryName = country.name.toLowerCase();
      if (countryName.length >= 3 && label.contains(countryName)) {
        return true;
      }
    }

    return false;
  }

  static List<String> _tokens(String input, {String? countryCode}) {
    final tokens = <String>{};
    final normalized = input.trim().toLowerCase();
    if (normalized.isEmpty) return const [];

    for (final part in normalized.split(RegExp(r'[,;|]'))) {
      final trimmed = part.trim();
      if (trimmed.length >= 2) tokens.add(trimmed);
      for (final word in trimmed.split(RegExp(r'\s+'))) {
        if (word.length >= 2) tokens.add(word);
      }
    }

    final cc = countryCode?.trim().toUpperCase();
    if (cc != null && cc.length == 2) {
      tokens.add(cc.toLowerCase());
      if (WorldCountries.containsIso(cc)) {
        tokens.add(WorldCountries.byIso(cc).name.toLowerCase());
      }
    }

    return tokens.toList();
  }

  static bool _isSignificantToken(String token) {
    if (token.length >= 3) return true;
    return RegExp(r'^[a-z]{2}$').hasMatch(token);
  }
}
