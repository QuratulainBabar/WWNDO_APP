import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

/// Cross-platform UI helpers — uses [defaultTargetPlatform], not dart:io.
abstract final class PlatformUi {
  static bool get isIOS => defaultTargetPlatform == TargetPlatform.iOS;

  static bool get isAndroid => defaultTargetPlatform == TargetPlatform.android;

  static String get backLabel => '← Back';

  static String get backArrow => '←';

  static String get biometricLabel => 'Use Face ID / Fingerprint';

  static String get biometricShortLabel => isIOS ? 'Face ID' : 'Fingerprint';

  static IconData get biometricIcon =>
      isIOS ? Icons.face_rounded : Icons.fingerprint_rounded;

  static String get biometricPromptReason =>
      isIOS ? 'Log in to WWNGO with Face ID' : 'Log in to WWNGO with your fingerprint';

  static String get biometricSetupReason =>
      isIOS ? 'Confirm Face ID to enable quick login' : 'Confirm your fingerprint to enable quick login';

  static ScrollPhysics get scrollPhysics =>
      isIOS ? const BouncingScrollPhysics() : const ClampingScrollPhysics();

  static Future<T?> showAppBottomSheet<T>(
    BuildContext context, {
    required Widget child,
  }) {
    return showModalBottomSheet<T>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Colors.transparent,
      builder: (_) => child,
    );
  }
}
