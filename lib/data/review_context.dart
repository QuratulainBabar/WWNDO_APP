import '../core/currency/app_currency.dart';
import 'models/created_delivery.dart';
import 'models/wallet_role.dart';

class ReviewContext {
  const ReviewContext({
    required this.revieweeId,
    required this.revieweeRole,
    required this.revieweeName,
    required this.confirmationMessage,
  });

  final String revieweeId;
  final WalletRole revieweeRole;
  final String revieweeName;
  final String confirmationMessage;
}

String formatReviewPayout(double? amount) {
  if (amount == null || amount <= 0) {
    return '${AppCurrencies.active.symbol.trim()}—';
  }
  return AppCurrencies.active.formatMajor(amount.round());
}

ReviewContext? resolveReviewContext({
  required CreatedDelivery delivery,
  required WalletRole reviewerRole,
  WalletRole? revieweeRole,
}) {
  final shipmentId = delivery.displayId;

  switch (reviewerRole) {
    case WalletRole.sender:
      final travelerId = delivery.travelerId?.trim();
      if (travelerId == null || travelerId.isEmpty) return null;
      final travelerName = _displayName(delivery.travelerName, fallback: 'your traveler');
      final payout = formatReviewPayout(delivery.bidAmount ?? delivery.maxBudget);
      return ReviewContext(
        revieweeId: travelerId,
        revieweeRole: WalletRole.traveler,
        revieweeName: travelerName,
        confirmationMessage:
            '$payout has been released to $travelerName\'s wallet for $shipmentId.',
      );
    case WalletRole.traveler:
      final target = revieweeRole ?? WalletRole.receiver;
      if (target == WalletRole.sender) {
        final senderId = delivery.senderId?.trim();
        if (senderId == null || senderId.isEmpty) return null;
        final senderName = _displayName(delivery.senderName, fallback: 'the sender');
        return ReviewContext(
          revieweeId: senderId,
          revieweeRole: WalletRole.sender,
          revieweeName: senderName,
          confirmationMessage:
              'Delivery $shipmentId complete. How was your experience with $senderName?',
        );
      }
      final receiverId = delivery.receiverId?.trim();
      if (receiverId == null || receiverId.isEmpty) return null;
      final receiverName =
          _displayName(delivery.receiverName, fallback: 'the receiver');
      return ReviewContext(
        revieweeId: receiverId,
        revieweeRole: WalletRole.receiver,
        revieweeName: receiverName,
        confirmationMessage:
            'Delivery $shipmentId complete. How was the handoff with $receiverName?',
      );
    case WalletRole.receiver:
      final travelerId = delivery.travelerId?.trim();
      if (travelerId == null || travelerId.isEmpty) return null;
      final travelerName = _displayName(delivery.travelerName, fallback: 'your traveler');
      return ReviewContext(
        revieweeId: travelerId,
        revieweeRole: WalletRole.traveler,
        revieweeName: travelerName,
        confirmationMessage:
            'Delivery $shipmentId confirmed. How was your experience with $travelerName?',
      );
  }
}

String _displayName(String? raw, {required String fallback}) {
  final trimmed = raw?.trim() ?? '';
  return trimmed.isNotEmpty ? trimmed : fallback;
}
