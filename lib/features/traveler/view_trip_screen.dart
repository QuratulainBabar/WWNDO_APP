import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../core/api/api_exception.dart';
import '../../core/config/demo_mode.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_typography.dart';
import '../../core/widgets/app_button.dart';
import '../../core/widgets/app_card.dart';
import '../../core/widgets/back_header.dart';
import '../../core/widgets/screen_body.dart';
import '../../data/models/traveler_trip.dart';
import '../../data/services/trip_repository.dart';
import '../../data/static_data.dart';
import '../../providers/auth_provider.dart';

/// Traveler-facing read-only trip details — opened from My Trips menu View.
class ViewTripScreen extends StatefulWidget {
  const ViewTripScreen({super.key, required this.tripId});

  final String tripId;

  @override
  State<ViewTripScreen> createState() => _ViewTripScreenState();
}

class _ViewTripScreenState extends State<ViewTripScreen> {
  TravelerTrip? _trip;
  bool _loading = true;
  String? _loadError;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _load());
  }

  TripRepository _repository() {
    final auth = context.read<AuthProvider>();
    final demoMode = context.read<DemoModeProvider>();
    return TripRepository(
      apiClient: auth.repository.apiClient,
      demoMode: demoMode,
    );
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _loadError = null;
    });

    final demoMode = context.read<DemoModeProvider>().enabled;
    if (demoMode) {
      final trip = StaticData.travelerTripById(widget.tripId) ??
          (StaticData.travelerPostedTrips.isNotEmpty
              ? StaticData.travelerPostedTrips.first
              : null);
      if (!mounted) return;
      if (trip == null) {
        setState(() {
          _loading = false;
          _loadError = 'Trip not found.';
        });
        return;
      }
      setState(() {
        _trip = trip;
        _loading = false;
      });
      return;
    }

    try {
      final trip = await _repository().getMyTrip(widget.tripId);
      if (!mounted) return;
      setState(() {
        _trip = trip;
        _loading = false;
      });
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _loadError = e.message;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _loadError = 'Unable to load this trip. Please try again.';
      });
    }
  }

  Future<void> _openEdit() async {
    final trip = _trip;
    if (trip == null || !trip.status.canEditOrCancel) return;
    final updated = await context.push<bool>('/edit-trip/${trip.displayId}');
    if (updated == true && mounted) {
      await _load();
    }
  }

  @override
  Widget build(BuildContext context) {
    final typo = context.typo;
    final trip = _trip;

    if (_loading) {
      return Scaffold(
        backgroundColor: AppColors.background,
        appBar: const BackHeader(
          title: 'Trip details',
          fallbackRoute: '/traveler-trips',
        ),
        body: const Center(
          child: CircularProgressIndicator(color: AppColors.primary),
        ),
      );
    }

    if (_loadError != null || trip == null) {
      return Scaffold(
        backgroundColor: AppColors.background,
        appBar: const BackHeader(
          title: 'Trip details',
          fallbackRoute: '/traveler-trips',
        ),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  _loadError ?? 'Trip not found.',
                  textAlign: TextAlign.center,
                  style: typo.sm.copyWith(color: AppColors.textSecondary),
                ),
                const SizedBox(height: 16),
                TextButton(onPressed: _load, child: const Text('Retry')),
              ],
            ),
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: BackHeader(
        title: 'Trip ${trip.displayId}',
        fallbackRoute: '/traveler-trips',
      ),
      body: ScreenBody(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(trip.route, style: typo.h1),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: trip.status.backgroundColor,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                trip.status.label,
                style: typo.sm.copyWith(
                  color: trip.status.color,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            const SizedBox(height: 16),
            AppCard(
              margin: EdgeInsets.zero,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _DetailRow(label: 'Trip ID', value: trip.displayId),
                  _DetailRow(
                    label: 'Type',
                    value: trip.isCountryToCountry
                        ? 'Country to country'
                        : 'City to city',
                  ),
                  _DetailRow(
                    label: 'Travel date',
                    value: DateFormat('MMM d, yyyy').format(trip.travelDate),
                  ),
                  _DetailRow(
                    label: 'Luggage capacity',
                    value:
                        '${trip.luggageCapacityKg.toStringAsFixed(0)} kg',
                  ),
                  if (trip.flightNumber != null &&
                      trip.flightNumber!.trim().isNotEmpty)
                    _DetailRow(
                      label: 'Flight',
                      value: trip.flightNumber!,
                    ),
                  if (trip.isCountryToCountry) ...[
                    if (trip.originAirport != null &&
                        trip.originAirport!.trim().isNotEmpty)
                      _DetailRow(
                        label: 'Origin airport',
                        value: trip.originAirport!,
                      ),
                    if (trip.destinationAirport != null &&
                        trip.destinationAirport!.trim().isNotEmpty)
                      _DetailRow(
                        label: 'Destination airport',
                        value: trip.destinationAirport!,
                      ),
                  ],
                ],
              ),
            ),
            if (trip.status.canEditOrCancel) ...[
              const SizedBox(height: 20),
              AppButton(
                label: 'Edit trip',
                onPressed: _openEdit,
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _DetailRow extends StatelessWidget {
  const _DetailRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final typo = context.typo;
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 130,
            child: Text(
              label,
              style: typo.sm.copyWith(color: AppColors.textSecondary),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: typo.bodyBold.copyWith(fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }
}
