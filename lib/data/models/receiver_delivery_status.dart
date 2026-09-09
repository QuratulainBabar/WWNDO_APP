import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import '../models/created_delivery.dart';
import '../models/incoming_parcel_request.dart';
import '../models/shipment.dart';

/// Maps API delivery status → Receiver UI labels/colors (Incoming list + home).
class ReceiverDeliveryStatus {
  const ReceiverDeliveryStatus({
    required this.label,
    required this.color,
    required this.isPast,
    required this.isPendingRequest,
  });

  final String label;
  final Color color;
  final bool isPast;
  final bool isPendingRequest;

  Color get backgroundColor => color.withValues(alpha: 0.12);

  static ReceiverDeliveryStatus fromDelivery(CreatedDelivery d) {
    final status = d.status;
    final accepted = d.isReceiverAccepted;

    if (status == 'cancelled') {
      // Receiver decline (before accept) shows as Rejected; other cancels stay Cancelled.
      if (!accepted) {
        return const ReceiverDeliveryStatus(
          label: 'Rejected',
          color: AppColors.danger,
          isPast: true,
          isPendingRequest: false,
        );
      }
      return const ReceiverDeliveryStatus(
        label: 'Cancelled',
        color: AppColors.danger,
        isPast: true,
        isPendingRequest: false,
      );
    }
    if (status == 'delivered') {
      return const ReceiverDeliveryStatus(
        label: 'Delivered',
        color: AppColors.success,
        isPast: true,
        isPendingRequest: false,
      );
    }
    if (status == 'posted' && !accepted) {
      return const ReceiverDeliveryStatus(
        label: 'New Request',
        color: AppColors.transit,
        isPast: false,
        isPendingRequest: true,
      );
    }
    if (status == 'posted' && accepted) {
      return const ReceiverDeliveryStatus(
        label: 'Receiver Accepted',
        color: Color(0xFF0D9488),
        isPast: false,
        isPendingRequest: false,
      );
    }
    if (status == 'matched') {
      return const ReceiverDeliveryStatus(
        label: 'Traveler Selected',
        color: AppColors.primary,
        isPast: false,
        isPendingRequest: false,
      );
    }
    if (status == 'in_transit') {
      return const ReceiverDeliveryStatus(
        label: 'In Transit',
        color: AppColors.transit,
        isPast: false,
        isPendingRequest: false,
      );
    }
    return ReceiverDeliveryStatus(
      label: status?.isNotEmpty == true ? _titleCase(status!) : 'Posted',
      color: AppColors.primary,
      isPast: false,
      isPendingRequest: false,
    );
  }

  static String _titleCase(String raw) {
    return raw
        .split('_')
        .where((p) => p.isNotEmpty)
        .map((p) => '${p[0].toUpperCase()}${p.substring(1)}')
        .join(' ');
  }

  ShipmentStatus get shipmentStatus {
    if (isPendingRequest) return ShipmentStatus.open;
    switch (label) {
      case 'Delivered':
        return ShipmentStatus.delivered;
      case 'In Transit':
        return ShipmentStatus.inTransit;
      case 'Collected':
        return ShipmentStatus.collected;
      case 'Cancelled':
      case 'Rejected':
        return ShipmentStatus.disputed;
      case 'Receiver Accepted':
        return ShipmentStatus.receiverAccepted;
      case 'Traveler Selected':
        return ShipmentStatus.bidAccepted;
      default:
        return ShipmentStatus.bidAccepted;
    }
  }
}

extension CreatedDeliveryReceiverX on CreatedDelivery {
  IncomingParcelRequest toIncomingParcelRequest() {
    final name = senderName?.trim().isNotEmpty == true
        ? senderName!.trim()
        : 'Sender';

    return IncomingParcelRequest(
      id: displayId,
      senderName: name,
      senderInitial: name.isNotEmpty ? name[0].toUpperCase() : 'S',
      parcelType: parcelCategory,
      weightKg: weightKg,
      pickupLocation: exactDisplayFrom,
      receiverLocation: exactDisplayTo,
      travelDate: travelDateParsed ?? DateTime.now(),
      status: isReceiverAccepted
          ? IncomingParcelRequestStatus.accepted
          : status == 'cancelled'
              ? IncomingParcelRequestStatus.rejected
              : IncomingParcelRequestStatus.pending,
    );
  }

  Shipment toShipment() {
    final statusInfo = ReceiverDeliveryStatus.fromDelivery(this);
    return Shipment(
      id: displayId,
      fromCity: exactDisplayFrom,
      toCity: exactDisplayTo,
      fromCode: fromCode ?? '',
      toCode: toCode ?? '',
      travelDate: travelDateParsed ?? DateTime.now(),
      status: statusInfo.shipmentStatus,
      role: ShipmentRole.receiver,
      parcelCategory: parcelCategory,
      parcelWeightKg: weightKg,
      parcelSize: parcelSize,
      description: description,
      travelerName: senderName,
      parcelPhotoCount: photos.length,
      parcelPhotoUrls: photos.map((p) => p.url).toList(),
    );
  }
}
