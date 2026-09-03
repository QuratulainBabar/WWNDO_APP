import 'models/created_delivery.dart';

/// Platform fee rules aligned with backend `fees.js` (USD).
abstract final class PlatformFees {
  static const double minWalletSenderUsd = 2.0;
  static const double minWalletReceiverUsd = 2.0;
  static const double minWalletTravelerUsd = 3.0;
  static const int maxTravelerRequestsPerDelivery = 2;

  static String get travelerRequestLimitMessage =>
      'You can request at most $maxTravelerRequestsPerDelivery travelers for this parcel.';

  static bool isDocumentCategory(String? category) =>
      (category ?? '').trim().toLowerCase() == 'documents';

  static bool senderPaysReceiverFee(CreatedDelivery delivery) {
    if (delivery.paysReceiverFee) return true;
    return (delivery.platformFeeShare ?? 0) <= 0;
  }

  static bool senderPaysReceiverFeeFrom({
    required String category,
    required double? platformFeeShare,
    bool paysReceiverFee = false,
  }) {
    if (paysReceiverFee) return true;
    if (platformFeeShare != null) return platformFeeShare <= 0;
    return false;
  }

  /// Stored receiver share amount (0 when sender covers receiver fee).
  static double platformFeeShareFor({
    required String category,
    required bool paysReceiverFee,
  }) =>
      paysReceiverFee
          ? 0
          : receiverPlatformFeeUsd(
              category: category,
              paysReceiverFee: false,
            );

  static double senderPlatformFeeUsd({
    required String category,
    required bool paysReceiverFee,
  }) {
    final doc = isDocumentCategory(category);
    if (paysReceiverFee) return doc ? 3.0 : 6.0;
    return doc ? 2.0 : 4.0;
  }

  static double receiverPlatformFeeUsd({
    required String category,
    required bool paysReceiverFee,
  }) {
    if (paysReceiverFee) return 0;
    return isDocumentCategory(category) ? 2.0 : 3.0;
  }

  /// Traveler platform fee — deducted from wallet at NFC CP1 handoff.
  static double travelerPlatformFeeUsd(String category) =>
      isDocumentCategory(category) ? 2.0 : 4.0;

  /// Generic $2 reserve to post. Must not return senderPlatformFeeUsd ($2/$4/$3/$6).
  static double minWalletForSenderCreate({
    required String category,
    required bool paysReceiverFee,
  }) =>
      minWalletSenderUsd;

  static double minWalletForReceiverAccept({
    required String category,
    required bool paysReceiverFee,
  }) {
    final fee = receiverPlatformFeeUsd(
      category: category,
      paysReceiverFee: paysReceiverFee,
    );
    return fee > 0 ? fee : minWalletReceiverUsd;
  }

  static double senderPlatformFeeForDelivery(CreatedDelivery delivery) {
    final paysReceiver = senderPaysReceiverFee(delivery);
    return senderPlatformFeeUsd(
      category: delivery.parcelCategory,
      paysReceiverFee: paysReceiver,
    );
  }

  /// Human-readable sender fee tier for UI copy.
  static String senderPlatformFeeLabel({
    required String category,
    required bool paysReceiverFee,
  }) {
    final fee = senderPlatformFeeUsd(
      category: category,
      paysReceiverFee: paysReceiverFee,
    );
    if (paysReceiverFee) {
      return '\$${fee.toStringAsFixed(2)} (includes receiver fee)';
    }
    return '\$${fee.toStringAsFixed(2)}';
  }

  static double receiverPlatformFeeForDelivery(CreatedDelivery delivery) {
    final paysReceiver = senderPaysReceiverFee(delivery);
    if (paysReceiver) return 0;
    final share = delivery.platformFeeShare;
    if (share != null && share > 0) return share;
    return receiverPlatformFeeUsd(
      category: delivery.parcelCategory,
      paysReceiverFee: false,
    );
  }
}
