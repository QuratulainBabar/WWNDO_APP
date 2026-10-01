import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../l10n/app_localizations.dart';

import '../../core/api/api_exception.dart';
import '../../core/config/demo_mode.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_typography.dart';
import '../../core/widgets/app_button.dart';
import '../../core/widgets/app_card.dart';
import '../../core/widgets/app_toast.dart';
import '../../core/widgets/back_header.dart';
import '../../core/widgets/cancel_request_confirmation_dialog.dart';
import '../../core/widgets/scrollable_form_screen.dart';
import '../../core/widgets/stacked_route_endpoints.dart';
import '../../data/models/traveler_trip.dart';
import '../../data/services/trip_repository.dart';
import '../../data/delivery_cancel_policy.dart';
import '../../data/static_data.dart';
import '../../providers/auth_provider.dart';

class CancelTripScreen extends StatefulWidget {
  const CancelTripScreen({super.key, required this.tripId});

  final String tripId;

  @override
  State<CancelTripScreen> createState() => _CancelTripScreenState();
}

class _CancelTripScreenState extends State<CancelTripScreen> {
  TravelerTrip? _trip;
  bool _loading = true;
  String? _loadError;
  bool _cancelling = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _load());
  }

  TripRepository _repository() {
    final auth = context.read<AuthProvider>();
    final demoMode = context.read<DemoModeProvider>();
    return TripRepository(
      apiClient: auth.repository.apiClient,
      demoMode: demoMode,
    );
  }

  String _blockedMessage(BuildContext context) {
    return context.l10n.travelerCancelBlocked(
      '${DeliveryCancelPolicy.travelerCancelMinHoursBeforeTravel}',
    );
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _loadError = null;
    });

    final demoMode = context.read<DemoModeProvider>().enabled;
    if (demoMode) {
      final trip = StaticData.travelerTripById(widget.tripId) ??
          (StaticData.travelerPostedTrips.isNotEmpty
              ? StaticData.travelerPostedTrips.first
              : null);
      if (!mounted) return;
      if (trip == null) {
        setState(() {
          _loading = false;
          _loadError = context.l10n.tripNotFound;
        });
        return;
      }
      setState(() {
        _trip = trip;
        _loading = false;
      });
      return;
    }

    try {
      final trip = await _repository().getMyTrip(widget.tripId);
      if (!mounted) return;
      setState(() {
        _trip = trip;
        _loading = false;
      });
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _loadError = e.message;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _loadError = context.l10n.unableToLoadTrip;
      });
    }
  }

  Future<void> _confirmCancel() async {
    final trip = _trip;
    if (trip == null) return;

    final demoMode = context.read<DemoModeProvider>().enabled;
    final blocked = _blockedMessage(context);

    if (demoMode) {
      if (!StaticData.canTravelerCancelTrip(trip)) {
        AppToast.error(context, blocked);
        return;
      }
    } else if (trip.status != TripStatus.openBid) {
      AppToast.error(context, blocked);
      return;
    }

    final confirmed = await showCancelRequestConfirmation(
      context,
      keepButtonFirst: true,
    );
    if (!confirmed || !mounted) return;

    if (demoMode) {
      final cancelled = StaticData.tryCancelTravelerTrip(trip.id);
      if (!cancelled) {
        AppToast.error(context, blocked);
        return;
      }
      AppToast.success(context, context.l10n.itemCancelled(trip.displayId));
      context.go('/traveler-trips');
      return;
    }

    setState(() => _cancelling = true);
    try {
      await _repository().cancelTrip(trip.displayId);
      if (!mounted) return;
      AppToast.success(context, context.l10n.itemCancelled(trip.displayId));
      context.go('/traveler-trips');
    } on ApiException catch (e) {
      if (!mounted) return;
      AppToast.error(context, e.message);
    } catch (_) {
      if (!mounted) return;
      AppToast.error(context, context.l10n.unableToCancelTrip);
    } finally {
      if (mounted) setState(() => _cancelling = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final typo = context.typo;
    final l10n = context.l10n;

    if (_loading) {
      return Scaffold(
        backgroundColor: AppColors.background,
        appBar: BackHeader(
          title: l10n.cancelTrip,
          fallbackRoute: '/traveler-trips',
        ),
        body: const Center(
          child: CircularProgressIndicator(color: AppColors.primary),
        ),
      );
    }

    if (_loadError != null || _trip == null) {
      return Scaffold(
        backgroundColor: AppColors.background,
        appBar: BackHeader(
          title: l10n.cancelTrip,
          fallbackRoute: '/traveler-trips',
        ),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  _loadError ?? l10n.tripNotFound,
                  textAlign: TextAlign.center,
                  style: typo.sm.copyWith(color: AppColors.textSecondary),
                ),
                const SizedBox(height: 16),
                TextButton(onPressed: _load, child: Text(l10n.retry)),
              ],
            ),
          ),
        ),
      );
    }

    final trip = _trip!;
    if (!trip.status.canEditOrCancel) {
      return Scaffold(
        backgroundColor: AppColors.background,
        appBar: BackHeader(
          title: l10n.cancelTripWithId(trip.displayId),
          fallbackRoute: '/traveler-trips',
        ),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Text(
              trip.status.isCompleted
                  ? l10n.completedTripsCannotBeCancelled
                  : l10n.tripCannotBeCancelledAtStage,
              textAlign: TextAlign.center,
              style: typo.sm.copyWith(color: AppColors.textSecondary),
            ),
          ),
        ),
      );
    }

    final demoMode = context.read<DemoModeProvider>().enabled;
    final canCancel = demoMode
        ? StaticData.canTravelerCancelTrip(trip)
        : trip.status == TripStatus.openBid;
    final noRequests = demoMode &&
        StaticData.matchingRequestCountForTrip(trip.id) == 0 &&
        trip.status == TripStatus.openBid;
    final travelWindowOpen = DeliveryCancelPolicy.canTravelerCancelBeforeTravel(
      trip.travelDate,
    );
    final hours =
        '${DeliveryCancelPolicy.travelerCancelMinHoursBeforeTravel}';

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: BackHeader(
        title: l10n.cancelTripWithId(trip.displayId),
        fallbackRoute: '/traveler-trips',
      ),
      body: ScrollableFormScreen(
        actions: [
          AppButton(
            label: l10n.keepTrip,
            variant: AppButtonVariant.ghost,
            onPressed: _cancelling ? null : () => context.pop(),
          ),
          AppButton(
            label: _cancelling ? l10n.cancellingEllipsis : l10n.cancelTrip,
            variant: AppButtonVariant.danger,
            onPressed: _cancelling || !canCancel ? null : _confirmCancel,
          ),
        ],
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              l10n.cancelTripConfirmTitle,
              style: typo.h3.copyWith(fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 8),
            Text(
              l10n.cancelTripConfirmBody,
              style: typo.sm.copyWith(color: AppColors.textSecondary),
            ),
            const SizedBox(height: 12),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: canCancel
                    ? AppColors.success.withValues(alpha: 0.1)
                    : AppColors.danger.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                canCancel
                    ? (noRequests
                        ? l10n.cancelTripNoRequestsYet
                        : (travelWindowOpen
                            ? l10n.cancelTripHoursBeforeFlight(hours)
                            : l10n.cancelTripMayBeBlocked(hours)))
                    : _blockedMessage(context),
                style: typo.sm.copyWith(
                  height: 1.45,
                  color: canCancel ? AppColors.success : AppColors.danger,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: AppCard(
                margin: EdgeInsets.zero,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    StackedRouteEndpoints(
                      from: trip.displayOrigin,
                      to: trip.displayDestination,
                      fallbackRoute: trip.route,
                      emphasized: true,
                    ),
                    const SizedBox(height: 6),
                    Text(
                      DateFormat.yMMMd(Localizations.localeOf(context).toString())
                          .format(trip.travelDate),
                      style: typo.sm.copyWith(color: AppColors.textSecondary),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      l10n.luggageAvailable(
                        trip.luggageCapacityKg.toStringAsFixed(0),
                      ),
                      style: typo.sm.copyWith(
                        color: AppColors.primary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
