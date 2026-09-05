import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../core/config/demo_mode.dart';
import '../core/widgets/app_toast.dart';
import '../providers/wallet_provider.dart';
import 'models/wallet_role.dart';
import 'parcel_creation_wallet_validation.dart';
import 'platform_fees.dart';
import 'wallet_service.dart';

/// Refreshes wallet balances from the API (live mode) before enforcing minimums.
abstract final class WalletGate {
  static Future<bool> ensureMinimum(
    BuildContext context,
    WalletRole role,
    double minimumUsd,
    String message,
  ) async {
    final demo = context.read<DemoModeProvider>().enabled;
    if (!demo) {
      try {
        await context.read<WalletProvider>().refresh(role, silent: true);
      } catch (_) {
        // Validation still uses the last synced WalletService cache.
      }
    }

    if (WalletService.availableUsd(role) >= minimumUsd) return true;
    if (!context.mounted) return false;
    AppToast.error(context, message);
    return false;
  }

  /// Balance check only — never deducts document/object platform fees.
  static Future<bool> ensureParcelCreation(
    BuildContext context, {
    String category = 'documents',
    bool paysReceiverFee = false,
  }) =>
      ensureMinimum(
        context,
        WalletRole.sender,
        PlatformFees.minWalletForSenderCreate(
          category: category,
          paysReceiverFee: paysReceiverFee,
        ),
        ParcelCreationWalletValidation.insufficientBalanceMessage,
      );

  static Future<bool> ensureTravelerTripCreation(BuildContext context) =>
      ensureMinimum(
        context,
        WalletRole.traveler,
        PlatformFees.minWalletTravelerUsd,
        'Minimum \$3 wallet balance is required to create a trip.',
      );

  static Future<bool> ensureReceiverAccept(
    BuildContext context, {
    required String category,
    required bool paysReceiverFee,
    double platformFeeUsd = 0,
  }) {
    final minimum = platformFeeUsd > 0 ? platformFeeUsd : 0.0;
    if (minimum <= 0) return Future.value(true);
    return ensureMinimum(
      context,
      WalletRole.receiver,
      minimum,
      'You need at least \$${minimum.toStringAsFixed(2)} in your wallet to accept (includes platform fee).',
    );
  }

  static Future<void> refreshRoles(
    BuildContext context,
    Iterable<WalletRole> roles,
  ) async {
    if (context.read<DemoModeProvider>().enabled) return;
    try {
      // Always pull full history so available balance and recent fee rows stay
      // in sync after Pay Now / platform-fee charges.
      await context.read<WalletProvider>().refresh(
            roles.isEmpty ? null : roles.first,
            silent: true,
            includeFullHistory: true,
          );
    } catch (_) {}
  }
}
