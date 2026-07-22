// TEMPORARILY DISABLED - SUMSUB KYC
// This implementation is preserved but excluded by sumsub_sdk_factory.dart.
// SNSMobileSDK.init and launch cannot be reached while the factory uses the stub.
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_idensic_mobile_sdk_plugin/flutter_idensic_mobile_sdk_plugin.dart';

import '../../models/kyc_models.dart';
import 'sumsub_sdk_launcher.dart';

/// Official Sumsub MobileSDK launcher (Android / iOS).
class MobileSumsubSdkLauncher implements SumsubSdkLauncher {
  @override
  bool get isSupported {
    if (kIsWeb) return false;
    return defaultTargetPlatform == TargetPlatform.android ||
        defaultTargetPlatform == TargetPlatform.iOS;
  }

  @override
  Future<SumsubSdkOutcome> launch({
    required String accessToken,
    required Future<String?> Function() onTokenExpiration,
  }) async {
    if (!isSupported) {
      return const SumsubSdkOutcome(
        status: SumsubSdkOutcomeStatus.failed,
        success: false,
        errorMessage:
            'Sumsub identity verification requires the Android or iOS app.',
        rawStatus: 'Unsupported',
      );
    }

    final sdk = SNSMobileSDK.init(accessToken, onTokenExpiration)
        .withHandlers(
          onStatusChanged: (newStatus, prevStatus) {
            debugPrint('Sumsub SDK status: $prevStatus -> $newStatus');
          },
        )
        .withDebug(kDebugMode)
        .withLocale(const Locale('en'))
        .build();

    final SNSMobileSDKResult result = await sdk.launch();
    return _mapResult(result);
  }

  SumsubSdkOutcome _mapResult(SNSMobileSDKResult result) {
    final raw = result.status.toString();
    final statusName = raw.contains('.') ? raw.split('.').last : raw;

    switch (result.status) {
      case SNSMobileSDKStatus.Approved:
        return SumsubSdkOutcome(
          status: SumsubSdkOutcomeStatus.approved,
          success: result.success,
          rawStatus: statusName,
        );
      case SNSMobileSDKStatus.Pending:
      case SNSMobileSDKStatus.TemporarilyDeclined:
        return SumsubSdkOutcome(
          status: SumsubSdkOutcomeStatus.pending,
          success: result.success,
          rawStatus: statusName,
        );
      case SNSMobileSDKStatus.FinallyRejected:
        return SumsubSdkOutcome(
          status: SumsubSdkOutcomeStatus.rejected,
          success: result.success,
          rawStatus: statusName,
        );
      case SNSMobileSDKStatus.Initial:
      case SNSMobileSDKStatus.Incomplete:
        return SumsubSdkOutcome(
          status: SumsubSdkOutcomeStatus.canceled,
          success: result.success,
          errorMessage: result.errorMsg,
          rawStatus: statusName,
        );
      case SNSMobileSDKStatus.Failed:
        return SumsubSdkOutcome(
          status: SumsubSdkOutcomeStatus.failed,
          success: false,
          errorMessage: result.errorMsg ?? 'Sumsub SDK failed.',
          rawStatus: statusName,
        );
      case SNSMobileSDKStatus.Ready:
        return SumsubSdkOutcome(
          status: SumsubSdkOutcomeStatus.incomplete,
          success: result.success,
          rawStatus: statusName,
        );
      case SNSMobileSDKStatus.ActionCompleted:
        return SumsubSdkOutcome(
          status: SumsubSdkOutcomeStatus.pending,
          success: result.success,
          rawStatus: statusName,
        );
    }
  }
}

SumsubSdkLauncher createSumsubSdkLauncher() => MobileSumsubSdkLauncher();
