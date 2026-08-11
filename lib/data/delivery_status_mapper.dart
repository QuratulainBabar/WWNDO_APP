import 'models/created_delivery.dart';
import 'models/delivery_tracking.dart';
import 'models/shipment.dart';

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
    required int activeTravelerRequestCount,
  }) {
    if (delivery.status != 'posted') return null;
    if (!delivery.isReceiverAccepted) {
      return SenderPostedPhase.waitingForReceiver;
    }
    if (activeTravelerRequestCount > 0) {
      return SenderPostedPhase.travelerReviewing;
    }
    return SenderPostedPhase.matchingTravelers;
  }

  static DeliveryTracking trackingFor(CreatedDelivery delivery) =>
      DeliveryTracking.fromDelivery(delivery);

  static int stepIndexFor(String? status) =>
      DeliveryTracking.progressFromApi(
        status,
        receiverAccepted: true,
      );
}
