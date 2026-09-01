import 'package:shared_preferences/shared_preferences.dart';

/// Persists biometric login prefs and soft-lock state for this device.
abstract final class BiometricPrefs {
  static const _enabledKey = 'biometric_login_enabled';
  static const _softLockedKey = 'biometric_session_soft_locked';

  static Future<bool> isLoginEnabled() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_enabledKey) ?? false;
  }

  static Future<void> setLoginEnabled(bool enabled) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_enabledKey, enabled);
    if (!enabled) {
      await prefs.setBool(_softLockedKey, false);
    }
  }

  /// True only after an explicit logout while biometric unlock is enabled.
  /// Cold-starting the app must NOT set this — otherwise users look "logged out".
  static Future<bool> isSessionSoftLocked() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_softLockedKey) ?? false;
  }

  static Future<void> setSessionSoftLocked(bool locked) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_softLockedKey, locked);
  }
}
