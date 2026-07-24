import 'dart:math';

import '../../core/api/api_exception.dart';
import '../models/otp_channel.dart';
import 'demo_auth_service.dart';

/// Local OTP store used only when Flutter demo mode is enabled (no backend).
abstract final class OtpService {
  static const otpTtl = Duration(minutes: 5);
  static const maxSendsPerWindow = 3;
  static const sendWindow = Duration(minutes: 15);
  static const maxFailedLogins = 5;
  static const lockoutDuration = Duration(minutes: 15);
  static const otpLength = 6;
  /// Fixed demo code accepted for verification (never shown in UI).
  static const demoOtpCode = '123456';

  static final Map<String, _OtpRecord> _records = {};
  static final Map<String, List<DateTime>> _sendLog = {};
  static final Map<String, int> _failedLogins = {};
  static final Map<String, DateTime> _lockedUntil = {};
  static final _random = Random.secure();

  static String _key(String contact, OtpPurpose purpose) => '${purpose.name}:$contact';

  static String _generateSixDigitOtp() {
    // 100000–999999 so the code is always visibly 6 digits.
    return (100000 + _random.nextInt(900000)).toString();
  }

  static void assertNotRateLimited(String contact) {
    final now = DateTime.now();
    final key = contact.toLowerCase();
    final sends = (_sendLog[key] ?? [])
        .where((t) => now.difference(t) < sendWindow)
        .toList();
    _sendLog[key] = sends;
    if (sends.length >= maxSendsPerWindow) {
      throw const ApiException(
        message: 'Too many OTP requests. Please wait before trying again.',
        code: 'OTP_RATE_LIMITED',
      );
    }
  }

  static void assertLoginNotLocked(String email) {
    final key = email.trim().toLowerCase();
    final locked = _lockedUntil[key];
    if (locked != null && locked.isAfter(DateTime.now())) {
      final mins = locked.difference(DateTime.now()).inMinutes + 1;
      throw ApiException(
        message: 'Account locked after $maxFailedLogins failed attempts. Try again in $mins min.',
        code: 'ACCOUNT_LOCKED',
      );
    }
    if (locked != null) {
      _lockedUntil.remove(key);
      _failedLogins.remove(key);
    }
  }

  static void recordFailedLogin(String email) {
    final key = email.trim().toLowerCase();
    final count = (_failedLogins[key] ?? 0) + 1;
    _failedLogins[key] = count;
    if (count >= maxFailedLogins) {
      _lockedUntil[key] = DateTime.now().add(lockoutDuration);
    }
  }

  static void clearFailedLogins(String email) {
    final key = email.trim().toLowerCase();
    _failedLogins.remove(key);
    _lockedUntil.remove(key);
  }

  static Future<void> sendOtp({
    required String contact,
    required OtpChannel channel,
    required OtpPurpose purpose,
  }) async {
    await DemoAuthService.simulateNetworkDelay();
    final normalized = contact.trim();
    assertNotRateLimited(normalized);

    final code = channel == OtpChannel.sms || purpose == OtpPurpose.verifyPhone
        ? demoOtpCode
        : _generateSixDigitOtp();
    final expiresAt = DateTime.now().add(otpTtl);
    _records[_key(normalized, purpose)] = _OtpRecord(
      code: code,
      channel: channel,
      expiresAt: expiresAt,
    );

    final logKey = normalized.toLowerCase();
    _sendLog[logKey] = [...(_sendLog[logKey] ?? []), DateTime.now()];
  }

  static Future<void> verifyOtp({
    required String contact,
    required OtpPurpose purpose,
    required String code,
  }) async {
    await DemoAuthService.simulateNetworkDelay();
    final normalized = contact.trim();
    final entered = code.trim();

    // Silent demo OTP — works for signup / login without showing it in the UI.
    if (entered == demoOtpCode) {
      _records.remove(_key(normalized, purpose));
      return;
    }

    final record = _records[_key(normalized, purpose)];
    if (record == null || record.expiresAt.isBefore(DateTime.now())) {
      throw const ApiException(
        message: 'Invalid or expired verification code',
        code: 'INVALID_OTP',
      );
    }
    if (entered != record.code) {
      throw const ApiException(
        message: 'Invalid or expired verification code',
        code: 'INVALID_OTP',
      );
    }
    _records.remove(_key(normalized, purpose));
  }
}

class _OtpRecord {
  _OtpRecord({
    required this.code,
    required this.channel,
    required this.expiresAt,
  });

  final String code;
  final OtpChannel channel;
  final DateTime expiresAt;
}
