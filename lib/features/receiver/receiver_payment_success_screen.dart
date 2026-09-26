import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../l10n/app_localizations.dart';

import '../../core/layout/responsive.dart';
import '../../core/platform/platform_ui.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_typography.dart';
import '../../core/widgets/app_button.dart';
import '../../core/widgets/back_header.dart';
import '../../data/wallet_service.dart';

class ReceiverPaymentResult {
  const ReceiverPaymentResult({
    required this.shipmentId,
    required this.feeAmount,
  });

  final String shipmentId;
  final double feeAmount;
}

class ReceiverPaymentSuccessScreen extends StatelessWidget {
  const ReceiverPaymentSuccessScreen({super.key, required this.result});

  final ReceiverPaymentResult result;

  @override
  Widget build(BuildContext context) {
    final typo = context.typo;
    final feeAmount = result.feeAmount;
    final shipmentId = result.shipmentId;

    return Scaffold(
      backgroundColor: AppColors.surface,
      appBar: const BackHeader(title: 'Payment'),
      body: SafeArea(
        child: SingleChildScrollView(
          physics: PlatformUi.scrollPhysics,
          padding: context.pagePadding,
          child: Column(
            children: [
              const SizedBox(height: 48),
              Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  color: AppColors.success.withValues(alpha: 0.12),
                  shape: BoxShape.circle,
                ),
                alignment: Alignment.center,
                child: const Icon(Icons.check, size: 40, color: AppColors.success),
              ),
              const SizedBox(height: 20),
              Text(
                'Payment Successful',
                style: typo.h1,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Text(
                'Platform fee paid',
                style: typo.h3,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Text(
                feeAmount == 0
                    ? 'Your platform fee share has been waived for $shipmentId.'
                    : '${WalletService.formatMajor(feeAmount)} platform fee share paid for $shipmentId.',
                textAlign: TextAlign.center,
                style: typo.sm.copyWith(height: 1.5),
              ),
              const SizedBox(height: 8),
              Text(
                'You can now view parcel details and follow your shipment.',
                textAlign: TextAlign.center,
                style: typo.sm.copyWith(color: AppColors.textSecondary),
              ),
              const SizedBox(height: 32),
              AppButton(
                label: context.tr('Continue'),
                onPressed: () => context.go('/receiver-tracking'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
