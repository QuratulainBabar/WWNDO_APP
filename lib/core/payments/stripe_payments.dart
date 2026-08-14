import 'package:flutter/material.dart';
import 'package:flutter_stripe/flutter_stripe.dart';

import '../config/api_config.dart';
import '../api/api_exception.dart';
import '../../data/services/wallet_repository.dart';

/// Stripe Payment Sheet helper for wallet top-up and escrow shortfall.
class StripePayments {
  StripePayments._();

  static bool _initialized = false;
  static String? _publishableKey;
  static bool _stripeEnabled = false;

  static bool get isEnabled => _stripeEnabled && (_publishableKey?.isNotEmpty ?? false);

  static Future<void> ensureConfigured(WalletRepository walletRepo) async {
    try {
      final config = await walletRepo.fetchPaymentsConfig();
      _stripeEnabled = config['stripeEnabled'] == true;
      final key = (config['publishableKey'] as String?)?.trim();
      if (key != null && key.isNotEmpty) {
        _publishableKey = key;
      } else if (ApiConfig.stripePublishableKey.isNotEmpty) {
        _publishableKey = ApiConfig.stripePublishableKey;
        _stripeEnabled = true;
      }
      if (_publishableKey != null && _publishableKey!.isNotEmpty) {
        Stripe.publishableKey = _publishableKey!;
        _initialized = true;
      }
    } catch (e) {
      debugPrint('Stripe config load failed: $e');
      if (ApiConfig.stripePublishableKey.isNotEmpty) {
        _publishableKey = ApiConfig.stripePublishableKey;
        Stripe.publishableKey = _publishableKey!;
        _stripeEnabled = true;
        _initialized = true;
      }
    }
  }

  /// Present Payment Sheet for a PaymentIntent client secret.
  static Future<void> presentPaymentSheet({
    required String clientSecret,
    String merchantDisplayName = 'WWNGO',
  }) async {
    if (!_initialized || (_publishableKey?.isEmpty ?? true)) {
      throw const ApiException(
        message: 'Stripe is not configured on this device.',
        code: 'STRIPE_NOT_CONFIGURED',
      );
    }

    await Stripe.instance.initPaymentSheet(
      paymentSheetParameters: SetupPaymentSheetParameters(
        paymentIntentClientSecret: clientSecret,
        merchantDisplayName: merchantDisplayName,
        style: ThemeMode.system,
      ),
    );
    await Stripe.instance.presentPaymentSheet();
  }
}
