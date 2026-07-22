import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../core/widgets/app_toast.dart';
import '../../data/models/traveler_trip.dart';
import '../../data/static_data.dart';
import '../../data/trip_creation_wallet_validation.dart';
import '../../providers/auth_provider.dart';

/// Shared gate + post helper for traveler trip creation screens.
abstract final class TripPostingActions {
  /// Blocks trip creation when the displayed mock wallet balance is below
  /// [TripCreationWalletValidation.minimumBalanceUsd].
  ///
  /// Shows the required toast and returns `false` when blocked.
  static bool ensureWalletAllowsTripCreation(BuildContext context) {
    final error = TripCreationWalletValidation.validate();
    if (error == null) return true;

    _showInsufficientBalanceFeedback(context, error);
    return false;
  }

  static void _showInsufficientBalanceFeedback(
    BuildContext context,
    String message,
  ) {
    AppToast.error(context, message);
  }

  static bool tryPostTrip(BuildContext context, TravelerTrip trip) {
    // Wallet gate first so the $3 message is never masked by other dialogs.
    if (!ensureWalletAllowsTripCreation(context)) return false;

    final authUser = context.read<AuthProvider>().user;
    final kycError = StaticData.validateKycApproved(authUser);
    if (kycError != null) {
      AppToast.error(context, kycError);
      return false;
    }

    StaticData.addTravelerPostedTrip(trip);
    context.go('/post-trip/success', extra: trip.route);
    return true;
  }
}
