import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';

enum TravelerBidStatus {
  pending('Pending', AppColors.warning),
  accepted('Accepted', AppColors.success),
  rejected('Rejected', AppColors.danger);

  const TravelerBidStatus(this.label, this.color);

  final String label;
  final Color color;

  String get matchingRequestLabel {
    switch (this) {
      case TravelerBidStatus.pending:
        return 'Bid Submitted';
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

  DateTime get offerSentAt => sentAt ?? deliveryDate;

  String get route => '$fromCity → $toCity';

  bool get isAccepted => status == TravelerBidStatus.accepted;
}
