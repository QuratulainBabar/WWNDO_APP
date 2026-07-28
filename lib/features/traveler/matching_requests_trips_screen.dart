import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../core/config/demo_mode.dart';
import '../../core/layout/responsive.dart';
import '../../core/platform/platform_ui.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_typography.dart';
import '../../core/widgets/app_button.dart';
import '../../core/widgets/app_card.dart';
import '../../core/widgets/back_header.dart';
import '../../data/models/traveler_trip.dart';
import '../../data/services/trip_repository.dart';
import '../../providers/auth_provider.dart';

/// Sender requests for traveler trips — loaded from API.
class MatchingRequestsTripsScreen extends StatefulWidget {
  const MatchingRequestsTripsScreen({super.key});

  @override
  State<MatchingRequestsTripsScreen> createState() =>
      _MatchingRequestsTripsScreenState();
}

class _MatchingRequestsTripsScreenState
    extends State<MatchingRequestsTripsScreen> {
  bool _loading = true;
  String? _error;
  List<({TravelerTrip trip, int requestCount})> _trips = const [];

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
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final trips = await _repo().listSenderRequestTrips();
      if (!mounted) return;
      setState(() {
        _trips = trips;
        _loading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _error = 'Unable to load sender requests.';
      });
    }
  }

  Future<void> _openTrip(TravelerTrip trip) async {
    await context.push('/matching-requests/${trip.displayId}');
    if (mounted) _load();
  }

  @override
  Widget build(BuildContext context) {
    final typo = context.typo;
    final horizontal = context.horizontalPadding;

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
            child: _loading
                ? const Center(
                    child: SizedBox(
                      width: 22,
                      height: 22,
                      child: CircularProgressIndicator(
                        strokeWidth: 2.5,
                        color: AppColors.primary,
                      ),
                    ),
                  )
                : _error != null
                    ? Center(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              _error!,
                              style: typo.sm.copyWith(color: AppColors.textSecondary),
                            ),
                            TextButton(onPressed: _load, child: const Text('Retry')),
                          ],
                        ),
                      )
                    : _trips.isEmpty
                        ? Center(
                            child: Padding(
                              padding: EdgeInsets.symmetric(horizontal: horizontal),
                              child: Text(
                                'No trips with sender requests yet.',
                                style: typo.sm.copyWith(color: AppColors.textSecondary),
                                textAlign: TextAlign.center,
                              ),
                            ),
                          )
                        : RefreshIndicator(
                            onRefresh: _load,
                            child: ListView.builder(
                              physics: AlwaysScrollableScrollPhysics(
                                parent: PlatformUi.scrollPhysics,
                              ),
                              padding: EdgeInsets.fromLTRB(horizontal, 0, horizontal, 24),
                              itemCount: _trips.length,
                              itemBuilder: (context, i) {
                                final entry = _trips[i];
                                return Padding(
                                  padding: const EdgeInsets.only(bottom: 12),
                                  child: _TripCard(
                                    trip: entry.trip,
                                    requestCount: entry.requestCount,
                                    onViewDetails: () => _openTrip(entry.trip),
                                  ),
                                );
                              },
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
    required this.requestCount,
    required this.onViewDetails,
  });

  final TravelerTrip trip;
  final int requestCount;
  final VoidCallback onViewDetails;

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
            style: typo.h3.copyWith(fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 12),
          _detailRow(
            context,
            label: 'Sender requests',
            valueWidget: _countBadge(context, requestCount),
          ),
          const SizedBox(height: 6),
          _detailRow(
            context,
            label: 'Travel date',
            value: DateFormat('MMM d, yyyy').format(trip.travelDate),
          ),
          const SizedBox(height: 14),
          AppButton(
            label: 'View Details',
            onPressed: onViewDetails,
          ),
        ],
      ),
    );
  }

  Widget _detailRow(
    BuildContext context, {
    required String label,
    String? value,
    Widget? valueWidget,
  }) {
    final typo = context.typo;
    return Row(
      children: [
        Expanded(
          child: Text(
            label,
            style: typo.sm.copyWith(color: AppColors.textSecondary),
          ),
        ),
        if (valueWidget != null)
          valueWidget
        else
          Text(
            value ?? '',
            style: typo.sm.copyWith(
              color: AppColors.textPrimary,
              fontWeight: FontWeight.w600,
            ),
          ),
      ],
    );
  }

  Widget _countBadge(BuildContext context, int count) {
    final typo = context.typo;
    return Container(
      width: 28,
      height: 28,
      alignment: Alignment.center,
      decoration: const BoxDecoration(
        color: AppColors.primary,
        shape: BoxShape.circle,
      ),
      child: Text(
        '$count',
        style: typo.sm.copyWith(
          color: Colors.white,
          fontWeight: FontWeight.w700,
          fontSize: 12,
        ),
      ),
    );
  }
}
