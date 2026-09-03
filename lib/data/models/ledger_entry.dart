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

  /// User-facing description without Stripe Payment Intent IDs.
  String get displayDescription => description
      .replaceAll(RegExp(r'\s*\((?:pi_|mock_pi_)[A-Za-z0-9_]+\)'), '')
      .trim();

  factory LedgerEntry.fromJson(Map<String, dynamic> json) {
    return LedgerEntry(
      id: json['id']?.toString() ?? '',
      role: WalletRole.fromQuery(json['role']?.toString()),
      type: _parseType(json['type']?.toString()),
      amountCents: (json['amountCents'] as num?)?.toInt() ?? 0,
      availableDeltaCents: (json['availableDeltaCents'] as num?)?.toInt() ?? 0,
      escrowDeltaCents: (json['escrowDeltaCents'] as num?)?.toInt() ?? 0,
      description: (json['description'] as String?) ?? '',
      shipmentId: json['shipmentId']?.toString(),
      hiddenFromHistory: json['hiddenFromHistory'] as bool? ?? false,
      createdAt: DateTime.tryParse(json['createdAt']?.toString() ?? '') ??
          DateTime.now(),
    );
  }

  static LedgerEntryType _parseType(String? raw) {
    switch (raw) {
      case 'topUp':
      case 'top_up':
        return LedgerEntryType.topUp;
      case 'withdrawal':
        return LedgerEntryType.withdrawal;
      case 'escrowHold':
      case 'escrow_hold':
        return LedgerEntryType.escrowHold;
      case 'escrowRelease':
      case 'escrow_release':
        return LedgerEntryType.escrowRelease;
      case 'escrowFreeze':
      case 'escrow_freeze':
        return LedgerEntryType.escrowFreeze;
      case 'deliveryPayout':
      case 'delivery_payout':
        return LedgerEntryType.deliveryPayout;
      case 'platformFee':
      case 'platform_fee':
        return LedgerEntryType.platformFee;
      case 'refund':
        return LedgerEntryType.refund;
      default:
        return LedgerEntryType.topUp;
    }
  }
}
