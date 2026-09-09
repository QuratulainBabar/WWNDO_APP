import '../photo_urls.dart';
import '../route_display.dart';
import 'traveler_bid.dart';

/// Sender-facing counter offer received from a traveler.
class SenderCounterOffer {
  const SenderCounterOffer({
    required this.id,
    required this.requestId,
    required this.tripId,
    required this.travelerName,
    required this.travelerInitial,
    required this.fromCity,
    required this.toCity,
    required this.travelDate,
    required this.amount,
    required this.maxBudget,
    required this.status,
    this.travelerRating,
    this.travelerReviewCount = 0,
    this.travelerBio,
    this.message,
    this.sentAt,
    this.parcelPhotoCount = 1,
    this.parcelPhotoUrls = const [],
    this.deliveryPublicId,
    this.deliveryStatus,
    this.paymentPending = false,
    this.originCountry,
    this.originAirport,
    this.destinationCountry,
    this.destinationAirport,
    this.apiRoute = '',
  });

  final String id;
  final String requestId;
  final String tripId;
  final String travelerName;
  final String travelerInitial;
  final double? travelerRating;
  final int travelerReviewCount;
  final String? travelerBio;
  /// Optional note the traveler included with this counter offer.
  final String? message;
  final String fromCity;
  final String toCity;
  final DateTime travelDate;
  final double amount;
  final double maxBudget;
  final TravelerBidStatus status;
  final DateTime? sentAt;
  final int parcelPhotoCount;
  final List<String> parcelPhotoUrls;
  final String? deliveryPublicId;
  final String? deliveryStatus;
  final bool paymentPending;
  final String? originCountry;
  final String? originAirport;
  final String? destinationCountry;
  final String? destinationAirport;
  /// Raw `route` string from the API (used as fallback only).
  final String apiRoute;

  String get displayFrom {
    final airport = (originAirport ?? '').trim();
    if (airport.isNotEmpty) {
      return compactRouteEndpoint(airport, country: originCountry);
    }
    return displayRouteEndpoint(
      city: fromCity,
      country: originCountry,
      routeFallback: routeLeft(apiRoute),
    );
  }

  String get displayTo {
    final airport = (destinationAirport ?? '').trim();
    if (airport.isNotEmpty) {
      return compactRouteEndpoint(airport, country: destinationCountry);
    }
    return displayRouteEndpoint(
      city: toCity,
      country: destinationCountry,
      routeFallback: routeRight(apiRoute),
    );
  }

  String get route {
    final exact = formatRouteArrow(displayFrom, displayTo);
    if (exact.isNotEmpty) return exact;
    return apiRoute;
  }

  bool get isOpen =>
      status == TravelerBidStatus.pending ||
      status == TravelerBidStatus.updated;

  bool get isAccepted => status == TravelerBidStatus.accepted && !paymentPending;
  bool get isRejected => status == TravelerBidStatus.rejected;
  bool get awaitsPayment => paymentPending;

  factory SenderCounterOffer.fromJson(Map<String, dynamic> json) {
    final apiRoute = (json['route'] as String?)?.trim() ?? '';
    var fromCity = (json['fromCity'] as String?)?.trim() ?? '';
    var toCity = (json['toCity'] as String?)?.trim() ?? '';
    if ((fromCity.isEmpty || toCity.isEmpty) && apiRoute.contains('→')) {
      final parts = apiRoute.split('→');
      if (fromCity.isEmpty) fromCity = parts.first.trim();
      if (toCity.isEmpty && parts.length > 1) toCity = parts.last.trim();
    }

    final travelRaw = json['travelDate'] ?? json['deliveryDate'];
    final sentRaw = json['sentAt'] ?? json['updatedAt'] ?? json['createdAt'];
    final travelerName =
        (json['travelerName'] as String?)?.trim().isNotEmpty == true
            ? (json['travelerName'] as String).trim()
            : 'Traveler';
    final initialRaw = (json['travelerInitial'] as String?)?.trim();
    final initial = (initialRaw != null && initialRaw.isNotEmpty)
        ? initialRaw[0].toUpperCase()
        : travelerName[0].toUpperCase();

    final tripPublicId = (json['tripPublicId'] as String?)?.trim() ?? '';
    final tripId = tripPublicId.isNotEmpty
        ? tripPublicId
        : (json['tripId'] as String?)?.trim() ?? '';
    final photoUrls = parsePhotoUrls(json['photos']);

    final status = TravelerBidStatus.fromApi(json['status'] as String?);
    final deliveryStatus = json['deliveryStatus'] as String?;
    final paymentPending = json['paymentPending'] == true ||
        (status == TravelerBidStatus.accepted && deliveryStatus == 'posted');

    return SenderCounterOffer(
      id: json['id'] as String? ?? '',
      requestId: json['requestId'] as String? ?? '',
      tripId: tripId,
      travelerName: travelerName,
      travelerInitial: initial,
      travelerRating: (json['travelerRating'] as num?)?.toDouble(),
      travelerReviewCount: (json['travelerReviewCount'] as num?)?.toInt() ?? 0,
      travelerBio: (json['travelerBio'] as String?)?.trim(),
      message: () {
        final raw = (json['message'] as String?)?.trim();
        return (raw != null && raw.isNotEmpty) ? raw : null;
      }(),
      fromCity: fromCity,
      toCity: toCity,
      travelDate: travelRaw is String
          ? (DateTime.tryParse(travelRaw) ?? DateTime.now())
          : DateTime.now(),
      amount: (json['amount'] as num?)?.toDouble() ?? 0,
      maxBudget: (json['maxBudget'] as num?)?.toDouble() ?? 0,
      status: status,
      sentAt: sentRaw is String ? DateTime.tryParse(sentRaw) : null,
      parcelPhotoCount: photoUrls.isNotEmpty
          ? photoUrls.length
          : (json['photoCount'] as num?)?.toInt() ?? 1,
      parcelPhotoUrls: photoUrls,
      deliveryPublicId: json['deliveryPublicId'] as String?,
      deliveryStatus: deliveryStatus,
      paymentPending: paymentPending,
      originCountry: (json['originCountry'] as String?)?.trim(),
      originAirport: (json['originAirport'] as String?)?.trim(),
      destinationCountry: (json['destinationCountry'] as String?)?.trim(),
      destinationAirport: (json['destinationAirport'] as String?)?.trim(),
      apiRoute: apiRoute,
    );
  }
}
