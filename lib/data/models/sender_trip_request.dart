import '../photo_urls.dart';
import '../route_display.dart';
import 'delivery_request.dart';

class SenderTripRequest {
  const SenderTripRequest({
    required this.id,
    required this.deliveryPublicId,
    required this.route,
    required this.travelDate,
    required this.weightKg,
    required this.maxBudget,
    required this.parcelCategory,
    required this.senderName,
    required this.senderInitial,
    required this.matchScore,
    required this.tripId,
    required this.tripPublicId,
    this.description = '',
    this.senderRating,
    this.status = 'pending',
    this.unread = true,
    this.parcelSize = '',
    this.meetupLocations = const [],
    this.receiverMeetupLocation = '',
    this.photoCount = 0,
    this.photoUrls = const [],
    this.fromCity = '',
    this.toCity = '',
    this.originCountry = '',
    this.destinationCountry = '',
    this.originAirport = '',
    this.destinationAirport = '',
  });

  final String id;
  final String deliveryPublicId;
  final String route;
  final DateTime travelDate;
  final double weightKg;
  final double maxBudget;
  final String parcelCategory;
  final String parcelSize;
  final String description;
  final String senderName;
  final String senderInitial;
  final double? senderRating;
  final int matchScore;
  final String tripId;
  final String tripPublicId;
  final String status;
  final bool unread;
  final List<String> meetupLocations;
  final String receiverMeetupLocation;
  final int photoCount;
  final List<String> photoUrls;
  final String fromCity;
  final String toCity;
  final String originCountry;
  final String destinationCountry;
  final String originAirport;
  final String destinationAirport;

  String get categoryTypeLabel {
    final normalized = parcelCategory.trim().toLowerCase();
    if (normalized == 'documents' ||
        normalized == 'document' ||
        normalized.startsWith('doc')) {
      return 'Document';
    }
    return 'Object';
  }

  String get displayMeetupLocation {
    if (meetupLocations.isEmpty) return 'Not specified';
    return meetupLocations.join(', ');
  }

  String get displayReceiverMeetupLocation {
    final location = receiverMeetupLocation.trim();
    if (location.isNotEmpty) return location;
    return 'Not specified';
  }

  String get displayDescription {
    final custom = description.trim();
    if (custom.isNotEmpty) return custom;
    if (categoryTypeLabel == 'Document') {
      return 'Sealed document package — papers or envelope only. Keep flat, dry, and unopened until delivery.';
    }
    return 'Physical object package — packed item(s) for hand delivery. Handle carefully in transit.';
  }

  /// Full sender-selected map / airport place (no City, Country compaction).
  String get displayFrom => exactRouteEndpoint(
        airport: originAirport,
        city: fromCity,
        country: originCountry,
        routeFallback: routeLeft(route),
      );

  String get displayTo => exactRouteEndpoint(
        airport: destinationAirport,
        city: toCity,
        country: destinationCountry,
        routeFallback: routeRight(route),
      );

  String get displayRoute {
    final exact = formatRouteArrow(displayFrom, displayTo);
    if (exact.isNotEmpty) return exact;
    return route;
  }

  /// Bridges API sender-request data into the existing parcel-detail / bid UI model.
  DeliveryRequest toDeliveryRequest() {
    return DeliveryRequest(
      id: id,
      fromCity: displayFrom,
      toCity: displayTo,
      travelDate: travelDate,
      maxBudget: maxBudget,
      category: parcelCategory,
      weightKg: weightKg,
      size: parcelSize,
      senderName: senderName,
      senderInitial: senderInitial,
      senderRating: senderRating ?? 0,
      description: description,
      meetupLocations: meetupLocations,
      receiverHandoffLocation: receiverMeetupLocation,
      photoCount: photoUrls.isNotEmpty ? photoUrls.length : photoCount,
      photoUrls: photoUrls,
    );
  }

  SenderTripRequest markRead() => SenderTripRequest(
        id: id,
        deliveryPublicId: deliveryPublicId,
        route: route,
        travelDate: travelDate,
        weightKg: weightKg,
        maxBudget: maxBudget,
        parcelCategory: parcelCategory,
        parcelSize: parcelSize,
        description: description,
        senderName: senderName,
        senderInitial: senderInitial,
        senderRating: senderRating,
        matchScore: matchScore,
        tripId: tripId,
        tripPublicId: tripPublicId,
        status: status,
        unread: false,
        meetupLocations: meetupLocations,
        receiverMeetupLocation: receiverMeetupLocation,
        photoCount: photoCount,
        photoUrls: photoUrls,
        fromCity: fromCity,
        toCity: toCity,
        originCountry: originCountry,
        destinationCountry: destinationCountry,
        originAirport: originAirport,
        destinationAirport: destinationAirport,
      );

  factory SenderTripRequest.fromJson(Map<String, dynamic> json) {
    final travelRaw = json['travelDate'];
    final travelDate = travelRaw is String
        ? (DateTime.tryParse(travelRaw) ?? DateTime.now())
        : DateTime.now();
    final name = json['senderName'] as String? ?? 'Sender';
    final meetupRaw = json['meetupLocations'];
    final meetup = meetupRaw is List
        ? meetupRaw.map((e) => e.toString()).where((e) => e.trim().isNotEmpty).toList()
        : const <String>[];
    final photoUrls = parsePhotoUrls(json['photos']);
    final photoCount = photoUrls.isNotEmpty
        ? photoUrls.length
        : (json['photoCount'] as num?)?.toInt() ?? 0;
    return SenderTripRequest(
      id: json['id'] as String? ?? '',
      deliveryPublicId: json['deliveryPublicId'] as String? ?? '',
      route: json['route'] as String? ?? '—',
      travelDate: travelDate,
      weightKg: (json['weightKg'] as num?)?.toDouble() ?? 0,
      maxBudget: (json['maxBudget'] as num?)?.toDouble() ?? 0,
      parcelCategory: json['parcelCategory'] as String? ?? '',
      parcelSize: json['parcelSize'] as String? ?? '',
      description: json['description'] as String? ?? '',
      senderName: name,
      senderInitial: (json['senderInitial'] as String?)?.trim().isNotEmpty == true
          ? (json['senderInitial'] as String).trim()
          : name[0].toUpperCase(),
      senderRating: (json['senderRating'] as num?)?.toDouble(),
      matchScore: (json['matchScore'] as num?)?.toInt() ?? 0,
      tripId: json['tripId'] as String? ?? '',
      tripPublicId: json['tripPublicId'] as String? ?? '',
      status: json['status'] as String? ?? 'pending',
      unread: json['unread'] as bool? ?? true,
      meetupLocations: meetup,
      receiverMeetupLocation:
          json['receiverMeetupLocation'] as String? ?? '',
      photoCount: photoCount,
      photoUrls: photoUrls,
      fromCity: json['fromCity'] as String? ?? '',
      toCity: json['toCity'] as String? ?? '',
      originCountry: json['originCountry'] as String? ?? '',
      destinationCountry: json['destinationCountry'] as String? ?? '',
      originAirport: json['originAirport'] as String? ?? '',
      destinationAirport: json['destinationAirport'] as String? ?? '',
    );
  }
}
