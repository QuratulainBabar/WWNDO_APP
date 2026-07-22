import 'package:shared_preferences/shared_preferences.dart';

/// Persists whether the user has enabled biometric login for this device.
abstract final class BiometricPrefs {
  static const _enabledKey = 'biometric_login_enabled';

  static Future<bool> isLoginEnabled() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_enabledKey) ?? false;
  }

  static Future<void> setLoginEnabled(bool enabled) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_enabledKey, enabled);
  }
}
