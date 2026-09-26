import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../core/l10n/app_language.dart';

/// Persists and applies the user's preferred app language.
class LocaleProvider extends ChangeNotifier {
  static const _prefsKey = 'preferred_language_code';

  AppLanguage _language = AppLanguage.english;
  bool _loaded = false;

  AppLanguage get language => _language;
  Locale get locale => _language.locale;
  String get code => _language.code;
  bool get isRtl => _language.isRtl;
  bool get loaded => _loaded;
  List<AppLanguage> get supported => AppLanguage.supported;

  Future<void> init() async {
    final prefs = await SharedPreferences.getInstance();
    _language = AppLanguage.fromCode(prefs.getString(_prefsKey));
    _loaded = true;
    notifyListeners();
  }

  Future<void> setLanguage(AppLanguage value) async {
    if (_language == value) return;
    _language = value;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_prefsKey, value.code);
  }

  Future<void> setLanguageCode(String code) =>
      setLanguage(AppLanguage.fromCode(code));
}
