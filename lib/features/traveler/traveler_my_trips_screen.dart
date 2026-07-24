import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_typography.dart';
import '../../core/widgets/app_card.dart';
import '../../core/widgets/back_link.dart';
import '../../core/widgets/screen_body.dart';
import '../../data/models/traveler_trip.dart';
import '../../providers/auth_provider.dart';

/// My Trips — empty until trips API is available.
class TravelerMyTripsScreen extends StatelessWidget {
  const TravelerMyTripsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final typo = context.typo;
    // Keep auth session warm; trips list has no backend endpoint yet.
    context.watch<AuthProvider>();
    const trips = <TravelerTrip>[];

    return Scaffold(
      backgroundColor: AppColors.background,
      body: ScreenBody(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            BackLink(onTap: () => context.go('/traveler-home')),
            const SizedBox(height: 16),
            Text('My Trips', style: typo.h1),
            const SizedBox(height: 12),
            if (trips.isEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 24),
                child: Text(
                  'No trips yet. Create a trip from Home.',
                  style: typo.sm.copyWith(color: AppColors.textSecondary),
                ),
              )
            else
              for (var i = 0; i < trips.length; i++) ...[
                if (i > 0) const SizedBox(height: 10),
                _TripCard(trip: trips[i]),
              ],
          ],
        ),
      ),
    );
  }
}

class _TripCard extends StatelessWidget {
  const _TripCard({required this.trip});

  final TravelerTrip trip;

  @override
  Widget build(BuildContext context) {
    final typo = context.typo;

    return AppCard(
      margin: EdgeInsets.zero,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            trip.route,
            style: typo.h3.copyWith(fontWeight: FontWeight.w800),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
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
    );
  }
}
