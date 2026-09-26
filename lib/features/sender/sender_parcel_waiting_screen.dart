import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../l10n/app_localizations.dart';

import '../../core/api/api_exception.dart';
import '../../core/config/demo_mode.dart';
import '../../core/layout/responsive.dart';
import '../../core/platform/platform_ui.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_typography.dart';
import '../../core/widgets/app_button.dart';
import '../../core/widgets/back_header.dart';
import '../../core/widgets/stacked_route_endpoints.dart';
import '../../data/delivery_status_mapper.dart';
import '../../data/models/created_delivery.dart';
import '../../data/models/shipment.dart';
import '../../data/models/traveler_request_summary.dart';
import '../../data/services/delivery_live_loader.dart';
import '../../data/services/delivery_repository.dart';
import '../../data/services/fulfillment_repository.dart';
import '../../providers/auth_provider.dart';

/// Intermediate screen while a posted delivery is not yet trackable.
class SenderParcelWaitingScreen extends StatefulWidget {
  const SenderParcelWaitingScreen({super.key, required this.shipmentId});

  final String shipmentId;

  @override
  State<SenderParcelWaitingScreen> createState() =>
      _SenderParcelWaitingScreenState();
}

class _SenderParcelWaitingScreenState extends State<SenderParcelWaitingScreen>
    with WidgetsBindingObserver {
  bool _loading = true;
  bool _redirecting = false;
  String? _error;
  DeliveryLiveSnapshot? _snapshot;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    WidgetsBinding.instance.addPostFrameCallback((_) => _load());
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _load(silent: true);
    }
  }

  void _redirectIfNeeded(
    CreatedDelivery delivery, {
    List<TravelerRequestSummary> travelerRequests = const [],
  }) {
    final phase = DeliveryStatusMapper.postedPhaseFor(
      delivery: delivery,
      travelerRequests: travelerRequests,
    );
    if (phase == SenderPostedPhase.waitingForReceiver) return;
    if (!mounted) return;

    final status = delivery.status?.trim().toLowerCase();
    final route = status != null && status.isNotEmpty && status != 'posted'
        ? '/shipment/${delivery.displayId}'
        : DeliveryStatusMapper.senderDetailRouteFor(
            delivery,
            travelerRequests: travelerRequests,
          );

    setState(() => _redirecting = true);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      context.go(route);
    });
  }

  Future<void> _load({bool silent = false}) async {
    final demo = context.read<DemoModeProvider>().enabled;
    if (demo) {
      if (!silent) {
        setState(() {
          _loading = false;
          _error = 'Turn off Demo mode to view live delivery status.';
        });
      }
      return;
    }

    if (!silent) {
      setState(() {
        _loading = true;
        _error = null;
      });
    }

    try {
      final auth = context.read<AuthProvider>();
      final repo = DeliveryRepository(
        apiClient: auth.repository.apiClient,
        demoMode: context.read<DemoModeProvider>(),
      );
      final snapshot = await DeliveryLiveLoader.load(
        deliveryRepo: repo,
        fulfillmentRepo: FulfillmentRepository(apiClient: auth.repository.apiClient),
        deliveryId: widget.shipmentId,
        includeMatchingCount: true,
      );
      if (!mounted) return;
      final delivery = snapshot.delivery;
      final phase = DeliveryStatusMapper.postedPhaseFor(
        delivery: delivery,
        travelerRequests: snapshot.travelerRequests,
      );
      if (phase != SenderPostedPhase.waitingForReceiver) {
        _redirectIfNeeded(
          delivery,
          travelerRequests: snapshot.travelerRequests,
        );
        return;
      }
      setState(() {
        _snapshot = snapshot;
        _loading = false;
      });
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _error = e.message;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _error = 'Unable to load delivery status.';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final typo = context.typo;

    if (_loading || _redirecting) {
      return Scaffold(
        backgroundColor: AppColors.surface,
        appBar: BackHeader(
          title: widget.shipmentId,
          fallbackRoute: '/my-posted-parcels',
        ),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    if (_error != null || _snapshot == null) {
      return Scaffold(
        backgroundColor: AppColors.surface,
        appBar: BackHeader(
          title: widget.shipmentId,
          fallbackRoute: '/my-posted-parcels',
        ),
        body: Center(
          child: Padding(
            padding: context.pagePadding,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  _error ?? 'Delivery not found.',
                  textAlign: TextAlign.center,
                  style: typo.sm.copyWith(color: AppColors.textSecondary),
                ),
                const SizedBox(height: 16),
                TextButton(onPressed: _load, child: Text(context.tr('Retry'))),
              ],
            ),
          ),
        ),
      );
    }

    final delivery = _snapshot!.delivery;
    final phase = DeliveryStatusMapper.postedPhaseFor(
      delivery: delivery,
      travelerRequests: _snapshot!.travelerRequests,
    );
    if (phase != SenderPostedPhase.waitingForReceiver) {
      return const SizedBox.shrink();
    }
    final isAwaitingTraveler = phase == SenderPostedPhase.travelerReviewing;
    final requests = _snapshot!.travelerRequests;

    final title = isAwaitingTraveler
        ? 'Awaiting traveler acceptance'
        : 'Waiting for receiver acceptance';
    final body = isAwaitingTraveler
        ? (requests.isEmpty
            ? 'We have sent a request to the traveler. Tracking unlocks after they accept.'
            : requests.length == 1
                ? 'We have sent a request to ${requests.first.travelerName}. Tracking unlocks after they accept.'
                : 'We have sent requests to ${requests.length} travelers. Tracking unlocks after one accepts.')
        : "We've notified your receiver.\nThe matching process will start once they accept.";

    final travelDate = delivery.travelDateParsed;

    return Scaffold(
      backgroundColor: AppColors.surface,
      appBar: BackHeader(
        title: delivery.displayId,
        fallbackRoute: '/my-posted-parcels',
      ),
      body: SafeArea(
        child: Padding(
          padding: context.pagePadding,
          child: Column(
            children: [
              Expanded(
                child: SingleChildScrollView(
                  physics: PlatformUi.scrollPhysics,
                  child: Column(
                    children: [
                      const SizedBox(height: 24),
                      Container(
                        width: 72,
                        height: 72,
                        decoration: BoxDecoration(
                          color: AppColors.warning.withValues(alpha: 0.14),
                          shape: BoxShape.circle,
                        ),
                        alignment: Alignment.center,
                        child: const Icon(
                          Icons.hourglass_top_rounded,
                          size: 36,
                          color: AppColors.warning,
                        ),
                      ),
                      const SizedBox(height: 20),
                      Text(
                        title,
                        style: typo.h1.copyWith(fontWeight: FontWeight.w700),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 10),
                      StackedRouteEndpoints(
                        from: delivery.exactDisplayFrom,
                        to: delivery.exactDisplayTo,
                        fallbackRoute: delivery.exactDisplayRoute.isNotEmpty
                            ? delivery.exactDisplayRoute
                            : delivery.route,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Travel date: ${travelDate != null ? DateFormat('MMM d, yyyy').format(travelDate) : delivery.travelDate}',
                        textAlign: TextAlign.center,
                        style: typo.sm.copyWith(
                          height: 1.5,
                          color: AppColors.textSecondary,
                        ),
                      ),
                      const SizedBox(height: 24),
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 18,
                          vertical: 20,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.kycBackground,
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Text(
                          body,
                          style: typo.sm.copyWith(
                            height: 1.5,
                            color: AppColors.textSecondary,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              if (phase == SenderPostedPhase.matchingTravelers)
                AppButton(
                  label: 'View Matching Travelers',
                  onPressed: () =>
                      context.push('/bid-requests/${delivery.displayId}'),
                )
              else
                AppButton(
                  label: 'Go to My Deliveries',
                  onPressed: () => context.go('/my-posted-parcels'),
                ),
              const SizedBox(height: AppButton.stackGap),
              AppButton(
                label: 'Back to Home',
                variant: AppButtonVariant.outline,
                onPressed: () => context.go('/home'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
