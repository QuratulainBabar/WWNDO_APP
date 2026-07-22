/// Major cities keyed by ISO country code for city-to-city route pickers.
class WorldCity {
  const WorldCity({
    required this.name,
    required this.countryIso,
  });

  final String name;
  final String countryIso;

  String get searchText => '$name $countryIso'.toLowerCase();
}

abstract final class WorldCities {
  static const List<WorldCity> all = [
    // United Kingdom
    WorldCity(name: 'London', countryIso: 'GB'),
    WorldCity(name: 'Manchester', countryIso: 'GB'),
    WorldCity(name: 'Birmingham', countryIso: 'GB'),
    WorldCity(name: 'Edinburgh', countryIso: 'GB'),
    WorldCity(name: 'Glasgow', countryIso: 'GB'),
    // Nigeria
    WorldCity(name: 'Lagos', countryIso: 'NG'),
    WorldCity(name: 'Abuja', countryIso: 'NG'),
    WorldCity(name: 'Port Harcourt', countryIso: 'NG'),
    WorldCity(name: 'Kano', countryIso: 'NG'),
    // France
    WorldCity(name: 'Paris', countryIso: 'FR'),
    WorldCity(name: 'Lyon', countryIso: 'FR'),
    WorldCity(name: 'Marseille', countryIso: 'FR'),
    WorldCity(name: 'Nice', countryIso: 'FR'),
    // Senegal
    WorldCity(name: 'Dakar', countryIso: 'SN'),
    WorldCity(name: 'Saint-Louis', countryIso: 'SN'),
    WorldCity(name: 'Thiès', countryIso: 'SN'),
    // UAE
    WorldCity(name: 'Dubai', countryIso: 'AE'),
    WorldCity(name: 'Abu Dhabi', countryIso: 'AE'),
    WorldCity(name: 'Sharjah', countryIso: 'AE'),
    // United States
    WorldCity(name: 'New York', countryIso: 'US'),
    WorldCity(name: 'Los Angeles', countryIso: 'US'),
    WorldCity(name: 'Chicago', countryIso: 'US'),
    WorldCity(name: 'Houston', countryIso: 'US'),
    WorldCity(name: 'Miami', countryIso: 'US'),
    // Canada
    WorldCity(name: 'Toronto', countryIso: 'CA'),
    WorldCity(name: 'Vancouver', countryIso: 'CA'),
    WorldCity(name: 'Montreal', countryIso: 'CA'),
    // Germany
    WorldCity(name: 'Berlin', countryIso: 'DE'),
    WorldCity(name: 'Frankfurt', countryIso: 'DE'),
    WorldCity(name: 'Munich', countryIso: 'DE'),
    // Spain
    WorldCity(name: 'Madrid', countryIso: 'ES'),
    WorldCity(name: 'Barcelona', countryIso: 'ES'),
    // Italy
    WorldCity(name: 'Rome', countryIso: 'IT'),
    WorldCity(name: 'Milan', countryIso: 'IT'),
    // Netherlands
    WorldCity(name: 'Amsterdam', countryIso: 'NL'),
    // Belgium
    WorldCity(name: 'Brussels', countryIso: 'BE'),
    // Turkey
    WorldCity(name: 'Istanbul', countryIso: 'TR'),
    WorldCity(name: 'Ankara', countryIso: 'TR'),
    // Morocco
    WorldCity(name: 'Casablanca', countryIso: 'MA'),
    WorldCity(name: 'Rabat', countryIso: 'MA'),
    WorldCity(name: 'Marrakech', countryIso: 'MA'),
    // Egypt
    WorldCity(name: 'Cairo', countryIso: 'EG'),
    WorldCity(name: 'Alexandria', countryIso: 'EG'),
    // South Africa
    WorldCity(name: 'Johannesburg', countryIso: 'ZA'),
    WorldCity(name: 'Cape Town', countryIso: 'ZA'),
    // India
    WorldCity(name: 'Delhi', countryIso: 'IN'),
    WorldCity(name: 'Mumbai', countryIso: 'IN'),
    WorldCity(name: 'Bengaluru', countryIso: 'IN'),
    // Pakistan
    WorldCity(name: 'Karachi', countryIso: 'PK'),
    WorldCity(name: 'Lahore', countryIso: 'PK'),
    WorldCity(name: 'Islamabad', countryIso: 'PK'),
    // China
    WorldCity(name: 'Beijing', countryIso: 'CN'),
    WorldCity(name: 'Shanghai', countryIso: 'CN'),
    // Japan
    WorldCity(name: 'Tokyo', countryIso: 'JP'),
    WorldCity(name: 'Osaka', countryIso: 'JP'),
    // Australia
    WorldCity(name: 'Sydney', countryIso: 'AU'),
    WorldCity(name: 'Melbourne', countryIso: 'AU'),
    // Brazil
    WorldCity(name: 'São Paulo', countryIso: 'BR'),
    WorldCity(name: 'Rio de Janeiro', countryIso: 'BR'),
    // Ghana
    WorldCity(name: 'Accra', countryIso: 'GH'),
    // Ivory Coast
    WorldCity(name: 'Abidjan', countryIso: 'CI'),
    // Kenya
    WorldCity(name: 'Nairobi', countryIso: 'KE'),
    // Saudi Arabia
    WorldCity(name: 'Jeddah', countryIso: 'SA'),
    WorldCity(name: 'Riyadh', countryIso: 'SA'),
  ];

  static List<WorldCity> forCountry(String iso) {
    final code = iso.trim().toUpperCase();
    return all.where((c) => c.countryIso == code).toList();
  }

  static WorldCity? byName(String name, {String? countryIso}) {
    final needle = name.trim().toLowerCase();
    final iso = countryIso?.trim().toUpperCase();
    for (final city in all) {
      if (city.name.toLowerCase() != needle) continue;
      if (iso != null && city.countryIso != iso) continue;
      return city;
    }
    return null;
  }

  static WorldCity? firstForCountry(String iso) {
    final list = forCountry(iso);
    return list.isEmpty ? null : list.first;
  }

  static List<WorldCity> search({
    required String query,
    String? countryIso,
  }) {
    final source =
        countryIso == null || countryIso.trim().isEmpty
            ? all
            : forCountry(countryIso);
    final q = query.trim().toLowerCase();
    if (q.isEmpty) return source;
    return source.where((c) => c.searchText.contains(q)).toList();
  }

  /// Countries that have at least one city in the catalog.
  static Set<String> get countryIsosWithCities =>
      {for (final c in all) c.countryIso};
}
