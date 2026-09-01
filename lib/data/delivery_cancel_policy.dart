/// Cancel/refund rules aligned with backend delivery + trip services (24h window).
abstract final class DeliveryCancelPolicy {
  static const int cancelMinHoursBeforeTravel = 24;
  static const int senderCancelMinHoursBeforeTravel =
      cancelMinHoursBeforeTravel;
  static const int travelerCancelMinHoursBeforeTravel =
      cancelMinHoursBeforeTravel;

  static bool canCancelBeforeTravel(
    DateTime travelDate, {
    DateTime? now,
  }) {
    final at = now ?? DateTime.now();
    return travelDate.difference(at) >=
        const Duration(hours: cancelMinHoursBeforeTravel);
  }

  static bool isPlatformFeeRefundableOnCancel(
    DateTime travelDate, {
    DateTime? now,
  }) =>
      canCancelBeforeTravel(travelDate, now: now);

  static bool canSenderCancelBeforeTravel(
    DateTime travelDate, {
    DateTime? now,
  }) =>
      canCancelBeforeTravel(travelDate, now: now);

  static bool canTravelerCancelBeforeTravel(
    DateTime travelDate, {
    DateTime? now,
  }) =>
      canCancelBeforeTravel(travelDate, now: now);

  static String get senderCancelBlockedMessage =>
      'Cancellation is only allowed at least '
      '$senderCancelMinHoursBeforeTravel hours before the flight date.';

  static String get travelerCancelBlockedMessage =>
      'Cancellation is only allowed at least '
      '$travelerCancelMinHoursBeforeTravel hours before the flight date.';

  static String senderBookingCancelResultMessage({
    required bool platformFeesRefunded,
  }) {
    if (platformFeesRefunded) {
      return 'Booking cancelled. Escrow and platform fees refunded.';
    }
    return 'Booking cancelled. Escrow refunded to sender; platform fees kept.';
  }

  static String travelerBookingCancelResultMessage({
    required bool platformFeesRefunded,
  }) {
    if (platformFeesRefunded) {
      return 'Request cancelled. Escrow and platform fees refunded.';
    }
    return 'Request cancelled. Escrow refunded to sender; platform fees kept.';
  }
}
