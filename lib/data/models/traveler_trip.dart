import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import '../route_display.dart';

enum TripStatus {
  openBid,
  inTransit,
  delivered,
  cancelled,
}

extension TripStatusX on TripStatus {
  String get label => switch (this) {
        TripStatus.openBid => 'Sender Requests',
        TripStatus.inTransit => 'In Transit',
        TripStatus.delivered => 'Completed',
        TripStatus.cancelled => 'Cancelled',
      };

  Color get color => switch (this) {
        TripStatus.openBid => AppColors.success,
        TripStatus.inTransit => AppColors.transit,
        TripStatus.delivered => AppColors.success,
        TripStatus.cancelled => AppColors.danger,
      };

  Color get backgroundColor => color.withValues(alpha: 0.12);

  bool get canEditOrCancel => this == TripStatus.openBid;

  bool get isCompleted =>
      this == TripStatus.delivered || this == TripStatus.cancelled;
}

TripStatus tripStatusFromApi(String? value) {
  switch (value) {
    case 'in_transit':
      return TripStatus.inTransit;
    case 'delivered':
    case 'completed':
      return TripStatus.delivered;
    case 'cancelled':
      return TripStatus.cancelled;
    case 'open_bid':
    default:
      return TripStatus.openBid;
  }
}

class TravelerTrip {
  const TravelerTrip({
    this.id = '',
    this.publicId,
    required this.origin,
    required this.destination,
    required this.travelDate,
    required this.luggageCapacityKg,
    this.status = TripStatus.openBid,
    this.tripType,
    this.travelerName,
    this.travelerRating,
    this.travelerReviewCount,
    this.flightNumber,
    this.fromCode,
    this.toCode,
    this.originCountry,
    this.destinationCountry,
    this.originCountryCode,
    this.destinationCountryCode,
    this.originAirport,
    this.destinationAirport,
  });

  final String id;
  final String? publicId;
  final String origin;
  final String destination;
  final DateTime travelDate;
  final double luggageCapacityKg;
  final TripStatus status;
  final String? tripType;
  final String? travelerName;
  final double? travelerRating;
  final int? travelerReviewCount;
  final String? flightNumber;
  final String? fromCode;
  final String? toCode;
  final String? originCountry;
  final String? destinationCountry;
  final String? originCountryCode;
  final String? destinationCountryCode;
  final String? originAirport;
  final String? destinationAirport;

  /// Exact map place when available (C2C airport), else stored origin/destination.
  String get displayOrigin {
    final airport = (originAirport ?? '').trim();
    if (airport.isNotEmpty) {
      return compactRouteEndpoint(airport, country: originCountry);
    }
    return displayRouteEndpoint(
      city: origin,
      country: originCountry,
    );
  }

  String get displayDestination {
    final airport = (destinationAirport ?? '').trim();
    if (airport.isNotEmpty) {
      return compactRouteEndpoint(airport, country: destinationCountry);
    }
    return displayRouteEndpoint(
      city: destination,
      country: destinationCountry,
    );
  }

  String get route => formatRouteArrow(displayOrigin, displayDestination);

  String get displayId => (publicId?.trim().isNotEmpty ?? false) ? publicId! : id;

  bool get isCountryToCountry => tripType == 'country_to_country';
}
