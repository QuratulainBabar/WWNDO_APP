import 'models/created_delivery.dart';

/// Platform fee rules aligned with backend `fees.js` (USD).
abstract final class PlatformFees {
  static const double minWalletSenderUsd = 2.0;
  static const double minWalletReceiverUsd = 2.0;
  static const double minWalletTravelerUsd = 2.0;
  static const int maxTravelerRequestsPerDelivery = 2;

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
    return isDocumentCategory(category) ? 2.0 : 4.0;
  }

  static double minWalletForSenderCreate({
    required String category,
    required bool paysReceiverFee,
  }) =>
      minWalletSenderUsd;

  static double minWalletForReceiverAccept({
    required String category,
    required bool paysReceiverFee,
  }) =>
      minWalletReceiverUsd;

  static double senderPlatformFeeForDelivery(CreatedDelivery delivery) {
    final paysReceiver = senderPaysReceiverFee(delivery);
    return delivery.platformFee ??
        senderPlatformFeeUsd(
          category: delivery.parcelCategory,
          paysReceiverFee: paysReceiver,
        );
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
