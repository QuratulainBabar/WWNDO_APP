import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import 'created_delivery.dart';
import '../delivery_status_mapper.dart';

enum ShipmentStatus {
  open,
  receiverAccepted,
  bidAccepted,
  photosUploaded,
  collected,
  inTransit,
  delivered,
  disputed,
}

/// Frontend-only sender list phases before / after matching on My Posted Deliveries.
enum SenderPostedPhase {
  waitingForReceiver,
  matchingTravelers,
  travelerReviewing,
  travelerAccepted,
  travelerSelected,
}

extension SenderPostedPhaseX on SenderPostedPhase {
  String get badgeLabel => switch (this) {
        SenderPostedPhase.waitingForReceiver => 'Receiver Pending',
        SenderPostedPhase.matchingTravelers => 'Matching Travelers',
        SenderPostedPhase.travelerReviewing => 'Traveler Reviewing',
        SenderPostedPhase.travelerAccepted => 'Traveler Accepted',
        SenderPostedPhase.travelerSelected => 'Traveler Selected',
      };

  String get description => switch (this) {
        SenderPostedPhase.waitingForReceiver =>
          'Receiver has not accepted the parcel request yet.',
        SenderPostedPhase.matchingTravelers =>
          'Receiver has accepted. Matching travelers are now available.',
        SenderPostedPhase.travelerReviewing =>
          'Selected traveler(s) are reviewing the request. You can still send requests to more matching travelers.',
        SenderPostedPhase.travelerAccepted =>
          'The traveler has accepted the parcel request.',
        SenderPostedPhase.travelerSelected =>
          'The sender has finalized the traveler.',
      };

  Color get color => switch (this) {
        SenderPostedPhase.waitingForReceiver => AppColors.warning,
        SenderPostedPhase.matchingTravelers => const Color(0xFF0D9488),
        SenderPostedPhase.travelerReviewing => AppColors.success,
        SenderPostedPhase.travelerAccepted => AppColors.primary,
        SenderPostedPhase.travelerSelected => AppColors.primary,
      };

  Color get backgroundColor => color.withValues(alpha: 0.12);
}

extension ShipmentStatusX on ShipmentStatus {
  String get label => switch (this) {
        ShipmentStatus.open => 'Open',
        ShipmentStatus.receiverAccepted => 'Receiver Accepted',
        ShipmentStatus.bidAccepted => 'Traveler Selected',
        ShipmentStatus.photosUploaded => 'Photos Uploaded',
        ShipmentStatus.collected => 'Collected',
        ShipmentStatus.inTransit => 'In Transit',
        ShipmentStatus.delivered => 'Delivered',
        ShipmentStatus.disputed => 'Disputed',
      };

  Color get color => switch (this) {
        ShipmentStatus.open => AppColors.success,
        ShipmentStatus.receiverAccepted => const Color(0xFF0D9488),
        ShipmentStatus.bidAccepted => AppColors.primary,
        ShipmentStatus.photosUploaded => AppColors.primary,
        ShipmentStatus.collected => AppColors.warning,
        ShipmentStatus.inTransit => AppColors.transit,
        ShipmentStatus.delivered => AppColors.success,
        ShipmentStatus.disputed => AppColors.danger,
      };

  Color get backgroundColor => color.withValues(alpha: 0.12);
}

enum ShipmentRole { sender, traveler, receiver }

extension ShipmentRoleX on ShipmentRole {
  String get label => switch (this) {
        ShipmentRole.sender => 'As sender',
        ShipmentRole.traveler => 'As traveler',
        ShipmentRole.receiver => 'As receiver',
      };
}

class Shipment {
  const Shipment({
    required this.id,
    required this.fromCity,
    required this.toCity,
    required this.fromCode,
    required this.toCode,
    required this.travelDate,
    required this.status,
    required this.role,
    this.parcelCategory = 'Documents',
    this.parcelWeightKg = 0.8,
    this.parcelSize = 'small box',
    this.description = '',
    this.travelerName,
    this.flightNumber,
    this.parcelPhotoCount = 2,
    this.parcelPhotoUrls = const [],
  });

  final String id;
  final String fromCity;
  final String toCity;
  final String fromCode;
  final String toCode;
  final DateTime travelDate;
  final ShipmentStatus status;
  final ShipmentRole role;
  final String parcelCategory;
  final double parcelWeightKg;
  final String parcelSize;
  final String description;
  final String? travelerName;
  final String? flightNumber;
  final int parcelPhotoCount;
  final List<String> parcelPhotoUrls;

  Shipment copyWith({
    String? id,
    String? fromCity,
    String? toCity,
    String? fromCode,
    String? toCode,
    DateTime? travelDate,
    ShipmentStatus? status,
    ShipmentRole? role,
    String? parcelCategory,
    double? parcelWeightKg,
    String? parcelSize,
    String? description,
    String? travelerName,
    String? flightNumber,
    int? parcelPhotoCount,
    List<String>? parcelPhotoUrls,
  }) {
    return Shipment(
      id: id ?? this.id,
      fromCity: fromCity ?? this.fromCity,
      toCity: toCity ?? this.toCity,
      fromCode: fromCode ?? this.fromCode,
      toCode: toCode ?? this.toCode,
      travelDate: travelDate ?? this.travelDate,
      status: status ?? this.status,
      role: role ?? this.role,
      parcelCategory: parcelCategory ?? this.parcelCategory,
      parcelWeightKg: parcelWeightKg ?? this.parcelWeightKg,
      parcelSize: parcelSize ?? this.parcelSize,
      description: description ?? this.description,
      travelerName: travelerName ?? this.travelerName,
      flightNumber: flightNumber ?? this.flightNumber,
      parcelPhotoCount: parcelPhotoCount ?? this.parcelPhotoCount,
      parcelPhotoUrls: parcelPhotoUrls ?? this.parcelPhotoUrls,
    );
  }

  String get route => '$fromCity → $toCity';

  int get currentStepIndex => trackingProgress;

  /// Lifecycle steps shown on the status timeline (step 2 label is dynamic via [DeliveryTracking]).
  static const trackingSteps = [
    'Open',
    'Receiver Accepted',
    'Collected',
    'In Transit',
    'Delivered',
  ];

  /// Progress through [trackingSteps]: 0 before open, 5 when delivered.
  int get trackingProgress => switch (status) {
        ShipmentStatus.open => 1,
        ShipmentStatus.receiverAccepted => 2,
        ShipmentStatus.bidAccepted => 2,
        ShipmentStatus.photosUploaded => 2,
        ShipmentStatus.collected => 3,
        ShipmentStatus.inTransit => 4,
        ShipmentStatus.delivered => 5,
        ShipmentStatus.disputed => 2,
      };

  static const steps = trackingSteps;

  /// Maps a live API delivery into the legacy [Shipment] view model for tracking UI.
  factory Shipment.fromDelivery(
    CreatedDelivery delivery, {
    required String status,
    ShipmentRole role = ShipmentRole.sender,
    String? travelerName,
  }) {
    return Shipment(
      id: delivery.displayId,
      fromCity: delivery.exactDisplayFrom,
      toCity: delivery.exactDisplayTo,
      fromCode: delivery.fromCode ?? '',
      toCode: delivery.toCode ?? '',
      travelDate: delivery.travelDateParsed ?? DateTime.now(),
      status: DeliveryStatusMapper.toShipmentStatus(status),
      role: role,
      parcelCategory: delivery.parcelCategory,
      parcelWeightKg: delivery.weightKg,
      parcelSize: delivery.parcelSize,
      description: delivery.description,
      travelerName: travelerName ?? delivery.senderName,
      parcelPhotoCount: delivery.photos.length,
      parcelPhotoUrls: delivery.photos.map((p) => p.url).toList(),
    );
  }
}
