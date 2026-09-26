import '../models/auth_user.dart';

/// Result of password login before any weekly email OTP step.
class PasswordLoginResult {
  const PasswordLoginResult._({
    this.user,
    this.requiresLoginOtp = false,
    this.email,
  });

  const PasswordLoginResult.authenticated(AuthUser user)
      : this._(user: user, requiresLoginOtp: false);

  const PasswordLoginResult.needsOtp({required String email})
      : this._(requiresLoginOtp: true, email: email);

  final AuthUser? user;
  final bool requiresLoginOtp;
  final String? email;
}

/// Authenticated weekly login-OTP status (`GET /auth/login-otp/status`).
class WeeklyLoginOtpStatus {
  const WeeklyLoginOtpStatus({
    required this.required,
    this.email,
  });

  final bool required;
  final String? email;
}
