import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../core/config/demo_mode.dart';
import '../../core/layout/responsive.dart';
import '../../core/platform/platform_ui.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_typography.dart';
import '../../core/widgets/app_badge.dart';
import '../../core/widgets/app_card.dart';
import '../../core/widgets/back_header.dart';
import '../../data/models/traveler_trip.dart';
import '../../data/services/delivery_repository.dart';
import '../../data/services/trip_repository.dart';
import '../../data/static_data.dart';
import '../../providers/auth_provider.dart';

/// Sender-facing list of published traveler trips, ranked by route similarity.
class DiscoverTravelersScreen extends StatefulWidget {
  const DiscoverTravelersScreen({super.key, this.shipmentId});

  final String? shipmentId;

  @override
  State<DiscoverTravelersScreen> createState() => _DiscoverTravelersScreenState();
}

class _DiscoverTravelersScreenState extends State<DiscoverTravelersScreen> {
  List<({TravelerTrip trip, int matchScore})>? _apiRanked;
  bool _loading = false;

  @override
  void initState() {
    super.initState();
    StaticData.travelerPostedTripsVersion.addListener(_onChanged);
    WidgetsBinding.instance.addPostFrameCallback((_) => _loadTrips());
  }

  @override
  void dispose() {
    StaticData.travelerPostedTripsVersion.removeListener(_onChanged);
    super.dispose();
  }

  void _onChanged() {
    if (mounted) setState(() {});
  }

  Future<void> _loadTrips() async {
    final shipmentId = widget.shipmentId;
    final demoMode = context.read<DemoModeProvider>();
    if (demoMode.enabled) return;

    setState(() => _loading = true);
    try {
      final auth = context.read<AuthProvider>();
      if (shipmentId != null) {
        final travelers = await DeliveryRepository(
          apiClient: auth.repository.apiClient,
          demoMode: demoMode,
        ).listMatchingTravelers(shipmentId);

        if (!mounted) return;
        // Backend already filters by matching route + luggage capacity.
        setState(() {
          _apiRanked = travelers
              .map(
                (t) => (
                  trip: TravelerTrip(
                    id: t.tripId,
                    publicId: t.tripId,
                    origin: t.origin,
                    destination: t.destination,
                    travelDate: t.travelDate,
                    luggageCapacityKg: t.luggageCapacityKg ?? 0,
                    travelerName: t.travelerName,
                    travelerRating: t.rating,
                  ),
                  matchScore: t.matchScore,
                ),
              )
              .toList();
          _loading = false;
        });
        return;
      }

      final trips = await TripRepository(
        apiClient: auth.repository.apiClient,
        demoMode: demoMode,
      ).listDiscoverableTrips();

      if (!mounted) return;
      setState(() {
        _apiRanked = trips
            .map((trip) => (trip: trip, matchScore: 100))
            .toList();
        _loading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _apiRanked = const [];
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final typo = context.typo;
    final shipment = widget.shipmentId == null
        ? null
        : StaticData.shipmentById(widget.shipmentId!);

    final demoMode = context.watch<DemoModeProvider>();
    final ranked = shipment == null
        ? (!demoMode.enabled && _apiRanked != null)
            ? _apiRanked!
            : StaticData.allDiscoverableTrips
        : (!demoMode.enabled && _apiRanked != null)
            ? _apiRanked!
            : StaticData.discoverableTripsForShipment(shipment);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: BackHeader(
        title: shipment == null
            ? 'Discover travelers'
            : 'Matched travelers',
      ),
      body: _loading && _apiRanked == null && !demoMode.enabled
          ? const Center(
              child: SizedBox(
                width: 28,
                height: 28,
                child: CircularProgressIndicator(strokeWidth: 2.5),
              ),
            )
          : ListView(
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
                onTap: () => context.push(
                  '/discover-trips/${entry.trip.displayId}',
                ),
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
    this.onTap,
  });

  final TravelerTrip trip;
  final int matchScore;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final typo = context.typo;
    final matchColor = matchScore >= 90
        ? AppColors.success
        : matchScore >= 80
            ? AppColors.primary
            : AppColors.warning;

    return GestureDetector(
      onTap: onTap,
      child: AppCard(
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
      ),
    );
  }
}
