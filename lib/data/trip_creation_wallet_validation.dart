import 'models/wallet_role.dart';
import 'wallet_service.dart';

/// Frontend wallet gate for traveler trip creation.
///
/// Uses the same mock balance shown in the Traveler Home [WalletCard]
/// via [WalletService]. Replace [currentBalanceUsd] with a backend-backed
/// lookup later without changing UI call sites.
abstract final class TripCreationWalletValidation {
  static const double minimumBalanceUsd = 3.0;

  static const String insufficientBalanceMessage =
      'Minimum \$3 wallet balance is required to create a trip.';

  static const String helperLabel =
      'Minimum Wallet Balance Required: \$3';

  /// Mock wallet balance currently displayed in the UI.
  static double currentBalanceUsd() =>
      WalletService.availableUsd(WalletRole.traveler);

  static bool get hasMinimumBalance =>
      currentBalanceUsd() >= minimumBalanceUsd;

  /// Returns null when trip creation is allowed; otherwise an error message.
  static String? validate() {
    if (hasMinimumBalance) return null;
    return insufficientBalanceMessage;
  }
}
