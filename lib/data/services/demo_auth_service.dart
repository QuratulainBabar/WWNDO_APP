import '../../core/api/api_exception.dart';
import '../../core/auth/selected_role.dart';
import '../models/auth_user.dart';
import '../models/otp_channel.dart';
import '../static_data.dart';
import 'otp_service.dart';
import 'token_storage.dart';

/// Local auth implementation for demo / offline mode (no backend).
abstract final class DemoAuthService {
  static const _accessToken = 'demo-access-token';
  static const _refreshToken = 'demo-refresh-token';
  static const _resetToken = 'demo-reset-token';

  /// Used by [AuthRepository] to detect a demo session vs a real API session.
  static const accessTokenForDetect = _accessToken;
  static const refreshTokenForDetect = _refreshToken;

  static AuthUser? _sessionUser;

  static Future<void> simulateNetworkDelay() =>
      Future<void>.delayed(const Duration(milliseconds: 350));

  static Future<AuthUser> signInAsDemo(TokenStorage storage) async {
    await simulateNetworkDelay();
    return _persistDemoSession(storage, StaticData.demoAuthUser);
  }

  static Future<AuthUser> register({
    required TokenStorage storage,
    required String name,
    required String email,
    required String phone,
    required String countryCode,
  }) async {
    await simulateNetworkDelay();
    final user = AuthUser(
      id: 'demo-user-${DateTime.now().millisecondsSinceEpoch}',
      name: name.trim(),
      email: email.trim(),
      phone: phone.trim(),
      countryCode: countryCode,
      bio: '',
      rating: 0,
      reviewCount: 0,
      walletBalance: 0,
      memberSince: _memberSinceLabel(DateTime.now()),
      isVerified: false,
      kycStatus: 'pending',
      accountStatus: 'active',
      emailVerified: false,
      phoneVerified: false,
    );
    return _persistDemoSession(storage, user);
  }

  static Future<AuthUser> login({
    required TokenStorage storage,
    required String email,
    required String password,
  }) async {
    await simulateNetworkDelay();
    OtpService.assertLoginNotLocked(email);

    if (password.length < 8) {
      OtpService.recordFailedLogin(email);
      throw const ApiException(
        message: 'Invalid email or password',
        code: 'INVALID_CREDENTIALS',
      );
    }

    OtpService.clearFailedLogins(email);
    final demoUser = StaticData.demoAuthUser;
    final trimmedEmail = email.trim();
    final cachedRole = await SelectedRoleStore.loadForUser(email: trimmedEmail);
    return _persistDemoSession(
      storage,
      demoUser.copyWith(
        email: trimmedEmail,
        role: cachedRole != null ? SelectedRoleStore.apiValue(cachedRole) : null,
        // Password login must not inherit demo user's pre-verified flags.
        emailVerified: false,
        phoneVerified: false,
        isVerified: false,
      ),
    );
  }

  static Future<void> sendLoginOtp({
    required String contact,
    required OtpChannel channel,
  }) async {
    await OtpService.sendOtp(
      contact: contact,
      channel: channel,
      purpose: OtpPurpose.login,
    );
  }

  static Future<AuthUser> verifyLoginOtp({
    required TokenStorage storage,
    required String contact,
    required OtpChannel channel,
    required String code,
  }) async {
    await OtpService.verifyOtp(
      contact: contact,
      purpose: OtpPurpose.login,
      code: code,
    );

    final trimmed = contact.trim();
    final isEmail = channel == OtpChannel.email;
    final existing = _sessionUser;

    // Login OTP authenticates only — email/phone stay unverified until
    // cross-verification OTP is entered.
    if (isEmail && existing != null && existing.email.toLowerCase() == trimmed.toLowerCase()) {
      return _persistDemoSession(storage, existing);
    }

    if (!isEmail && existing != null && existing.phone.replaceAll(' ', '') == trimmed.replaceAll(' ', '')) {
      return _persistDemoSession(storage, existing);
    }

    final user = isEmail
        ? AuthUser(
            id: 'demo-otp-${DateTime.now().millisecondsSinceEpoch}',
            name: 'WWNGO User',
            email: trimmed,
            phone: '+33 612 345 678',
            countryCode: 'FR',
            bio: '',
            rating: 0,
            reviewCount: 0,
            walletBalance: 0,
            memberSince: _memberSinceLabel(DateTime.now()),
            isVerified: false,
            kycStatus: 'pending',
            accountStatus: 'active',
            emailVerified: false,
            phoneVerified: false,
          )
        : AuthUser(
            id: 'demo-otp-${DateTime.now().millisecondsSinceEpoch}',
            name: 'WWNGO User',
            email: 'user@wwngo.demo',
            phone: trimmed,
            countryCode: 'FR',
            bio: '',
            rating: 0,
            reviewCount: 0,
            walletBalance: 0,
            memberSince: _memberSinceLabel(DateTime.now()),
            isVerified: false,
            kycStatus: 'pending',
            accountStatus: 'active',
            emailVerified: false,
            phoneVerified: false,
          );

    return _persistDemoSession(storage, user);
  }

  static Future<void> sendCrossVerificationOtp({
    required AuthUser user,
    required OtpChannel channel,
  }) async {
    final contact = channel == OtpChannel.email ? user.email : user.phone;
    final purpose =
        channel == OtpChannel.email ? OtpPurpose.verifyEmail : OtpPurpose.verifyPhone;
    await OtpService.sendOtp(contact: contact, channel: channel, purpose: purpose);
  }

  static Future<AuthUser> verifyCrossVerificationOtp({
    required TokenStorage storage,
    required AuthUser user,
    required OtpChannel channel,
    required String code,
  }) async {
    final contact = channel == OtpChannel.email ? user.email : user.phone;
    final purpose =
        channel == OtpChannel.email ? OtpPurpose.verifyEmail : OtpPurpose.verifyPhone;
    await OtpService.verifyOtp(contact: contact, purpose: purpose, code: code);

    final updated = channel == OtpChannel.email
        ? user.copyWith(emailVerified: true)
        : user.copyWith(phoneVerified: true);
    return _persistDemoSession(storage, updated);
  }

  static Future<AuthUser> setRole({
    required TokenStorage storage,
    required AuthUser user,
    required String role,
  }) async {
    await simulateNetworkDelay();
    final updated = user.copyWith(role: role);
    final parsed = SelectedRoleStore.tryParse(role);
    if (parsed != null) {
      await SelectedRoleStore.saveForUser(
        userId: updated.id,
        email: updated.email,
        role: parsed,
      );
    }
    return _persistDemoSession(storage, updated);
  }

  static Future<bool> refreshSession({
    required TokenStorage storage,
    required AuthUser? currentUser,
  }) async {
    await simulateNetworkDelay();
    if (currentUser == null) return false;
    await storage.saveTokens(
      accessToken: _accessToken,
      refreshToken: _refreshToken,
    );
    return true;
  }

  static Future<void> logout(TokenStorage storage) async {
    await storage.clear();
    _sessionUser = null;
  }

  static Future<void> sendPasswordResetOtp({
    required String contact,
    required OtpChannel channel,
  }) async {
    await OtpService.sendOtp(
      contact: contact,
      channel: channel,
      purpose: OtpPurpose.passwordReset,
    );
  }

  static Future<String> verifyPasswordResetOtp({
    required String contact,
    required OtpChannel channel,
    required String code,
  }) async {
    await OtpService.verifyOtp(
      contact: contact,
      purpose: OtpPurpose.passwordReset,
      code: code,
    );
    return _resetToken;
  }

  static Future<void> resetPassword() => simulateNetworkDelay();

  static Future<void> changePassword({
    required String currentPassword,
    required String newPassword,
  }) async {
    await simulateNetworkDelay();
    if (currentPassword.isEmpty) {
      throw const ApiException(
        message: 'Current password is required',
        code: 'VALIDATION_ERROR',
      );
    }
    if (newPassword.length < 8) {
      throw const ApiException(
        message: 'New password must be at least 8 characters',
        code: 'VALIDATION_ERROR',
      );
    }
    if (currentPassword == newPassword) {
      throw const ApiException(
        message: 'New password must be different from current password',
        code: 'VALIDATION_ERROR',
      );
    }
  }

  static Future<void> verifyPassword(String password) async {
    await simulateNetworkDelay();
    if (password.isEmpty) {
      throw const ApiException(
        message: 'Enter your password',
        code: 'VALIDATION_ERROR',
      );
    }
  }

  static Future<AuthUser> _persistDemoSession(
    TokenStorage storage,
    AuthUser user,
  ) async {
    _sessionUser = user;
    await storage.saveSession(
      accessToken: _accessToken,
      refreshToken: _refreshToken,
      user: user,
    );
    return user;
  }

  static String _memberSinceLabel(DateTime date) {
    const months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
    ];
    return '${months[date.month - 1]} ${date.year}';
  }
}
