import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import '../../data/delivery_status_mapper.dart';
import '../../data/models/created_delivery.dart';
import '../../data/models/shipment.dart';
import '../../data/models/traveler_request_summary.dart';

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
    List<TravelerRequestSummary> travelerRequests = const [],
    SenderPostedPhase? postedPhase,
  }) {
    final phase = postedPhase ??
        (d.status == 'posted' && d.isReceiverAccepted
            ? DeliveryStatusMapper.postedPhaseFor(
                delivery: d,
                travelerRequests: travelerRequests,
              )
            : null);

    if (phase == SenderPostedPhase.travelerAccepted) {
      return const SenderDeliveryStatus(
        label: 'Traveler Accepted',
        color: AppColors.primary,
        isActive: true,
        canEditOrCancel: true,
        description:
            'A traveler accepted your request. Review the offer and pay to confirm.',
      );
    }
    if (phase == SenderPostedPhase.travelerReviewing) {
      return const SenderDeliveryStatus(
        label: 'Traveler Reviewing',
        color: AppColors.success,
        isActive: true,
        canEditOrCancel: true,
        description: 'Waiting for travelers to respond to your requests.',
      );
    }

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
      case 'waiting_receiver':
        return const SenderDeliveryStatus(
          label: 'Waiting for Receiver',
          color: AppColors.warning,
          isActive: true,
          canEditOrCancel: true,
        );
      case 'bid_accepted':
        return const SenderDeliveryStatus(
          label: 'Traveler Selected',
          color: AppColors.primary,
          isActive: true,
          description: 'Payment secured in escrow. Meet for NFC handoff.',
        );
      case 'ready_for_handoff':
        return const SenderDeliveryStatus(
          label: 'Ready for Handoff',
          color: AppColors.primary,
          isActive: true,
        );
      case 'matched':
        return const SenderDeliveryStatus(
          label: 'Traveler Selected',
          color: AppColors.primary,
          isActive: true,
        );
      case 'collected':
        return const SenderDeliveryStatus(
          label: 'Collected',
          color: AppColors.transit,
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
      case 'disputed':
        return const SenderDeliveryStatus(
          label: 'Disputed',
          color: AppColors.danger,
          isActive: true,
        );
      default:
        return SenderDeliveryStatus(
          label: (status == null || status.isEmpty)
              ? 'Posted'
              : status.replaceAll('_', ' '),
          color: AppColors.success,
          isActive: true,
          canEditOrCancel: false,
        );
    }
  }
}
