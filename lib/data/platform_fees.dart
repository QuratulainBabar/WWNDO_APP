import '../core/currency/app_currency.dart';
import 'models/created_delivery.dart';

/// Platform fee rules aligned with backend `fees.js`.
abstract final class PlatformFees {
  static const double minWalletSenderUsd = 2.0;
  static const double minWalletReceiverUsd = 2.0;
  static const double minWalletTravelerUsd = 3.0;

  /// Traveler platform fee — always $3 for Document and Object.
  static const double travelerPlatformFeeAmountUsd = 3.0;
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
    // Same for Document and Object: $2, or $3 when sender covers receiver fee.
    if (paysReceiverFee) return 3.0;
    return 2.0;
  }

  static double receiverPlatformFeeUsd({
    required String category,
    required bool paysReceiverFee,
  }) {
    if (paysReceiverFee) return 0;
    // Same for Document and Object.
    return 2.0;
  }

  /// Traveler platform fee — charged at sender Pay Now (wallet first, then card).
  /// Always $3 for Document and Object.
  static double travelerPlatformFeeUsd(String category) =>
      travelerPlatformFeeAmountUsd;

  static String travelerPlatformFeeLabel({required String category}) {
    final fee = travelerPlatformFeeUsd(category);
    return '${AppCurrencies.active.formatMajor(fee)} (charged at Pay Now)';
  }

  /// Generic $2 reserve to post. Must not return senderPlatformFeeUsd ($2/$3).
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
    return fee;
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
      return '${AppCurrencies.active.formatMajor(fee)} (includes receiver fee)';
    }
    return AppCurrencies.active.formatMajor(fee);
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
