import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../core/api/api_exception.dart';
import '../../core/config/demo_mode.dart';
import '../../core/widgets/app_toast.dart';
import '../../data/models/traveler_trip.dart';
import '../../data/services/trip_repository.dart';
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

  /// Posts a trip via POST /api/v1/trips (demo mode keeps local StaticData).
  static Future<bool> tryPostTrip(
    BuildContext context,
    TravelerTrip trip, {
    required CreateTripRequest request,
  }) async {
    // Wallet gate first so the $3 message is never masked by other dialogs.
    if (!ensureWalletAllowsTripCreation(context)) return false;

    final auth = context.read<AuthProvider>();
    final authUser = auth.user;
    final kycError = StaticData.validateKycApproved(authUser);
    if (kycError != null) {
      AppToast.error(context, kycError);
      return false;
    }

    final demoMode = context.read<DemoModeProvider>();
    if (demoMode.enabled) {
      StaticData.addTravelerPostedTrip(trip);
      if (context.mounted) {
        context.go('/post-trip/success', extra: trip.route);
      }
      return true;
    }

    try {
      final created = await TripRepository(
        apiClient: auth.repository.apiClient,
        demoMode: demoMode,
      ).createTrip(request);

      StaticData.addTravelerPostedTrip(
        TravelerTrip(
          id: created.id,
          origin: created.origin,
          destination: created.destination,
          travelDate: created.travelDate,
          luggageCapacityKg: created.luggageCapacityKg,
          status: created.status,
        ),
      );

      if (!context.mounted) return true;
      context.go('/post-trip/success', extra: created.route);
      return true;
    } on ApiException catch (e) {
      if (context.mounted) AppToast.error(context, e.message);
      return false;
    } catch (e) {
      if (context.mounted) {
        AppToast.error(
          context,
          e.toString().replaceFirst('Exception: ', ''),
        );
      }
      return false;
    }
  }
}
