import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
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
      await _applyPublishableKey();
    } catch (e) {
      debugPrint('Stripe config load failed: $e');
      if (ApiConfig.stripePublishableKey.isNotEmpty) {
        _publishableKey = ApiConfig.stripePublishableKey;
        _stripeEnabled = true;
        await _applyPublishableKey();
      }
    }
  }

  static Future<void> _applyPublishableKey() async {
    if (_publishableKey == null || _publishableKey!.isEmpty) {
      _initialized = false;
      _stripeEnabled = false;
      return;
    }
    Stripe.publishableKey = _publishableKey!;
    try {
      await Stripe.instance.applySettings();
      _initialized = true;
      if (kDebugMode) {
        debugPrint('Stripe configured (${_publishableKey!.substring(0, 12)}...)');
      }
    } on PlatformException catch (e) {
      _initialized = false;
      debugPrint('Stripe applySettings failed: ${e.message}');
      rethrow;
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

    if (kDebugMode) {
      debugPrint('Stripe: opening payment sheet');
    }

    try {
      await Stripe.instance.initPaymentSheet(
        paymentSheetParameters: SetupPaymentSheetParameters(
          paymentIntentClientSecret: clientSecret,
          merchantDisplayName: merchantDisplayName,
          style: ThemeMode.light,
          allowsDelayedPaymentMethods: false,
          appearance: const PaymentSheetAppearance(
            colors: PaymentSheetAppearanceColors(
              primary: Color(0xFF1A56DB),
              background: Color(0xFFFFFFFF),
              componentBackground: Color(0xFFF9FAFB),
              componentBorder: Color(0xFFD1D5DB),
              componentDivider: Color(0xFFE5E7EB),
              primaryText: Color(0xFF111827),
              secondaryText: Color(0xFF6B7280),
              componentText: Color(0xFF111827),
              placeholderText: Color(0xFF9CA3AF),
              icon: Color(0xFF6B7280),
            ),
          ),
        ),
      );
      await Stripe.instance.presentPaymentSheet();
      if (kDebugMode) {
        debugPrint('Stripe: payment sheet completed');
      }
    } on StripeException catch (e) {
      debugPrint(
        'StripeException: ${e.error.code} ${e.error.message} '
        '${e.error.localizedMessage ?? ''}',
      );
      if (e.error.code == FailureCode.Canceled) {
        throw const ApiException(
          message: 'Payment cancelled.',
          code: 'PAYMENT_CANCELLED',
        );
      }
      throw ApiException(
        message: e.error.localizedMessage ??
            e.error.message ??
            'Card payment failed. Please try again.',
        code: 'STRIPE_ERROR',
      );
    } on PlatformException catch (e) {
      debugPrint('Stripe PlatformException: ${e.code} ${e.message}');
      throw ApiException(
        message: e.message ?? 'Card payment failed. Please try again.',
        code: e.code,
      );
    }
  }
}
