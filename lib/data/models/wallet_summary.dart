import 'ledger_entry.dart';
import 'wallet_role.dart';

/// Wallet balances + recent ledger for a single role.
class WalletSummary {
  const WalletSummary({
    required this.role,
    required this.availableCents,
    required this.escrowCents,
    this.currency = 'USD',
    this.minimumWithdrawalCents = 1000,
    this.recentTransactions = const [],
  });

  final WalletRole role;
  final int availableCents;
  final int escrowCents;
  final String currency;
  final int minimumWithdrawalCents;
  final List<LedgerEntry> recentTransactions;

  double get availableUsd => availableCents / 100;
  double get escrowUsd => escrowCents / 100;

  /// Empty wallet for a new user with no backend activity.
  factory WalletSummary.empty(WalletRole role) => WalletSummary(
        role: role,
        availableCents: 0,
        escrowCents: 0,
      );

  factory WalletSummary.fromJson(Map<String, dynamic> json) {
    final role = WalletRole.fromQuery(json['role']?.toString());
    final recent = json['recentTransactions'];
    return WalletSummary(
      role: role,
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
    );
  }
}
