import 'world_countries.dart';

/// Major airports keyed by ISO country code for country-to-country routes.
class WorldAirport {
  const WorldAirport({
    required this.code,
    required this.name,
    required this.city,
    required this.countryIso,
  });

  final String code;
  final String name;
  final String city;
  final String countryIso;

  /// Stored / API label, e.g. `Paris Charles de Gaulle (CDG)`.
  String get label => '$name ($code)';

  /// Suggestion title shown in search results.
  String get resultTitle => label;

  String get locationSubtitle {
    final country = WorldCountries.byIso(countryIso).name;
    return '$city, $country';
  }

  String get searchText =>
      '$name $code $city $countryIso ${WorldCountries.byIso(countryIso).name}'
          .toLowerCase();
}

abstract final class WorldAirports {
  static const List<WorldAirport> all = [
    // France
    WorldAirport(
      code: 'CDG',
      name: 'Paris Charles de Gaulle',
      city: 'Paris',
      countryIso: 'FR',
    ),
    WorldAirport(
      code: 'ORY',
      name: 'Paris Orly',
      city: 'Paris',
      countryIso: 'FR',
    ),
    WorldAirport(
      code: 'BVA',
      name: 'Beauvais Tillé',
      city: 'Beauvais',
      countryIso: 'FR',
    ),
    WorldAirport(
      code: 'LYS',
      name: 'Lyon-Saint Exupéry',
      city: 'Lyon',
      countryIso: 'FR',
    ),
    WorldAirport(
      code: 'MRS',
      name: 'Marseille Provence',
      city: 'Marseille',
      countryIso: 'FR',
    ),
    WorldAirport(
      code: 'NCE',
      name: 'Nice Côte d\'Azur',
      city: 'Nice',
      countryIso: 'FR',
    ),
    // Senegal
    WorldAirport(
      code: 'DSS',
      name: 'Blaise Diagne',
      city: 'Dakar',
      countryIso: 'SN',
    ),
    WorldAirport(
      code: 'DKR',
      name: 'Léopold Sédar Senghor',
      city: 'Dakar',
      countryIso: 'SN',
    ),
    // UAE
    WorldAirport(
      code: 'DXB',
      name: 'Dubai International',
      city: 'Dubai',
      countryIso: 'AE',
    ),
    WorldAirport(
      code: 'AUH',
      name: 'Abu Dhabi International',
      city: 'Abu Dhabi',
      countryIso: 'AE',
    ),
    WorldAirport(
      code: 'SHJ',
      name: 'Sharjah International',
      city: 'Sharjah',
      countryIso: 'AE',
    ),
    // Nigeria
    WorldAirport(
      code: 'LOS',
      name: 'Murtala Muhammed',
      city: 'Lagos',
      countryIso: 'NG',
    ),
    WorldAirport(
      code: 'ABV',
      name: 'Nnamdi Azikiwe',
      city: 'Abuja',
      countryIso: 'NG',
    ),
    // UK
    WorldAirport(
      code: 'LHR',
      name: 'London Heathrow',
      city: 'London',
      countryIso: 'GB',
    ),
    WorldAirport(
      code: 'LGW',
      name: 'London Gatwick',
      city: 'London',
      countryIso: 'GB',
    ),
    WorldAirport(
      code: 'STN',
      name: 'London Stansted',
      city: 'London',
      countryIso: 'GB',
    ),
    WorldAirport(
      code: 'LTN',
      name: 'London Luton',
      city: 'London',
      countryIso: 'GB',
    ),
    WorldAirport(
      code: 'LCY',
      name: 'London City',
      city: 'London',
      countryIso: 'GB',
    ),
    WorldAirport(
      code: 'MAN',
      name: 'Manchester',
      city: 'Manchester',
      countryIso: 'GB',
    ),
    // US
    WorldAirport(
      code: 'JFK',
      name: 'John F. Kennedy',
      city: 'New York',
      countryIso: 'US',
    ),
    WorldAirport(
      code: 'EWR',
      name: 'Newark Liberty',
      city: 'Newark',
      countryIso: 'US',
    ),
    WorldAirport(
      code: 'LAX',
      name: 'Los Angeles International',
      city: 'Los Angeles',
      countryIso: 'US',
    ),
    WorldAirport(
      code: 'ORD',
      name: 'O\'Hare International',
      city: 'Chicago',
      countryIso: 'US',
    ),
    // Canada
    WorldAirport(
      code: 'YYZ',
      name: 'Toronto Pearson',
      city: 'Toronto',
      countryIso: 'CA',
    ),
    WorldAirport(
      code: 'YVR',
      name: 'Vancouver International',
      city: 'Vancouver',
      countryIso: 'CA',
    ),
    // Germany
    WorldAirport(
      code: 'FRA',
      name: 'Frankfurt',
      city: 'Frankfurt',
      countryIso: 'DE',
    ),
    WorldAirport(
      code: 'MUC',
      name: 'Munich',
      city: 'Munich',
      countryIso: 'DE',
    ),
    // Spain
    WorldAirport(
      code: 'MAD',
      name: 'Madrid-Barajas',
      city: 'Madrid',
      countryIso: 'ES',
    ),
    WorldAirport(
      code: 'BCN',
      name: 'Barcelona-El Prat',
      city: 'Barcelona',
      countryIso: 'ES',
    ),
    // Italy
    WorldAirport(
      code: 'FCO',
      name: 'Rome Fiumicino',
      city: 'Rome',
      countryIso: 'IT',
    ),
    WorldAirport(
      code: 'MXP',
      name: 'Milan Malpensa',
      city: 'Milan',
      countryIso: 'IT',
    ),
    // Netherlands
    WorldAirport(
      code: 'AMS',
      name: 'Amsterdam Schiphol',
      city: 'Amsterdam',
      countryIso: 'NL',
    ),
    // Belgium
    WorldAirport(
      code: 'BRU',
      name: 'Brussels',
      city: 'Brussels',
      countryIso: 'BE',
    ),
    // Turkey
    WorldAirport(
      code: 'IST',
      name: 'Istanbul',
      city: 'Istanbul',
      countryIso: 'TR',
    ),
    // Morocco
    WorldAirport(
      code: 'CMN',
      name: 'Casablanca Mohammed V',
      city: 'Casablanca',
      countryIso: 'MA',
    ),
    // Egypt
    WorldAirport(
      code: 'CAI',
      name: 'Cairo International',
      city: 'Cairo',
      countryIso: 'EG',
    ),
    // South Africa
    WorldAirport(
      code: 'JNB',
      name: 'O.R. Tambo',
      city: 'Johannesburg',
      countryIso: 'ZA',
    ),
    WorldAirport(
      code: 'CPT',
      name: 'Cape Town International',
      city: 'Cape Town',
      countryIso: 'ZA',
    ),
    // India
    WorldAirport(
      code: 'DEL',
      name: 'Indira Gandhi International',
      city: 'Delhi',
      countryIso: 'IN',
    ),
    WorldAirport(
      code: 'BOM',
      name: 'Chhatrapati Shivaji Maharaj',
      city: 'Mumbai',
      countryIso: 'IN',
    ),
    // Pakistan
    WorldAirport(
      code: 'KHI',
      name: 'Jinnah International',
      city: 'Karachi',
      countryIso: 'PK',
    ),
    WorldAirport(
      code: 'LHE',
      name: 'Allama Iqbal International',
      city: 'Lahore',
      countryIso: 'PK',
    ),
    WorldAirport(
      code: 'ISB',
      name: 'Islamabad International',
      city: 'Islamabad',
      countryIso: 'PK',
    ),
    // China
    WorldAirport(
      code: 'PEK',
      name: 'Beijing Capital',
      city: 'Beijing',
      countryIso: 'CN',
    ),
    WorldAirport(
      code: 'PVG',
      name: 'Shanghai Pudong',
      city: 'Shanghai',
      countryIso: 'CN',
    ),
    // Japan
    WorldAirport(
      code: 'NRT',
      name: 'Narita International',
      city: 'Tokyo',
      countryIso: 'JP',
    ),
    WorldAirport(
      code: 'HND',
      name: 'Haneda',
      city: 'Tokyo',
      countryIso: 'JP',
    ),
    // Australia
    WorldAirport(
      code: 'SYD',
      name: 'Sydney Kingsford Smith',
      city: 'Sydney',
      countryIso: 'AU',
    ),
    WorldAirport(
      code: 'MEL',
      name: 'Melbourne',
      city: 'Melbourne',
      countryIso: 'AU',
    ),
    // Brazil
    WorldAirport(
      code: 'GRU',
      name: 'São Paulo Guarulhos',
      city: 'São Paulo',
      countryIso: 'BR',
    ),
    // Ghana
    WorldAirport(
      code: 'ACC',
      name: 'Kotoka International',
      city: 'Accra',
      countryIso: 'GH',
    ),
    // Ivory Coast
    WorldAirport(
      code: 'ABJ',
      name: 'Félix-Houphouët-Boigny',
      city: 'Abidjan',
      countryIso: 'CI',
    ),
    // Kenya
    WorldAirport(
      code: 'NBO',
      name: 'Jomo Kenyatta',
      city: 'Nairobi',
      countryIso: 'KE',
    ),
    // Saudi Arabia
    WorldAirport(
      code: 'JED',
      name: 'King Abdulaziz',
      city: 'Jeddah',
      countryIso: 'SA',
    ),
    WorldAirport(
      code: 'RUH',
      name: 'King Khalid',
      city: 'Riyadh',
      countryIso: 'SA',
    ),
  ];

  static List<WorldAirport> forCountry(String iso) {
    final code = iso.trim().toUpperCase();
    return all.where((a) => a.countryIso == code).toList();
  }

  static WorldAirport? byCode(String code) {
    final normalized = code.trim().toUpperCase();
    for (final airport in all) {
      if (airport.code == normalized) return airport;
    }
    return null;
  }

  static WorldAirport? byLabel(String label) {
    final trimmed = label.trim();
    final lower = trimmed.toLowerCase();
    for (final airport in all) {
      if (airport.label == trimmed ||
          airport.resultTitle == trimmed ||
          airport.code == trimmed.toUpperCase() ||
          airport.name.toLowerCase() == lower) {
        return airport;
      }
    }
    // Match legacy labels like "Charles de Gaulle (CDG)" after name updates.
    final codeMatch = RegExp(r'\(([A-Z]{3})\)').firstMatch(trimmed);
    if (codeMatch != null) {
      return byCode(codeMatch.group(1)!);
    }
    return null;
  }

  /// Resolve a Google Places airport label to a catalog row (city + country).
  static WorldAirport? matchFromLabel(String label) {
    final exact = byLabel(label);
    if (exact != null) return exact;

    final hay = label.trim().toLowerCase();
    if (hay.isEmpty) return null;

    for (final match in RegExp(r'\b([a-z]{3})\b').allMatches(hay)) {
      final found = byCode(match.group(1)!);
      if (found != null) return found;
    }

    WorldAirport? best;
    var bestLen = 0;
    for (final airport in all) {
      final name = airport.name.toLowerCase();
      if (name.length >= 5 && hay.contains(name) && name.length > bestLen) {
        best = airport;
        bestLen = name.length;
      }
    }
    return best;
  }

  static WorldAirport? firstForCountry(String iso) {
    final list = forCountry(iso);
    return list.isEmpty ? null : list.first;
  }

  static List<WorldAirport> searchInCountry(String iso, String query) {
    final airports = forCountry(iso);
    final q = query.trim().toLowerCase();
    if (q.isEmpty) return airports;
    return airports.where((a) => _matches(a, q)).toList();
  }

  /// Global airport search by city, airport name, or IATA code.
  static List<WorldAirport> search(String query, {int limit = 8}) {
    final q = query.trim().toLowerCase();
    if (q.isEmpty) return const [];

    final matches = all.where((a) => _matches(a, q)).toList();
    matches.sort((a, b) {
      final aScore = _rank(a, q);
      final bScore = _rank(b, q);
      if (aScore != bScore) return aScore.compareTo(bScore);
      return a.resultTitle.compareTo(b.resultTitle);
    });
    if (limit <= 0 || matches.length <= limit) return matches;
    return matches.take(limit).toList();
  }

  static int searchCount(String query) {
    final q = query.trim().toLowerCase();
    if (q.isEmpty) return 0;
    return all.where((a) => _matches(a, q)).length;
  }

  static bool _matches(WorldAirport airport, String q) {
    return airport.searchText.contains(q);
  }

  static int _rank(WorldAirport airport, String q) {
    final city = airport.city.toLowerCase();
    final code = airport.code.toLowerCase();
    final name = airport.name.toLowerCase();
    if (code == q) return 0;
    if (city == q) return 1;
    if (city.startsWith(q)) return 2;
    if (name.startsWith(q)) return 3;
    if (code.startsWith(q)) return 4;
    if (city.contains(q)) return 5;
    if (name.contains(q)) return 6;
    return 7;
  }

  /// Countries that have at least one airport in the catalog.
  static Set<String> get countryIsosWithAirports =>
      {for (final a in all) a.countryIso};
}
