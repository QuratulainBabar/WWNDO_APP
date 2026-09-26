import '../core/currency/app_currency.dart';
import 'models/wallet_role.dart';
import 'wallet_service.dart';

/// Frontend wallet gate for sender parcel / delivery creation.
abstract final class ParcelCreationWalletValidation {
  static const double minimumBalanceUsd = 2.0;

  static String get insufficientBalanceMessage =>
      'Minimum ${AppCurrencies.active.formatMajor(minimumBalanceUsd)} wallet balance is required to create a delivery.';

  static String get helperLabel =>
      'Minimum wallet balance: ${AppCurrencies.active.formatMajor(minimumBalanceUsd)} (platform fees apply when you pay)';

  static double currentBalanceUsd() =>
      WalletService.availableUsd(WalletRole.sender);

  static bool hasMinimumBalance() =>
      currentBalanceUsd() >= minimumBalanceUsd;

  static String? validate() {
    if (hasMinimumBalance()) return null;
    return insufficientBalanceMessage;
  }
}
