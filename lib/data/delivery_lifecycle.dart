/// Backend delivery status helpers shared by tracking and cancel flows.
abstract final class DeliveryLifecycle {
  static const senderCancellableStatuses = {
    'posted',
    'waiting_receiver',
    'bid_accepted',
    'matched',
    'ready_for_handoff',
  };

  static bool isSenderCancellable(String? status) =>
      status != null && senderCancellableStatuses.contains(status);
}
