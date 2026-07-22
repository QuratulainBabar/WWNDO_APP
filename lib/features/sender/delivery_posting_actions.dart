import 'package:flutter/material.dart';

import '../../core/widgets/app_toast.dart';
import '../../data/parcel_creation_wallet_validation.dart';

/// Shared wallet gate for sender delivery creation screens.
abstract final class DeliveryPostingActions {
  /// Blocks parcel creation when the displayed mock wallet balance is below
  /// [ParcelCreationWalletValidation.minimumBalanceUsd].
  ///
  /// Shows the required toast and returns `false` when blocked.
  static bool ensureWalletAllowsParcelCreation(BuildContext context) {
    final error = ParcelCreationWalletValidation.validate();
    if (error == null) return true;

    AppToast.error(context, error);
    return false;
  }
}
