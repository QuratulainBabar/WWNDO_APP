import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../core/layout/responsive.dart';
import '../../core/platform/platform_ui.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_typography.dart';
import '../../core/widgets/app_button.dart';
import '../../core/widgets/back_header.dart';
import '../../data/models/shipment.dart';
import '../../data/static_data.dart';

/// Intermediate screen while a posted delivery is not yet trackable.
class SenderParcelWaitingScreen extends StatelessWidget {
  const SenderParcelWaitingScreen({super.key, required this.shipmentId});

  final String shipmentId;

  @override
  Widget build(BuildContext context) {
    final typo = context.typo;
    final shipment = StaticData.shipmentById(shipmentId);
    final phase = shipment == null
        ? SenderPostedPhase.waitingForReceiver
        : StaticData.senderPostedPhase(shipment) ??
            SenderPostedPhase.waitingForReceiver;
    final isAwaitingTraveler = phase == SenderPostedPhase.travelerReviewing;
    final selectedTravelers =
        StaticData.selectedMatchingTravelersFor(shipmentId);
    final selected = StaticData.selectedMatchingTravelerFor(shipmentId);

    final title = isAwaitingTraveler
        ? 'Awaiting traveler acceptance'
        : 'Waiting for receiver acceptance';
    final body = isAwaitingTraveler
        ? (selectedTravelers.isEmpty
            ? 'We have sent a request to the traveler. Tracking unlocks after they accept.'
            : selectedTravelers.length == 1
                ? 'We have sent a request to ${selected!.travelerName}. Tracking unlocks after they accept.'
                : 'We have sent requests to ${selectedTravelers.length} travelers. Tracking unlocks after one accepts.')
        : "We've notified your receiver.\nThe matching process will start once they accept.";

    return Scaffold(
      backgroundColor: AppColors.surface,
      appBar: BackHeader(
        title: shipment?.id ?? 'Delivery',
        fallbackRoute: '/my-posted-parcels',
      ),
      body: SafeArea(
        child: Padding(
          padding: context.pagePadding,
          child: Column(
            children: [
              Expanded(
                child: SingleChildScrollView(
                  physics: PlatformUi.scrollPhysics,
                  child: Column(
                    children: [
                      const SizedBox(height: 24),
                      Container(
                        width: 72,
                        height: 72,
                        decoration: BoxDecoration(
                          color: AppColors.warning.withValues(alpha: 0.14),
                          shape: BoxShape.circle,
                        ),
                        alignment: Alignment.center,
                        child: const Icon(
                          Icons.hourglass_top_rounded,
                          size: 36,
                          color: AppColors.warning,
                        ),
                      ),
                      const SizedBox(height: 20),
                      Text(
                        title,
                        style: typo.h1.copyWith(fontWeight: FontWeight.w700),
                        textAlign: TextAlign.center,
                      ),
                      if (shipment != null) ...[
                        const SizedBox(height: 10),
                        Text(
                          '${shipment.route}\n'
                          'Travel date: ${DateFormat('MMM d, yyyy').format(shipment.travelDate)}',
                          textAlign: TextAlign.center,
                          style: typo.sm.copyWith(
                            height: 1.5,
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ],
                      const SizedBox(height: 24),
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 18,
                          vertical: 20,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.kycBackground,
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Text(
                          body,
                          style: typo.sm.copyWith(
                            height: 1.5,
                            color: AppColors.textSecondary,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              if (phase == SenderPostedPhase.matchingTravelers)
                AppButton(
                  label: 'View Matching Travelers',
                  onPressed: () => context.push('/bid-requests/$shipmentId'),
                )
              else
                AppButton(
                  label: 'Go to My Deliveries',
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
}
