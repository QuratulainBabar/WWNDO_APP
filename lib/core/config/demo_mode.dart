import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// When enabled, auth flows use local static data instead of the backend API.
class DemoModeProvider extends ChangeNotifier {
  static const _prefsKey = 'demo_mode_enabled';

  bool _enabled = false;
  bool _loaded = false;

  bool get enabled => _enabled;
  bool get loaded => _loaded;

  Future<void> init() async {
    final prefs = await SharedPreferences.getInstance();
    _enabled = prefs.getBool(_prefsKey) ?? false;
    _loaded = true;
    notifyListeners();
  }

  Future<void> setEnabled(bool value) async {
    if (_enabled == value) return;
    _enabled = value;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_prefsKey, value);
  }
}
