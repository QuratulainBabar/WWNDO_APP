import 'package:flutter/foundation.dart';

import 'models/ledger_entry.dart';
import 'models/wallet_role.dart';

/// Role-aware wallet balances, per-shipment escrow, and immutable cents ledger.
abstract final class WalletService {
  static final walletVersion = ValueNotifier(0);

  static final List<LedgerEntry> _ledger = [];
  static final Map<WalletRole, int> _availableCents = {
    WalletRole.sender: 0,
    WalletRole.traveler: 0,
    WalletRole.receiver: 0,
  };
  static final Map<WalletRole, int> _escrowCents = {
    WalletRole.sender: 0,
    WalletRole.traveler: 0,
    WalletRole.receiver: 0,
  };

  /// Escrow principal held per shipment (sender role).
  static final Map<String, int> _escrowCentsByShipmentId = {};
  static final Set<String> _frozenShipmentIds = {};
  static final Set<String> _refundedShipmentIds = {};
  static final Set<String> _releasedShipmentIds = {};

  static bool _seeded = false;

  /// Bump when demo ledger history visibility changes so hot reload re-seeds.
  static const _seedGeneration = 4;
  static int _appliedSeedGeneration = 0;

  /// Transaction History shows a short demo ledger only (all roles).
  static const _historyLimit = 2;

  static const minimumWithdrawalCents = 1000;

  static void seedDemoLedger() {
    if (_appliedSeedGeneration == _seedGeneration && _seeded) return;
    _appliedSeedGeneration = _seedGeneration;
    _seeded = true;

    _ledger.clear();
    _availableCents
      ..[WalletRole.sender] = 0
      ..[WalletRole.traveler] = 0
      ..[WalletRole.receiver] = 0;
    _escrowCents
      ..[WalletRole.sender] = 0
      ..[WalletRole.traveler] = 0
      ..[WalletRole.receiver] = 0;
    _escrowCentsByShipmentId.clear();
    _frozenShipmentIds.clear();
    _refundedShipmentIds.clear();
    _releasedShipmentIds.clear();

    // Fund wallets first so platform-fee seed rows never go negative.
    _append(
      LedgerEntry(
        id: 'led-s-top',
        role: WalletRole.sender,
        type: LedgerEntryType.topUp,
        amountCents: 25000,
        availableDeltaCents: 25000,
        description: 'Top-up via Stripe',
        createdAt: DateTime(2026, 6, 1),
      ),
    );
    _append(
      LedgerEntry(
        id: 'led-t-pay',
        role: WalletRole.traveler,
        type: LedgerEntryType.deliveryPayout,
        amountCents: 20600,
        availableDeltaCents: 20600,
        shipmentId: 'WW-33104',
        description: 'WW-33104 · Delivery payout',
        createdAt: DateTime(2026, 5, 30),
      ),
    );
    _append(
      LedgerEntry(
        id: 'led-t-wd',
        role: WalletRole.traveler,
        type: LedgerEntryType.withdrawal,
        amountCents: 5000,
        availableDeltaCents: -5000,
        description: 'Withdrawal via Stripe Connect · Barclays',
        createdAt: DateTime(2026, 5, 18),
      ),
    );
    _append(
      LedgerEntry(
        id: 'led-r-top',
        role: WalletRole.receiver,
        type: LedgerEntryType.topUp,
        amountCents: 18400,
        availableDeltaCents: 18400,
        description: 'Top-up via Stripe',
        createdAt: DateTime(2026, 6, 8),
      ),
    );

    void holdEscrowSeed({
      required String shipmentId,
      required int amountCents,
      required DateTime at,
      bool hiddenFromHistory = false,
    }) {
      _recordShipmentEscrow(shipmentId, amountCents);
      _append(
        LedgerEntry(
          id: 'led-s-esc-$shipmentId',
          role: WalletRole.sender,
          type: LedgerEntryType.escrowHold,
          amountCents: amountCents,
          availableDeltaCents: -amountCents,
          escrowDeltaCents: amountCents,
          shipmentId: shipmentId,
          description: '$shipmentId · Escrow hold',
          createdAt: at,
          hiddenFromHistory: hiddenFromHistory,
        ),
      );
    }

    void chargeDocFeesSeed(
      String shipmentId,
      DateTime at, {
      bool hideSenderFromHistory = false,
    }) {
      for (final role in [
        WalletRole.sender,
        WalletRole.traveler,
        WalletRole.receiver,
      ]) {
        _append(
          LedgerEntry(
            id: 'led-${role.name}-fee-$shipmentId',
            role: role,
            type: LedgerEntryType.platformFee,
            amountCents: 200,
            availableDeltaCents: -200,
            shipmentId: shipmentId,
            description: '$shipmentId · Platform fee',
            createdAt: at,
            hiddenFromHistory: role == WalletRole.traveler ||
                (hideSenderFromHistory && role == WalletRole.sender),
          ),
        );
      }
    }

    // Older demo rows stay on the ledger for balances/escrow, but are hidden
    // from sender Transaction History (blue-circle items).
    holdEscrowSeed(
      shipmentId: 'WW-48291',
      amountCents: 2350,
      at: DateTime(2026, 6, 10),
      hiddenFromHistory: true,
    );
    chargeDocFeesSeed(
      'WW-48291',
      DateTime(2026, 6, 10),
      hideSenderFromHistory: true,
    );

    holdEscrowSeed(
      shipmentId: 'WW-61023',
      amountCents: 3500,
      at: DateTime(2026, 6, 5),
      hiddenFromHistory: true,
    );
    chargeDocFeesSeed(
      'WW-61023',
      DateTime(2026, 6, 5),
      hideSenderFromHistory: true,
    );

    // Collected, ≥24h before travel — escrow + fees refunded on cancel.
    holdEscrowSeed(
      shipmentId: 'WW-74011',
      amountCents: 3000,
      at: DateTime(2026, 7, 10),
    );
    chargeDocFeesSeed(
      'WW-74011',
      DateTime(2026, 7, 10),
      hideSenderFromHistory: true,
    );

    // Receiver cancel demo <24h — escrow refunded, fees kept on cancel.
    holdEscrowSeed(
      shipmentId: 'WW-74022',
      amountCents: 2600,
      at: DateTime(2026, 7, 16),
    );
    chargeDocFeesSeed('WW-74022', DateTime(2026, 7, 16));
  }

  static List<LedgerEntry> immutableLedgerFor(WalletRole role) {
    seedDemoLedger();
    return List<LedgerEntry>.unmodifiable(
      _ledger.where((e) => e.role == role).toList()
        ..sort((a, b) => b.createdAt.compareTo(a.createdAt)),
    );
  }

  /// Visible Transaction History rows (excludes [LedgerEntry.hiddenFromHistory]).
  /// Capped to [_historyLimit] demo rows per role.
  static List<LedgerEntry> historyFor(WalletRole role) {
    final visible = immutableLedgerFor(role)
        .where((e) => !e.hiddenFromHistory)
        .toList();
    if (visible.length > _historyLimit) {
      return List<LedgerEntry>.unmodifiable(visible.take(_historyLimit));
    }
    return List<LedgerEntry>.unmodifiable(visible);
  }

  static List<LedgerEntry> ledgerForShipment(String shipmentId) {
    seedDemoLedger();
    return List<LedgerEntry>.unmodifiable(
      _ledger.where((e) => e.shipmentId == shipmentId).toList()
        ..sort((a, b) => b.createdAt.compareTo(a.createdAt)),
    );
  }

  static int availableCents(WalletRole role) {
    seedDemoLedger();
    return _availableCents[role] ?? 0;
  }

  static int escrowCents(WalletRole role) {
    seedDemoLedger();
    return _escrowCents[role] ?? 0;
  }

  static int escrowCentsForShipment(String shipmentId) {
    seedDemoLedger();
    return _escrowCentsByShipmentId[shipmentId] ?? 0;
  }

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
    seedDemoLedger();
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
    seedDemoLedger();
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
    seedDemoLedger();
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
