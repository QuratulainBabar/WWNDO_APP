import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../core/layout/responsive.dart';
import '../../core/platform/platform_ui.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_typography.dart';
import '../../core/widgets/app_button.dart';
import '../../core/widgets/back_header.dart';
import 'bid_acceptance_payment_screen.dart';

/// Shown after the sender selects a matching traveler (before Pay Now).
class TravelerSelectedConfirmationScreen extends StatelessWidget {
  const TravelerSelectedConfirmationScreen({
    super.key,
    required this.acceptance,
  });

  final BidAcceptanceContext acceptance;

  @override
  Widget build(BuildContext context) {
    final typo = context.typo;
    final name = acceptance.bid.travelerName;

    return Scaffold(
      backgroundColor: AppColors.surface,
      appBar: const BackHeader(title: 'Confirmation'),
      body: SafeArea(
        child: SingleChildScrollView(
          physics: PlatformUi.scrollPhysics,
          padding: context.pagePadding,
          child: Column(
            children: [
              const SizedBox(height: 24),
              Stack(
                alignment: Alignment.center,
                children: [
                  ..._confettiDots(),
                  Container(
                    width: 88,
                    height: 88,
                    decoration: BoxDecoration(
                      color: AppColors.success.withValues(alpha: 0.14),
                      shape: BoxShape.circle,
                    ),
                    alignment: Alignment.center,
                    child: Container(
                      width: 64,
                      height: 64,
                      decoration: const BoxDecoration(
                        color: AppColors.success,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.check, size: 36, color: Colors.white),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              Text(
                'Traveler Selected!',
                style: typo.h1,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Text(
                '$name has been selected and notified of your parcel request.\nYou can pay securely to confirm the booking.',
                textAlign: TextAlign.center,
                style: typo.sm.copyWith(height: 1.5, color: AppColors.textSecondary),
              ),
              const SizedBox(height: 28),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.kycBackground,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: AppColors.border),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'What happens next?',
                      style: typo.bodyBold.copyWith(fontWeight: FontWeight.w700),
                    ),
                    const SizedBox(height: 14),
                    _step(context, 1, 'Pay to lock escrow and confirm the traveler'),
                    _step(context, 2, 'Meet traveler and enable NFC for handoff'),
                    _step(context, 3, 'After NFC match, parcel becomes Collected'),
                    _step(context, 4, 'Traveler marks In Transit, then enables NFC for receiver'),
                  ],
                ),
              ),
              const SizedBox(height: 32),
              AppButton(
                label: 'Continue to Payment',
                onPressed: () => context.push(
                  '/bid-acceptance-payment',
                  extra: acceptance,
                ),
              ),
              const SizedBox(height: AppButton.stackGap),
              AppButton(
                label: 'Go to My Deliveries',
                variant: AppButtonVariant.outline,
                onPressed: () => context.go('/my-posted-parcels'),
              ),
              const SizedBox(height: AppButton.stackGap),
              AppButton(
                label: 'Back to Home',
                variant: AppButtonVariant.outline,
                onPressed: () => context.go('/home'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _step(BuildContext context, int number, String text) {
    final typo = context.typo;
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 28,
            height: 28,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.12),
              shape: BoxShape.circle,
            ),
            child: Text(
              '$number',
              style: typo.sm.copyWith(
                fontWeight: FontWeight.w700,
                color: AppColors.primaryDark,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.only(top: 4),
              child: Text(text, style: typo.sm),
            ),
          ),
        ],
      ),
    );
  }

  List<Widget> _confettiDots() {
    const colors = [
      AppColors.primary,
      AppColors.warning,
      AppColors.success,
      Color(0xFF38BDF8),
    ];
    const offsets = [
      Offset(-42, -28),
      Offset(46, -22),
      Offset(-36, 34),
      Offset(40, 30),
      Offset(-52, 6),
      Offset(54, 8),
    ];
    return [
      for (var i = 0; i < offsets.length; i++)
        Transform.translate(
          offset: offsets[i],
          child: Container(
            width: i.isEven ? 8 : 6,
            height: i.isEven ? 4 : 8,
            decoration: BoxDecoration(
              color: colors[i % colors.length],
              borderRadius: BorderRadius.circular(2),
            ),
          ),
        ),
    ];
  }
}
