import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../core/config/demo_mode.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_typography.dart';
import '../../core/widgets/app_card.dart';
import '../../core/widgets/back_link.dart';
import '../../core/widgets/screen_body.dart';
import '../../data/models/traveler_trip.dart';
import '../../data/services/trip_repository.dart';
import '../../data/static_data.dart';
import '../../providers/auth_provider.dart';

/// My Trips tab — lists trips from GET /api/v1/trips.
class TravelerMyTripsScreen extends StatefulWidget {
  const TravelerMyTripsScreen({super.key});

  @override
  State<TravelerMyTripsScreen> createState() => _TravelerMyTripsScreenState();
}

class _TravelerMyTripsScreenState extends State<TravelerMyTripsScreen> {
  List<TravelerTrip> _trips = const [];
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    StaticData.travelerPostedTripsVersion.addListener(_onTripsChanged);
    WidgetsBinding.instance.addPostFrameCallback((_) => _load());
  }

  @override
  void dispose() {
    StaticData.travelerPostedTripsVersion.removeListener(_onTripsChanged);
    super.dispose();
  }

  void _onTripsChanged() {
    if (!mounted) return;
    final demoMode = context.read<DemoModeProvider>().enabled;
    setState(() {
      _trips = StaticData.travelerTripsForDisplay(demoMode: demoMode);
      _loading = false;
      _error = null;
    });
  }

  TripRepository _repository() {
    final auth = context.read<AuthProvider>();
    final demoMode = context.read<DemoModeProvider>();
    return TripRepository(
      apiClient: auth.repository.apiClient,
      demoMode: demoMode,
    );
  }

  Future<void> _load({bool silent = false}) async {
    if (!mounted) return;
    final demoMode = context.read<DemoModeProvider>();

    if (demoMode.enabled) {
      setState(() {
        _trips = StaticData.travelerTripsForDisplay(demoMode: true);
        _loading = false;
        _error = null;
      });
      return;
    }

    if (!silent) {
      setState(() {
        _loading = true;
        _error = null;
      });
    }

    try {
      final trips = await _repository().listMyTrips();
      StaticData.replaceTravelerPostedTrips(trips);
      if (!mounted) return;
      setState(() {
        _trips = List<TravelerTrip>.from(trips);
        _loading = false;
        _error = null;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _trips = StaticData.travelerTripsForDisplay(demoMode: false);
        _loading = false;
        if (_trips.isEmpty) {
          _error = 'Unable to load your trips. Tap Retry.';
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final typo = context.typo;

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
            if (_loading && _trips.isEmpty)
              const Padding(
                padding: EdgeInsets.only(top: 24),
                child: Center(
                  child: SizedBox(
                    width: 22,
                    height: 22,
                    child: CircularProgressIndicator(
                      strokeWidth: 2.5,
                      color: AppColors.primary,
                    ),
                  ),
                ),
              )
            else if (_trips.isEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 24),
                child: Column(
                  children: [
                    Text(
                      _error ?? 'No trips yet. Create a trip from Home.',
                      style: typo.sm.copyWith(color: AppColors.textSecondary),
                    ),
                    if (_error != null) ...[
                      const SizedBox(height: 12),
                      TextButton(
                        onPressed: () => _load(),
                        child: const Text('Retry'),
                      ),
                    ],
                  ],
                ),
              )
            else
              for (var i = 0; i < _trips.length; i++) ...[
                if (i > 0) const SizedBox(height: 10),
                _TripCard(trip: _trips[i]),
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
