import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import '../../data/models/created_delivery.dart';

/// Badge UI for sender delivery lists (home, My Posted Deliveries).
class SenderDeliveryStatus {
  const SenderDeliveryStatus({
    required this.label,
    required this.color,
    required this.isActive,
    this.description,
    this.canEditOrCancel = false,
  });

  final String label;
  final Color color;
  final bool isActive;
  final String? description;
  final bool canEditOrCancel;

  Color get backgroundColor => color.withValues(alpha: 0.12);

  static bool needsMatchingTravelerCount(CreatedDelivery d) =>
      d.status == 'posted' && d.isReceiverAccepted;

  static String matchingTravelersLabel(int? count) {
    if (count != null && count > 0) {
      return 'Matching Travelers ($count)';
    }
    return 'Matching Travelers';
  }

  static int? countFromMap(CreatedDelivery d, Map<String, int> counts) =>
      counts[d.displayId] ?? counts[d.id];

  static SenderDeliveryStatus fromDelivery(
    CreatedDelivery d, {
    int? matchingTravelerCount,
  }) {
    return fromApi(
      d.status,
      receiverAccepted: d.isReceiverAccepted,
      matchingTravelerCount: matchingTravelerCount,
    );
  }

  static SenderDeliveryStatus fromApi(
    String? status, {
    bool receiverAccepted = false,
    int? matchingTravelerCount,
  }) {
    switch (status) {
      case 'posted':
        if (receiverAccepted) {
          return SenderDeliveryStatus(
            label: matchingTravelersLabel(matchingTravelerCount),
            color: const Color(0xFF0D9488),
            isActive: true,
            canEditOrCancel: true,
            description: 'Receiver accepted. Choose a matching traveler.',
          );
        }
        return const SenderDeliveryStatus(
          label: 'Receiver Pending',
          color: AppColors.warning,
          isActive: true,
          canEditOrCancel: true,
          description: 'Receiver has not accepted the parcel request yet.',
        );
      case 'matched':
        return const SenderDeliveryStatus(
          label: 'Traveler Selected',
          color: AppColors.primary,
          isActive: true,
        );
      case 'in_transit':
        return const SenderDeliveryStatus(
          label: 'In Transit',
          color: AppColors.transit,
          isActive: true,
        );
      case 'delivered':
        return const SenderDeliveryStatus(
          label: 'Delivered',
          color: AppColors.success,
          isActive: false,
        );
      case 'cancelled':
        return const SenderDeliveryStatus(
          label: 'Cancelled',
          color: AppColors.danger,
          isActive: false,
        );
      default:
        return const SenderDeliveryStatus(
          label: 'Posted',
          color: AppColors.success,
          isActive: true,
          canEditOrCancel: true,
        );
    }
  }
}
