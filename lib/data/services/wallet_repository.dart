import '../../core/api/api_client.dart';
import '../../core/api/api_exception.dart';
import '../../core/config/demo_mode.dart';
import '../models/ledger_entry.dart';
import '../models/shipment_escrow.dart';
import '../models/wallet_role.dart';
import '../models/wallet_summary.dart';

/// Backend wallet API access (balances, escrow, transaction summary).
class WalletRepository {
  WalletRepository({
    required ApiClient apiClient,
    DemoModeProvider? demoMode,
  })  : _apiClient = apiClient,
        _demoMode = demoMode;

  final ApiClient _apiClient;
  final DemoModeProvider? _demoMode;

  bool get _isDemoMode => _demoMode?.enabled ?? false;

  /// GET /api/v1/wallet?role=
  Future<WalletSummary> fetchSummary(
    WalletRole role, {
    int recentLimit = 6,
  }) async {
    if (_isDemoMode) {
      return WalletSummary.empty(role);
    }

    final data = await _apiClient.get(
      '/wallet?role=${role.queryParam}&recentLimit=$recentLimit',
      authenticated: true,
    );
    return WalletSummary.fromJson(data);
  }

  /// GET /api/v1/wallet/escrow/:shipmentId
  Future<ShipmentEscrow> fetchShipmentEscrow(String shipmentId) async {
    if (_isDemoMode) {
      return ShipmentEscrow.none(shipmentId);
    }

    final data = await _apiClient.get(
      '/wallet/escrow/${Uri.encodeComponent(shipmentId)}',
      authenticated: true,
    );
    return ShipmentEscrow.fromJson(data);
  }

  /// GET /api/v1/wallet/transactions?role=
  Future<List<LedgerEntry>> fetchTransactions(
    WalletRole role, {
    int limit = 50,
  }) async {
    if (_isDemoMode) return const [];

    final data = await _apiClient.get(
      '/wallet/transactions?role=${role.queryParam}&limit=$limit',
      authenticated: true,
    );
    final list = data['transactions'];
    if (list is! List) return const [];
    return list
        .whereType<Map>()
        .map((e) => LedgerEntry.fromJson(Map<String, dynamic>.from(e)))
        .toList();
  }

  /// POST /api/v1/wallet/kyc-welcome-credit
  /// Credits $10 to sender, traveler, and receiver (idempotent).
  Future<Map<String, WalletSummary>> grantKycWelcomeCredit() async {
    if (_isDemoMode) {
      throw const ApiException(
        message: 'KYC welcome credit is handled locally in demo mode.',
        code: 'DEMO_MODE',
      );
    }

    final data = await _apiClient.post(
      '/wallet/kyc-welcome-credit',
      authenticated: true,
    );

    final walletsRaw = data['wallets'];
    final result = <String, WalletSummary>{};
    if (walletsRaw is Map) {
      for (final entry in walletsRaw.entries) {
        final role = WalletRole.fromQuery(entry.key.toString());
        final value = entry.value;
        if (value is Map) {
          result[role.queryParam] = WalletSummary.fromJson({
            ...Map<String, dynamic>.from(value),
            'role': role.queryParam,
            'recentTransactions': const [],
          });
        }
      }
    }
    return result;
  }

  /// GET /api/v1/wallet/payments/config
  Future<Map<String, dynamic>> fetchPaymentsConfig() async {
    if (_isDemoMode) {
      return {
        'stripeEnabled': false,
        'publishableKey': null,
        'currency': 'USD',
      };
    }
    try {
      return await _apiClient.get(
        '/wallet/payments/config',
        authenticated: true,
      );
    } on ApiException catch (e) {
      if (e.statusCode == 404 || e.code == 'NOT_FOUND') {
        return {
          'stripeEnabled': false,
          'publishableKey': null,
          'currency': 'USD',
        };
      }
      rethrow;
    }
  }

  /// POST /api/v1/wallet/top-up
  /// Returns either a credited [WalletSummary] or a payment-required payload.
  Future<Map<String, dynamic>> topUpRaw({
    required WalletRole role,
    required int amountCents,
  }) async {
    if (_isDemoMode) {
      throw const ApiException(
        message: 'Top-up is unavailable in demo mode.',
        code: 'DEMO_MODE',
      );
    }

    return _apiClient.post(
      '/wallet/top-up',
      body: {
        'role': role.queryParam,
        'amountCents': amountCents,
      },
      authenticated: true,
    );
  }

  /// POST /api/v1/wallet/top-up/confirm
  Future<WalletSummary> confirmTopUp({
    required String paymentIntentId,
    required WalletRole role,
  }) async {
    final data = await _apiClient.post(
      '/wallet/top-up/confirm',
      body: {'paymentIntentId': paymentIntentId},
      authenticated: true,
    );
    return WalletSummary.fromJson({
      ...data,
      'role': data['role'] ?? role.queryParam,
      'recentTransactions': const [],
    });
  }

  /// POST /api/v1/wallet/top-up
  Future<WalletSummary> topUp({
    required WalletRole role,
    required int amountCents,
  }) async {
    if (_isDemoMode) {
      throw const ApiException(
        message: 'Top-up is unavailable in demo mode.',
        code: 'DEMO_MODE',
      );
    }

    final data = await topUpRaw(role: role, amountCents: amountCents);
    if (data['requiresPayment'] == true) {
      throw ApiException(
        message: 'Card payment required to complete top-up.',
        code: 'PAYMENT_REQUIRED',
        statusCode: 402,
        details: {
          'paymentIntentId': data['paymentIntentId'],
          'clientSecret': data['clientSecret'],
          'amountCents': data['amountCents'] ?? amountCents,
          'role': role.queryParam,
        },
      );
    }
    return WalletSummary.fromJson({
      ...data,
      'role': data['role'] ?? role.queryParam,
      'recentTransactions': const [],
    });
  }

  /// POST /api/v1/wallet/withdraw
  Future<WalletSummary> withdraw({
    required WalletRole role,
    required int amountCents,
  }) async {
    if (_isDemoMode) {
      throw const ApiException(
        message: 'Withdrawal is unavailable in demo mode.',
        code: 'DEMO_MODE',
      );
    }

    final data = await _apiClient.post(
      '/wallet/withdraw',
      body: {
        'role': role.queryParam,
        'amountCents': amountCents,
      },
      authenticated: true,
    );
    return WalletSummary.fromJson({
      ...data,
      'role': data['role'] ?? role.queryParam,
      'recentTransactions': const [],
    });
  }

  /// GET /api/v1/wallet/connect/status
  Future<Map<String, dynamic>> fetchConnectStatus() async {
    if (_isDemoMode) {
      return {'linked': false, 'ready': false};
    }
    try {
      return await _apiClient.get(
        '/wallet/connect/status',
        authenticated: true,
      );
    } on ApiException catch (e) {
      if (e.statusCode == 404 || e.code == 'NOT_FOUND') {
        return {'linked': false, 'ready': false};
      }
      rethrow;
    }
  }

  /// POST /api/v1/wallet/connect/onboard
  Future<Map<String, dynamic>> startConnectOnboarding() async {
    if (_isDemoMode) {
      throw const ApiException(
        message: 'Stripe Connect is unavailable in demo mode.',
        code: 'DEMO_MODE',
      );
    }
    return _apiClient.post(
      '/wallet/connect/onboard',
      body: const {'returnPath': '/wallet'},
      authenticated: true,
    );
  }
}
