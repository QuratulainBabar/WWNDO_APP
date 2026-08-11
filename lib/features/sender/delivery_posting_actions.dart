import 'package:flutter/material.dart';

import '../../data/wallet_gate.dart';

/// Shared wallet gate for sender delivery creation screens.
abstract final class DeliveryPostingActions {
  /// Blocks parcel creation when wallet balance is below \$2 (refreshed from API in live mode).
  static Future<bool> ensureWalletAllowsParcelCreation(BuildContext context) =>
      WalletGate.ensureParcelCreation(context);
}
