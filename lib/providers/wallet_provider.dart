import 'package:flutter/foundation.dart';

import '../core/api/api_exception.dart';
import '../core/config/demo_mode.dart';
import '../data/models/ledger_entry.dart';
import '../data/models/wallet_role.dart';
import '../data/models/wallet_summary.dart';
import '../data/services/auth_repository.dart';
import '../data/services/wallet_repository.dart';
import '../data/wallet_service.dart';

/// Loads wallet balance, escrow, and transactions from the backend API.
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

  WalletRole? _loadedRole;
  WalletRole? get loadedRole => _loadedRole;

  WalletSummary? _summary;
  WalletSummary? get summary => _summary;

  List<LedgerEntry> _transactions = const [];
  List<LedgerEntry> get transactions => _transactions;

  bool get isDemoMode => _demoMode?.enabled ?? false;

  int availableCents(WalletRole role) {
    // Prefer the local cache so debug $0→$10 fallback stays consistent
    // with WalletCard / creation validation (both read WalletService).
    return WalletService.availableCents(role);
  }

  int escrowCents(WalletRole role) {
    if (_summary != null && _summary!.role == role) {
      return _summary!.escrowCents;
    }
    return WalletService.escrowCents(role);
  }

  List<LedgerEntry> historyFor(WalletRole role) {
    if (_loadedRole == role && _transactions.isNotEmpty) {
      return _transactions;
    }
    if (_summary != null &&
        _summary!.role == role &&
        _summary!.recentTransactions.isNotEmpty) {
      return _summary!.recentTransactions;
    }
    return WalletService.historyFor(role);
  }

  /// Fetch balances + recent transactions for [role].
  /// New users / empty wallets resolve to $0.00 with an empty ledger.
  Future<WalletSummary> refresh(
    WalletRole role, {
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
        final empty = WalletSummary.empty(role);
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

      final summary = await _walletRepository.fetchSummary(role);
      List<LedgerEntry> history = summary.recentTransactions;
      if (includeFullHistory) {
        history = await _walletRepository.fetchTransactions(role);
      }

      _apply(summary, transactions: history);
      return summary;
    } on ApiException catch (e) {
      // Fall back to zeros so the UI never shows stale demo amounts.
      final empty = WalletSummary.empty(role);
      _apply(empty, transactions: const []);
      if (!silent) {
        _error = e.message;
        rethrow;
      }
      return empty;
    } catch (e) {
      final empty = WalletSummary.empty(role);
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
      await _walletRepository.topUp(role: role, amountCents: amountCents);
      await refresh(role, silent: true, includeFullHistory: true);
    } on ApiException catch (e) {
      _error = e.message;
      rethrow;
    } finally {
      _loading = false;
      notifyListeners();
    }
  }

  /// After identity verification: ensure each role wallet has the $10 welcome credit.
  Future<void> ensureKycWelcomeCredit() async {
    try {
      if (isDemoMode || _authRepository.currentUser == null) {
        WalletService.grantKycWelcomeCredit();
        notifyListeners();
        return;
      }

      final ok = await _authRepository.ensureAuthenticated();
      if (!ok) return;

      final wallets = await _walletRepository.grantKycWelcomeCredit();
      if (wallets.isEmpty) {
        WalletService.grantKycWelcomeCredit();
        for (final role in WalletRole.values) {
          await refresh(role, silent: true);
        }
        return;
      }

      for (final role in WalletRole.values) {
        final summary = wallets[role.queryParam];
        if (summary != null) {
          _apply(summary, transactions: summary.recentTransactions);
        } else {
          await refresh(role, silent: true);
        }
      }
    } catch (e) {
      debugPrint('KYC welcome credit failed: $e');
      // Local fallback so Continue-to-app still shows $10 in-session.
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

  void clear() {
    _summary = null;
    _transactions = const [];
    _loadedRole = null;
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
            role: summary.role,
            availableCents: availableCents,
            escrowCents: summary.escrowCents,
            currency: summary.currency,
            minimumWithdrawalCents: summary.minimumWithdrawalCents,
            recentTransactions: summary.recentTransactions,
          );
    _summary = effective;
    _transactions = List<LedgerEntry>.unmodifiable(transactions);
    _loadedRole = effective.role;
    WalletService.applyRemoteState(
      role: effective.role,
      availableCents: summary.availableCents,
      escrowCents: effective.escrowCents,
      history: transactions,
    );
    notifyListeners();
  }
}
