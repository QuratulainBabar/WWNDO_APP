// TEMPORARILY DISABLED - SUMSUB KYC
// Preserved for restoration; no active route invokes these actions.
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../core/widgets/app_toast.dart';
import '../../data/models/kyc_models.dart';
import '../../data/notification_service.dart';
import '../../providers/auth_provider.dart';
import '../../providers/kyc_provider.dart';

/// KYC submission helpers — live Sumsub path + demo fallbacks.
abstract final class KycFlowActions {
  /// Live path: backend access token → Sumsub SDK → refresh KYC status.
  static Future<void> startSumsubVerification(BuildContext context) async {
    final kyc = context.read<KycProvider>();
    final result = await kyc.startVerification();
    if (!context.mounted) return;

    final outcome = result.outcome;
    final backendStatus = result.status?.kycStatus;

    if (outcome.status == SumsubSdkOutcomeStatus.canceled ||
        outcome.status == SumsubSdkOutcomeStatus.incomplete) {
      AppToast.info(context, outcome.userMessage);
      return;
    }

    if (outcome.status == SumsubSdkOutcomeStatus.failed ||
        outcome.status == SumsubSdkOutcomeStatus.unknown) {
      AppToast.error(context, outcome.userMessage);
      return;
    }

    // Prefer backend status after sync; fall back to SDK outcome.
    final effective = backendStatus ??
        switch (outcome.status) {
          SumsubSdkOutcomeStatus.approved => KycStatusValue.approved,
          SumsubSdkOutcomeStatus.rejected => KycStatusValue.rejected,
          SumsubSdkOutcomeStatus.pending => KycStatusValue.submitted,
          _ => KycStatusValue.submitted,
        };

    switch (effective) {
      case KycStatusValue.approved:
        AppToast.success(context, 'Identity verification approved.');
        context.go('/kyc-approved');
      case KycStatusValue.rejected:
        AppToast.error(context, 'Verification was rejected. Please try again.');
        context.go('/kyc-rejected');
      case KycStatusValue.submitted:
        AppToast.info(context, 'Documents submitted. Verification is pending review.');
        context.go('/kyc-pending-review');
      case KycStatusValue.pending:
        AppToast.info(context, outcome.userMessage);
    }
  }

  static Future<void> refreshAndRoute(BuildContext context) async {
    final kyc = context.read<KycProvider>();
    try {
      final result = await kyc.refreshStatus(sync: true);
      if (!context.mounted) return;
      switch (result.kycStatus) {
        case KycStatusValue.approved:
          context.go('/kyc-approved');
        case KycStatusValue.rejected:
          context.go('/kyc-rejected');
        case KycStatusValue.submitted:
          context.go('/kyc-pending-review');
        case KycStatusValue.pending:
          context.go('/kyc');
      }
    } catch (e) {
      if (context.mounted) {
        AppToast.error(context, kyc.error ?? e.toString());
      }
    }
  }

  static Future<void> submitForReview(BuildContext context) async {
    final auth = context.read<AuthProvider>();
    await auth.submitKycForReview();
    if (!context.mounted) return;
    context.go('/kyc-pending-review');
  }

  static Future<void> approveDemo(BuildContext context) async {
    final auth = context.read<AuthProvider>();
    await auth.approveKyc();
    NotificationService.notifyKycApproved();
    if (!context.mounted) return;
    context.go('/kyc-approved');
  }

  static Future<void> rejectDemo(BuildContext context) async {
    final auth = context.read<AuthProvider>();
    await auth.rejectKyc();
    NotificationService.notifyKycRejected();
    if (!context.mounted) return;
    context.go('/kyc-rejected');
  }

  static Future<void> resetForRetry(BuildContext context) async {
    final auth = context.read<AuthProvider>();
    await auth.resetKycForRetry();
  }
}
