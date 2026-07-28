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
import '../../providers/auth_provider.dart';

/// Sender-facing full trip detail — opened from notifications or discover list.
class DiscoverTripDetailScreen extends StatefulWidget {
  const DiscoverTripDetailScreen({super.key, required this.tripId});

  final String tripId;

  @override
  State<DiscoverTripDetailScreen> createState() => _DiscoverTripDetailScreenState();
}

class _DiscoverTripDetailScreenState extends State<DiscoverTripDetailScreen> {
  bool _loading = true;
  String? _error;
  TravelerTrip? _trip;

  String get _tripId => widget.tripId.trim();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _load());
  }

  TripRepository _repo() {
    final auth = context.read<AuthProvider>();
    final demoMode = context.read<DemoModeProvider>();
    return TripRepository(
      apiClient: auth.repository.apiClient,
      demoMode: demoMode,
    );
  }

  Future<void> _load() async {
    final tripId = _tripId;
    if (tripId.isEmpty) {
      setState(() {
        _loading = false;
        _error = 'Trip not found.';
      });
      return;
    }

    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final trip = await _repo().getDiscoverableTrip(tripId);
      if (!mounted) return;
      setState(() {
        _trip = trip;
        _loading = false;
      });
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _error = e.message;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _error = 'Unable to load trip details.';
      });
    }
  }

  void _createDelivery() {
    final trip = _trip;
    if (trip == null || trip.status == TripStatus.cancelled) return;
    final path = trip.isCountryToCountry
        ? '/post-delivery/country-to-country'
        : '/post-delivery';
    context.push(path, extra: trip);
  }

  @override
  Widget build(BuildContext context) {
    final typo = context.typo;
    final trip = _trip;
    final canSendParcel =
        trip != null && trip.status != TripStatus.cancelled;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: const BackHeader(
        title: 'Trip details',
        fallbackRoute: '/discover-travelers',
      ),
      body: ScreenBody(
        child: _loading
            ? const Center(
                child: SizedBox(
                  width: 28,
                  height: 28,
                  child: CircularProgressIndicator(strokeWidth: 2.5),
                ),
              )
            : _error != null
                ? Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _error!,
                        style: typo.sm.copyWith(color: AppColors.textSecondary),
                      ),
                      TextButton(onPressed: _load, child: const Text('Retry')),
                    ],
                  )
                : trip == null
                    ? Text(
                        'Trip not found.',
                        style: typo.sm.copyWith(color: AppColors.textSecondary),
                      )
                    : Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(trip.route, style: typo.h1),
                          const SizedBox(height: 8),
                          Text(
                            'Posted by ${trip.travelerName ?? 'Traveler'}',
                            style: typo.sm.copyWith(color: AppColors.textSecondary),
                          ),
                          if (trip.travelerRating != null) ...[
                            const SizedBox(height: 4),
                            Text(
                              '${trip.travelerRating!.toStringAsFixed(1)} rating'
                              '${trip.travelerReviewCount != null ? ' · ${trip.travelerReviewCount} reviews' : ''}',
                              style: typo.sm,
                            ),
                          ],
                          if (trip.status == TripStatus.cancelled) ...[
                            const SizedBox(height: 12),
                            Text(
                              'This trip is no longer available.',
                              style: typo.sm.copyWith(color: AppColors.danger),
                            ),
                          ],
                          const SizedBox(height: 16),
                          AppCard(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                _DetailRow(
                                  label: 'Trip ID',
                                  value: trip.displayId,
                                ),
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
                                  value: '${trip.luggageCapacityKg.toStringAsFixed(0)} kg',
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
                          const SizedBox(height: 16),
                          Text(
                            canSendParcel
                                ? 'If this route works for your parcel, create a delivery and match with this traveler.'
                                : 'You can still view this trip, but it can no longer accept parcels.',
                            style: typo.sm.copyWith(color: AppColors.textSecondary),
                          ),
                          if (canSendParcel) ...[
                            const SizedBox(height: 20),
                            AppButton(
                              label: 'Send parcel on this route',
                              onPressed: _createDelivery,
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
