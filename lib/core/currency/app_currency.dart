import 'package:flutter/foundation.dart';

/// Supported display / payment currencies (manual preference — not tied to country).
@immutable
class AppCurrency {
  const AppCurrency({
    required this.code,
    required this.name,
    required this.symbol,
    this.decimals = 2,
  });

  /// ISO 4217 code, e.g. `USD`.
  final String code;

  /// User-facing name.
  final String name;

  /// Display symbol, e.g. `$`, `€`.
  final String symbol;

  /// Minor-unit decimals (Stripe amount = major * 10^decimals).
  final int decimals;

  /// Lowercase code for Stripe (`usd`, `eur`, …).
  String get stripeCode => code.toLowerCase();

  /// Text-field prefix, e.g. `$ `.
  String get prefixText => '$symbol ';

  /// Label suffix, e.g. `Amount (EUR)`.
  String fieldLabel(String base) => '$base ($code)';

  String formatCents(int cents) {
    final major = cents / _factor;
    return '$symbol${major.toStringAsFixed(decimals)}';
  }

  String formatMajor(num amount) =>
      '$symbol${amount.toStringAsFixed(decimals)}';

  int get _factor {
    var f = 1;
    for (var i = 0; i < decimals; i++) {
      f *= 10;
    }
    return f;
  }

  int toMinorUnits(num major) => (major * _factor).round();

  // ── Client market currencies (manual preference — not locked to country) ──
  static const usd = AppCurrency(code: 'USD', name: 'US Dollar', symbol: '\$');
  static const eur = AppCurrency(code: 'EUR', name: 'Euro', symbol: '€');
  static const gbp = AppCurrency(code: 'GBP', name: 'British Pound', symbol: '£');
  static const cad = AppCurrency(code: 'CAD', name: 'Canadian Dollar', symbol: 'CA\$');
  static const aud = AppCurrency(code: 'AUD', name: 'Australian Dollar', symbol: 'A\$');
  static const aed = AppCurrency(code: 'AED', name: 'UAE Dirham', symbol: 'AED ');
  static const sar = AppCurrency(code: 'SAR', name: 'Saudi Riyal', symbol: 'SAR ');
  static const qar = AppCurrency(code: 'QAR', name: 'Qatari Riyal', symbol: 'QAR ');
  static const kwd = AppCurrency(
    code: 'KWD',
    name: 'Kuwaiti Dinar',
    symbol: 'KD ',
    decimals: 3,
  );
  static const bhd = AppCurrency(
    code: 'BHD',
    name: 'Bahraini Dinar',
    symbol: 'BD ',
    decimals: 3,
  );
  static const omr = AppCurrency(
    code: 'OMR',
    name: 'Omani Rial',
    symbol: 'OMR ',
    decimals: 3,
  );
  static const inr = AppCurrency(code: 'INR', name: 'Indian Rupee', symbol: '₹');
  static const cny = AppCurrency(code: 'CNY', name: 'Chinese Yuan', symbol: '¥');
  static const try_ = AppCurrency(code: 'TRY', name: 'Turkish Lira', symbol: '₺');

  static const List<AppCurrency> supported = [
    usd,
    eur,
    gbp,
    cad,
    aud,
    aed,
    sar,
    qar,
    kwd,
    bhd,
    omr,
    inr,
    cny,
    try_,
  ];

  static AppCurrency fromCode(String? code) {
    final normalized = (code ?? '').trim().toUpperCase();
    for (final c in supported) {
      if (c.code == normalized) return c;
    }
    return usd;
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) || other is AppCurrency && other.code == code;

  @override
  int get hashCode => code.hashCode;
}

/// Active currency bound by [CurrencyProvider] for static formatters.
abstract final class AppCurrencies {
  static AppCurrency _active = AppCurrency.usd;
  static final ValueNotifier<int> version = ValueNotifier<int>(0);

  static AppCurrency get active => _active;

  static void bind(AppCurrency currency) {
    if (_active == currency) return;
    _active = currency;
    version.value++;
  }
}
