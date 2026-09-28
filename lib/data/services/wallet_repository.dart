import '../../core/api/api_client.dart';
import '../../core/api/api_exception.dart';
import '../../core/config/demo_mode.dart';
import '../models/fx_quote.dart';
import '../models/ledger_entry.dart';
import '../models/shipment_escrow.dart';
import '../models/wallet_role.dart';
import '../models/wallet_summary.dart';

/// Backend wallet API access (unified balance, escrow, transaction history).
class WalletRepository {
  WalletRepository({
    required ApiClient apiClient,
    DemoModeProvider? demoMode,
  })  : _apiClient = apiClient,
        _demoMode = demoMode;

  final ApiClient _apiClient;
  final DemoModeProvider? _demoMode;

  bool get _isDemoMode => _demoMode?.enabled ?? false;

  /// GET /api/v1/wallet — single balance for the user.
  Future<WalletSummary> fetchSummary({
    WalletRole? contextRole,
    int recentLimit = 6,
  }) async {
    if (_isDemoMode) {
      return WalletSummary.empty(contextRole);
    }

    final data = await _apiClient.get(
      '/wallet?recentLimit=$recentLimit',
      authenticated: true,
    );
    return WalletSummary.fromJson(data, contextRole: contextRole);
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

  /// GET /api/v1/wallet/transactions — unified history (all roles).
  Future<List<LedgerEntry>> fetchTransactions({int limit = 50}) async {
    if (_isDemoMode) return const [];

    final data = await _apiClient.get(
      '/wallet/transactions?limit=$limit',
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
  Future<WalletSummary?> grantKycWelcomeCredit() async {
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

    final walletRaw = data['wallet'];
    if (walletRaw is Map) {
      return WalletSummary.fromJson(Map<String, dynamic>.from(walletRaw));
    }
    return null;
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
  Future<Map<String, dynamic>> topUpRaw({
    required WalletRole role,
    required int amountCents,
    String? currency,
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
        if (currency != null && currency.isNotEmpty) 'currency': currency,
      },
      authenticated: true,
    );
  }

  /// POST /api/v1/wallet/top-up/confirm
  Future<WalletSummary> confirmTopUp({
    required String paymentIntentId,
    WalletRole? contextRole,
  }) async {
    final data = await _apiClient.post(
      '/wallet/top-up/confirm',
      body: {'paymentIntentId': paymentIntentId},
      authenticated: true,
    );
    return WalletSummary.fromJson(
      {
        ...data,
        'recentTransactions': const [],
      },
      contextRole: contextRole,
    );
  }

  /// POST /api/v1/wallet/top-up
  Future<WalletSummary> topUp({
    required WalletRole role,
    required int amountCents,
    String? currency,
  }) async {
    if (_isDemoMode) {
      throw const ApiException(
        message: 'Top-up is unavailable in demo mode.',
        code: 'DEMO_MODE',
      );
    }

    final data = await topUpRaw(
      role: role,
      amountCents: amountCents,
      currency: currency,
    );
    if (data['mock'] == true && data['requiresPayment'] != true) {
      throw const ApiException(
        message:
            'Stripe Payment Sheet was skipped. Configure STRIPE_SECRET_KEY on the server.',
        code: 'STRIPE_NOT_CONFIGURED',
        statusCode: 503,
      );
    }
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
    return WalletSummary.fromJson(
      {
        ...data,
        'recentTransactions': const [],
      },
      contextRole: role,
    );
  }

  /// POST /api/v1/wallet/withdraw
  Future<WalletSummary> withdraw({
    required WalletRole role,
    required int amountCents,
    String? currency,
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
        if (currency != null && currency.isNotEmpty) 'currency': currency,
      },
      authenticated: true,
    );
    return WalletSummary.fromJson(
      {
        ...data,
        'recentTransactions': const [],
      },
      contextRole: role,
    );
  }

  /// POST /api/v1/wallet/fx/quote — live Stripe FX conversion.
  ///
  /// [amountCents] is in [fromCurrency] minor units. Secret key stays on the
  /// server; the app only receives rates + converted amounts.
  Future<FxQuote> fetchFxQuote({
    required String fromCurrency,
    required String toCurrency,
    required int amountCents,
    bool useBaseRate = false,
  }) async {
    if (_isDemoMode) {
      final same =
          fromCurrency.trim().toUpperCase() == toCurrency.trim().toUpperCase();
      return FxQuote(
        fromCurrency: fromCurrency.trim().toUpperCase(),
        toCurrency: toCurrency.trim().toUpperCase(),
        amountCents: amountCents,
        convertedAmountCents: same ? amountCents : amountCents,
        exchangeRate: 1,
        baseRate: 1,
        lockDuration: 'none',
      );
    }

    final data = await _apiClient.post(
      '/wallet/fx/quote',
      body: {
        'fromCurrency': fromCurrency.trim().toUpperCase(),
        'toCurrency': toCurrency.trim().toUpperCase(),
        'amountCents': amountCents,
        if (useBaseRate) 'useBaseRate': true,
      },
      authenticated: true,
    );
    return FxQuote.fromJson(data);
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
  Future<Map<String, dynamic>> startConnectOnboarding({String? role}) async {
    if (_isDemoMode) {
      throw const ApiException(
        message: 'Stripe Connect is unavailable in demo mode.',
        code: 'DEMO_MODE',
      );
    }
    return _apiClient.post(
      '/wallet/connect/onboard',
      body: {
        'returnPath': '/connect/return',
        if (role != null && role.isNotEmpty) 'role': role,
      },
      authenticated: true,
    );
  }
}
