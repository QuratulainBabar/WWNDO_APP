import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../core/config/demo_mode.dart';
import '../core/widgets/app_toast.dart';
import '../providers/wallet_provider.dart';
import 'models/wallet_role.dart';
import 'parcel_creation_wallet_validation.dart';
import 'platform_fees.dart';
import 'trip_creation_wallet_validation.dart';
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

  static Future<bool> ensureTripCreation(BuildContext context) => ensureMinimum(
        context,
        WalletRole.traveler,
        TripCreationWalletValidation.minimumBalanceUsd,
        TripCreationWalletValidation.insufficientBalanceMessage,
      );

  static Future<bool> ensureParcelCreation(
    BuildContext context, {
    String category = 'documents',
    bool paysReceiverFee = false,
  }) =>
      ensureMinimum(
        context,
        WalletRole.sender,
        ParcelCreationWalletValidation.minimumBalanceUsd,
        ParcelCreationWalletValidation.insufficientBalanceMessage,
      );

  static Future<bool> ensureReceiverAccept(
    BuildContext context, {
    required String category,
    required bool paysReceiverFee,
    double platformFeeUsd = 0,
  }) =>
      ensureMinimum(
        context,
        WalletRole.receiver,
        PlatformFees.minWalletReceiverUsd,
        'You need at least \$${PlatformFees.minWalletReceiverUsd.toStringAsFixed(2)} '
            'in your wallet to accept this request.',
      );

  static Future<void> refreshRoles(
    BuildContext context,
    Iterable<WalletRole> roles,
  ) async {
    if (context.read<DemoModeProvider>().enabled) return;
    final wallet = context.read<WalletProvider>();
    for (final role in roles) {
      try {
        await wallet.refresh(role, silent: true);
      } catch (_) {}
    }
  }
}
