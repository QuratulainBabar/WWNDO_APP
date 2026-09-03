import '../delivery_status_mapper.dart';
import '../models/created_delivery.dart';
import '../models/delivery_tracking.dart';
import '../models/traveler_request_summary.dart';
import 'delivery_repository.dart';
import 'fulfillment_repository.dart';

/// Bundled live delivery state loaded from the API (no StaticData).
class DeliveryLiveSnapshot {
  const DeliveryLiveSnapshot({
    required this.delivery,
    required this.status,
    required this.tracking,
    required this.cp1Confirmed,
    required this.cp2Confirmed,
    required this.disputed,
    required this.travelerRequests,
    this.matchingTravelerCount,
  });

  final CreatedDelivery delivery;
  final String status;
  final DeliveryTracking tracking;
  final bool cp1Confirmed;
  final bool cp2Confirmed;
  final bool disputed;
  final List<TravelerRequestSummary> travelerRequests;
  final int? matchingTravelerCount;

  int get activeTravelerRequestCount => travelerRequests.length;

  bool get isReceiverAccepted => delivery.isReceiverAccepted;
}

abstract final class DeliveryLiveLoader {
  static Future<DeliveryLiveSnapshot> load({
    required DeliveryRepository deliveryRepo,
    required FulfillmentRepository fulfillmentRepo,
    required String deliveryId,
    String role = 'sender',
    bool includeMatchingCount = false,
  }) async {
    final delivery = await deliveryRepo.getDelivery(deliveryId, role: role);
    final displayId = delivery.displayId;

    final isSender = role == 'sender';
    final results = await Future.wait([
      fulfillmentRepo.getTimeline(displayId),
      fulfillmentRepo.listNfcCheckpoints(displayId),
      // Sender-only endpoint — travelers/receivers get 404 if called.
      if (isSender)
        deliveryRepo.listTravelerRequests(displayId)
      else
        Future.value(<TravelerRequestSummary>[]),
      if (includeMatchingCount &&
          isSender &&
          delivery.status == 'posted' &&
          delivery.isReceiverAccepted)
        deliveryRepo.listMatchingTravelers(displayId)
      else
        Future.value(<dynamic>[]),
    ]);

    final timeline = results[0] as Map<String, dynamic>;
    final checkpoints = results[1] as List<Map<String, dynamic>>;
    final travelerRequests = results[2] as List<TravelerRequestSummary>;
    final matchingRaw = results.length > 3 ? results[3] : null;

    final status =
        (timeline['status'] as String?) ?? delivery.status ?? 'posted';
    final cp1 = checkpoints.any(
      (c) =>
          c['checkpoint'] == 'handoff_sender_traveler' &&
          c['confirmedAt'] != null,
    );
    final cp2 = checkpoints.any(
      (c) =>
          c['checkpoint'] == 'delivery_traveler_receiver' &&
          c['confirmedAt'] != null,
    );
    final disputed = status == 'disputed' || delivery.disputed;
    final deliveryForTracking = CreatedDelivery(
      id: delivery.id,
      publicId: delivery.publicId,
      deliveryType: delivery.deliveryType,
      route: delivery.route,
      travelDate: delivery.travelDate,
      parcelCategory: delivery.parcelCategory,
      parcelSize: delivery.parcelSize,
      weightKg: delivery.weightKg,
      maxBudget: delivery.maxBudget,
      description: delivery.description,
      preferredMeetupLocations: delivery.preferredMeetupLocations,
      acknowledged: delivery.acknowledged,
      photos: delivery.photos,
      status: status,
      senderId: delivery.senderId,
      senderName: delivery.senderName,
      travelerId: delivery.travelerId,
      travelerName: delivery.travelerName,
      receiverId: delivery.receiverId,
      receiverName: delivery.receiverName,
      bidAmount: delivery.bidAmount,
      receiverAcceptedAt: delivery.receiverAcceptedAt,
      disputed: disputed,
    );

    return DeliveryLiveSnapshot(
      delivery: deliveryForTracking,
      status: status,
      tracking: DeliveryStatusMapper.trackingFor(deliveryForTracking),
      cp1Confirmed: cp1,
      cp2Confirmed: cp2,
      disputed: disputed,
      travelerRequests: travelerRequests,
      matchingTravelerCount: matchingRaw is List ? matchingRaw.length : null,
    );
  }
}
