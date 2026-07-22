/// ISO 3166-1 alpha-2 country catalog for route From / To pickers.
class WorldCountry {
  const WorldCountry({required this.iso, required this.name});

  final String iso;
  final String name;

  String get flag {
    final upper = iso.toUpperCase();
    if (upper.length != 2) return '🏳️';
    return String.fromCharCodes(
      upper.codeUnits.map((c) => 0x1F1E6 - 65 + c),
    );
  }

  String get searchText => '$name $iso'.toLowerCase();
}

abstract final class WorldCountries {
  static const preferredIsos = ['FR', 'SN', 'US', 'GB', 'NG', 'AE', 'CA'];

  static const List<WorldCountry> all = [
    WorldCountry(iso: 'AF', name: 'Afghanistan'),
    WorldCountry(iso: 'AL', name: 'Albania'),
    WorldCountry(iso: 'DZ', name: 'Algeria'),
    WorldCountry(iso: 'AD', name: 'Andorra'),
    WorldCountry(iso: 'AO', name: 'Angola'),
    WorldCountry(iso: 'AG', name: 'Antigua and Barbuda'),
    WorldCountry(iso: 'AR', name: 'Argentina'),
    WorldCountry(iso: 'AM', name: 'Armenia'),
    WorldCountry(iso: 'AU', name: 'Australia'),
    WorldCountry(iso: 'AT', name: 'Austria'),
    WorldCountry(iso: 'AZ', name: 'Azerbaijan'),
    WorldCountry(iso: 'BS', name: 'Bahamas'),
    WorldCountry(iso: 'BH', name: 'Bahrain'),
    WorldCountry(iso: 'BD', name: 'Bangladesh'),
    WorldCountry(iso: 'BB', name: 'Barbados'),
    WorldCountry(iso: 'BY', name: 'Belarus'),
    WorldCountry(iso: 'BE', name: 'Belgium'),
    WorldCountry(iso: 'BZ', name: 'Belize'),
    WorldCountry(iso: 'BJ', name: 'Benin'),
    WorldCountry(iso: 'BT', name: 'Bhutan'),
    WorldCountry(iso: 'BO', name: 'Bolivia'),
    WorldCountry(iso: 'BA', name: 'Bosnia and Herzegovina'),
    WorldCountry(iso: 'BW', name: 'Botswana'),
    WorldCountry(iso: 'BR', name: 'Brazil'),
    WorldCountry(iso: 'BN', name: 'Brunei'),
    WorldCountry(iso: 'BG', name: 'Bulgaria'),
    WorldCountry(iso: 'BF', name: 'Burkina Faso'),
    WorldCountry(iso: 'BI', name: 'Burundi'),
    WorldCountry(iso: 'CV', name: 'Cabo Verde'),
    WorldCountry(iso: 'KH', name: 'Cambodia'),
    WorldCountry(iso: 'CM', name: 'Cameroon'),
    WorldCountry(iso: 'CA', name: 'Canada'),
    WorldCountry(iso: 'CF', name: 'Central African Republic'),
    WorldCountry(iso: 'TD', name: 'Chad'),
    WorldCountry(iso: 'CL', name: 'Chile'),
    WorldCountry(iso: 'CN', name: 'China'),
    WorldCountry(iso: 'CO', name: 'Colombia'),
    WorldCountry(iso: 'KM', name: 'Comoros'),
    WorldCountry(iso: 'CG', name: 'Congo'),
    WorldCountry(iso: 'CD', name: 'Congo (DRC)'),
    WorldCountry(iso: 'CR', name: 'Costa Rica'),
    WorldCountry(iso: 'CI', name: "Côte d'Ivoire"),
    WorldCountry(iso: 'HR', name: 'Croatia'),
    WorldCountry(iso: 'CU', name: 'Cuba'),
    WorldCountry(iso: 'CY', name: 'Cyprus'),
    WorldCountry(iso: 'CZ', name: 'Czechia'),
    WorldCountry(iso: 'DK', name: 'Denmark'),
    WorldCountry(iso: 'DJ', name: 'Djibouti'),
    WorldCountry(iso: 'DM', name: 'Dominica'),
    WorldCountry(iso: 'DO', name: 'Dominican Republic'),
    WorldCountry(iso: 'EC', name: 'Ecuador'),
    WorldCountry(iso: 'EG', name: 'Egypt'),
    WorldCountry(iso: 'SV', name: 'El Salvador'),
    WorldCountry(iso: 'GQ', name: 'Equatorial Guinea'),
    WorldCountry(iso: 'ER', name: 'Eritrea'),
    WorldCountry(iso: 'EE', name: 'Estonia'),
    WorldCountry(iso: 'SZ', name: 'Eswatini'),
    WorldCountry(iso: 'ET', name: 'Ethiopia'),
    WorldCountry(iso: 'FJ', name: 'Fiji'),
    WorldCountry(iso: 'FI', name: 'Finland'),
    WorldCountry(iso: 'FR', name: 'France'),
    WorldCountry(iso: 'GA', name: 'Gabon'),
    WorldCountry(iso: 'GM', name: 'Gambia'),
    WorldCountry(iso: 'GE', name: 'Georgia'),
    WorldCountry(iso: 'DE', name: 'Germany'),
    WorldCountry(iso: 'GH', name: 'Ghana'),
    WorldCountry(iso: 'GR', name: 'Greece'),
    WorldCountry(iso: 'GD', name: 'Grenada'),
    WorldCountry(iso: 'GT', name: 'Guatemala'),
    WorldCountry(iso: 'GN', name: 'Guinea'),
    WorldCountry(iso: 'GW', name: 'Guinea-Bissau'),
    WorldCountry(iso: 'GY', name: 'Guyana'),
    WorldCountry(iso: 'HT', name: 'Haiti'),
    WorldCountry(iso: 'HN', name: 'Honduras'),
    WorldCountry(iso: 'HK', name: 'Hong Kong'),
    WorldCountry(iso: 'HU', name: 'Hungary'),
    WorldCountry(iso: 'IS', name: 'Iceland'),
    WorldCountry(iso: 'IN', name: 'India'),
    WorldCountry(iso: 'ID', name: 'Indonesia'),
    WorldCountry(iso: 'IR', name: 'Iran'),
    WorldCountry(iso: 'IQ', name: 'Iraq'),
    WorldCountry(iso: 'IE', name: 'Ireland'),
    WorldCountry(iso: 'IL', name: 'Israel'),
    WorldCountry(iso: 'IT', name: 'Italy'),
    WorldCountry(iso: 'JM', name: 'Jamaica'),
    WorldCountry(iso: 'JP', name: 'Japan'),
    WorldCountry(iso: 'JO', name: 'Jordan'),
    WorldCountry(iso: 'KZ', name: 'Kazakhstan'),
    WorldCountry(iso: 'KE', name: 'Kenya'),
    WorldCountry(iso: 'KI', name: 'Kiribati'),
    WorldCountry(iso: 'KW', name: 'Kuwait'),
    WorldCountry(iso: 'KG', name: 'Kyrgyzstan'),
    WorldCountry(iso: 'LA', name: 'Laos'),
    WorldCountry(iso: 'LV', name: 'Latvia'),
    WorldCountry(iso: 'LB', name: 'Lebanon'),
    WorldCountry(iso: 'LS', name: 'Lesotho'),
    WorldCountry(iso: 'LR', name: 'Liberia'),
    WorldCountry(iso: 'LY', name: 'Libya'),
    WorldCountry(iso: 'LI', name: 'Liechtenstein'),
    WorldCountry(iso: 'LT', name: 'Lithuania'),
    WorldCountry(iso: 'LU', name: 'Luxembourg'),
    WorldCountry(iso: 'MO', name: 'Macao'),
    WorldCountry(iso: 'MG', name: 'Madagascar'),
    WorldCountry(iso: 'MW', name: 'Malawi'),
    WorldCountry(iso: 'MY', name: 'Malaysia'),
    WorldCountry(iso: 'MV', name: 'Maldives'),
    WorldCountry(iso: 'ML', name: 'Mali'),
    WorldCountry(iso: 'MT', name: 'Malta'),
    WorldCountry(iso: 'MH', name: 'Marshall Islands'),
    WorldCountry(iso: 'MR', name: 'Mauritania'),
    WorldCountry(iso: 'MU', name: 'Mauritius'),
    WorldCountry(iso: 'MX', name: 'Mexico'),
    WorldCountry(iso: 'FM', name: 'Micronesia'),
    WorldCountry(iso: 'MD', name: 'Moldova'),
    WorldCountry(iso: 'MC', name: 'Monaco'),
    WorldCountry(iso: 'MN', name: 'Mongolia'),
    WorldCountry(iso: 'ME', name: 'Montenegro'),
    WorldCountry(iso: 'MA', name: 'Morocco'),
    WorldCountry(iso: 'MZ', name: 'Mozambique'),
    WorldCountry(iso: 'MM', name: 'Myanmar'),
    WorldCountry(iso: 'NA', name: 'Namibia'),
    WorldCountry(iso: 'NR', name: 'Nauru'),
    WorldCountry(iso: 'NP', name: 'Nepal'),
    WorldCountry(iso: 'NL', name: 'Netherlands'),
    WorldCountry(iso: 'NZ', name: 'New Zealand'),
    WorldCountry(iso: 'NI', name: 'Nicaragua'),
    WorldCountry(iso: 'NE', name: 'Niger'),
    WorldCountry(iso: 'NG', name: 'Nigeria'),
    WorldCountry(iso: 'KP', name: 'North Korea'),
    WorldCountry(iso: 'MK', name: 'North Macedonia'),
    WorldCountry(iso: 'NO', name: 'Norway'),
    WorldCountry(iso: 'OM', name: 'Oman'),
    WorldCountry(iso: 'PK', name: 'Pakistan'),
    WorldCountry(iso: 'PW', name: 'Palau'),
    WorldCountry(iso: 'PS', name: 'Palestine'),
    WorldCountry(iso: 'PA', name: 'Panama'),
    WorldCountry(iso: 'PG', name: 'Papua New Guinea'),
    WorldCountry(iso: 'PY', name: 'Paraguay'),
    WorldCountry(iso: 'PE', name: 'Peru'),
    WorldCountry(iso: 'PH', name: 'Philippines'),
    WorldCountry(iso: 'PL', name: 'Poland'),
    WorldCountry(iso: 'PT', name: 'Portugal'),
    WorldCountry(iso: 'QA', name: 'Qatar'),
    WorldCountry(iso: 'RO', name: 'Romania'),
    WorldCountry(iso: 'RU', name: 'Russia'),
    WorldCountry(iso: 'RW', name: 'Rwanda'),
    WorldCountry(iso: 'KN', name: 'Saint Kitts and Nevis'),
    WorldCountry(iso: 'LC', name: 'Saint Lucia'),
    WorldCountry(iso: 'VC', name: 'Saint Vincent and the Grenadines'),
    WorldCountry(iso: 'WS', name: 'Samoa'),
    WorldCountry(iso: 'SM', name: 'San Marino'),
    WorldCountry(iso: 'ST', name: 'Sao Tome and Principe'),
    WorldCountry(iso: 'SA', name: 'Saudi Arabia'),
    WorldCountry(iso: 'SN', name: 'Senegal'),
    WorldCountry(iso: 'RS', name: 'Serbia'),
    WorldCountry(iso: 'SC', name: 'Seychelles'),
    WorldCountry(iso: 'SL', name: 'Sierra Leone'),
    WorldCountry(iso: 'SG', name: 'Singapore'),
    WorldCountry(iso: 'SK', name: 'Slovakia'),
    WorldCountry(iso: 'SI', name: 'Slovenia'),
    WorldCountry(iso: 'SB', name: 'Solomon Islands'),
    WorldCountry(iso: 'SO', name: 'Somalia'),
    WorldCountry(iso: 'ZA', name: 'South Africa'),
    WorldCountry(iso: 'KR', name: 'South Korea'),
    WorldCountry(iso: 'SS', name: 'South Sudan'),
    WorldCountry(iso: 'ES', name: 'Spain'),
    WorldCountry(iso: 'LK', name: 'Sri Lanka'),
    WorldCountry(iso: 'SD', name: 'Sudan'),
    WorldCountry(iso: 'SR', name: 'Suriname'),
    WorldCountry(iso: 'SE', name: 'Sweden'),
    WorldCountry(iso: 'CH', name: 'Switzerland'),
    WorldCountry(iso: 'SY', name: 'Syria'),
    WorldCountry(iso: 'TW', name: 'Taiwan'),
    WorldCountry(iso: 'TJ', name: 'Tajikistan'),
    WorldCountry(iso: 'TZ', name: 'Tanzania'),
    WorldCountry(iso: 'TH', name: 'Thailand'),
    WorldCountry(iso: 'TL', name: 'Timor-Leste'),
    WorldCountry(iso: 'TG', name: 'Togo'),
    WorldCountry(iso: 'TO', name: 'Tonga'),
    WorldCountry(iso: 'TT', name: 'Trinidad and Tobago'),
    WorldCountry(iso: 'TN', name: 'Tunisia'),
    WorldCountry(iso: 'TR', name: 'Türkiye'),
    WorldCountry(iso: 'TM', name: 'Turkmenistan'),
    WorldCountry(iso: 'TV', name: 'Tuvalu'),
    WorldCountry(iso: 'UG', name: 'Uganda'),
    WorldCountry(iso: 'UA', name: 'Ukraine'),
    WorldCountry(iso: 'AE', name: 'United Arab Emirates'),
    WorldCountry(iso: 'GB', name: 'United Kingdom'),
    WorldCountry(iso: 'US', name: 'United States'),
    WorldCountry(iso: 'UY', name: 'Uruguay'),
    WorldCountry(iso: 'UZ', name: 'Uzbekistan'),
    WorldCountry(iso: 'VU', name: 'Vanuatu'),
    WorldCountry(iso: 'VA', name: 'Vatican City'),
    WorldCountry(iso: 'VE', name: 'Venezuela'),
    WorldCountry(iso: 'VN', name: 'Vietnam'),
    WorldCountry(iso: 'YE', name: 'Yemen'),
    WorldCountry(iso: 'ZM', name: 'Zambia'),
    WorldCountry(iso: 'ZW', name: 'Zimbabwe'),
  ];

  static WorldCountry byIso(String iso, {String fallback = 'FR'}) {
    final upper = iso.toUpperCase();
    return all.firstWhere(
      (c) => c.iso == upper,
      orElse: () => all.firstWhere((c) => c.iso == fallback),
    );
  }

  static bool containsIso(String iso) {
    final upper = iso.toUpperCase();
    return all.any((c) => c.iso == upper);
  }

  static List<WorldCountry> ordered() {
    final preferred = <WorldCountry>[];
    final rest = <WorldCountry>[];
    final seen = <String>{};

    for (final iso in preferredIsos) {
      final country = byIso(iso);
      preferred.add(country);
      seen.add(country.iso);
    }
    for (final country in all) {
      if (seen.add(country.iso)) rest.add(country);
    }
    rest.sort((a, b) => a.name.compareTo(b.name));
    return [...preferred, ...rest];
  }

  static List<WorldCountry> search(String query) {
    final q = query.trim().toLowerCase();
    if (q.isEmpty) return ordered();
    return ordered().where((c) => c.searchText.contains(q)).toList();
  }
}
