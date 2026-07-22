import '../../models/kyc_models.dart';
import 'sumsub_sdk_launcher.dart';

/// Fallback launcher for web / desktop — Sumsub MobileSDK is Android/iOS only.
class StubSumsubSdkLauncher implements SumsubSdkLauncher {
  @override
  bool get isSupported => false;

  @override
  Future<SumsubSdkOutcome> launch({
    required String accessToken,
    required Future<String?> Function() onTokenExpiration,
  }) async {
    return const SumsubSdkOutcome(
      status: SumsubSdkOutcomeStatus.failed,
      success: false,
      errorMessage:
          'Sumsub identity verification requires the Android or iOS app.',
      rawStatus: 'Unsupported',
    );
  }
}

SumsubSdkLauncher createSumsubSdkLauncher() => StubSumsubSdkLauncher();
