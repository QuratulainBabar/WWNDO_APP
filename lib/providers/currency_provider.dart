import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../core/currency/app_currency.dart';

/// Persists the user's preferred currency for prices and payments app-wide.
class CurrencyProvider extends ChangeNotifier {
  static const _prefsKey = 'preferred_currency_code';

  AppCurrency _currency = AppCurrency.usd;
  bool _loaded = false;

  AppCurrency get currency => _currency;
  String get code => _currency.code;
  String get symbol => _currency.symbol;
  String get stripeCode => _currency.stripeCode;
  bool get loaded => _loaded;
  List<AppCurrency> get supported => AppCurrency.supported;

  Future<void> init() async {
    final prefs = await SharedPreferences.getInstance();
    final saved = prefs.getString(_prefsKey);
    _currency = AppCurrency.fromCode(saved);
    AppCurrencies.bind(_currency);
    _loaded = true;
    notifyListeners();
  }

  Future<void> setCurrency(AppCurrency value) async {
    if (_currency == value) return;
    _currency = value;
    AppCurrencies.bind(value);
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_prefsKey, value.code);
  }

  Future<void> setCurrencyCode(String code) =>
      setCurrency(AppCurrency.fromCode(code));

  String formatCents(int cents) => _currency.formatCents(cents);

  String formatMajor(num amount) => _currency.formatMajor(amount);

  String fieldLabel(String base) => _currency.fieldLabel(base);
}
