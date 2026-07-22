import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../core/layout/responsive.dart';
import '../../core/platform/platform_ui.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_typography.dart';
import '../../core/widgets/app_button.dart';
import '../../core/widgets/app_card.dart';
import '../../core/widgets/back_header.dart';
import '../../data/models/traveler_trip.dart';
import '../../data/static_data.dart';

class MatchingRequestsTripsScreen extends StatelessWidget {
  const MatchingRequestsTripsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final typo = context.typo;
    final horizontal = context.horizontalPadding;
    final trips = StaticData.travelerPostedTrips;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: const BackHeader(title: 'Sender Requests'),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: EdgeInsets.fromLTRB(horizontal, 4, horizontal, 12),
            child: Text(
              'Select a trip to view sender requests.',
              style: typo.sm.copyWith(height: 1.45),
            ),
          ),
          Expanded(
            child: ListView.builder(
              physics: PlatformUi.scrollPhysics,
              padding: EdgeInsets.fromLTRB(horizontal, 0, horizontal, 24),
              itemCount: trips.length,
              itemBuilder: (context, i) => _TripCard(
                trip: trips[i],
                matchingCount: StaticData.matchingRequestCountForTrip(trips[i].id),
                onViewDetails: () => context.push('/matching-requests/${trips[i].id}'),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _TripCard extends StatelessWidget {
  const _TripCard({
    required this.trip,
    required this.matchingCount,
    required this.onViewDetails,
  });

  final TravelerTrip trip;
  final int matchingCount;
  final VoidCallback onViewDetails;

  @override
  Widget build(BuildContext context) {
    final typo = context.typo;

    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            trip.route,
            style: typo.h3.copyWith(fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 12),
          _detailRow(
            context,
            label: 'Sender requests',
            valueWidget: _countBadge(context, matchingCount),
          ),
          const SizedBox(height: 6),
          _detailRow(
            context,
            label: 'Travel date',
            value: DateFormat('MMM d, yyyy').format(trip.travelDate),
          ),
          const SizedBox(height: 14),
          AppButton(label: 'View Details', small: true, onPressed: onViewDetails),
        ],
      ),
    );
  }

  Widget _countBadge(BuildContext context, int count) {
    final typo = context.typo;
    return Container(
      constraints: const BoxConstraints(minWidth: 28, minHeight: 28),
      padding: const EdgeInsets.symmetric(horizontal: 6),
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: AppColors.primary.withValues(alpha: 0.12),
        shape: BoxShape.circle,
      ),
      child: Text(
        '$count',
        style: typo.sm.copyWith(
          color: AppColors.primary,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }

  Widget _detailRow(
    BuildContext context, {
    required String label,
    String? value,
    Widget? valueWidget,
    TextStyle? valueStyle,
  }) {
    final typo = context.typo;
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: typo.sm),
        valueWidget ??
            Text(
              value!,
              style: valueStyle ?? typo.sm.copyWith(
                color: AppColors.textPrimary,
                fontWeight: FontWeight.w600,
              ),
            ),
      ],
    );
  }
}
