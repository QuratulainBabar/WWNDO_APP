import '../models/bid.dart';
import '../route_display.dart';

/// Traveler returned by GET /deliveries/:id/matching-travelers.
class MatchingTraveler {
  const MatchingTraveler({
    required this.tripId,
    required this.travelerId,
    required this.travelerName,
    required this.initial,
    required this.rating,
    required this.reviewCount,
    required this.travelDate,
    required this.origin,
    required this.destination,
    required this.route,
    required this.matchScore,
    required this.price,
    this.tripPublicId,
    this.bio,
    this.luggageCapacityKg,
    this.flightNumber,
    this.tripType,
    this.message,
    this.departureTime,
    this.travelMethod,
    this.originAirport,
    this.destinationAirport,
    this.fromCity,
    this.toCity,
  });

  final String tripId;
  final String? tripPublicId;
  final String travelerId;
  final String travelerName;
  final String initial;
  final double rating;
  final int reviewCount;
  final DateTime travelDate;
  final String origin;
  final String destination;
  final String route;
  final int matchScore;
  final double price;
  final String? bio;
  final double? luggageCapacityKg;
  final String? flightNumber;
  final String? tripType;
  final String? message;
  final String? departureTime;
  final String? travelMethod;
  final String? originAirport;
  final String? destinationAirport;
  final String? fromCity;
  final String? toCity;

  String get displayFrom => exactRouteEndpoint(
        airport: originAirport,
        city: fromCity ?? origin,
      );

  String get displayTo => exactRouteEndpoint(
        airport: destinationAirport,
        city: toCity ?? destination,
      );

  String get displayRoute {
    final exact = formatRouteArrow(displayFrom, displayTo);
    if (exact.isNotEmpty) return exact;
    return route;
  }

  String? get fromEndpointType {
    if (originAirport?.trim().isNotEmpty == true) return 'Airport';
    if (fromCity?.trim().isNotEmpty == true) return 'City';
    return null;
  }

  String? get toEndpointType {
    if (destinationAirport?.trim().isNotEmpty == true) return 'Airport';
    if (toCity?.trim().isNotEmpty == true) return 'City';
    return null;
  }

  String? get travelMethodLabel {
    switch (travelMethod?.trim().toLowerCase()) {
      case 'air':
        return 'By Air';
      case 'land':
        return 'By Land';
      default:
        return null;
    }
  }

  factory MatchingTraveler.fromJson(Map<String, dynamic> json) {
    final travelRaw = json['travelDate'];
    DateTime travelDate;
    if (travelRaw is String && travelRaw.isNotEmpty) {
      travelDate = DateTime.tryParse(travelRaw) ?? DateTime.now();
    } else {
      travelDate = DateTime.now();
    }

    final name = json['travelerName'] as String? ?? 'Traveler';
    final initial = (json['initial'] as String?)?.trim().isNotEmpty == true
        ? (json['initial'] as String).trim()
        : name[0].toUpperCase();

    return MatchingTraveler(
      tripId: json['tripId'] as String? ?? '',
      tripPublicId: json['tripPublicId'] as String?,
      travelerId: json['travelerId'] as String? ?? '',
      travelerName: name,
      initial: initial,
      rating: (json['rating'] as num?)?.toDouble() ?? 0,
      reviewCount: (json['reviewCount'] as num?)?.toInt() ?? 0,
      travelDate: travelDate,
      origin: json['origin'] as String? ?? '',
      destination: json['destination'] as String? ?? '',
      route: json['route'] as String? ?? '',
      matchScore: (json['matchScore'] as num?)?.toInt() ??
          (json['routeMatchConfidence'] as num?)?.toInt() ??
          0,
      price: (json['price'] as num?)?.toDouble() ?? 0,
      bio: json['bio'] as String?,
      luggageCapacityKg: (json['luggageCapacityKg'] as num?)?.toDouble(),
      flightNumber: json['flightNumber'] as String?,
      tripType: json['tripType'] as String?,
      message: json['message'] as String?,
      departureTime: json['departureTime'] as String?,
      travelMethod: json['travelMethod'] as String?,
      originAirport: json['originAirport'] as String?,
      destinationAirport: json['destinationAirport'] as String?,
      fromCity: json['fromCity'] as String?,
      toCity: json['toCity'] as String?,
    );
  }

  /// Maps API match into the existing Bid card model (UI unchanged).
  Bid toBid() {
    return Bid(
      id: tripId.isNotEmpty ? tripId : (tripPublicId ?? travelerId),
      travelerName: travelerName,
      initial: initial,
      rating: rating,
      reviewCount: reviewCount,
      price: price,
      travelDate: travelDate,
      routeMatchConfidence: matchScore,
      flightNumber: flightNumber,
      message: message,
      bio: bio,
      completedDeliveries: reviewCount,
      luggageCapacityKg: luggageCapacityKg,
      route: displayRoute,
      origin: displayFrom,
      destination: displayTo,
      departureTime: departureTime,
      travelMethod: travelMethod,
      fromEndpointType: fromEndpointType,
      toEndpointType: toEndpointType,
    );
  }

  /// True when this traveler's luggage capacity can carry [parcelWeightKg].
  /// Unknown capacity fails closed (cannot confirm fit).
  bool canCarryWeightKg(double parcelWeightKg) {
    final capacity = luggageCapacityKg;
    if (capacity == null) return false;
    return capacity >= parcelWeightKg;
  }
}
