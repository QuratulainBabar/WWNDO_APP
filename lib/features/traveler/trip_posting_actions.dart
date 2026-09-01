import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../core/api/api_exception.dart';
import '../../core/config/demo_mode.dart';
import '../../core/widgets/app_toast.dart';
import '../../data/models/traveler_trip.dart';
import '../../data/services/trip_repository.dart';
import '../../data/kyc_validation.dart';
import '../../providers/auth_provider.dart';

/// Shared gate + post helper for traveler trip creation screens.
abstract final class TripPostingActions {
  /// Posts a trip via POST /api/v1/trips (demo mode keeps local StaticData).
  static Future<bool> tryPostTrip(
    BuildContext context,
    TravelerTrip trip, {
    required CreateTripRequest request,
  }) async {
    final auth = context.read<AuthProvider>();
    final authUser = auth.user;
    final kycError = KycValidation.validateApproved(authUser);
    if (kycError != null) {
      AppToast.error(context, kycError);
      return false;
    }

    final demoMode = context.read<DemoModeProvider>();
    if (demoMode.enabled) {
      if (context.mounted) {
        AppToast.error(context, 'Turn off Demo mode to post trips to the server.');
      }
      return false;
    }

    try {
      final created = await TripRepository(
        apiClient: auth.repository.apiClient,
        demoMode: demoMode,
      ).createTrip(request);

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
