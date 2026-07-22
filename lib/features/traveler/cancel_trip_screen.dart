import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_typography.dart';
import '../../core/widgets/app_button.dart';
import '../../core/widgets/app_card.dart';
import '../../core/widgets/app_toast.dart';
import '../../core/widgets/back_header.dart';
import '../../core/widgets/scrollable_form_screen.dart';
import '../../data/models/traveler_trip.dart';
import '../../data/static_data.dart';

class CancelTripScreen extends StatelessWidget {
  const CancelTripScreen({super.key, required this.tripId});

  final String tripId;

  TravelerTrip get _trip =>
      StaticData.travelerTripById(tripId) ?? StaticData.travelerPostedTrips.first;

  void _confirmCancel(BuildContext context) {
    final trip = _trip;
    if (!StaticData.canTravelerCancelTrip(trip)) {
      AppToast.error(context, StaticData.travelerCancelBlockedMessage);
      return;
    }

    final cancelled = StaticData.tryCancelTravelerTrip(tripId);
    if (!cancelled) {
      AppToast.error(context, StaticData.travelerCancelBlockedMessage);
      return;
    }

    AppToast.success(context, '${trip.id} cancelled');
    context.go('/traveler-trips');
  }

  @override
  Widget build(BuildContext context) {
    final typo = context.typo;
    final trip = _trip;
    final canCancel = StaticData.canTravelerCancelTrip(trip);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: BackHeader(
        title: 'Cancel ${trip.id}',
        fallbackRoute: '/traveler-trips',
      ),
      body: ScrollableFormScreen(
        actions: [
          AppButton(
            label: 'Cancel trip',
            variant: AppButtonVariant.danger,
            onPressed: () => _confirmCancel(context),
          ),
          AppButton(
            label: 'Keep trip',
            variant: AppButtonVariant.ghost,
            onPressed: () => context.pop(),
          ),
        ],
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Are you sure you want to cancel this trip?',
              style: typo.h3.copyWith(fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 8),
            Text(
              'This will remove your trip from open bids. Any pending matches will no longer be visible to senders.',
              style: typo.sm.copyWith(color: AppColors.textSecondary),
            ),
            const SizedBox(height: 12),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: canCancel
                    ? AppColors.success.withValues(alpha: 0.1)
                    : AppColors.danger.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                canCancel
                    ? StaticData.matchingRequestCountForTrip(trip.id) == 0 &&
                            trip.status == TripStatus.openBid
                        ? 'You can cancel this trip because it has no sender requests yet.'
                        : 'You can cancel this trip because it is still more than '
                            '${StaticData.travelerCancelMinHoursBeforeTravel} hours before the flight.'
                    : StaticData.travelerCancelBlockedMessage,
                style: typo.sm.copyWith(
                  height: 1.45,
                  color: canCancel ? AppColors.success : AppColors.danger,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: AppCard(
                margin: EdgeInsets.zero,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      trip.route,
                      style: typo.h3.copyWith(fontWeight: FontWeight.w800),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      DateFormat('MMM d, yyyy').format(trip.travelDate),
                      style: typo.sm.copyWith(color: AppColors.textSecondary),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${trip.luggageCapacityKg.toStringAsFixed(0)} kg luggage available',
                      style: typo.sm.copyWith(
                        color: AppColors.primary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
