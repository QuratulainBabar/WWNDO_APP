import '../geo/world_countries.dart';
import 'country_dial_codes.dart';

/// ISO country + dial-code catalog for international phone inputs.
class PhoneCountry {
  const PhoneCountry({
    required this.iso,
    required this.name,
    required this.dialCode,
  });

  final String iso;
  final String name;
  /// Includes leading `+`, e.g. `+33`.
  final String dialCode;

  /// Regional-indicator emoji flag for [iso].
  String get flag {
    final upper = iso.toUpperCase();
    if (upper.length != 2) return '🏳️';
    return String.fromCharCodes(
      upper.codeUnits.map((c) => 0x1F1E6 - 65 + c),
    );
  }

  String get searchText => '$name $iso $dialCode'.toLowerCase();
}

abstract final class PhoneCountries {
  static const preferredIsos = ['FR', 'US', 'GB', 'NG', 'AE', 'CA'];

  static const List<PhoneCountry> all = [
    PhoneCountry(iso: 'FR', name: 'France', dialCode: '+33'),
    PhoneCountry(iso: 'US', name: 'United States', dialCode: '+1'),
    PhoneCountry(iso: 'GB', name: 'United Kingdom', dialCode: '+44'),
    PhoneCountry(iso: 'NG', name: 'Nigeria', dialCode: '+234'),
    PhoneCountry(iso: 'AE', name: 'United Arab Emirates', dialCode: '+971'),
    PhoneCountry(iso: 'CA', name: 'Canada', dialCode: '+1'),
    PhoneCountry(iso: 'AF', name: 'Afghanistan', dialCode: '+93'),
    PhoneCountry(iso: 'AL', name: 'Albania', dialCode: '+355'),
    PhoneCountry(iso: 'DZ', name: 'Algeria', dialCode: '+213'),
    PhoneCountry(iso: 'AR', name: 'Argentina', dialCode: '+54'),
    PhoneCountry(iso: 'AU', name: 'Australia', dialCode: '+61'),
    PhoneCountry(iso: 'AT', name: 'Austria', dialCode: '+43'),
    PhoneCountry(iso: 'BD', name: 'Bangladesh', dialCode: '+880'),
    PhoneCountry(iso: 'BE', name: 'Belgium', dialCode: '+32'),
    PhoneCountry(iso: 'BJ', name: 'Benin', dialCode: '+229'),
    PhoneCountry(iso: 'BR', name: 'Brazil', dialCode: '+55'),
    PhoneCountry(iso: 'BF', name: 'Burkina Faso', dialCode: '+226'),
    PhoneCountry(iso: 'CM', name: 'Cameroon', dialCode: '+237'),
    PhoneCountry(iso: 'CL', name: 'Chile', dialCode: '+56'),
    PhoneCountry(iso: 'CN', name: 'China', dialCode: '+86'),
    PhoneCountry(iso: 'CI', name: "Côte d'Ivoire", dialCode: '+225'),
    PhoneCountry(iso: 'CO', name: 'Colombia', dialCode: '+57'),
    PhoneCountry(iso: 'CD', name: 'Congo (DRC)', dialCode: '+243'),
    PhoneCountry(iso: 'HR', name: 'Croatia', dialCode: '+385'),
    PhoneCountry(iso: 'CZ', name: 'Czechia', dialCode: '+420'),
    PhoneCountry(iso: 'DK', name: 'Denmark', dialCode: '+45'),
    PhoneCountry(iso: 'EG', name: 'Egypt', dialCode: '+20'),
    PhoneCountry(iso: 'ET', name: 'Ethiopia', dialCode: '+251'),
    PhoneCountry(iso: 'FI', name: 'Finland', dialCode: '+358'),
    PhoneCountry(iso: 'DE', name: 'Germany', dialCode: '+49'),
    PhoneCountry(iso: 'GH', name: 'Ghana', dialCode: '+233'),
    PhoneCountry(iso: 'GR', name: 'Greece', dialCode: '+30'),
    PhoneCountry(iso: 'GN', name: 'Guinea', dialCode: '+224'),
    PhoneCountry(iso: 'HK', name: 'Hong Kong', dialCode: '+852'),
    PhoneCountry(iso: 'HU', name: 'Hungary', dialCode: '+36'),
    PhoneCountry(iso: 'IN', name: 'India', dialCode: '+91'),
    PhoneCountry(iso: 'ID', name: 'Indonesia', dialCode: '+62'),
    PhoneCountry(iso: 'IE', name: 'Ireland', dialCode: '+353'),
    PhoneCountry(iso: 'IL', name: 'Israel', dialCode: '+972'),
    PhoneCountry(iso: 'IT', name: 'Italy', dialCode: '+39'),
    PhoneCountry(iso: 'JP', name: 'Japan', dialCode: '+81'),
    PhoneCountry(iso: 'JO', name: 'Jordan', dialCode: '+962'),
    PhoneCountry(iso: 'KE', name: 'Kenya', dialCode: '+254'),
    PhoneCountry(iso: 'KW', name: 'Kuwait', dialCode: '+965'),
    PhoneCountry(iso: 'LB', name: 'Lebanon', dialCode: '+961'),
    PhoneCountry(iso: 'LR', name: 'Liberia', dialCode: '+231'),
    PhoneCountry(iso: 'LY', name: 'Libya', dialCode: '+218'),
    PhoneCountry(iso: 'MY', name: 'Malaysia', dialCode: '+60'),
    PhoneCountry(iso: 'ML', name: 'Mali', dialCode: '+223'),
    PhoneCountry(iso: 'MR', name: 'Mauritania', dialCode: '+222'),
    PhoneCountry(iso: 'MX', name: 'Mexico', dialCode: '+52'),
    PhoneCountry(iso: 'MA', name: 'Morocco', dialCode: '+212'),
    PhoneCountry(iso: 'MZ', name: 'Mozambique', dialCode: '+258'),
    PhoneCountry(iso: 'NL', name: 'Netherlands', dialCode: '+31'),
    PhoneCountry(iso: 'NZ', name: 'New Zealand', dialCode: '+64'),
    PhoneCountry(iso: 'NE', name: 'Niger', dialCode: '+227'),
    PhoneCountry(iso: 'NO', name: 'Norway', dialCode: '+47'),
    PhoneCountry(iso: 'OM', name: 'Oman', dialCode: '+968'),
    PhoneCountry(iso: 'PK', name: 'Pakistan', dialCode: '+92'),
    PhoneCountry(iso: 'PH', name: 'Philippines', dialCode: '+63'),
    PhoneCountry(iso: 'PL', name: 'Poland', dialCode: '+48'),
    PhoneCountry(iso: 'PT', name: 'Portugal', dialCode: '+351'),
    PhoneCountry(iso: 'QA', name: 'Qatar', dialCode: '+974'),
    PhoneCountry(iso: 'RO', name: 'Romania', dialCode: '+40'),
    PhoneCountry(iso: 'RU', name: 'Russia', dialCode: '+7'),
    PhoneCountry(iso: 'SA', name: 'Saudi Arabia', dialCode: '+966'),
    PhoneCountry(iso: 'SN', name: 'Senegal', dialCode: '+221'),
    PhoneCountry(iso: 'RS', name: 'Serbia', dialCode: '+381'),
    PhoneCountry(iso: 'SG', name: 'Singapore', dialCode: '+65'),
    PhoneCountry(iso: 'ZA', name: 'South Africa', dialCode: '+27'),
    PhoneCountry(iso: 'KR', name: 'South Korea', dialCode: '+82'),
    PhoneCountry(iso: 'ES', name: 'Spain', dialCode: '+34'),
    PhoneCountry(iso: 'LK', name: 'Sri Lanka', dialCode: '+94'),
    PhoneCountry(iso: 'SE', name: 'Sweden', dialCode: '+46'),
    PhoneCountry(iso: 'CH', name: 'Switzerland', dialCode: '+41'),
    PhoneCountry(iso: 'TZ', name: 'Tanzania', dialCode: '+255'),
    PhoneCountry(iso: 'TH', name: 'Thailand', dialCode: '+66'),
    PhoneCountry(iso: 'TG', name: 'Togo', dialCode: '+228'),
    PhoneCountry(iso: 'TN', name: 'Tunisia', dialCode: '+216'),
    PhoneCountry(iso: 'TR', name: 'Türkiye', dialCode: '+90'),
    PhoneCountry(iso: 'UG', name: 'Uganda', dialCode: '+256'),
    PhoneCountry(iso: 'UA', name: 'Ukraine', dialCode: '+380'),
    PhoneCountry(iso: 'VN', name: 'Vietnam', dialCode: '+84'),
    PhoneCountry(iso: 'ZM', name: 'Zambia', dialCode: '+260'),
    PhoneCountry(iso: 'ZW', name: 'Zimbabwe', dialCode: '+263'),
  ];

  static PhoneCountry byIso(String iso, {String fallback = 'FR'}) {
    final upper = iso.toUpperCase();
    for (final country in all) {
      if (country.iso == upper) return country;
    }
    if (WorldCountries.containsIso(upper)) {
      final dialCode = CountryDialCodes.forIso(upper);
      if (dialCode != null) {
        final world = WorldCountries.byIso(upper);
        return PhoneCountry(iso: upper, name: world.name, dialCode: dialCode);
      }
    }
    return all.firstWhere((c) => c.iso == fallback);
  }

  /// Longest-prefix match so `+234` wins over shorter codes.
  /// When several countries share a dial code (e.g. US/CA `+1`), prefers [preferIso].
  static PhoneCountry? byDialCode(String dialCode, {String? preferIso}) {
    final normalized = dialCode.startsWith('+') ? dialCode : '+$dialCode';
    final matches = <PhoneCountry>[];
    var bestLen = 0;
    for (final country in all) {
      if (normalized == country.dialCode ||
          normalized.startsWith(country.dialCode)) {
        if (country.dialCode.length > bestLen) {
          bestLen = country.dialCode.length;
          matches
            ..clear()
            ..add(country);
        } else if (country.dialCode.length == bestLen) {
          matches.add(country);
        }
      }
    }
    if (matches.isEmpty) return null;
    if (preferIso != null) {
      final preferred = preferIso.toUpperCase();
      for (final m in matches) {
        if (m.iso == preferred) return m;
      }
    }
    return matches.first;
  }

  static List<PhoneCountry> search(String query) {
    final q = query.trim().toLowerCase();
    if (q.isEmpty) return ordered();
    return ordered()
        .where((c) => c.searchText.contains(q) || c.dialCode.contains(q))
        .toList();
  }

  /// Preferred markets first, then remaining world countries A–Z by name.
  static List<PhoneCountry> ordered() {
    final preferred = <PhoneCountry>[];
    final rest = <PhoneCountry>[];
    final seen = <String>{};

    for (final iso in preferredIsos) {
      final country = byIso(iso);
      preferred.add(country);
      seen.add(country.iso);
    }
    for (final world in WorldCountries.ordered()) {
      if (!seen.add(world.iso)) continue;
      final dialCode = CountryDialCodes.forIso(world.iso);
      if (dialCode == null) continue;
      rest.add(PhoneCountry(iso: world.iso, name: world.name, dialCode: dialCode));
    }
    return [...preferred, ...rest];
  }

  /// Digits-only national number (strips spaces and leading zeros).
  static String nationalDigits(String national) {
    return national.replaceAll(RegExp(r'\D'), '').replaceFirst(RegExp(r'^0+'), '');
  }

  /// Digits-only national number length (ignores spaces).
  static bool isValidNational(String national, {int minDigits = 6}) {
    final digits = nationalDigits(national);
    return digits.length >= minDigits && digits.length <= 15;
  }

  /// Combines dial code + national into a compact E.164-ish string.
  static String formatFull(PhoneCountry country, String national) {
    return '${country.dialCode}${nationalDigits(national)}';
  }

  /// Splits a stored phone into country + national part.
  static ({PhoneCountry country, String national}) parse(
    String raw, {
    String fallbackIso = 'FR',
  }) {
    final trimmed = raw.trim();
    if (trimmed.isEmpty) {
      return (country: byIso(fallbackIso), national: '');
    }

    final withPlus = trimmed.startsWith('+') ? trimmed : '+$trimmed';
    final compact = withPlus.replaceAll(RegExp(r'[\s\-()]'), '');
    final matched = byDialCode(compact, preferIso: fallbackIso);
    if (matched != null) {
      final national = compact.substring(matched.dialCode.length);
      return (country: matched, national: national);
    }

    return (
      country: byIso(fallbackIso),
      national: trimmed.replaceFirst(RegExp(r'^\+'), ''),
    );
  }
}
