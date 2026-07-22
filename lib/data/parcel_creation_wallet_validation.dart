import 'models/wallet_role.dart';
import 'wallet_service.dart';

/// Frontend wallet gate for sender parcel / delivery creation.
///
/// Uses the same mock balance shown in the Sender Home [WalletCard]
/// via [WalletService]. Replace [currentBalanceUsd] with a backend-backed
/// lookup later without changing UI call sites.
abstract final class ParcelCreationWalletValidation {
  static const double minimumBalanceUsd = 2.0;

  static const String insufficientBalanceMessage =
      'Minimum \$2 wallet balance is required to create a delivery.';

  static const String helperLabel =
      'Minimum Wallet Balance Required: \$2';

  /// Mock wallet balance currently displayed in the UI.
  static double currentBalanceUsd() =>
      WalletService.availableUsd(WalletRole.sender);

  static bool get hasMinimumBalance =>
      currentBalanceUsd() >= minimumBalanceUsd;

  /// Returns null when parcel creation is allowed; otherwise an error message.
  static String? validate() {
    if (hasMinimumBalance) return null;
    return insufficientBalanceMessage;
  }
}
