import 'package:flutter/foundation.dart';

import '../core/api/api_exception.dart';
import '../core/config/demo_mode.dart';
import '../core/payments/stripe_payments.dart';
import '../data/models/ledger_entry.dart';
import '../data/models/shipment_escrow.dart';
import '../data/models/wallet_role.dart';
import '../data/models/wallet_summary.dart';
import '../data/services/auth_repository.dart';
import '../data/services/wallet_repository.dart';
import '../data/wallet_service.dart';

/// Loads unified wallet balance, escrow, and transaction history from the API.
class WalletProvider extends ChangeNotifier {
  WalletProvider({
    required AuthRepository authRepository,
    DemoModeProvider? demoMode,
    WalletRepository? walletRepository,
  })  : _authRepository = authRepository,
        _demoMode = demoMode,
        _walletRepository = walletRepository ??
            WalletRepository(
              apiClient: authRepository.apiClient,
              demoMode: demoMode,
            );

  final AuthRepository _authRepository;
  final WalletRepository _walletRepository;
  final DemoModeProvider? _demoMode;

  bool _loading = false;
  bool get loading => _loading;

  String? _error;
  String? get error => _error;

  WalletSummary? _summary;
  WalletSummary? get summary => _summary;

  List<LedgerEntry> _transactions = const [];
  List<LedgerEntry> get transactions => _transactions;

  bool get isDemoMode => _demoMode?.enabled ?? false;

  /// Unified balance — [role] is ignored (same wallet for all roles).
  int availableCents([WalletRole? role]) => WalletService.availableCents();

  int escrowCents([WalletRole? role]) =>
      _summary?.escrowCents ?? WalletService.escrowCents();

  /// Unified transaction history across sender, traveler, and receiver activity.
  List<LedgerEntry> historyFor([WalletRole? role]) {
    if (_transactions.isNotEmpty) {
      return _transactions;
    }
    if (_summary != null && _summary!.recentTransactions.isNotEmpty) {
      return _summary!.recentTransactions;
    }
    return WalletService.historyFor();
  }

  /// Fetch unified balances + transaction history.
  /// [contextRole] is optional UI context only (e.g. active app role).
  Future<WalletSummary> refresh(
    WalletRole? contextRole, {
    bool silent = false,
    bool includeFullHistory = false,
  }) async {
    if (!silent) {
      _loading = true;
      _error = null;
      notifyListeners();
    }

    try {
      if (isDemoMode || _authRepository.currentUser == null) {
        final empty = WalletSummary.empty(contextRole);
        _apply(empty, transactions: const []);
        return empty;
      }

      final ok = await _authRepository.ensureAuthenticated();
      if (!ok) {
        throw const ApiException(
          message: 'Please sign in again to continue.',
          code: 'UNAUTHORIZED',
          statusCode: 401,
        );
      }

      final summary =
          await _walletRepository.fetchSummary(contextRole: contextRole);
      List<LedgerEntry> history = summary.recentTransactions;
      if (includeFullHistory) {
        history = await _walletRepository.fetchTransactions();
      }

      _apply(summary, transactions: history);
      return summary;
    } on ApiException catch (e) {
      final empty = WalletSummary.empty(contextRole);
      _apply(empty, transactions: const []);
      if (!silent) {
        _error = e.message;
        rethrow;
      }
      return empty;
    } catch (e) {
      final empty = WalletSummary.empty(contextRole);
      _apply(empty, transactions: const []);
      if (!silent) {
        _error = 'Unable to load wallet.';
        rethrow;
      }
      return empty;
    } finally {
      if (!silent) {
        _loading = false;
        notifyListeners();
      }
    }
  }

  Future<void> topUp({
    required WalletRole role,
    required int amountCents,
  }) async {
    _loading = true;
    _error = null;
    notifyListeners();
    try {
      if (isDemoMode) {
        WalletService.topUpViaStripe(role: role, amountCents: amountCents);
        await refresh(role, silent: true);
        return;
      }

      await StripePayments.ensureConfigured(_walletRepository);

      try {
        await _walletRepository.topUp(role: role, amountCents: amountCents);
      } on ApiException catch (e) {
        if (!e.requiresPayment || e.clientSecret == null) rethrow;
        await StripePayments.presentPaymentSheet(clientSecret: e.clientSecret!);
        final intentId = e.paymentIntentId;
        if (intentId == null || intentId.isEmpty) {
          throw const ApiException(
            message: 'Payment completed but intent id is missing.',
            code: 'PAYMENT_INCOMPLETE',
          );
        }
        await _walletRepository.confirmTopUp(
          paymentIntentId: intentId,
          contextRole: role,
        );
      }

      await refresh(role, silent: true, includeFullHistory: true);
    } on ApiException catch (e) {
      _error = e.message;
      rethrow;
    } finally {
      _loading = false;
      notifyListeners();
    }
  }

  Future<void> ensureKycWelcomeCredit() async {
    try {
      if (isDemoMode || _authRepository.currentUser == null) {
        WalletService.grantKycWelcomeCredit();
        notifyListeners();
        return;
      }

      final ok = await _authRepository.ensureAuthenticated();
      if (!ok) return;

      final summary = await _walletRepository.grantKycWelcomeCredit();
      if (summary != null) {
        _apply(summary, transactions: summary.recentTransactions);
      } else {
        await refresh(null, silent: true);
      }
    } catch (e) {
      debugPrint('KYC welcome credit failed: $e');
      WalletService.grantKycWelcomeCredit();
      notifyListeners();
    }
  }

  Future<void> withdraw({
    required WalletRole role,
    required int amountCents,
  }) async {
    _loading = true;
    _error = null;
    notifyListeners();
    try {
      if (isDemoMode) {
        final ok = WalletService.withdrawViaStripeConnect(
          role: role,
          amountCents: amountCents,
        );
        if (!ok) {
          throw ApiException(
            message: WalletService.validateWithdrawal(role, amountCents) ??
                'Withdrawal failed',
            code: 'VALIDATION_ERROR',
          );
        }
        await refresh(role, silent: true);
        return;
      }
      await _walletRepository.withdraw(role: role, amountCents: amountCents);
      await refresh(role, silent: true, includeFullHistory: true);
    } on ApiException catch (e) {
      _error = e.message;
      rethrow;
    } finally {
      _loading = false;
      notifyListeners();
    }
  }

  Future<ShipmentEscrow> refreshShipmentEscrow(String shipmentId) async {
    if (shipmentId.trim().isEmpty) {
      return ShipmentEscrow.none(shipmentId);
    }

    if (isDemoMode || _authRepository.currentUser == null) {
      final cached = WalletService.escrowCentsForShipment(shipmentId);
      final status = WalletService.isEscrowReleased(shipmentId)
          ? 'released'
          : WalletService.isEscrowRefunded(shipmentId)
              ? 'refunded'
              : WalletService.isEscrowFrozen(shipmentId)
                  ? 'frozen'
                  : cached > 0
                      ? 'held'
                      : 'none';
      return ShipmentEscrow(
        shipmentId: shipmentId,
        amountCents: cached,
        status: status,
      );
    }

    try {
      final escrow = await _walletRepository.fetchShipmentEscrow(shipmentId);
      WalletService.applyRemoteShipmentEscrow(escrow);
      notifyListeners();
      return escrow;
    } catch (e) {
      debugPrint('Shipment escrow fetch failed: $e');
      return ShipmentEscrow(
        shipmentId: shipmentId,
        amountCents: WalletService.escrowCentsForShipment(shipmentId),
        status: WalletService.isEscrowReleased(shipmentId)
            ? 'released'
            : WalletService.isEscrowRefunded(shipmentId)
                ? 'refunded'
                : WalletService.isEscrowFrozen(shipmentId)
                    ? 'frozen'
                    : WalletService.escrowCentsForShipment(shipmentId) > 0
                        ? 'held'
                        : 'none',
      );
    }
  }

  void clear() {
    _summary = null;
    _transactions = const [];
    _error = null;
    WalletService.resetToEmpty();
    notifyListeners();
  }

  void _apply(WalletSummary summary, {required List<LedgerEntry> transactions}) {
    final availableCents =
        WalletService.resolveAvailableCents(summary.availableCents);
    final effective = availableCents == summary.availableCents
        ? summary
        : WalletSummary(
            contextRole: summary.contextRole,
            availableCents: availableCents,
            escrowCents: summary.escrowCents,
            currency: summary.currency,
            minimumWithdrawalCents: summary.minimumWithdrawalCents,
            recentTransactions: summary.recentTransactions,
            shipmentEscrows: summary.shipmentEscrows,
          );
    _summary = effective;
    _transactions = List<LedgerEntry>.unmodifiable(transactions);
    WalletService.applyRemoteState(
      availableCents: summary.availableCents,
      escrowCents: effective.escrowCents,
      history: transactions,
      shipmentEscrows: effective.shipmentEscrows,
    );
    notifyListeners();
  }
}
