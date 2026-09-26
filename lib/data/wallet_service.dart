import 'package:flutter/foundation.dart';

import '../core/currency/app_currency.dart';
import 'models/ledger_entry.dart';
import 'models/shipment_escrow.dart';
import 'models/wallet_role.dart';

/// Single wallet balance per user. [WalletRole] tags ledger activity only.
abstract final class WalletService {
  static final walletVersion = ValueNotifier(0);

  static const minimumWithdrawalCents = 1000;

  /// Welcome balance is disabled — new users start at $0, no signup credit.
  static const kycWelcomeCreditCents = 0;
  static const kycWelcomeDescription =
      'Welcome credit after identity verification';

  /// Balance always starts at $0 — no fabricated fallback in any build.
  static const int devZeroBalanceFallbackCents = 0;

  static int get _initialAvailableCents =>
      kDebugMode ? devZeroBalanceFallbackCents : 0;

  static final List<LedgerEntry> _ledger = [];
  static int _availableCents = kDebugMode ? devZeroBalanceFallbackCents : 0;
  static int _escrowCents = 0;

  /// Escrow principal held per shipment.
  static final Map<String, int> _escrowCentsByShipmentId = {};
  static final Set<String> _frozenShipmentIds = {};
  static final Set<String> _refundedShipmentIds = {};
  static final Set<String> _releasedShipmentIds = {};

  /// Maps a backend available balance into the in-app cache amount.
  static int resolveAvailableCents(int backendAvailableCents) {
    if (backendAvailableCents < 0) return 0;
    if (kDebugMode && backendAvailableCents == 0) {
      return devZeroBalanceFallbackCents;
    }
    return backendAvailableCents;
  }

  /// Reset all balances and ledger to empty ($0.00). Used on logout / new user.
  static void resetToEmpty() {
    _ledger.clear();
    _availableCents = _initialAvailableCents;
    _escrowCents = 0;
    _escrowCentsByShipmentId.clear();
    _frozenShipmentIds.clear();
    _refundedShipmentIds.clear();
    _releasedShipmentIds.clear();
    walletVersion.value++;
  }

  /// Welcome balance is disabled — no signup/KYC credit is ever granted.
  static bool grantKycWelcomeCredit() {
    return false;
  }

  /// Replace cached balances / unified history with backend values.
  static void applyRemoteState({
    required int availableCents,
    required int escrowCents,
    List<LedgerEntry> history = const [],
    List<ShipmentEscrow> shipmentEscrows = const [],
  }) {
    _availableCents = resolveAvailableCents(availableCents);
    _escrowCents = escrowCents < 0 ? 0 : escrowCents;

    _ledger
      ..clear()
      ..addAll(history);

    // Related list is only held/frozen — drop stale active rows no longer returned.
    final relatedIds = <String>{
      for (final e in shipmentEscrows)
        if (e.shipmentId.isNotEmpty) e.shipmentId,
    };
    final staleActiveIds = _escrowCentsByShipmentId.keys
        .where(
          (id) =>
              !relatedIds.contains(id) &&
              !_releasedShipmentIds.contains(id) &&
              !_refundedShipmentIds.contains(id),
        )
        .toList();
    for (final id in staleActiveIds) {
      _escrowCentsByShipmentId.remove(id);
      _frozenShipmentIds.remove(id);
    }

    for (final escrow in shipmentEscrows) {
      _applyShipmentEscrow(escrow);
    }
    walletVersion.value++;
  }

  /// Merge a single backend shipment-escrow row into the local cache.
  static void applyRemoteShipmentEscrow(ShipmentEscrow escrow) {
    _applyShipmentEscrow(escrow);
    walletVersion.value++;
  }

  static void _applyShipmentEscrow(ShipmentEscrow escrow) {
    final id = escrow.shipmentId;
    if (id.isEmpty) return;

    _frozenShipmentIds.remove(id);
    _refundedShipmentIds.remove(id);
    _releasedShipmentIds.remove(id);

    switch (escrow.status) {
      case 'held':
        _escrowCentsByShipmentId[id] = escrow.amountCents < 0 ? 0 : escrow.amountCents;
        break;
      case 'frozen':
        _escrowCentsByShipmentId[id] = escrow.amountCents < 0 ? 0 : escrow.amountCents;
        _frozenShipmentIds.add(id);
        break;
      case 'refunded':
        if (escrow.amountCents > 0) {
          _escrowCentsByShipmentId[id] = escrow.amountCents;
        } else {
          _escrowCentsByShipmentId.remove(id);
        }
        _refundedShipmentIds.add(id);
        break;
      case 'released':
        if (escrow.amountCents > 0) {
          _escrowCentsByShipmentId[id] = escrow.amountCents;
        } else {
          _escrowCentsByShipmentId.remove(id);
        }
        _releasedShipmentIds.add(id);
        break;
      default:
        if (escrow.amountCents > 0) {
          _escrowCentsByShipmentId[id] = escrow.amountCents;
        } else {
          _escrowCentsByShipmentId.remove(id);
        }
    }
  }

  static List<LedgerEntry> immutableLedger() {
    return List<LedgerEntry>.unmodifiable(
      _ledger.toList()..sort((a, b) => b.createdAt.compareTo(a.createdAt)),
    );
  }

  /// Unified transaction history (all roles). [role] is ignored — kept for call-site compat.
  static List<LedgerEntry> historyFor([WalletRole? role]) {
    return List<LedgerEntry>.unmodifiable(
      immutableLedger().where((e) => !e.hiddenFromHistory),
    );
  }

  static List<LedgerEntry> ledgerForShipment(String shipmentId) {
    return List<LedgerEntry>.unmodifiable(
      _ledger.where((e) => e.shipmentId == shipmentId).toList()
        ..sort((a, b) => b.createdAt.compareTo(a.createdAt)),
    );
  }

  /// Unified available balance — [role] is ignored (same wallet for all roles).
  static int availableCents([WalletRole? role]) => _availableCents;

  /// Unified escrow balance on this user's wallet (sender-held funds).
  /// [role] is ignored for the ledger total.
  static int escrowCents([WalletRole? role]) => _escrowCents;

  /// Active (held/frozen) escrow still awaiting delivery release.
  /// Used so Travelers can see payouts locked for their shipments even though
  /// the hold lives on the Sender's wallet.
  static int pendingIncomingEscrowCents() {
    var total = 0;
    for (final entry in _escrowCentsByShipmentId.entries) {
      if (_releasedShipmentIds.contains(entry.key)) continue;
      if (_refundedShipmentIds.contains(entry.key)) continue;
      if (entry.value > 0) total += entry.value;
    }
    return total;
  }

  /// Home WalletCard escrow line: Sender shows locked funds; Traveler shows
  /// expected payout still in escrow for their deliveries.
  static int displayEscrowCents(WalletRole role) {
    if (role == WalletRole.traveler) {
      return pendingIncomingEscrowCents();
    }
    return _escrowCents;
  }

  static int escrowCentsForShipment(String shipmentId) =>
      _escrowCentsByShipmentId[shipmentId] ?? 0;

  static bool isEscrowFrozen(String shipmentId) =>
      _frozenShipmentIds.contains(shipmentId);

  static bool isEscrowRefunded(String shipmentId) =>
      _refundedShipmentIds.contains(shipmentId);

  static bool isEscrowReleased(String shipmentId) =>
      _releasedShipmentIds.contains(shipmentId);

  static double availableUsd([WalletRole? role]) => availableCents(role) / 100;

  static double escrowUsd([WalletRole? role]) => escrowCents(role) / 100;

  static double displayEscrowUsd(WalletRole role) =>
      displayEscrowCents(role) / 100;

  static String formatCents(int cents) => AppCurrencies.active.formatCents(cents);

  static String formatMajor(num amount) => AppCurrencies.active.formatMajor(amount);

  static String fieldLabel([String base = 'Amount']) =>
      AppCurrencies.active.fieldLabel(base);

  static String amountFieldLabel([String base = 'Amount']) => fieldLabel(base);

  static String get currencyCode => AppCurrencies.active.code;

  static String get currencySymbol => AppCurrencies.active.symbol;

  static String get currencyPrefix => AppCurrencies.active.prefixText;

  static String? validateWithdrawal(WalletRole role, int amountCents) {
    if (amountCents < minimumWithdrawalCents) {
      return 'Minimum withdrawal is ${formatCents(minimumWithdrawalCents)}';
    }
    if (amountCents > availableCents()) {
      return 'Amount exceeds available balance';
    }
    return null;
  }

  static bool topUpViaStripe({
    required WalletRole role,
    required int amountCents,
  }) {
    if (amountCents <= 0) return false;
    _append(
      LedgerEntry(
        id: 'led-${role.name}-top-${DateTime.now().millisecondsSinceEpoch}',
        role: role,
        type: LedgerEntryType.topUp,
        amountCents: amountCents,
        availableDeltaCents: amountCents,
        description: 'Top-up via Stripe',
        createdAt: DateTime.now(),
      ),
    );
    return true;
  }

  static bool ensureAvailableWithCardFallback({
    required WalletRole role,
    required int amountCents,
  }) {
    if (amountCents <= 0) return true;
    final available = availableCents();
    if (available >= amountCents) return true;
    return topUpViaStripe(role: role, amountCents: amountCents - available);
  }

  static bool withdrawViaStripeConnect({
    required WalletRole role,
    required int amountCents,
  }) {
    final error = validateWithdrawal(role, amountCents);
    if (error != null) return false;

    _append(
      LedgerEntry(
        id: 'led-${role.name}-wd-${DateTime.now().millisecondsSinceEpoch}',
        role: role,
        type: LedgerEntryType.withdrawal,
        amountCents: amountCents,
        availableDeltaCents: -amountCents,
        description: 'Withdrawal via Stripe Connect',
        createdAt: DateTime.now(),
      ),
    );
    return true;
  }

  static bool holdEscrow({
    required WalletRole role,
    required String shipmentId,
    required int amountCents,
    required String description,
  }) {
    if (amountCents <= 0 || availableCents() < amountCents) return false;
    if (_escrowCentsByShipmentId.containsKey(shipmentId)) return false;

    _recordShipmentEscrow(shipmentId, amountCents);
    _append(
      LedgerEntry(
        id: 'led-${role.name}-esc-h-${DateTime.now().millisecondsSinceEpoch}',
        role: role,
        type: LedgerEntryType.escrowHold,
        amountCents: amountCents,
        availableDeltaCents: -amountCents,
        escrowDeltaCents: amountCents,
        shipmentId: shipmentId,
        description: description,
        createdAt: DateTime.now(),
      ),
    );
    return true;
  }

  static bool chargePlatformFee({
    required WalletRole role,
    required String shipmentId,
    required int amountCents,
    required String description,
  }) {
    if (amountCents <= 0 || availableCents() < amountCents) return false;

    _append(
      LedgerEntry(
        id: 'led-${role.name}-fee-${DateTime.now().millisecondsSinceEpoch}',
        role: role,
        type: LedgerEntryType.platformFee,
        amountCents: amountCents,
        availableDeltaCents: -amountCents,
        shipmentId: shipmentId,
        description: description,
        createdAt: DateTime.now(),
      ),
    );
    return true;
  }

  static bool releaseEscrowToTraveler({
    required WalletRole senderRole,
    required WalletRole travelerRole,
    required String shipmentId,
    required String description,
  }) {
    if (_frozenShipmentIds.contains(shipmentId)) return false;
    if (_refundedShipmentIds.contains(shipmentId)) return false;
    if (_releasedShipmentIds.contains(shipmentId)) return false;

    final amountCents = _escrowCentsByShipmentId[shipmentId] ?? 0;
    if (amountCents <= 0 || escrowCents() < amountCents) return false;

    _releasedShipmentIds.add(shipmentId);
    _escrowCentsByShipmentId.remove(shipmentId);

    _append(
      LedgerEntry(
        id: 'led-${senderRole.name}-esc-r-${DateTime.now().millisecondsSinceEpoch}',
        role: senderRole,
        type: LedgerEntryType.escrowRelease,
        amountCents: amountCents,
        escrowDeltaCents: -amountCents,
        shipmentId: shipmentId,
        description: '$description · Escrow released (NFC CP2)',
        createdAt: DateTime.now(),
      ),
    );
    _append(
      LedgerEntry(
        id: 'led-${travelerRole.name}-pay-${DateTime.now().millisecondsSinceEpoch}',
        role: travelerRole,
        type: LedgerEntryType.deliveryPayout,
        amountCents: amountCents,
        availableDeltaCents: amountCents,
        shipmentId: shipmentId,
        description: description,
        createdAt: DateTime.now(),
      ),
    );
    return true;
  }

  static bool refundEscrow({
    required WalletRole role,
    required String shipmentId,
    required String description,
    int? platformFeeRefundCents,
  }) {
    if (_refundedShipmentIds.contains(shipmentId)) return false;
    if (_releasedShipmentIds.contains(shipmentId)) return false;

    final principalCents = _escrowCentsByShipmentId[shipmentId] ?? 0;
    if (principalCents <= 0) return false;

    _refundedShipmentIds.add(shipmentId);
    _frozenShipmentIds.remove(shipmentId);
    _escrowCentsByShipmentId.remove(shipmentId);

    _append(
      LedgerEntry(
        id: 'led-${role.name}-ref-${DateTime.now().millisecondsSinceEpoch}',
        role: role,
        type: LedgerEntryType.refund,
        amountCents: principalCents,
        availableDeltaCents: principalCents,
        escrowDeltaCents: -principalCents,
        shipmentId: shipmentId,
        description: '$description · Escrow principal refunded',
        createdAt: DateTime.now(),
      ),
    );

    final feeRefund = platformFeeRefundCents ?? 0;
    if (feeRefund > 0) {
      _refundPlatformFeeToRole(
        role: role,
        shipmentId: shipmentId,
        amountCents: feeRefund,
      );
    }
    return true;
  }

  static void refundAllPlatformFeesForShipment(String shipmentId) {
    for (final role in WalletRole.values) {
      final netCents = netPlatformFeeCentsCharged(
        role: role,
        shipmentId: shipmentId,
      );
      if (netCents > 0) {
        _refundPlatformFeeToRole(
          role: role,
          shipmentId: shipmentId,
          amountCents: netCents,
        );
      }
    }
  }

  static int netPlatformFeeCentsCharged({
    required WalletRole role,
    required String shipmentId,
  }) {
    var charged = 0;
    var refunded = 0;
    for (final entry in _ledger) {
      if (entry.shipmentId != shipmentId || entry.role != role) continue;
      if (entry.type == LedgerEntryType.platformFee) {
        charged += entry.amountCents;
      } else if (entry.type == LedgerEntryType.refund &&
          entry.description.contains('Platform fee')) {
        refunded += entry.amountCents;
      }
    }
    final net = charged - refunded;
    return net > 0 ? net : 0;
  }

  static void _refundPlatformFeeToRole({
    required WalletRole role,
    required String shipmentId,
    required int amountCents,
  }) {
    if (amountCents <= 0) return;
    _append(
      LedgerEntry(
        id: 'led-${role.name}-fee-ref-${DateTime.now().microsecondsSinceEpoch}',
        role: role,
        type: LedgerEntryType.refund,
        amountCents: amountCents,
        availableDeltaCents: amountCents,
        shipmentId: shipmentId,
        description: '$shipmentId · Platform fee refunded',
        createdAt: DateTime.now(),
      ),
    );
  }

  static void freezeEscrow({
    required WalletRole role,
    required String shipmentId,
    required String description,
  }) {
    if (_releasedShipmentIds.contains(shipmentId)) return;
    if (_refundedShipmentIds.contains(shipmentId)) return;
    if (_frozenShipmentIds.contains(shipmentId)) return;
    if ((_escrowCentsByShipmentId[shipmentId] ?? 0) <= 0) return;

    _frozenShipmentIds.add(shipmentId);
    _append(
      LedgerEntry(
        id: 'led-${role.name}-esc-frz-${DateTime.now().millisecondsSinceEpoch}',
        role: role,
        type: LedgerEntryType.escrowFreeze,
        amountCents: _escrowCentsByShipmentId[shipmentId]!,
        shipmentId: shipmentId,
        description: '$description · Escrow frozen',
        createdAt: DateTime.now(),
      ),
    );
  }

  static void _recordShipmentEscrow(String shipmentId, int amountCents) {
    _escrowCentsByShipmentId[shipmentId] = amountCents;
  }

  static void _append(LedgerEntry entry) {
    _ledger.add(entry);
    _availableCents += entry.availableDeltaCents;
    _escrowCents += entry.escrowDeltaCents;
    walletVersion.value++;
  }
}
