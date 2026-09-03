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

    void consider(PhoneCountry country) {
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

    final seen = <String>{};
    for (final country in all) {
      seen.add(country.iso);
      consider(country);
    }
    for (final world in WorldCountries.all) {
      if (!seen.add(world.iso)) continue;
      final code = CountryDialCodes.forIso(world.iso);
      if (code == null) continue;
      consider(
        PhoneCountry(iso: world.iso, name: world.name, dialCode: code),
      );
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

  /// National-number example used as the phone-field placeholder for [iso].
  /// Spacing follows common local grouping (not a validation mask).
  static String nationalExample(String iso) {
    return _nationalExamples[iso.toUpperCase()] ?? '612 345 678';
  }

  /// Local-number placeholder for [country], e.g. `802 123 4567` for Nigeria.
  /// Never includes the calling code — that is shown separately to the left
  /// of the input. Any accidental `+NN` / `NN` prefix is stripped.
  static String examplePlaceholder(PhoneCountry country) {
    return stripLeadingDialCode(
      nationalExample(country.iso),
      country.dialCode,
    );
  }

  /// Removes a leading calling-code prefix (`+234`, `234`, …) from [value].
  static String stripLeadingDialCode(String value, String dialCode) {
    var result = value.trim();
    if (result.isEmpty) return result;

    final plusCode = dialCode.startsWith('+') ? dialCode : '+$dialCode';
    final digits = plusCode.substring(1);

    if (result.startsWith(plusCode)) {
      return result.substring(plusCode.length).trim();
    }
    if (result.startsWith(digits) &&
        (result.length == digits.length ||
            !RegExp(r'\d').hasMatch(result[digits.length]))) {
      return result.substring(digits.length).trim();
    }
    return result;
  }

  static const Map<String, String> _nationalExamples = {
    'AE': '50 123 4567',
    'AF': '70 123 4567',
    'AL': '67 212 3456',
    'AR': '11 2345 6789',
    'AT': '664 123456',
    'AU': '412 345 678',
    'BD': '1712 345678',
    'BE': '470 12 34 56',
    'BJ': '90 12 34 56',
    'BR': '11 91234 5678',
    'BF': '70 12 34 56',
    'CA': '416 555 0123',
    'CD': '81 234 5678',
    'CH': '78 123 45 67',
    'CI': '01 23 45 67 89',
    'CL': '9 1234 5678',
    'CM': '6 71 23 45 67',
    'CN': '131 2345 6789',
    'CO': '300 123 4567',
    'CZ': '601 123 456',
    'DE': '151 23456789',
    'DK': '20 12 34 56',
    'DZ': '551 23 45 67',
    'EG': '100 123 4567',
    'ES': '612 34 56 78',
    'ET': '91 123 4567',
    'FI': '41 2345678',
    'FR': '6 12 34 56 78',
    'GB': '7400 123456',
    'GH': '24 123 4567',
    'GN': '601 12 34 56',
    'GR': '691 234 5678',
    'HK': '5123 4567',
    'HR': '91 234 5678',
    'HU': '20 123 4567',
    'ID': '812 3456 7890',
    'IE': '85 012 3456',
    'IL': '50 123 4567',
    'IN': '98765 43210',
    'IT': '312 345 6789',
    'JO': '7 9012 3456',
    'JP': '90 1234 5678',
    'KE': '712 345678',
    'KR': '10 1234 5678',
    'KW': '5000 1234',
    'LB': '71 123 456',
    'LK': '71 234 5678',
    'LR': '77 012 3456',
    'LY': '91 234 5678',
    'MA': '612 345 678',
    'ML': '65 01 23 45',
    'MR': '22 12 34 56',
    'MX': '55 1234 5678',
    'MY': '12 345 6789',
    'MZ': '82 123 4567',
    'NE': '90 12 34 56',
    'NG': '802 123 4567',
    'NL': '6 12345678',
    'NO': '406 12 345',
    'NZ': '21 123 4567',
    'OM': '9212 3456',
    'PH': '917 123 4567',
    'PK': '300 1234567',
    'PL': '512 345 678',
    'PT': '912 345 678',
    'QA': '3312 3456',
    'RO': '712 345 678',
    'RS': '60 1234567',
    'RU': '912 345 67 89',
    'SA': '50 123 4567',
    'SE': '70 123 45 67',
    'SG': '8123 4567',
    'SN': '77 123 45 67',
    'TH': '81 234 5678',
    'TG': '90 12 34 56',
    'TN': '20 123 456',
    'TR': '501 234 56 78',
    'TZ': '712 345 678',
    'UA': '50 123 4567',
    'UG': '712 345678',
    'US': '202 555 0123',
    'VN': '91 234 56 78',
    'ZA': '71 123 4567',
    'ZM': '95 1234567',
    'ZW': '71 234 5678',
    'HN': '9123 4567',
    'CR': '8312 3456',
    'GT': '5123 4567',
    'SV': '7012 3456',
    'NI': '8123 4567',
    'PA': '6123 4567',
    'PE': '912 345 678',
    'EC': '99 123 4567',
    'BO': '7123 4567',
    'PY': '981 123 456',
    'UY': '94 123 456',
    'VE': '412 123 4567',
  };

  /// ITU-style national significant number length (digits only, no calling code).
  static ({int min, int max}) nationalDigitRange(String iso) {
    final key = iso.toUpperCase();
    final override = _nsnLengthOverrides[key];
    if (override != null) return override;

    final dial = CountryDialCodes.forIso(key);
    if (key == 'US' || key == 'CA') return (min: 10, max: 10);
    if (dial != null && dial.startsWith('+1') && dial.length > 2) {
      return (min: 7, max: 7);
    }

    final exampleDigits =
        (_nationalExamples[key] ?? '').replaceAll(RegExp(r'\D'), '');
    if (exampleDigits.length >= 6) {
      return (min: exampleDigits.length, max: exampleDigits.length);
    }

    final ccLen = (dial ?? '+').replaceAll('+', '').length;
    final e164Max = (15 - ccLen).clamp(6, 12);
    return (min: 7, max: e164Max);
  }

  static const Map<String, ({int min, int max})> _nsnLengthOverrides = {
    'DE': (min: 10, max: 11),
    'IT': (min: 9, max: 10),
    'BR': (min: 10, max: 11),
    'AR': (min: 10, max: 10),
    'AT': (min: 10, max: 11),
    'SE': (min: 9, max: 10),
    'NO': (min: 8, max: 8),
    'DK': (min: 8, max: 8),
    'FI': (min: 9, max: 10),
    'NL': (min: 9, max: 9),
    'BE': (min: 9, max: 9),
    'CH': (min: 9, max: 9),
    'HN': (min: 8, max: 8),
    'CR': (min: 8, max: 8),
    'GT': (min: 8, max: 8),
    'SV': (min: 8, max: 8),
    'NI': (min: 8, max: 8),
    'PA': (min: 8, max: 8),
    'BO': (min: 8, max: 8),
    'PY': (min: 9, max: 9),
    'UY': (min: 8, max: 8),
    'PE': (min: 9, max: 9),
    'EC': (min: 9, max: 9),
    'VE': (min: 10, max: 10),
    'MX': (min: 10, max: 10),
    'CL': (min: 9, max: 9),
    'CO': (min: 10, max: 10),
    'PK': (min: 10, max: 10),
    'IN': (min: 10, max: 10),
    'BD': (min: 10, max: 10),
    'NG': (min: 10, max: 10),
    'GB': (min: 10, max: 10),
    'FR': (min: 9, max: 9),
    'US': (min: 10, max: 10),
    'CA': (min: 10, max: 10),
    'AU': (min: 9, max: 9),
    'AE': (min: 9, max: 9),
    'SA': (min: 9, max: 9),
    'EG': (min: 10, max: 10),
    'ZA': (min: 9, max: 9),
    'KE': (min: 9, max: 9),
    'GH': (min: 9, max: 9),
    'CN': (min: 11, max: 11),
    'JP': (min: 10, max: 10),
    'KR': (min: 9, max: 10),
    'ID': (min: 10, max: 12),
    'PH': (min: 10, max: 10),
    'TH': (min: 9, max: 9),
    'VN': (min: 9, max: 9),
    'TR': (min: 10, max: 10),
    'RU': (min: 10, max: 10),
    'UA': (min: 9, max: 9),
    'PL': (min: 9, max: 9),
    'ES': (min: 9, max: 9),
    'PT': (min: 9, max: 9),
    'IE': (min: 9, max: 9),
    'NZ': (min: 8, max: 10),
    'SG': (min: 8, max: 8),
    'HK': (min: 8, max: 8),
    'QA': (min: 8, max: 8),
    'KW': (min: 8, max: 8),
    'OM': (min: 8, max: 8),
    'BH': (min: 8, max: 8),
    'JO': (min: 9, max: 9),
    'LB': (min: 7, max: 8),
    'IQ': (min: 10, max: 10),
    'IR': (min: 10, max: 10),
    'IL': (min: 8, max: 9),
    'MY': (min: 9, max: 10),
    'MM': (min: 8, max: 10),
    'NP': (min: 10, max: 10),
    'LK': (min: 9, max: 9),
    'TZ': (min: 9, max: 9),
    'UG': (min: 9, max: 9),
    'ET': (min: 9, max: 9),
    'MA': (min: 9, max: 9),
    'TN': (min: 8, max: 8),
    'DZ': (min: 9, max: 9),
    'LY': (min: 9, max: 9),
    'SD': (min: 9, max: 9),
    'CI': (min: 10, max: 10),
    'SN': (min: 9, max: 9),
    'CM': (min: 9, max: 9),
    'CD': (min: 9, max: 9),
    'AO': (min: 9, max: 9),
    'MZ': (min: 9, max: 9),
    'ZW': (min: 9, max: 9),
    'ZM': (min: 9, max: 9),
    'RW': (min: 9, max: 9),
    'MG': (min: 9, max: 9),
    'MU': (min: 8, max: 8),
    'SC': (min: 7, max: 7),
  };

  /// Caps [national] to the country's maximum digit count and applies local
  /// spacing from [nationalExample] (as-you-type friendly).
  static String clampNational(String national, PhoneCountry country) {
    return formatNationalAsYouType(national, country);
  }

  /// Inserts spaces while typing using the country's example grouping.
  /// Example FR `6 12 34 56 78` → typing `612345678` becomes `6 12 34 56 78`.
  static String formatNationalAsYouType(String input, PhoneCountry country) {
    final digitsOnly = input.replaceAll(RegExp(r'\D'), '');
    final max = nationalDigitRange(country.iso).max;
    final digits =
        digitsOnly.length > max ? digitsOnly.substring(0, max) : digitsOnly;
    if (digits.isEmpty) return '';

    final pattern = nationalExample(country.iso);
    final out = StringBuffer();
    var di = 0;

    for (var i = 0; i < pattern.length && di < digits.length; i++) {
      final ch = pattern[i];
      if (ch == ' ') {
        if (out.isNotEmpty && di < digits.length) {
          out.write(' ');
        }
        continue;
      }
      if (ch.codeUnitAt(0) >= 48 && ch.codeUnitAt(0) <= 57) {
        out.write(digits[di]);
        di++;
      }
    }

    if (di < digits.length) {
      if (out.isNotEmpty && !out.toString().endsWith(' ')) {
        out.write(' ');
      }
      out.write(digits.substring(di));
    }

    return out.toString();
  }

  /// Digits-only national number (strips spaces and leading zeros).
  static String nationalDigits(String national) {
    return national.replaceAll(RegExp(r'\D'), '').replaceFirst(RegExp(r'^0+'), '');
  }

  /// Digits-only national number length for [country] when provided.
  static bool isValidNational(
    String national, {
    PhoneCountry? country,
    int minDigits = 6,
  }) {
    final digits = nationalDigits(national);
    if (country != null) {
      final range = nationalDigitRange(country.iso);
      return digits.length >= range.min && digits.length <= range.max;
    }
    return digits.length >= minDigits && digits.length <= 15;
  }

  /// Login / reset contact field: country-aware when a calling code is present.
  static bool isValidContactPhone(String raw) {
    final trimmed = raw.trim();
    if (trimmed.isEmpty) return false;
    final digits = trimmed.replaceAll(RegExp(r'\D'), '');
    if (digits.length > 15) return false;
    if (trimmed.startsWith('+')) {
      final parsed = parse(trimmed);
      return isValidNational(parsed.national, country: parsed.country);
    }
    return digits.length >= 8 && digits.length <= 15;
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
