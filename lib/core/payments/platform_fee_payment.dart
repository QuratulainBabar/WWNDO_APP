import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../api/api_exception.dart';
import '../../data/models/wallet_role.dart';
import '../../data/services/wallet_repository.dart';
import '../../providers/auth_provider.dart';
import '../../core/config/demo_mode.dart';
import 'stripe_payments.dart';

/// Stripe retry loop for receiver/traveler platform fee charges (402 PAYMENT_REQUIRED).
abstract final class PlatformFeePayment {
  static Future<T> withStripeRetry<T>({
    required BuildContext context,
    required WalletRole role,
    required Future<T> Function(String? paymentIntentId) attempt,
  }) async {
    final auth = context.read<AuthProvider>();
    final walletRepo = WalletRepository(
      apiClient: auth.repository.apiClient,
      demoMode: context.read<DemoModeProvider>(),
    );
    await StripePayments.ensureConfigured(walletRepo);
    if (!StripePayments.isEnabled) {
      return attempt(null);
    }

    String? paymentIntentId;
    for (var i = 0; i < 3; i++) {
      try {
        return await attempt(paymentIntentId);
      } on ApiException catch (e) {
        if (!e.requiresPayment || e.clientSecret == null) rethrow;
        final payRole = e.paymentRole;
        if (payRole != null && payRole != role.name) {
          rethrow;
        }
        await StripePayments.presentPaymentSheet(clientSecret: e.clientSecret!);
        paymentIntentId = e.paymentIntentId;
        if (paymentIntentId == null || paymentIntentId.isEmpty) {
          throw const ApiException(
            message: 'Card payment succeeded but payment id is missing.',
            code: 'PAYMENT_INCOMPLETE',
          );
        }
        await walletRepo.confirmTopUp(
          paymentIntentId: paymentIntentId,
          role: role,
        );
      }
    }
    throw const ApiException(
      message: 'Payment could not be completed.',
      code: 'PAYMENT_INCOMPLETE',
    );
  }
}
