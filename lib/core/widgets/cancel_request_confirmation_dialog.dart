import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../theme/app_typography.dart';
import 'app_button.dart';

/// Shows a confirmation popup before cancelling a parcel request.
/// Returns `true` when the user confirms cancellation.
Future<bool> showCancelRequestConfirmation(BuildContext context) async {
  final confirmed = await showDialog<bool>(
    context: context,
    builder: (dialogContext) {
      final typo = dialogContext.typo;
      return Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 28, 24, 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Cancel Request',
                style: typo.h2.copyWith(fontWeight: FontWeight.w700),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Text(
                'Allowed even if the parcel is already collected, '
                'as long as the flight has not started.',
                style: typo.sm.copyWith(color: AppColors.textSecondary),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              _CancellationPolicySection(
                title: 'More than 24 hours before travel',
                escrowLabel: 'Escrow Amount: Refunded',
                feeLabel: 'Platform Fee: Refunded (all users)',
              ),
              const SizedBox(height: 14),
              _CancellationPolicySection(
                title: 'Less than 24 hours before travel',
                escrowLabel: 'Escrow Amount: Refunded to Sender',
                feeLabel: 'Platform Fee: Non-refundable (all users)',
              ),
              const SizedBox(height: 24),
              AppButton(
                label: 'Cancel Request',
                variant: AppButtonVariant.danger,
                onPressed: () => Navigator.of(dialogContext).pop(true),
              ),
              const SizedBox(height: AppButton.stackGap),
              AppButton(
                label: 'Keep',
                variant: AppButtonVariant.ghost,
                onPressed: () => Navigator.of(dialogContext).pop(false),
              ),
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
      alignment: Alignment.centerLeft,
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
