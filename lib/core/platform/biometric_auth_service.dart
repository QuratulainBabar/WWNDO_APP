import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:local_auth/local_auth.dart';
import 'platform_ui.dart';

enum BiometricAuthStatus {
  success,
  cancelled,
  notAvailable,
  notEnrolled,
  lockedOut,
  failed,
}

class BiometricAuthResult {
  const BiometricAuthResult(this.status, {this.message});

  final BiometricAuthStatus status;
  final String? message;

  bool get isSuccess => status == BiometricAuthStatus.success;
}

/// Wraps [LocalAuthentication] with platform-aware messaging.
abstract final class BiometricAuthService {
  static final LocalAuthentication _auth = LocalAuthentication();

  static Future<bool> isDeviceSupported() => _auth.isDeviceSupported();

  static Future<bool> canCheckBiometrics() => _auth.canCheckBiometrics;

  static Future<List<BiometricType>> getAvailableBiometrics() =>
      _auth.getAvailableBiometrics();

  static Future<BiometricAuthResult> authenticate({
    required String reason,
    bool biometricOnly = true,
  }) async {
    if (kIsWeb) {
      return const BiometricAuthResult(
        BiometricAuthStatus.notAvailable,
        message: 'Biometric login is not supported in the browser.',
      );
    }

    try {
      final supported = await _auth.isDeviceSupported();
      if (!supported) {
        return BiometricAuthResult(
          BiometricAuthStatus.notAvailable,
          message: '${PlatformUi.biometricShortLabel} is not available on this device.',
        );
      }

      final canCheck = await _auth.canCheckBiometrics;
      final biometrics = await _auth.getAvailableBiometrics();
      if (!canCheck || biometrics.isEmpty) {
        return BiometricAuthResult(
          BiometricAuthStatus.notEnrolled,
          message:
              'No ${PlatformUi.biometricShortLabel.toLowerCase()} is set up on this device. Add one in your device settings first.',
        );
      }

      final authenticated = await _auth.authenticate(
        localizedReason: reason,
        options: AuthenticationOptions(
          biometricOnly: biometricOnly,
          stickyAuth: true,
          useErrorDialogs: true,
        ),
      );

      if (authenticated) {
        return const BiometricAuthResult(BiometricAuthStatus.success);
      }
      return BiometricAuthResult(
        BiometricAuthStatus.failed,
        message: '${PlatformUi.biometricShortLabel} was not recognized. Try again.',
      );
    } on PlatformException catch (error) {
      return BiometricAuthResult(
        _mapPlatformError(error),
        message: error.message ?? 'Authentication failed. Please try again.',
      );
    } catch (_) {
      return const BiometricAuthResult(
        BiometricAuthStatus.failed,
        message: 'Something went wrong. Please try again.',
      );
    }
  }

  static BiometricAuthStatus _mapPlatformError(PlatformException error) {
    switch (error.code) {
      case 'NotAvailable':
      case 'notAvailable':
        return BiometricAuthStatus.notAvailable;
      case 'NotEnrolled':
      case 'notEnrolled':
        return BiometricAuthStatus.notEnrolled;
      case 'LockedOut':
      case 'lockedOut':
      case 'PermanentlyLockedOut':
      case 'permanentlyLockedOut':
        return BiometricAuthStatus.lockedOut;
      case 'PasscodeNotSet':
        return BiometricAuthStatus.notEnrolled;
      case 'UserCancel':
      case 'userCanceled':
      case 'Canceled':
      case 'canceled':
        return BiometricAuthStatus.cancelled;
      default:
        return BiometricAuthStatus.failed;
    }
  }
}
