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
    if (status == 'matched' || (status == 'posted' && accepted)) {
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
        return ShipmentStatus.disputed;
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
    final pickup = fromCity?.isNotEmpty == true
        ? fromCity!
        : (originCountry ?? route.split('→').first.trim());
    final destination = toCity?.isNotEmpty == true
        ? toCity!
        : (destinationCountry ??
            (route.contains('→') ? route.split('→').last.trim() : route));

    return IncomingParcelRequest(
      id: displayId,
      senderName: name,
      senderInitial: name.isNotEmpty ? name[0].toUpperCase() : 'S',
      parcelType: parcelCategory,
      weightKg: weightKg,
      pickupLocation: pickup,
      receiverLocation: destination,
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
      fromCity: fromCity ?? originCountry ?? '',
      toCity: toCity ?? destinationCountry ?? '',
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
    );
  }
}
