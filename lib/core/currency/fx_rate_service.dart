import 'package:flutter/foundation.dart';

import 'app_currency.dart';

/// Cached Stripe FX rate for converting wallet ledger USD → display currency.
///
/// Ledger amounts stay in USD cents; UI formatters use this cache so any
/// selected currency shows a live converted value.
abstract final class FxRateService {
  static double _usdToDisplayRate = 1;
  static String _displayCurrencyCode = 'USD';
  static DateTime? _fetchedAt;
  static String? _quoteId;
  static bool _ready = true; // USD is always ready

  /// Bumped whenever the cached rate changes (UI can rebuild).
  static final ValueNotifier<int> version = ValueNotifier<int>(0);

  static double get usdToDisplayRate => _usdToDisplayRate;
  static String get displayCurrencyCode => _displayCurrencyCode;
  static DateTime? get fetchedAt => _fetchedAt;
  static String? get quoteId => _quoteId;
  static bool get isIdentity => _displayCurrencyCode == 'USD';
  static bool get ready => _ready;

  /// Apply a USD → [toCurrency] rate from Stripe FX Quotes.
  static void applyUsdToDisplayRate({
    required String toCurrency,
    required double exchangeRate,
    String? quoteId,
  }) {
    final code = toCurrency.trim().toUpperCase();
    final rate = code == 'USD'
        ? 1.0
        : (exchangeRate.isFinite && exchangeRate > 0 ? exchangeRate : 0.0);
    if (code != 'USD' && rate <= 0) {
      _ready = false;
      return;
    }
    final changed = code != _displayCurrencyCode ||
        rate != _usdToDisplayRate ||
        quoteId != _quoteId;
    _displayCurrencyCode = code;
    _usdToDisplayRate = rate;
    _quoteId = quoteId;
    _fetchedAt = DateTime.now();
    _ready = true;
    if (changed) {
      version.value++;
      AppCurrencies.notifyChanged();
    }
  }

  static void resetToUsd() {
    applyUsdToDisplayRate(toCurrency: 'USD', exchangeRate: 1, quoteId: null);
  }

  /// Convert ledger USD minor units → active display currency minor units.
  static int usdCentsToDisplayMinor(int usdCents) {
    final currency = AppCurrencies.active;
    if (currency.code == 'USD') return usdCents;
    final rate = _usdToDisplayRate > 0 ? _usdToDisplayRate : 1.0;
    final usdMajor = usdCents / 100.0;
    final displayMajor = usdMajor * rate;
    return currency.toMinorUnits(displayMajor);
  }

  /// Format a ledger USD-cents amount in the active display currency.
  static String formatUsdCents(int usdCents) {
    return AppCurrencies.active.formatCents(usdCentsToDisplayMinor(usdCents));
  }

  /// Format a ledger USD major amount in the active display currency.
  static String formatUsdMajor(num usdMajor) {
    final rate = _usdToDisplayRate > 0 ? _usdToDisplayRate : 1.0;
    final displayMajor =
        AppCurrencies.active.code == 'USD' ? usdMajor : usdMajor * rate;
    return AppCurrencies.active.formatMajor(displayMajor);
  }

  /// Convert display-currency major units → USD cents using the inverse rate.
  /// Prefer a live FX quote for withdrawals when possible.
  static int displayMajorToUsdCents(num displayMajor) {
    if (AppCurrencies.active.code == 'USD') {
      return (displayMajor * 100).round();
    }
    if (_usdToDisplayRate <= 0) return (displayMajor * 100).round();
    final usdMajor = displayMajor / _usdToDisplayRate;
    return (usdMajor * 100).round();
  }
}
