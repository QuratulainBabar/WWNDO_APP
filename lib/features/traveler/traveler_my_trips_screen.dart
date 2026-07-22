import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_typography.dart';
import '../../core/widgets/app_badge.dart';
import '../../core/widgets/app_card.dart';
import '../../core/widgets/back_link.dart';
import '../../core/widgets/screen_body.dart';
import '../../data/models/shipment.dart';
import '../../data/models/traveler_trip.dart';
import '../../data/static_data.dart';

class TravelerMyTripsScreen extends StatelessWidget {
  const TravelerMyTripsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final typo = context.typo;
    StaticData.purgeFranceSenegalOpenTripOnce();

    return Scaffold(
      backgroundColor: AppColors.background,
      body: ScreenBody(
        child: ValueListenableBuilder<int>(
          valueListenable: StaticData.travelerPostedTripsVersion,
          builder: (context, _, _) {
            final trips = StaticData.travelerPostedTrips;

            return Column(
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
            );
          },
        ),
      ),
    );
  }
}

class _TripCard extends StatelessWidget {
  const _TripCard({required this.trip});

  final TravelerTrip trip;

  bool get _isOpenBid => trip.status == TripStatus.openBid;

  String _statusLabel() {
    if (!_isOpenBid) return trip.status.label;
    final count = StaticData.matchingRequestCountForTrip(trip.id);
    return 'Sender Requests ($count)';
  }

  void _onStatusTap(BuildContext context) {
    if (_isOpenBid) {
      context.push('/matching-requests/${trip.id}');
      return;
    }

    Shipment? shipment;
    for (final s in StaticData.travelerShipments) {
      if (s.fromCity == trip.origin && s.toCity == trip.destination) {
        shipment = s;
        break;
      }
    }
    if (shipment == null) {
      final wantDelivered = trip.status == TripStatus.delivered;
      for (final s in StaticData.travelerShipments) {
        final status = StaticData.effectiveStatus(s);
        if (wantDelivered && status == ShipmentStatus.delivered) {
          shipment = s;
          break;
        }
        if (!wantDelivered &&
            (status == ShipmentStatus.inTransit ||
                status == ShipmentStatus.collected ||
                status == ShipmentStatus.bidAccepted)) {
          shipment = s;
          break;
        }
      }
    }

    if (shipment != null) {
      context.push('/shipment/${shipment.id}?traveler=true');
    } else {
      context.push('/traveler-deliveries');
    }
  }

  List<PopupMenuEntry<String>> _menuItems(BuildContext context) {
    final typo = context.typo;
    final itemStyle = typo.body.copyWith(fontWeight: FontWeight.w400);

    return [
      PopupMenuItem(
        value: 'edit',
        height: 42,
        child: Text('Edit', style: itemStyle),
      ),
      const PopupMenuItem<String>(
        enabled: false,
        height: 1,
        padding: EdgeInsets.zero,
        child: Divider(
          height: 1,
          thickness: 1,
          color: AppColors.border,
        ),
      ),
      PopupMenuItem(
        value: 'cancel',
        height: 42,
        child: Text('Cancel', style: itemStyle),
      ),
    ];
  }

  @override
  Widget build(BuildContext context) {
    final typo = context.typo;

    return AppCard(
      margin: EdgeInsets.zero,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      trip.route,
                      style: typo.h3.copyWith(fontWeight: FontWeight.w800),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 8),
                    GestureDetector(
                      onTap: () => _onStatusTap(context),
                      behavior: HitTestBehavior.opaque,
                      child: AppBadge(
                        label: _statusLabel(),
                        color: trip.status.color,
                        backgroundColor: trip.status.backgroundColor,
                        semiBold: true,
                        wide: true,
                      ),
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
              if (_isOpenBid)
                PopupMenuButton<String>(
                  icon: const Icon(
                    Icons.more_vert,
                    color: AppColors.textSecondary,
                    size: 22,
                  ),
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(
                    minWidth: 36,
                    minHeight: 36,
                  ),
                  tooltip: 'More options',
                  onSelected: (value) {
                    if (value == 'edit') {
                      context.push('/edit-trip/${trip.id}');
                    } else if (value == 'cancel') {
                      context.push('/cancel-trip/${trip.id}');
                    }
                  },
                  itemBuilder: _menuItems,
                ),
            ],
          ),
        ],
      ),
    );
  }
}
