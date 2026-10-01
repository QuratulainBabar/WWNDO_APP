import 'package:flutter/material.dart';

import '../../data/delivery_cancel_policy.dart';
import '../../l10n/app_localizations.dart';
import '../theme/app_colors.dart';
import '../theme/app_typography.dart';
import 'app_button.dart';

/// Shows a confirmation popup before cancelling a parcel request.
/// Returns `true` when the user confirms cancellation.
///
/// When [keepButtonFirst] is true, Keep is shown above Cancel Request
/// (traveler cancel-trip confirmation).
Future<bool> showCancelRequestConfirmation(
  BuildContext context, {
  bool keepButtonFirst = false,
}) async {
  final confirmed = await showDialog<bool>(
    context: context,
    builder: (dialogContext) {
      final typo = dialogContext.typo;
      final l10n = dialogContext.l10n;
      final hours = '${DeliveryCancelPolicy.cancelMinHoursBeforeTravel}';
      final cancelButton = AppButton(
        label: l10n.cancelRequestTitle,
        variant: AppButtonVariant.danger,
        onPressed: () => Navigator.of(dialogContext).pop(true),
      );
      final keepButton = AppButton(
        label: l10n.keep,
        variant: AppButtonVariant.ghost,
        onPressed: () => Navigator.of(dialogContext).pop(false),
      );
      return Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 28, 24, 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                l10n.cancelRequestTitle,
                style: typo.h2.copyWith(fontWeight: FontWeight.w700),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Text(
                l10n.cancelRequestBody,
                style: typo.sm.copyWith(color: AppColors.textSecondary),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              _CancellationPolicySection(
                title: l10n.cancelPolicyMoreThanHours(hours),
                escrowLabel: l10n.escrowAmountRefunded,
                feeLabel: l10n.platformFeeRefundedAllUsers,
              ),
              const SizedBox(height: 14),
              _CancellationPolicySection(
                title: l10n.cancelPolicyLessThanHours(hours),
                escrowLabel: l10n.escrowAmountRefundedToSender,
                feeLabel: l10n.platformFeeNonRefundableAllUsers,
              ),
              const SizedBox(height: 24),
              if (keepButtonFirst) ...[
                keepButton,
                const SizedBox(height: AppButton.stackGap),
                cancelButton,
              ] else ...[
                cancelButton,
                const SizedBox(height: AppButton.stackGap),
                keepButton,
              ],
            ],
          ),
        ),
      );
    },
  );
  return confirmed ?? false;
}

class _CancellationPolicySection extends StatelessWidget {
  const _CancellationPolicySection({
    required this.title,
    required this.escrowLabel,
    required this.feeLabel,
  });

  final String title;
  final String escrowLabel;
  final String feeLabel;

  @override
  Widget build(BuildContext context) {
    final typo = context.typo;
    return Align(
      alignment: AlignmentDirectional.centerStart,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: typo.sm.copyWith(
              fontWeight: FontWeight.w700,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            escrowLabel,
            style: typo.sm.copyWith(
              height: 1.5,
              color: AppColors.textSecondary,
            ),
          ),
          Text(
            feeLabel,
            style: typo.sm.copyWith(
              height: 1.5,
              color: AppColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }
}
