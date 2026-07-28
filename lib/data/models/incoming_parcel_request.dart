import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';

enum IncomingParcelRequestStatus { pending, accepted, rejected }

extension IncomingParcelRequestStatusX on IncomingParcelRequestStatus {
  String get label => switch (this) {
        IncomingParcelRequestStatus.pending => 'New Request',
        IncomingParcelRequestStatus.accepted => 'Receiver Accepted',
        IncomingParcelRequestStatus.rejected => 'Rejected',
      };

  Color get color => switch (this) {
        IncomingParcelRequestStatus.pending => AppColors.transit,
        IncomingParcelRequestStatus.accepted => const Color(0xFF0D9488),
        IncomingParcelRequestStatus.rejected => AppColors.danger,
      };

  Color get backgroundColor => color.withValues(alpha: 0.12);
}

/// Sender-initiated parcel request awaiting receiver review (mock layer).
class IncomingParcelRequest {
  const IncomingParcelRequest({
    required this.id,
    required this.senderName,
    required this.senderInitial,
    required this.parcelType,
    required this.weightKg,
    required this.pickupLocation,
    required this.receiverLocation,
    required this.travelDate,
    this.travelerLabel = 'Will be assigned',
    this.status = IncomingParcelRequestStatus.pending,
  });

  final String id;
  final String senderName;
  final String senderInitial;
  final String parcelType;
  final double weightKg;
  final String pickupLocation;
  final String receiverLocation;
  final DateTime travelDate;
  final String travelerLabel;
  final IncomingParcelRequestStatus status;

  String get route => '$pickupLocation → $receiverLocation';

  IncomingParcelRequest copyWith({
    IncomingParcelRequestStatus? status,
  }) {
    return IncomingParcelRequest(
      id: id,
      senderName: senderName,
      senderInitial: senderInitial,
      parcelType: parcelType,
      weightKg: weightKg,
      pickupLocation: pickupLocation,
      receiverLocation: receiverLocation,
      travelDate: travelDate,
      travelerLabel: travelerLabel,
      status: status ?? this.status,
    );
  }
}
