import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../core/layout/responsive.dart';
import '../../core/platform/platform_ui.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_typography.dart';
import '../../core/widgets/app_button.dart';
import '../../core/widgets/back_header.dart';
import '../../data/static_data.dart';
import 'bid_acceptance_payment_screen.dart';

class BidPaymentSuccessScreen extends StatelessWidget {
  const BidPaymentSuccessScreen({super.key, required this.acceptance});

  final BidAcceptanceContext acceptance;

  @override
  Widget build(BuildContext context) {
    final typo = context.typo;
    final total = StaticData.totalPayment(
      acceptance.bid.price,
      category: StaticData.shipmentById(acceptance.shipmentId)
              ?.parcelCategory ??
          'Documents',
      shipmentId: acceptance.shipmentId,
    );

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
              Text('Payment Successful', style: typo.h1, textAlign: TextAlign.center),
              const SizedBox(height: 8),
              Text('Bid Accepted', style: typo.h3, textAlign: TextAlign.center),
              const SizedBox(height: 8),
              Text(
                '\$${total.toStringAsFixed(2)} deposited securely in escrow.',
                textAlign: TextAlign.center,
                style: typo.sm.copyWith(height: 1.5),
              ),
              const SizedBox(height: 8),
              Text(
                'Platform fees collected · Selected bid locked · Parties notified',
                textAlign: TextAlign.center,
                style: typo.sm.copyWith(color: AppColors.textSecondary),
              ),
              const SizedBox(height: 32),
              AppButton(
                label: 'Continue',
                onPressed: () => context.push(
                  '/bid-accepted',
                  extra: acceptance.bid,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
