import 'ledger_entry.dart';
import 'shipment_escrow.dart';
import 'wallet_role.dart';

/// Unified wallet balances + recent ledger for the authenticated user.
class WalletSummary {
  const WalletSummary({
    this.contextRole,
    required this.availableCents,
    required this.escrowCents,
    this.currency = 'USD',
    this.minimumWithdrawalCents = 1000,
    this.recentTransactions = const [],
    this.shipmentEscrows = const [],
  });

  /// Optional UI context (active app role) — not a balance partition.
  final WalletRole? contextRole;
  final int availableCents;
  final int escrowCents;
  final String currency;
  final int minimumWithdrawalCents;
  final List<LedgerEntry> recentTransactions;
  final List<ShipmentEscrow> shipmentEscrows;

  double get availableUsd => availableCents / 100;
  double get escrowUsd => escrowCents / 100;

  /// Backward compat for callers that still read `.role`.
  WalletRole get role => contextRole ?? WalletRole.sender;

  factory WalletSummary.empty([WalletRole? contextRole]) => WalletSummary(
        contextRole: contextRole,
        availableCents: 0,
        escrowCents: 0,
      );

  factory WalletSummary.fromJson(
    Map<String, dynamic> json, {
    WalletRole? contextRole,
  }) {
    final roleFromJson = json['role']?.toString();
    final recent = json['recentTransactions'];
    final escrows = json['shipmentEscrows'];
    return WalletSummary(
      contextRole: contextRole ??
          (roleFromJson != null ? WalletRole.fromQuery(roleFromJson) : null),
      availableCents: (json['availableCents'] as num?)?.toInt() ?? 0,
      escrowCents: (json['escrowCents'] as num?)?.toInt() ?? 0,
      currency: (json['currency'] as String?) ?? 'USD',
      minimumWithdrawalCents:
          (json['minimumWithdrawalCents'] as num?)?.toInt() ?? 1000,
      recentTransactions: recent is List
          ? recent
              .whereType<Map>()
              .map((e) => LedgerEntry.fromJson(Map<String, dynamic>.from(e)))
              .toList()
          : const [],
      shipmentEscrows: escrows is List
          ? escrows
              .whereType<Map>()
              .map((e) => ShipmentEscrow.fromJson(Map<String, dynamic>.from(e)))
              .toList()
          : const [],
    );
  }
}
