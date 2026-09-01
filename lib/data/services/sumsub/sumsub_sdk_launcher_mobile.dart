import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_idensic_mobile_sdk_plugin/flutter_idensic_mobile_sdk_plugin.dart';

import '../../models/kyc_models.dart';
import 'sumsub_sdk_launcher.dart';

/// Official Sumsub MobileSDK launcher (Android / iOS).
class MobileSumsubSdkLauncher implements SumsubSdkLauncher {
  @override
  bool get isSupported =>
      !kIsWeb &&
      (defaultTargetPlatform == TargetPlatform.android ||
          defaultTargetPlatform == TargetPlatform.iOS);

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

    try {
      final sdk = SNSMobileSDK.init(
        accessToken,
        onTokenExpiration,
      )
          .withHandlers(
            onStatusChanged: (newStatus, prevStatus) {
              if (kDebugMode) {
                debugPrint('Sumsub SDK status: $prevStatus -> $newStatus');
              }
            },
          )
          .withDebug(kDebugMode)
          .build();

      final result = await sdk.launch();
      return _mapResult(result);
    } catch (e, st) {
      if (kDebugMode) {
        debugPrint('Sumsub SDK launch error: $e\n$st');
      }
      return SumsubSdkOutcome(
        status: SumsubSdkOutcomeStatus.failed,
        success: false,
        errorMessage: e.toString(),
        rawStatus: 'Exception',
      );
    }
  }

  SumsubSdkOutcome _mapResult(SNSMobileSDKResult result) {
    final raw = result.status.name;
    switch (result.status) {
      case SNSMobileSDKStatus.Approved:
        return SumsubSdkOutcome(
          status: SumsubSdkOutcomeStatus.approved,
          success: result.success,
          rawStatus: raw,
        );
      case SNSMobileSDKStatus.Pending:
      case SNSMobileSDKStatus.ActionCompleted:
        return SumsubSdkOutcome(
          status: SumsubSdkOutcomeStatus.pending,
          success: result.success,
          rawStatus: raw,
        );
      case SNSMobileSDKStatus.FinallyRejected:
      case SNSMobileSDKStatus.TemporarilyDeclined:
        return SumsubSdkOutcome(
          status: SumsubSdkOutcomeStatus.rejected,
          success: result.success,
          errorMessage: result.errorMsg,
          rawStatus: raw,
        );
      case SNSMobileSDKStatus.Incomplete:
        return SumsubSdkOutcome(
          status: SumsubSdkOutcomeStatus.incomplete,
          success: result.success,
          errorMessage: result.errorMsg,
          rawStatus: raw,
        );
      case SNSMobileSDKStatus.Failed:
        return SumsubSdkOutcome(
          status: SumsubSdkOutcomeStatus.failed,
          success: false,
          errorMessage: result.errorMsg ?? 'Sumsub verification failed.',
          rawStatus: raw,
        );
      case SNSMobileSDKStatus.Ready:
      case SNSMobileSDKStatus.Initial:
        // User closed SDK before finishing.
        return SumsubSdkOutcome(
          status: SumsubSdkOutcomeStatus.canceled,
          success: false,
          errorMessage: result.errorMsg,
          rawStatus: raw,
        );
    }
  }
}

SumsubSdkLauncher createSumsubSdkLauncher() => MobileSumsubSdkLauncher();
