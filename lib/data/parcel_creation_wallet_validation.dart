import 'models/wallet_role.dart';
import 'wallet_service.dart';

/// Frontend wallet gate for sender parcel / delivery creation.
abstract final class ParcelCreationWalletValidation {
  static const double minimumBalanceUsd = 2.0;

  static const String insufficientBalanceMessage =
      'Minimum \$2 wallet balance is required to create a delivery.';

  static const String helperLabel =
      'Minimum wallet balance: \$2 (platform fees apply when you pay)';

  static double currentBalanceUsd() =>
      WalletService.availableUsd(WalletRole.sender);

  static bool hasMinimumBalance() =>
      currentBalanceUsd() >= minimumBalanceUsd;

  static String? validate() {
    if (hasMinimumBalance()) return null;
    return insufficientBalanceMessage;
  }
}
