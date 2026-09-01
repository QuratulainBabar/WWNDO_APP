import 'models/wallet_role.dart';
import 'wallet_service.dart';

/// Frontend wallet gate for traveler trip creation.
abstract final class TripCreationWalletValidation {
  static const double minimumBalanceUsd = 2.0;

  static const String insufficientBalanceMessage =
      'Minimum \$2 wallet balance is required to create a trip.';

  static const String helperLabel =
      'Minimum wallet balance: \$2 (platform fees apply at booking)';

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
