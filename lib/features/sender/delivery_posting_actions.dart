import 'package:flutter/material.dart';

import '../../data/wallet_gate.dart';

/// Shared wallet gate for sender delivery creation screens.
/// Posting must not debit platform fees; this only checks a generic minimum.
abstract final class DeliveryPostingActions {
  static Future<bool> ensureWalletAllowsParcelCreation(
    BuildContext context, {
    String category = 'documents',
    bool paysReceiverFee = false,
  }) =>
      WalletGate.ensureParcelCreation(
        context,
        category: category,
        paysReceiverFee: paysReceiverFee,
      );
}
