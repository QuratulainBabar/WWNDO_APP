import '../../models/kyc_models.dart';

/// Platform-agnostic Sumsub SDK launcher.
abstract class SumsubSdkLauncher {
  /// Whether the official Sumsub MobileSDK can run on this platform.
  bool get isSupported;

  /// Launches Sumsub with [accessToken] and refreshes via [onTokenExpiration].
  Future<SumsubSdkOutcome> launch({
    required String accessToken,
    required Future<String?> Function() onTokenExpiration,
  });
}
