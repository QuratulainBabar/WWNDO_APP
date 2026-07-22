/// Major airports keyed by ISO country code for country-to-country routes.
class WorldAirport {
  const WorldAirport({
    required this.code,
    required this.name,
    required this.countryIso,
  });

  final String code;
  final String name;
  final String countryIso;

  String get label => '$name ($code)';

  String get searchText => '$name $code $countryIso'.toLowerCase();
}

abstract final class WorldAirports {
  static const List<WorldAirport> all = [
    // France
    WorldAirport(code: 'CDG', name: 'Charles de Gaulle', countryIso: 'FR'),
    WorldAirport(code: 'ORY', name: 'Paris Orly', countryIso: 'FR'),
    WorldAirport(code: 'LYS', name: 'Lyon-Saint Exupéry', countryIso: 'FR'),
    WorldAirport(code: 'MRS', name: 'Marseille Provence', countryIso: 'FR'),
    WorldAirport(code: 'NCE', name: 'Nice Côte d\'Azur', countryIso: 'FR'),
    // Senegal
    WorldAirport(code: 'DSS', name: 'Blaise Diagne', countryIso: 'SN'),
    WorldAirport(code: 'DKR', name: 'Léopold Sédar Senghor', countryIso: 'SN'),
    // UAE
    WorldAirport(code: 'DXB', name: 'Dubai International', countryIso: 'AE'),
    WorldAirport(code: 'AUH', name: 'Abu Dhabi International', countryIso: 'AE'),
    WorldAirport(code: 'SHJ', name: 'Sharjah International', countryIso: 'AE'),
    // Nigeria
    WorldAirport(code: 'LOS', name: 'Murtala Muhammed', countryIso: 'NG'),
    WorldAirport(code: 'ABV', name: 'Nnamdi Azikiwe', countryIso: 'NG'),
    // UK
    WorldAirport(code: 'LHR', name: 'London Heathrow', countryIso: 'GB'),
    WorldAirport(code: 'LGW', name: 'London Gatwick', countryIso: 'GB'),
    WorldAirport(code: 'MAN', name: 'Manchester', countryIso: 'GB'),
    // US
    WorldAirport(code: 'JFK', name: 'John F. Kennedy', countryIso: 'US'),
    WorldAirport(code: 'EWR', name: 'Newark Liberty', countryIso: 'US'),
    WorldAirport(code: 'LAX', name: 'Los Angeles International', countryIso: 'US'),
    WorldAirport(code: 'ORD', name: 'O\'Hare International', countryIso: 'US'),
    // Canada
    WorldAirport(code: 'YYZ', name: 'Toronto Pearson', countryIso: 'CA'),
    WorldAirport(code: 'YVR', name: 'Vancouver International', countryIso: 'CA'),
    // Germany
    WorldAirport(code: 'FRA', name: 'Frankfurt', countryIso: 'DE'),
    WorldAirport(code: 'MUC', name: 'Munich', countryIso: 'DE'),
    // Spain
    WorldAirport(code: 'MAD', name: 'Madrid-Barajas', countryIso: 'ES'),
    WorldAirport(code: 'BCN', name: 'Barcelona-El Prat', countryIso: 'ES'),
    // Italy
    WorldAirport(code: 'FCO', name: 'Rome Fiumicino', countryIso: 'IT'),
    WorldAirport(code: 'MXP', name: 'Milan Malpensa', countryIso: 'IT'),
    // Netherlands
    WorldAirport(code: 'AMS', name: 'Amsterdam Schiphol', countryIso: 'NL'),
    // Belgium
    WorldAirport(code: 'BRU', name: 'Brussels', countryIso: 'BE'),
    // Turkey
    WorldAirport(code: 'IST', name: 'Istanbul', countryIso: 'TR'),
    // Morocco
    WorldAirport(code: 'CMN', name: 'Casablanca Mohammed V', countryIso: 'MA'),
    // Egypt
    WorldAirport(code: 'CAI', name: 'Cairo International', countryIso: 'EG'),
    // South Africa
    WorldAirport(code: 'JNB', name: 'O.R. Tambo', countryIso: 'ZA'),
    WorldAirport(code: 'CPT', name: 'Cape Town International', countryIso: 'ZA'),
    // India
    WorldAirport(code: 'DEL', name: 'Indira Gandhi International', countryIso: 'IN'),
    WorldAirport(code: 'BOM', name: 'Chhatrapati Shivaji Maharaj', countryIso: 'IN'),
    // Pakistan
    WorldAirport(code: 'KHI', name: 'Jinnah International', countryIso: 'PK'),
    WorldAirport(code: 'LHE', name: 'Allama Iqbal International', countryIso: 'PK'),
    WorldAirport(code: 'ISB', name: 'Islamabad International', countryIso: 'PK'),
    // China
    WorldAirport(code: 'PEK', name: 'Beijing Capital', countryIso: 'CN'),
    WorldAirport(code: 'PVG', name: 'Shanghai Pudong', countryIso: 'CN'),
    // Japan
    WorldAirport(code: 'NRT', name: 'Narita International', countryIso: 'JP'),
    WorldAirport(code: 'HND', name: 'Haneda', countryIso: 'JP'),
    // Australia
    WorldAirport(code: 'SYD', name: 'Sydney Kingsford Smith', countryIso: 'AU'),
    WorldAirport(code: 'MEL', name: 'Melbourne', countryIso: 'AU'),
    // Brazil
    WorldAirport(code: 'GRU', name: 'São Paulo Guarulhos', countryIso: 'BR'),
    // Ghana
    WorldAirport(code: 'ACC', name: 'Kotoka International', countryIso: 'GH'),
    // Ivory Coast
    WorldAirport(code: 'ABJ', name: 'Félix-Houphouët-Boigny', countryIso: 'CI'),
    // Kenya
    WorldAirport(code: 'NBO', name: 'Jomo Kenyatta', countryIso: 'KE'),
    // Saudi Arabia
    WorldAirport(code: 'JED', name: 'King Abdulaziz', countryIso: 'SA'),
    WorldAirport(code: 'RUH', name: 'King Khalid', countryIso: 'SA'),
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
    for (final airport in all) {
      if (airport.label == trimmed || airport.code == trimmed.toUpperCase()) {
        return airport;
      }
    }
    return null;
  }

  static WorldAirport? firstForCountry(String iso) {
    final list = forCountry(iso);
    return list.isEmpty ? null : list.first;
  }

  static List<WorldAirport> searchInCountry(String iso, String query) {
    final airports = forCountry(iso);
    final q = query.trim().toLowerCase();
    if (q.isEmpty) return airports;
    return airports.where((a) => a.searchText.contains(q)).toList();
  }

  /// Countries that have at least one airport in the catalog.
  static Set<String> get countryIsosWithAirports =>
      {for (final a in all) a.countryIso};
}
