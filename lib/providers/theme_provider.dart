import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../core/theme/app_colors.dart';

/// Persists and applies Light / Dark mode for the whole app.
class ThemeProvider extends ChangeNotifier {
  static const _prefsKey = 'theme_dark_mode';

  bool _isDark = false;
  bool _loaded = false;

  bool get isDark => _isDark;
  bool get isLight => !_isDark;
  bool get loaded => _loaded;
  ThemeMode get themeMode => _isDark ? ThemeMode.dark : ThemeMode.light;

  Future<void> init() async {
    final prefs = await SharedPreferences.getInstance();
    _isDark = prefs.getBool(_prefsKey) ?? false;
    AppColors.bind(_isDark ? AppColorPalette.dark : AppColorPalette.light);
    _loaded = true;
    notifyListeners();
  }

  Future<void> setDarkMode(bool value) async {
    if (_isDark == value) return;
    _isDark = value;
    AppColors.bind(value ? AppColorPalette.dark : AppColorPalette.light);
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_prefsKey, value);
  }
}
