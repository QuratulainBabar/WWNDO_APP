import 'created_delivery.dart';
import 'shipment.dart';

/// Timeline labels and progress derived from API delivery status or demo shipment state.
class DeliveryTracking {
  const DeliveryTracking({
    required this.stepLabels,
    required this.progress,
  });

  final List<String> stepLabels;
  final int progress;

  static const stepCount = 5;

  static List<String> stepLabelsFor({required bool travelerSelected}) => [
        'Open',
        travelerSelected ? 'Traveler Selected' : 'Receiver Accepted',
        'Collected',
        'In Transit',
        'Delivered',
      ];

  static bool isTravelerSelectedApi(String? status) {
    switch (status?.trim().toLowerCase()) {
      case 'matched':
      case 'collected':
      case 'in_transit':
      case 'delivered':
        return true;
      default:
        return false;
    }
  }

  static int progressFromApi(String? status, {required bool receiverAccepted}) {
    switch (status?.trim().toLowerCase()) {
      case 'posted':
        return receiverAccepted ? 2 : 1;
      case 'matched':
        return 2;
      case 'collected':
        return 3;
      case 'in_transit':
        return 4;
      case 'delivered':
        return 5;
      case 'cancelled':
        return 1;
      default:
        return 1;
    }
  }

  factory DeliveryTracking.fromDelivery(CreatedDelivery delivery) {
    final status = delivery.status;
    final travelerSelected = isTravelerSelectedApi(status);
    return DeliveryTracking(
      stepLabels: stepLabelsFor(travelerSelected: travelerSelected),
      progress: progressFromApi(
        status,
        receiverAccepted: delivery.isReceiverAccepted,
      ),
    );
  }

  /// Demo/static shipment detail — uses effective status and sender posted phase.
  factory DeliveryTracking.fromShipmentContext({
    required ShipmentStatus effectiveStatus,
    required SenderPostedPhase? postedPhase,
    required int effectiveStepIndex,
  }) {
    final travelerSelected = switch (effectiveStatus) {
      ShipmentStatus.open =>
        postedPhase == SenderPostedPhase.travelerSelected,
      ShipmentStatus.disputed => effectiveStepIndex >= 2,
      _ => true,
    };

    final progress = effectiveStatus == ShipmentStatus.open
        ? (postedPhase == SenderPostedPhase.waitingForReceiver ? 1 : 2)
        : effectiveStepIndex;

    return DeliveryTracking(
      stepLabels: stepLabelsFor(travelerSelected: travelerSelected),
      progress: progress,
    );
  }
}
