import 'package:flutter/material.dart';

/// Supported app languages (manual preference in Settings).
@immutable
class AppLanguage {
  const AppLanguage({
    required this.code,
    required this.name,
    required this.nativeName,
    this.scriptCode,
    this.countryCode,
  });

  /// BCP-47 language code used by [Locale], e.g. `en`, `zh`.
  final String code;

  /// English display name.
  final String name;

  /// Autonym shown in the language picker.
  final String nativeName;

  final String? scriptCode;
  final String? countryCode;

  Locale get locale => Locale.fromSubtags(
        languageCode: code,
        scriptCode: scriptCode,
        countryCode: countryCode,
      );

  bool get isRtl => code == 'ar';

  static const english = AppLanguage(
    code: 'en',
    name: 'English',
    nativeName: 'English',
  );
  static const french = AppLanguage(
    code: 'fr',
    name: 'French',
    nativeName: 'Français',
  );
  static const spanish = AppLanguage(
    code: 'es',
    name: 'Spanish',
    nativeName: 'Español',
  );
  static const italian = AppLanguage(
    code: 'it',
    name: 'Italian',
    nativeName: 'Italiano',
  );
  static const dutch = AppLanguage(
    code: 'nl',
    name: 'Dutch',
    nativeName: 'Nederlands',
  );
  static const german = AppLanguage(
    code: 'de',
    name: 'German',
    nativeName: 'Deutsch',
  );
  static const arabic = AppLanguage(
    code: 'ar',
    name: 'Arabic',
    nativeName: 'العربية',
  );
  static const hindi = AppLanguage(
    code: 'hi',
    name: 'Hindi',
    nativeName: 'हिन्दी',
  );
  static const chinese = AppLanguage(
    code: 'zh',
    name: 'Chinese',
    nativeName: '中文',
  );
  static const turkish = AppLanguage(
    code: 'tr',
    name: 'Turkish',
    nativeName: 'Türkçe',
  );
  static const russian = AppLanguage(
    code: 'ru',
    name: 'Russian',
    nativeName: 'Русский',
  );

  static const List<AppLanguage> supported = [
    english,
    french,
    spanish,
    italian,
    dutch,
    german,
    arabic,
    hindi,
    chinese,
    turkish,
    russian,
  ];

  static AppLanguage fromCode(String? code) {
    final normalized = (code ?? '').trim().toLowerCase();
    for (final lang in supported) {
      if (lang.code == normalized) return lang;
    }
    return english;
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) || other is AppLanguage && other.code == code;

  @override
  int get hashCode => code.hashCode;
}
