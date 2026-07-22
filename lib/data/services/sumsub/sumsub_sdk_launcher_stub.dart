import '../../models/kyc_models.dart';
import 'sumsub_sdk_launcher.dart';

/// TEMPORARILY DISABLED - SUMSUB KYC
/// Inert launcher used on every platform while the integration is paused.
class MobileSumsubSdkLauncher implements SumsubSdkLauncher {
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
      errorMessage: 'Identity verification is temporarily unavailable.',
      rawStatus: 'TemporarilyDisabled',
    );
  }
}

SumsubSdkLauncher createSumsubSdkLauncher() => MobileSumsubSdkLauncher();
