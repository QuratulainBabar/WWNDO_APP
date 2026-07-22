import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../core/layout/responsive.dart';
import '../../core/platform/platform_ui.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_typography.dart';
import '../../core/widgets/app_badge.dart';
import '../../core/widgets/app_card.dart';
import '../../core/widgets/back_header.dart';
import '../../data/models/traveler_trip.dart';
import '../../data/static_data.dart';

/// Sender-facing list of published traveler trips, ranked by route similarity.
class DiscoverTravelersScreen extends StatefulWidget {
  const DiscoverTravelersScreen({super.key, this.shipmentId});

  final String? shipmentId;

  @override
  State<DiscoverTravelersScreen> createState() => _DiscoverTravelersScreenState();
}

class _DiscoverTravelersScreenState extends State<DiscoverTravelersScreen> {
  @override
  void initState() {
    super.initState();
    StaticData.travelerPostedTripsVersion.addListener(_onChanged);
  }

  @override
  void dispose() {
    StaticData.travelerPostedTripsVersion.removeListener(_onChanged);
    super.dispose();
  }

  void _onChanged() {
    if (mounted) setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final typo = context.typo;
    final shipment = widget.shipmentId == null
        ? null
        : StaticData.shipmentById(widget.shipmentId!);

    final ranked = shipment == null
        ? StaticData.allDiscoverableTrips
        : StaticData.discoverableTripsForShipment(shipment);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: BackHeader(
        title: shipment == null
            ? 'Discover travelers'
            : 'Matched travelers',
      ),
      body: ListView(
        physics: PlatformUi.scrollPhysics,
        padding: context.pagePadding,
        children: [
          Text(
            shipment == null
                ? 'Posted traveler trips are discoverable here and ranked by route similarity when matched to a parcel.'
                : 'Travelers matched to ${shipment.route} by route similarity.',
            style: typo.sm.copyWith(color: AppColors.textSecondary),
          ),
          const SizedBox(height: 16),
          if (ranked.isEmpty)
            AppCard(
              child: Text(
                'No matching traveler trips yet. Ask travelers to post this route.',
                style: typo.sm,
              ),
            )
          else
            ...ranked.map(
              (entry) => _DiscoverTripCard(
                trip: entry.trip,
                matchScore: entry.matchScore,
              ),
            ),
        ],
      ),
    );
  }
}

class _DiscoverTripCard extends StatelessWidget {
  const _DiscoverTripCard({
    required this.trip,
    required this.matchScore,
  });

  final TravelerTrip trip;
  final int matchScore;

  @override
  Widget build(BuildContext context) {
    final typo = context.typo;
    final matchColor = matchScore >= 90
        ? AppColors.success
        : matchScore >= 80
            ? AppColors.primary
            : AppColors.warning;

    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  trip.route,
                  style: typo.h3.copyWith(fontWeight: FontWeight.w700),
                ),
              ),
              AppBadge(
                label: '$matchScore% Match',
                color: matchColor,
                backgroundColor: matchColor.withValues(alpha: 0.12),
                semiBold: true,
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            'Travel date: ${DateFormat('MMM d, yyyy').format(trip.travelDate)}',
            style: typo.sm,
          ),
          const SizedBox(height: 4),
          Text(
            'Luggage capacity: ${trip.luggageCapacityKg.toStringAsFixed(0)} kg',
            style: typo.sm.copyWith(color: AppColors.textSecondary),
          ),
        ],
      ),
    );
  }
}
