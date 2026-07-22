import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';

enum TripStatus {
  openBid,
  inTransit,
  delivered,
}

extension TripStatusX on TripStatus {
  String get label => switch (this) {
        TripStatus.openBid => 'Sender Requests',
        TripStatus.inTransit => 'In Transit',
        TripStatus.delivered => 'Delivered',
      };

  Color get color => switch (this) {
        TripStatus.openBid => AppColors.success,
        TripStatus.inTransit => AppColors.transit,
        TripStatus.delivered => AppColors.success,
      };

  Color get backgroundColor => color.withValues(alpha: 0.12);
}

class TravelerTrip {
  const TravelerTrip({
    this.id = '',
    required this.origin,
    required this.destination,
    required this.travelDate,
    required this.luggageCapacityKg,
    this.status = TripStatus.openBid,
  });

  final String id;
  final String origin;
  final String destination;
  final DateTime travelDate;
  final double luggageCapacityKg;
  final TripStatus status;

  String get route => '$origin → $destination';
}
