import 'package:shared_preferences/shared_preferences.dart';

/// Persists biometric login prefs, soft-lock, and inactivity lock state.
abstract final class BiometricPrefs {
  static const _enabledKey = 'biometric_login_enabled';
  static const _softLockedKey = 'biometric_session_soft_locked';
  static const _lastActivityKey = 'session_last_activity_ms';

  /// Require Face ID / biometric re-entry after this much idle time.
  static const inactivityLockDuration = Duration(hours: 12);

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

  /// Records "now" as the last interactive use of the app.
  static Future<void> touchLastActivity([DateTime? at]) async {
    final prefs = await SharedPreferences.getInstance();
    final stamp = (at ?? DateTime.now()).millisecondsSinceEpoch;
    await prefs.setInt(_lastActivityKey, stamp);
  }

  static Future<DateTime?> lastActivityAt() async {
    final prefs = await SharedPreferences.getInstance();
    final ms = prefs.getInt(_lastActivityKey);
    if (ms == null) return null;
    return DateTime.fromMillisecondsSinceEpoch(ms);
  }

  static Future<void> clearLastActivity() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_lastActivityKey);
  }

  /// True when a prior activity stamp exists and is older than [inactivityLockDuration].
  /// Missing stamp → not due (baseline set on next touch / login).
  static Future<bool> isInactivityLockDue() async {
    final last = await lastActivityAt();
    if (last == null) return false;
    return DateTime.now().difference(last) >= inactivityLockDuration;
  }
}
