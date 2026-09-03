/// Backend delivery status helpers shared by tracking and cancel flows.
abstract final class DeliveryLifecycle {
  /// Open listings — cancel only ≥24h before travel.
  static const openCancellableStatuses = {
    'posted',
    'waiting_receiver',
  };

  /// Booked shipments — cancel through collected; escrow always refunded;
  /// platform fees refunded only when travel is still ≥24h away.
  static const bookingCancellableStatuses = {
    'bid_accepted',
    'matched',
    'ready_for_handoff',
    'collected',
  };

  /// Booked deliveries where a dispute may be opened (escrow / parcel at risk).
  static const disputableStatuses = {
    'bid_accepted',
    'matched',
    'ready_for_handoff',
    'collected',
    'in_transit',
    'delivered',
  };

  /// Receiver may dispute only after the parcel is with the traveler (or delivered).
  static const receiverDisputableStatuses = {
    'collected',
    'in_transit',
    'delivered',
  };

  static bool isDisputable(String? status) =>
      status != null && disputableStatuses.contains(status.trim().toLowerCase());

  static bool isReceiverDisputable(String? status) =>
      status != null &&
      receiverDisputableStatuses.contains(status.trim().toLowerCase());

  static bool isSenderCancellable(String? status) =>
      status != null &&
      (openCancellableStatuses.contains(status) ||
          bookingCancellableStatuses.contains(status));

  static bool isBookingCancellable(String? status) =>
      status != null && bookingCancellableStatuses.contains(status);

  static bool requiresTravelWindowForOpenCancel(String? status) =>
      status != null && openCancellableStatuses.contains(status);
}
