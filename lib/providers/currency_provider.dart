import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../core/api/api_exception.dart';
import '../core/config/demo_mode.dart';
import '../core/currency/app_currency.dart';
import '../core/currency/fx_rate_service.dart';
import '../data/models/fx_quote.dart';
import '../data/services/wallet_repository.dart';

/// Persists the user's preferred currency and keeps a live Stripe FX rate
/// (USD ledger → display currency) for app-wide formatting.
class CurrencyProvider extends ChangeNotifier {
  static const _prefsKey = 'preferred_currency_code';

  AppCurrency _currency = AppCurrency.usd;
  bool _loaded = false;
  bool _fxLoading = false;
  String? _fxError;

  WalletRepository? _walletRepository;
  DemoModeProvider? _demoMode;

  AppCurrency get currency => _currency;
  String get code => _currency.code;
  String get symbol => _currency.symbol;
  String get stripeCode => _currency.stripeCode;
  bool get loaded => _loaded;
  bool get fxLoading => _fxLoading;
  String? get fxError => _fxError;
  double get usdToDisplayRate => FxRateService.usdToDisplayRate;
  bool get fxReady => FxRateService.ready;
  List<AppCurrency> get supported => AppCurrency.supported;

  /// Wire API access after [AuthRepository] / wallet repo exist.
  void attachFxSource({
    required WalletRepository walletRepository,
    DemoModeProvider? demoMode,
  }) {
    _walletRepository = walletRepository;
    _demoMode = demoMode;
  }

  Future<void> init() async {
    final prefs = await SharedPreferences.getInstance();
    final saved = prefs.getString(_prefsKey);
    _currency = AppCurrency.fromCode(saved);
    AppCurrencies.bind(_currency);
    if (_currency.code == 'USD') {
      FxRateService.resetToUsd();
    }
    _loaded = true;
    notifyListeners();
  }

  Future<void> setCurrency(AppCurrency value) async {
    if (_currency == value) {
      await refreshFxRate(force: true);
      return;
    }
    _currency = value;
    AppCurrencies.bind(value);
    // Optimistic UI: bind currency immediately, then load live rate.
    notifyListeners();
    await refreshFxRate(force: true);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_prefsKey, value.code);
  }

  Future<void> setCurrencyCode(String code) =>
      setCurrency(AppCurrency.fromCode(code));

  /// Refresh Stripe FX quote for USD → active currency.
  Future<void> refreshFxRate({bool force = false}) async {
    final to = _currency.code.toUpperCase();
    if (to == 'USD') {
      FxRateService.resetToUsd();
      _fxError = null;
      notifyListeners();
      return;
    }

    final repo = _walletRepository;
    if (repo == null) {
      _fxError = 'Currency conversion is not ready yet.';
      notifyListeners();
      return;
    }

    if (!force &&
        FxRateService.displayCurrencyCode == to &&
        FxRateService.ready &&
        FxRateService.fetchedAt != null &&
        DateTime.now().difference(FxRateService.fetchedAt!) <
            const Duration(minutes: 5)) {
      return;
    }

    _fxLoading = true;
    _fxError = null;
    notifyListeners();

    try {
      if (_demoMode?.enabled == true) {
        // Demo has no Stripe FX — keep 1:1 so amounts stay readable.
        FxRateService.applyUsdToDisplayRate(
          toCurrency: to,
          exchangeRate: 1,
        );
        return;
      }

      // $1.00 USD reference → target currency (returns exchangeRate + converted).
      final quote = await repo.fetchFxQuote(
        fromCurrency: 'USD',
        toCurrency: to,
        amountCents: 100,
      );
      if (quote.exchangeRate <= 0) {
        throw const ApiException(
          message: 'Invalid exchange rate from server',
          code: 'FX_RATE_INVALID',
        );
      }
      FxRateService.applyUsdToDisplayRate(
        toCurrency: to,
        exchangeRate: quote.exchangeRate,
        quoteId: quote.quoteId,
      );
      _fxError = null;
      if (kDebugMode) {
        debugPrint(
          'FX rate USD→$to = ${quote.exchangeRate} (quote ${quote.quoteId})',
        );
      }
    } on ApiException catch (e) {
      _fxError = e.message;
      if (kDebugMode) {
        debugPrint('FX rate refresh failed: ${e.message}');
      }
    } catch (e) {
      _fxError = 'Unable to load exchange rate';
      if (kDebugMode) {
        debugPrint('FX rate refresh failed: $e');
      }
    } finally {
      _fxLoading = false;
      notifyListeners();
    }
  }

  /// Live convert any supported pair via the backend (does not change cache).
  Future<FxQuote> convert({
    required String fromCurrency,
    required String toCurrency,
    required int amountCents,
    bool useBaseRate = false,
  }) async {
    final repo = _walletRepository;
    if (repo == null) {
      throw const ApiException(
        message: 'Currency conversion is not ready yet.',
        code: 'FX_NOT_READY',
      );
    }
    return repo.fetchFxQuote(
      fromCurrency: fromCurrency,
      toCurrency: toCurrency,
      amountCents: amountCents,
      useBaseRate: useBaseRate,
    );
  }

  String formatCents(int usdLedgerCents) =>
      FxRateService.formatUsdCents(usdLedgerCents);

  String formatMajor(num usdMajor) => FxRateService.formatUsdMajor(usdMajor);

  String fieldLabel(String base) => _currency.fieldLabel(base);

  /// Parse a user-entered major amount in the active currency → minor units.
  int parseMajorToMinor(String text) {
    final major = double.tryParse(text.trim()) ?? 0;
    return _currency.toMinorUnits(major);
  }
}
