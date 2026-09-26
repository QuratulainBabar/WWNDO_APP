import 'package:flutter/foundation.dart';

import '../core/platform/biometric_prefs.dart';

/// Gates the app behind Face ID / biometric after 12h of inactivity.
///
/// Applies to any authenticated session (Sender, Traveler, Receiver). Does not
/// lock on every open — only when [BiometricPrefs.inactivityLockDuration] has
/// elapsed since the last recorded activity.
class SessionInactivityLock extends ChangeNotifier {
  bool _locked = false;
  bool _ready = false;

  bool get isLocked => _locked;
  bool get ready => _ready;

  /// Call once after [AuthProvider.init] so cold starts respect the 12h rule.
  Future<void> init({required bool isAuthenticated}) async {
    if (kIsWeb || !isAuthenticated) {
      _locked = false;
      _ready = true;
      notifyListeners();
      return;
    }

    if (await BiometricPrefs.isInactivityLockDue()) {
      _locked = true;
    } else {
      _locked = false;
      // Establish / refresh baseline so the clock starts from this session.
      await BiometricPrefs.touchLastActivity();
    }
    _ready = true;
    notifyListeners();
  }

  /// Persist activity when the app goes to background (while unlocked).
  Future<void> onAppPaused({required bool isAuthenticated}) async {
    if (kIsWeb || !isAuthenticated || _locked) return;
    await BiometricPrefs.touchLastActivity();
  }

  /// On foreground: lock if idle ≥ 12h; otherwise refresh activity.
  Future<void> onAppResumed({required bool isAuthenticated}) async {
    if (kIsWeb) {
      if (_locked) {
        _locked = false;
        notifyListeners();
      }
      return;
    }

    if (!isAuthenticated) {
      if (_locked) {
        _locked = false;
        notifyListeners();
      }
      return;
    }

    if (_locked) return;

    if (await BiometricPrefs.isInactivityLockDue()) {
      _locked = true;
      notifyListeners();
      return;
    }

    await BiometricPrefs.touchLastActivity();
  }

  /// After successful Face ID / biometric — continue into the app.
  Future<void> unlock() async {
    await BiometricPrefs.touchLastActivity();
    if (!_locked) return;
    _locked = false;
    notifyListeners();
  }

  /// Fresh login / session restore — clear any stale lock and start the clock.
  Future<void> onAuthenticated() async {
    await BiometricPrefs.touchLastActivity();
    if (_locked) {
      _locked = false;
      notifyListeners();
    }
  }

  /// Logout — drop activity baseline and clear the gate.
  Future<void> onLoggedOut() async {
    await BiometricPrefs.clearLastActivity();
    if (_locked) {
      _locked = false;
      notifyListeners();
    }
  }
}
