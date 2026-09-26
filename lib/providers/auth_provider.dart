import 'package:flutter/foundation.dart';

import '../core/push/push_notification_service.dart';
import '../core/api/api_exception.dart';
import '../core/config/demo_mode.dart';
import '../core/platform/biometric_prefs.dart';
import '../data/models/auth_user.dart';
import '../data/models/otp_channel.dart';
import '../data/models/password_login_result.dart';
import '../data/services/auth_repository.dart';
import 'session_inactivity_lock.dart';

class AuthProvider extends ChangeNotifier {
  AuthProvider({
    AuthRepository? repository,
    DemoModeProvider? demoMode,
    SessionInactivityLock? inactivityLock,
  })  : _demoMode = demoMode,
        _inactivityLock = inactivityLock,
        _repository = repository ??
            AuthRepository(demoMode: demoMode);

  final AuthRepository _repository;
  final DemoModeProvider? _demoMode;
  final SessionInactivityLock? _inactivityLock;

  AuthUser? get user => _repository.currentUser;
  bool get isAuthenticated => user != null;
  bool get isDemoMode => _demoMode?.enabled ?? false;
  bool _initializing = true;
  bool get initializing => _initializing;
  bool _loading = false;
  bool get loading => _loading;

  AuthRepository get repository => _repository;

  Future<void> init() async {
    await _repository.init();
    _initializing = false;
    notifyListeners();
  }

  Future<AuthUser> signInAsDemo() {
    return _run(_repository.signInAsDemo);
  }

  Future<AuthUser> register({
    required String name,
    required String email,
    required String phone,
    required String dialCode,
    required String phoneNumber,
    required String password,
    required String countryCode,
    required bool acceptedTerms,
  }) {
    return _run(() => _repository.register(
          name: name,
          email: email,
          phone: phone,
          dialCode: dialCode,
          phoneNumber: phoneNumber,
          password: password,
          countryCode: countryCode,
          acceptedTerms: acceptedTerms,
        ));
  }

  Future<PasswordLoginResult> login({
    required String email,
    required String password,
  }) {
    return _run(() => _repository.login(email: email, password: password));
  }

  Future<void> sendPasswordLoginOtp({
    required String email,
    required String password,
    bool trackLoading = true,
  }) {
    if (!trackLoading) {
      return _repository.sendPasswordLoginOtp(
        email: email,
        password: password,
      );
    }
    return _run(() => _repository.sendPasswordLoginOtp(
          email: email,
          password: password,
        ));
  }

  Future<AuthUser> completePasswordLoginOtp({
    required String email,
    required String password,
    required String code,
  }) {
    return _run(() => _repository.completePasswordLoginOtp(
          email: email,
          password: password,
          code: code,
        ));
  }

  Future<bool> isWeeklyLoginOtpRequired() {
    return _repository.isWeeklyLoginOtpRequired();
  }

  Future<WeeklyLoginOtpStatus> getWeeklyLoginOtpStatus() {
    return _repository.getWeeklyLoginOtpStatus();
  }

  Future<void> sendAuthenticatedLoginOtp({bool trackLoading = false}) {
    if (!trackLoading) {
      return _repository.sendAuthenticatedLoginOtp();
    }
    return _run(_repository.sendAuthenticatedLoginOtp);
  }

  Future<AuthUser> verifyAuthenticatedLoginOtp({required String code}) {
    return _run(() => _repository.verifyAuthenticatedLoginOtp(code: code));
  }

  Future<void> logout() => _run(_repository.logout);

  /// Clears the session completely (no biometric soft-lock). Used when the user
  /// chooses password login from the inactivity Face ID gate.
  Future<void> logoutFully() => _run(() => _repository.logout(forceFull: true));

  Future<void> sendPasswordResetOtp({
    required String contact,
    required OtpChannel channel,
  }) {
    return _run(() => _repository.sendPasswordResetOtp(
          contact: contact,
          channel: channel,
        ));
  }

  Future<String> verifyPasswordResetOtp({
    required String contact,
    required OtpChannel channel,
    required String code,
  }) {
    return _run(() => _repository.verifyPasswordResetOtp(
          contact: contact,
          channel: channel,
          code: code,
        ));
  }

  Future<void> sendLoginOtp({
    required String contact,
    required OtpChannel channel,
  }) {
    return _run(() => _repository.sendLoginOtp(contact: contact, channel: channel));
  }

  Future<AuthUser> verifyLoginOtp({
    required String contact,
    required OtpChannel channel,
    required String code,
  }) {
    return _run(() => _repository.verifyLoginOtp(
          contact: contact,
          channel: channel,
          code: code,
        ));
  }

  Future<void> sendCrossVerificationOtp({required OtpChannel channel}) {
    return _run(() => _repository.sendCrossVerificationOtp(channel: channel));
  }

  Future<AuthUser> verifyCrossVerificationOtp({
    required OtpChannel channel,
    required String code,
  }) {
    return _run(() => _repository.verifyCrossVerificationOtp(
          channel: channel,
          code: code,
        ));
  }

  Future<AuthUser> setRole(String role) {
    return _run(() => _repository.setRole(role));
  }

  Future<void> updateLinkedPhone(String phone) {
    return _run(() async {
      final current = _repository.currentUser;
      if (current == null) {
        throw const ApiException(message: 'Not signed in', code: 'UNAUTHORIZED');
      }
      await _repository.updateCurrentUser(current.copyWith(phone: phone.trim()));
    });
  }

  Future<AuthUser> submitKycForReview() {
    return _run(_repository.submitKycForReview);
  }

  Future<AuthUser> approveKyc() {
    return _run(_repository.approveKyc);
  }

  Future<AuthUser> rejectKyc() {
    return _run(_repository.rejectKyc);
  }

  Future<AuthUser> resetKycForRetry() {
    return _run(_repository.resetKycForRetry);
  }

  Future<void> resetPassword({
    required String resetToken,
    required String password,
  }) {
    return _run(() => _repository.resetPassword(
          resetToken: resetToken,
          password: password,
        ));
  }

  Future<void> changePassword({
    required String currentPassword,
    required String newPassword,
  }) {
    return _run(() => _repository.changePassword(
          currentPassword: currentPassword,
          newPassword: newPassword,
        ));
  }

  Future<AuthUser> updateProfile({
    required String name,
    required String email,
    required String phone,
    required String dialCode,
    required String phoneNumber,
    required String countryCode,
  }) {
    return _run(() => _repository.updateProfile(
          name: name,
          email: email,
          phone: phone,
          dialCode: dialCode,
          phoneNumber: phoneNumber,
          countryCode: countryCode,
        ));
  }

  Future<AuthUser> fetchProfile() {
    return _run(_repository.fetchProfile);
  }

  /// Upload profile photo and refresh listeners so Profile avatars update.
  Future<String?> uploadAvatarBytes(
    List<int> bytes, {
    String filename = 'avatar.png',
  }) async {
    final url = await _repository.uploadAvatarBytes(bytes, filename: filename);
    notifyListeners();
    return url;
  }

  Future<String?> uploadAvatar(String filePath) async {
    final url = await _repository.uploadAvatar(filePath);
    notifyListeners();
    return url;
  }

  /// Remove profile photo and refresh listeners so Profile avatars update.
  Future<void> deleteAvatar() async {
    await _repository.deleteAvatar();
    notifyListeners();
  }

  /// Refreshes `/auth/me` without flipping the global [loading] flag.
  /// Safe for home/header widgets that should stay interactive while syncing.
  Future<AuthUser?> refreshUser() async {
    try {
      final user = await _repository.fetchProfile();
      notifyListeners();
      return user;
    } on ApiException {
      return null;
    }
  }

  Future<void> verifyPassword(String password) {
    return _run(() => _repository.verifyPassword(password));
  }

  Future<bool> tryRestoreSession() async {
    try {
      final restored = await _repository.refreshSession();
      if (restored) {
        await BiometricPrefs.setSessionSoftLocked(false);
        await _inactivityLock?.onAuthenticated();
        notifyListeners();
        PushNotificationService.registerIfAuthenticated(_repository).ignore();
      }
      return restored;
    } on ApiException {
      await BiometricPrefs.setLoginEnabled(false);
      await BiometricPrefs.setSessionSoftLocked(false);
      await _repository.logout(forceFull: true);
      await _inactivityLock?.onLoggedOut();
      notifyListeners();
      return false;
    }
  }

  Future<bool> canUnlockWithBiometric() =>
      _repository.canUnlockWithBiometric();

  Future<T> _run<T>(Future<T> Function() action) async {
    _loading = true;
    notifyListeners();
    try {
      final result = await action();
      if (isAuthenticated) {
        await _inactivityLock?.onAuthenticated();
        PushNotificationService.registerIfAuthenticated(_repository).ignore();
      } else {
        await _inactivityLock?.onLoggedOut();
      }
      notifyListeners();
      return result;
    } on ApiException {
      rethrow;
    } finally {
      _loading = false;
      notifyListeners();
    }
  }
}
