import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';

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
    this.deliveryPublicId,
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
  final String? deliveryPublicId;

  DateTime get offerSentAt => sentAt ?? deliveryDate;

  String get route {
    if (fromCity.isNotEmpty && toCity.isNotEmpty) {
      return '$fromCity → $toCity';
    }
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
      parcelPhotoCount: (json['photoCount'] as num?)?.toInt() ?? 1,
      deliveryPublicId: json['deliveryPublicId'] as String?,
    );
  }
}
