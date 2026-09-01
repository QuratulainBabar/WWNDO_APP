import 'models/created_delivery.dart';
import 'models/delivery_tracking.dart';
import 'models/shipment.dart';
import 'models/traveler_request_summary.dart';

/// Maps API delivery status to UI enums used by tracking screens.
abstract final class DeliveryStatusMapper {
  static ShipmentStatus toShipmentStatus(String? status) {
    switch (status?.trim().toLowerCase()) {
      case 'posted':
      case 'waiting_receiver':
        return ShipmentStatus.open;
      case 'bid_accepted':
      case 'matched':
        return ShipmentStatus.bidAccepted;
      case 'ready_for_handoff':
        return ShipmentStatus.photosUploaded;
      case 'collected':
        return ShipmentStatus.collected;
      case 'in_transit':
        return ShipmentStatus.inTransit;
      case 'delivered':
        return ShipmentStatus.delivered;
      case 'disputed':
        return ShipmentStatus.disputed;
      default:
        return ShipmentStatus.open;
    }
  }

  static SenderPostedPhase? postedPhaseFor({
    required CreatedDelivery delivery,
    List<TravelerRequestSummary> travelerRequests = const [],
    int activeTravelerRequestCount = 0,
  }) {
    if (delivery.status != 'posted') return null;
    if (!delivery.isReceiverAccepted) {
      return SenderPostedPhase.waitingForReceiver;
    }
    if (travelerRequests.isNotEmpty) {
      if (travelerRequests.any((r) => r.isAccepted)) {
        return SenderPostedPhase.travelerAccepted;
      }
      if (travelerRequests.any((r) => r.isPending)) {
        return SenderPostedPhase.travelerReviewing;
      }
    } else if (activeTravelerRequestCount > 0) {
      return SenderPostedPhase.travelerReviewing;
    }
    return SenderPostedPhase.matchingTravelers;
  }

  /// Sender navigation target for a live delivery (posted flow vs tracking).
  static String senderDetailRouteFor(
    CreatedDelivery delivery, {
    List<TravelerRequestSummary> travelerRequests = const [],
    int activeTravelerRequestCount = 0,
  }) {
    final id = delivery.displayId;
    final status = delivery.status?.trim().toLowerCase();
    if (status != null && status.isNotEmpty && status != 'posted') {
      return '/shipment/$id';
    }

    final phase = postedPhaseFor(
      delivery: delivery,
      travelerRequests: travelerRequests,
      activeTravelerRequestCount: activeTravelerRequestCount,
    );
    return switch (phase) {
      SenderPostedPhase.waitingForReceiver => '/sender-parcel-waiting/$id',
      SenderPostedPhase.matchingTravelers ||
      SenderPostedPhase.travelerReviewing =>
        '/bid-requests/$id',
      SenderPostedPhase.travelerAccepted =>
        '/sender-counter-offer?delivery=$id',
      _ => '/shipment/$id',
    };
  }

  static DeliveryTracking trackingFor(CreatedDelivery delivery) =>
      DeliveryTracking.fromDelivery(delivery);

  static int stepIndexFor(String? status) =>
      DeliveryTracking.progressFromApi(
        status,
        receiverAccepted: true,
      );
}
