import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import '../photo_urls.dart';
import '../route_display.dart';

enum TravelerBidStatus {
  pending('Pending', AppColors.warning),
  updated('Updated', AppColors.primary),
  accepted('Accepted', AppColors.success),
  rejected('Rejected', AppColors.danger);

  const TravelerBidStatus(this.label, this.color);

  final String label;
  final Color color;

  static TravelerBidStatus fromApi(String? raw) {
    switch ((raw ?? '').trim().toLowerCase()) {
      case 'updated':
        return TravelerBidStatus.updated;
      case 'accepted':
        return TravelerBidStatus.accepted;
      case 'rejected':
      case 'declined':
        return TravelerBidStatus.rejected;
      case 'pending':
      default:
        return TravelerBidStatus.pending;
    }
  }

  String get matchingRequestLabel {
    switch (this) {
      case TravelerBidStatus.pending:
        return 'Bid Submitted';
      case TravelerBidStatus.updated:
        return 'Offer Updated';
      case TravelerBidStatus.accepted:
        return 'Bid Accepted';
      case TravelerBidStatus.rejected:
        return 'Rejected';
    }
  }
}

class TravelerBid {
  const TravelerBid({
    required this.id,
    required this.requestId,
    required this.tripId,
    required this.senderName,
    required this.senderInitial,
    required this.fromCity,
    required this.toCity,
    required this.deliveryDate,
    required this.amount,
    required this.status,
    this.sentAt,
    this.parcelPhotoCount = 1,
    this.parcelPhotoUrls = const [],
    this.deliveryPublicId,
    this.maxBudget,
    this.isAcceptance = false,
    this.originCountry = '',
    this.destinationCountry = '',
    this.originAirport = '',
    this.destinationAirport = '',
  });

  final String id;
  final String requestId;
  final String tripId;
  final String senderName;
  final String senderInitial;
  final String fromCity;
  final String toCity;
  final DateTime deliveryDate;
  final double amount;
  final TravelerBidStatus status;
  /// When the traveler sent this counter offer. Falls back to [deliveryDate] if null.
  final DateTime? sentAt;
  final int parcelPhotoCount;
  final List<String> parcelPhotoUrls;
  final String? deliveryPublicId;
  /// Sender's original max budget for this delivery (when provided by the API).
  final double? maxBudget;
  /// True when the traveler accepted the sender's budget (not a counter-offer).
  final bool isAcceptance;
  final String originCountry;
  final String destinationCountry;
  final String originAirport;
  final String destinationAirport;

  DateTime get offerSentAt => sentAt ?? deliveryDate;

  /// True when the traveler accepted the sender's exact maximum budget
  /// (Accept Offer), not a negotiated counter-offer amount.
  bool get isExactMaxBudgetAcceptance {
    if (isAcceptance) return true;
    final max = maxBudget;
    if (max != null &&
        (amount - max).abs() < 0.005 &&
        status != TravelerBidStatus.updated) {
      // Legacy rows: Accept Offer stored as pending/accepted at max budget.
      return true;
    }
    return false;
  }

  /// Accepted Offers list: only while still awaiting sender decision.
  /// Once sender accepts (or rejects), the item moves to My Deliveries / drops.
  bool get isPendingExactMaxBudgetAcceptance =>
      isExactMaxBudgetAcceptance &&
      (status == TravelerBidStatus.pending ||
          status == TravelerBidStatus.updated);

  /// Counter Offers Sent: traveler-submitted counters still awaiting sender
  /// decision. Once the sender accepts, the delivery leaves this list.
  bool get isCounterOfferSent =>
      !isExactMaxBudgetAcceptance && status != TravelerBidStatus.accepted;

  /// Full sender-selected map / airport place for C2C (no country-only label).
  String get displayFrom => exactRouteEndpoint(
        airport: originAirport,
        city: fromCity,
        country: originCountry,
      );

  String get displayTo => exactRouteEndpoint(
        airport: destinationAirport,
        city: toCity,
        country: destinationCountry,
      );

  String get route {
    final exact = formatRouteArrow(displayFrom, displayTo);
    if (exact.isNotEmpty) return exact;
    return [fromCity, toCity].where((s) => s.isNotEmpty).join(' → ');
  }

  bool get isAccepted => status == TravelerBidStatus.accepted;

  factory TravelerBid.fromJson(Map<String, dynamic> json) {
    final route = (json['route'] as String?)?.trim() ?? '';
    var fromCity = (json['fromCity'] as String?)?.trim() ?? '';
    var toCity = (json['toCity'] as String?)?.trim() ?? '';
    if ((fromCity.isEmpty || toCity.isEmpty) && route.contains('→')) {
      final parts = route.split('→');
      if (fromCity.isEmpty) fromCity = parts.first.trim();
      if (toCity.isEmpty && parts.length > 1) toCity = parts.last.trim();
    }

    final travelRaw = json['travelDate'] ?? json['deliveryDate'];
    final sentRaw = json['sentAt'] ?? json['updatedAt'] ?? json['createdAt'];
    final senderName =
        (json['senderName'] as String?)?.trim().isNotEmpty == true
            ? (json['senderName'] as String).trim()
            : 'Sender';
    final initialRaw = (json['senderInitial'] as String?)?.trim();
    final initial = (initialRaw != null && initialRaw.isNotEmpty)
        ? initialRaw[0].toUpperCase()
        : senderName[0].toUpperCase();

    final tripPublicId = (json['tripPublicId'] as String?)?.trim() ?? '';
    final tripId = tripPublicId.isNotEmpty
        ? tripPublicId
        : (json['tripId'] as String?)?.trim() ?? '';
    final photoUrls = parsePhotoUrls(json['photos']);

    return TravelerBid(
      id: json['id'] as String? ?? '',
      requestId: json['requestId'] as String? ?? '',
      tripId: tripId,
      senderName: senderName,
      senderInitial: initial,
      fromCity: fromCity,
      toCity: toCity,
      deliveryDate: travelRaw is String
          ? (DateTime.tryParse(travelRaw) ?? DateTime.now())
          : DateTime.now(),
      amount: (json['amount'] as num?)?.toDouble() ?? 0,
      status: TravelerBidStatus.fromApi(json['status'] as String?),
      sentAt: sentRaw is String ? DateTime.tryParse(sentRaw) : null,
      parcelPhotoCount: photoUrls.isNotEmpty
          ? photoUrls.length
          : (json['photoCount'] as num?)?.toInt() ?? 1,
      parcelPhotoUrls: photoUrls,
      deliveryPublicId: json['deliveryPublicId'] as String?,
      maxBudget: (json['maxBudget'] as num?)?.toDouble(),
      isAcceptance: json['isAcceptance'] == true,
      originCountry: (json['originCountry'] as String?)?.trim() ?? '',
      destinationCountry:
          (json['destinationCountry'] as String?)?.trim() ?? '',
      originAirport: (json['originAirport'] as String?)?.trim() ?? '',
      destinationAirport:
          (json['destinationAirport'] as String?)?.trim() ?? '',
    );
  }
}
