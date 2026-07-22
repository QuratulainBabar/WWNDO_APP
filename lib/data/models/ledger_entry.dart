import 'wallet_role.dart';

enum LedgerEntryType {
  topUp,
  withdrawal,
  escrowHold,
  escrowRelease,
  escrowFreeze,
  deliveryPayout,
  platformFee,
  refund,
}

/// Immutable append-only ledger row. Amounts are stored in USD cents.
class LedgerEntry {
  const LedgerEntry({
    required this.id,
    required this.role,
    required this.type,
    required this.amountCents,
    required this.description,
    required this.createdAt,
    this.shipmentId,
    this.escrowDeltaCents = 0,
    this.availableDeltaCents = 0,
    this.hiddenFromHistory = false,
  });

  final String id;
  final WalletRole role;
  final LedgerEntryType type;
  final int amountCents;
  final int availableDeltaCents;
  final int escrowDeltaCents;
  final String description;
  final DateTime createdAt;
  final String? shipmentId;

  /// When true, omitted from Transaction History UI (still affects balances).
  final bool hiddenFromHistory;

  bool get isCredit => availableDeltaCents > 0 || escrowDeltaCents > 0;
}
