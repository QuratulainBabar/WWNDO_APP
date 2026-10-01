import '../core/currency/app_currency.dart';
import 'models/created_delivery.dart';
import 'models/wallet_role.dart';

enum ReviewConfirmationKind {
  /// Sender → traveler: escrow payout released.
  payoutReleasedToTraveler,

  /// Traveler → sender, or generic experience after delivery complete.
  deliveryCompleteExperience,

  /// Traveler → receiver handoff.
  deliveryCompleteHandoff,

  /// Receiver → traveler (or sender demo) after delivery confirmed.
  deliveryConfirmedExperience,
}

class ReviewContext {
  const ReviewContext({
    required this.revieweeId,
    required this.revieweeRole,
    required this.revieweeName,
    required this.shipmentId,
    required this.kind,
    this.payoutAmount,
  });

  final String revieweeId;
  final WalletRole revieweeRole;
  final String revieweeName;
  final String shipmentId;
  final ReviewConfirmationKind kind;

  /// Formatted payout amount for [ReviewConfirmationKind.payoutReleasedToTraveler].
  final String? payoutAmount;
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
      final travelerName = _displayName(delivery.travelerName);
      final payout =
          formatReviewPayout(delivery.bidAmount ?? delivery.maxBudget);
      return ReviewContext(
        revieweeId: travelerId,
        revieweeRole: WalletRole.traveler,
        revieweeName: travelerName ?? '',
        shipmentId: shipmentId,
        kind: ReviewConfirmationKind.payoutReleasedToTraveler,
        payoutAmount: payout,
      );
    case WalletRole.traveler:
      final target = revieweeRole ?? WalletRole.receiver;
      if (target == WalletRole.sender) {
        final senderId = delivery.senderId?.trim();
        if (senderId == null || senderId.isEmpty) return null;
        final senderName = _displayName(delivery.senderName);
        return ReviewContext(
          revieweeId: senderId,
          revieweeRole: WalletRole.sender,
          revieweeName: senderName ?? '',
          shipmentId: shipmentId,
          kind: ReviewConfirmationKind.deliveryCompleteExperience,
        );
      }
      final receiverId = delivery.receiverId?.trim();
      if (receiverId == null || receiverId.isEmpty) return null;
      final receiverName = _displayName(delivery.receiverName);
      return ReviewContext(
        revieweeId: receiverId,
        revieweeRole: WalletRole.receiver,
        revieweeName: receiverName ?? '',
        shipmentId: shipmentId,
        kind: ReviewConfirmationKind.deliveryCompleteHandoff,
      );
    case WalletRole.receiver:
      final travelerId = delivery.travelerId?.trim();
      if (travelerId == null || travelerId.isEmpty) return null;
      final travelerName = _displayName(delivery.travelerName);
      return ReviewContext(
        revieweeId: travelerId,
        revieweeRole: WalletRole.traveler,
        revieweeName: travelerName ?? '',
        shipmentId: shipmentId,
        kind: ReviewConfirmationKind.deliveryConfirmedExperience,
      );
  }
}

String? _displayName(String? raw) {
  final trimmed = raw?.trim() ?? '';
  return trimmed.isNotEmpty ? trimmed : null;
}
