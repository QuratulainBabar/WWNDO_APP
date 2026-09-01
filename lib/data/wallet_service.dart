import 'package:flutter/foundation.dart';

import 'models/ledger_entry.dart';
import 'models/shipment_escrow.dart';
import 'models/wallet_role.dart';

/// Role-aware wallet balances, per-shipment escrow, and immutable cents ledger.
///
/// Display amounts come from the backend via [applyRemoteState]. Local mutation
/// helpers remain for in-app shipment flows until those are fully API-backed.
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
  static final Map<WalletRole, int> _availableCents = {
    WalletRole.sender: kDebugMode ? devZeroBalanceFallbackCents : 0,
    WalletRole.traveler: kDebugMode ? devZeroBalanceFallbackCents : 0,
    WalletRole.receiver: kDebugMode ? devZeroBalanceFallbackCents : 0,
  };
  static final Map<WalletRole, int> _escrowCents = {
    WalletRole.sender: 0,
    WalletRole.traveler: 0,
    WalletRole.receiver: 0,
  };

  /// Escrow principal held per shipment.
  static final Map<String, int> _escrowCentsByShipmentId = {};
  static final Set<String> _frozenShipmentIds = {};
  static final Set<String> _refundedShipmentIds = {};
  static final Set<String> _releasedShipmentIds = {};

  /// Maps a backend available balance into the in-app cache amount.
  /// In debug builds, a $0 backend balance becomes [devZeroBalanceFallbackCents].
  static int resolveAvailableCents(int backendAvailableCents) {
    if (backendAvailableCents < 0) return 0;
    if (kDebugMode && backendAvailableCents == 0) {
      return devZeroBalanceFallbackCents;
    }
    return backendAvailableCents;
  }

  /// Reset all balances and ledger to empty ($0.00). Used on logout / new user.
  /// In debug builds, reseeds the $10 testing fallback instead of true zero.
  static void resetToEmpty() {
    _ledger.clear();
    final available = _initialAvailableCents;
    _availableCents
      ..[WalletRole.sender] = available
      ..[WalletRole.traveler] = available
      ..[WalletRole.receiver] = available;
    _escrowCents
      ..[WalletRole.sender] = 0
      ..[WalletRole.traveler] = 0
      ..[WalletRole.receiver] = 0;
    _escrowCentsByShipmentId.clear();
    _frozenShipmentIds.clear();
    _refundedShipmentIds.clear();
    _releasedShipmentIds.clear();
    walletVersion.value++;
  }

  /// Welcome balance is disabled — no signup/KYC credit is ever granted.
  /// Kept as a no-op so existing callers continue to compile and run.
  static bool grantKycWelcomeCredit() {
    return false;
  }

  /// Replace cached balances / history for [role] with backend values.
  static void applyRemoteState({
    required WalletRole role,
    required int availableCents,
    required int escrowCents,
    List<LedgerEntry> history = const [],
    List<ShipmentEscrow> shipmentEscrows = const [],
  }) {
    _availableCents[role] = resolveAvailableCents(availableCents);
    _escrowCents[role] = escrowCents < 0 ? 0 : escrowCents;

    _ledger.removeWhere((e) => e.role == role);
    _ledger.addAll(history.where((e) => e.role == role));
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

  static List<LedgerEntry> immutableLedgerFor(WalletRole role) {
    return List<LedgerEntry>.unmodifiable(
      _ledger.where((e) => e.role == role).toList()
        ..sort((a, b) => b.createdAt.compareTo(a.createdAt)),
    );
  }

  /// Visible Transaction History rows (excludes [LedgerEntry.hiddenFromHistory]).
  static List<LedgerEntry> historyFor(WalletRole role) {
    return List<LedgerEntry>.unmodifiable(
      immutableLedgerFor(role).where((e) => !e.hiddenFromHistory),
    );
  }

  static List<LedgerEntry> ledgerForShipment(String shipmentId) {
    return List<LedgerEntry>.unmodifiable(
      _ledger.where((e) => e.shipmentId == shipmentId).toList()
        ..sort((a, b) => b.createdAt.compareTo(a.createdAt)),
    );
  }

  static int availableCents(WalletRole role) => _availableCents[role] ?? 0;

  static int escrowCents(WalletRole role) => _escrowCents[role] ?? 0;

  static int escrowCentsForShipment(String shipmentId) =>
      _escrowCentsByShipmentId[shipmentId] ?? 0;

  static bool isEscrowFrozen(String shipmentId) =>
      _frozenShipmentIds.contains(shipmentId);

  static bool isEscrowRefunded(String shipmentId) =>
      _refundedShipmentIds.contains(shipmentId);

  static bool isEscrowReleased(String shipmentId) =>
      _releasedShipmentIds.contains(shipmentId);

  static double availableUsd(WalletRole role) => availableCents(role) / 100;

  static double escrowUsd(WalletRole role) => escrowCents(role) / 100;

  static String formatCents(int cents) => '\$${(cents / 100).toStringAsFixed(2)}';

  static String? validateWithdrawal(WalletRole role, int amountCents) {
    if (amountCents < minimumWithdrawalCents) {
      return 'Minimum withdrawal is ${formatCents(minimumWithdrawalCents)}';
    }
    if (amountCents > availableCents(role)) {
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

  /// Ensures [role] has at least [amountCents] available.
  /// If the wallet is short, the shortfall is charged via mock Stripe card.
  static bool ensureAvailableWithCardFallback({
    required WalletRole role,
    required int amountCents,
  }) {
    if (amountCents <= 0) return true;
    final available = availableCents(role);
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

  /// Holds escrow for [shipmentId]. Returns false if balance is insufficient
  /// or escrow was already held for this shipment.
  static bool holdEscrow({
    required WalletRole role,
    required String shipmentId,
    required int amountCents,
    required String description,
  }) {
    if (amountCents <= 0 || availableCents(role) < amountCents) return false;
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

  /// Charges a platform fee. Returns false if balance is insufficient.
  static bool chargePlatformFee({
    required WalletRole role,
    required String shipmentId,
    required int amountCents,
    required String description,
  }) {
    if (amountCents <= 0 || availableCents(role) < amountCents) return false;

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
    if (amountCents <= 0 || escrowCents(senderRole) < amountCents) return false;

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

  /// Credits back net platform fees charged to every role for [shipmentId].
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

  /// Net platform fees still held for [role] on [shipmentId] (charged − refunded).
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
    _availableCents[entry.role] =
        (_availableCents[entry.role] ?? 0) + entry.availableDeltaCents;
    _escrowCents[entry.role] =
        (_escrowCents[entry.role] ?? 0) + entry.escrowDeltaCents;
    walletVersion.value++;
  }
}
