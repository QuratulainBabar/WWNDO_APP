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
import '../../core/widgets/app_avatar.dart';
import '../../core/widgets/app_badge.dart';
import '../../core/widgets/app_button.dart';
import '../../core/widgets/app_card.dart';
import '../../core/widgets/back_header.dart';
import '../../data/models/bid.dart';
import '../../data/models/created_delivery.dart';
import '../../data/models/matching_traveler.dart';
import '../../data/models/traveler_request_summary.dart';
import '../../data/platform_fees.dart';
import '../../data/services/delivery_repository.dart';
import '../../data/services/trip_repository.dart';
import '../../data/static_data.dart';
import '../../data/trip_date_window.dart';
import '../../data/wallet_service.dart';
import '../../core/widgets/app_toast.dart';
import '../../core/widgets/stacked_route_endpoints.dart';
import '../../core/time/local_time.dart';
import '../../providers/auth_provider.dart';
import '../../providers/notification_realtime_provider.dart';
import 'bid_acceptance_payment_screen.dart';
import 'bid_sort.dart';

class BidRequestsScreen extends StatefulWidget {
  const BidRequestsScreen({super.key, required this.shipmentId});

  final String shipmentId;

  @override
  State<BidRequestsScreen> createState() => _BidRequestsScreenState();
}

class _BidRequestsScreenState extends State<BidRequestsScreen> {
  BidSortOption _sort = BidSortOption.bestMatchScore;
  List<Bid>? _apiBids;
  CreatedDelivery? _delivery;
  List<TravelerRequestSummary> _travelerRequests = const [];
  bool _loading = true;
  bool _paying = false;
  bool _requesting = false;
  String? _error;

  NotificationRealtimeProvider? _realtimeProvider;
  VoidCallback? _realtimeListener;
  int _lastDeliveryUpdateTick = 0;
  int _loadGeneration = 0;

  TravelerRequestSummary? _requestFor(Bid bid) {
    for (final r in _travelerRequests) {
      if (r.tripId == bid.id || r.tripPublicId == bid.id) return r;
    }
    return null;
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _load();
      _attachRealtimeListener();
    });
  }

  void _attachRealtimeListener() {
    final realtime = context.read<NotificationRealtimeProvider>();
    if (_realtimeProvider == realtime && _realtimeListener != null) return;
    if (_realtimeListener != null) {
      _realtimeProvider?.removeListener(_realtimeListener!);
    }
    _realtimeProvider = realtime;
    _lastDeliveryUpdateTick = realtime.deliveryUpdateTick;
    _realtimeListener = () {
      if (!mounted) return;
      final tick = realtime.deliveryUpdateTick;
      if (tick != _lastDeliveryUpdateTick) {
        _lastDeliveryUpdateTick = tick;
        _load();
      }
    };
    realtime.addListener(_realtimeListener!);
  }

  @override
  void dispose() {
    if (_realtimeListener != null) {
      _realtimeProvider?.removeListener(_realtimeListener!);
    }
    super.dispose();
  }

  DeliveryRepository _repository() {
    final auth = context.read<AuthProvider>();
    return DeliveryRepository(
      apiClient: auth.repository.apiClient,
      demoMode: context.read<DemoModeProvider>(),
    );
  }

  TripRepository _tripRepository() {
    final auth = context.read<AuthProvider>();
    return TripRepository(
      apiClient: auth.repository.apiClient,
      demoMode: context.read<DemoModeProvider>(),
    );
  }

  Future<void> _load() async {
    final demo = context.read<DemoModeProvider>().enabled;
    if (demo) {
      setState(() {
        _loading = false;
        _error = 'Turn off Demo mode to browse matching travelers from the API.';
      });
      return;
    }

    final generation = ++_loadGeneration;
    // Soft refresh: keep the last good list visible so realtime reloads cannot
    // flash / stick on an empty state while a newer request is in flight.
    final hasCachedList = _apiBids != null && _delivery != null;
    if (!hasCachedList) {
      setState(() {
        _loading = true;
        _error = null;
      });
    } else if (_error != null) {
      setState(() => _error = null);
    }

    try {
      final repo = _repository();
      final results = await Future.wait([
        repo.getDelivery(widget.shipmentId, role: 'sender'),
        repo.listMatchingTravelers(widget.shipmentId),
        repo.listTravelerRequests(widget.shipmentId),
      ]);
      if (!mounted || generation != _loadGeneration) return;

      final delivery = results[0] as CreatedDelivery;
      // Same source as home matching badge counts: destination + luggage +
      // delivery-relative date window (delivery − 5 … delivery + 7).
      var travelers = results[1] as List<MatchingTraveler>;
      final deliveryDate = delivery.travelDateParsed;
      if (deliveryDate != null) {
        travelers = TripDateWindow.filterByDeliveryTravelDate(
          travelers,
          (t) => t.travelDate,
          deliveryDate,
        );
      }
      final bids = travelers.map((t) => t.toBid()).toList();
      if (bids.isNotEmpty) {
        // Highlight the best match for the existing card badge.
        final bestScore = bids
            .map((b) => b.routeMatchConfidence)
            .fold<int>(0, (a, b) => a > b ? a : b);
        for (var i = 0; i < bids.length; i++) {
          if (bids[i].routeMatchConfidence == bestScore) {
            bids[i] = bids[i].copyWith(featured: true);
            break;
          }
        }
      }
      // Keep StaticData in sync for any leftover demo/profile helpers.
      StaticData.replaceMatchingTravelersFromApi(
        shipmentId: delivery.displayId,
        bids: bids,
      );
      if (delivery.id.isNotEmpty && delivery.id != delivery.displayId) {
        StaticData.replaceMatchingTravelersFromApi(
          shipmentId: delivery.id,
          bids: bids,
        );
      }
      if (!mounted || generation != _loadGeneration) return;
      setState(() {
        _delivery = delivery;
        _apiBids = bids;
        _travelerRequests = results[2] as List<TravelerRequestSummary>;
        _loading = false;
        _error = null;
      });
    } on ApiException catch (e) {
      if (!mounted || generation != _loadGeneration) return;
      // Keep last good list on transient/realtime failures.
      if (hasCachedList) {
        setState(() => _loading = false);
        return;
      }
      setState(() {
        _loading = false;
        _error = e.message;
      });
    } catch (_) {
      if (!mounted || generation != _loadGeneration) return;
      if (hasCachedList) {
        setState(() => _loading = false);
        return;
      }
      setState(() {
        _loading = false;
        _error = 'Unable to load matching travelers.';
      });
    }
  }

  BidReviewStatus _reviewStatusFor(Bid bid) {
    final request = _requestFor(bid);
    if (request == null) return BidReviewStatus.open;
    if (request.isAccepted) return BidReviewStatus.approved;
    return BidReviewStatus.deliveryRequested;
  }

  Future<void> _payNow(Bid bid) async {
    if (_paying) return;
    final demo = context.read<DemoModeProvider>().enabled;
    if (demo) {
      AppToast.error(context, context.l10n.demoModeCompleteLivePayment);
      return;
    }

    final status = _reviewStatusFor(bid);
    if (status != BidReviewStatus.approved &&
        status != BidReviewStatus.accepted) {
      AppToast.info(
        context,
        context.l10n.payNowAfterAccept(bid.travelerName),
      );
      return;
    }

    setState(() => _paying = true);
    try {
      final offer = await _tripRepository().getSenderCounterOfferByDelivery(
        widget.shipmentId,
      );
      if (!mounted) return;

      final request = _requestFor(bid);
      final matchesRequest = request == null ||
          offer.requestId.isEmpty ||
          offer.requestId == request.id;
      final matchesTrip = offer.tripId.isEmpty ||
          bid.id.isEmpty ||
          offer.tripId == bid.id ||
          offer.tripId == (request?.tripPublicId ?? '');
      if (!matchesRequest || !matchesTrip) {
        AppToast.info(
          context,
          context.l10n.noPayableOfferFrom(bid.travelerName),
        );
        return;
      }

      if (!offer.isOpen && !offer.awaitsPayment) {
        AppToast.info(
          context,
          offer.isAccepted
              ? context.l10n.offerAlreadyPaidConfirmed
              : context.l10n.offerNoLongerAvailableToPay,
        );
        context.push('/sender-counter-offer/${offer.id}');
        return;
      }

      final delivery = _delivery;
      context.push(
        '/bid-acceptance-payment',
        extra: BidAcceptanceContext(
          bid: bid.copyWith(
            id: offer.id,
            price: offer.amount,
            travelerName: offer.travelerName,
            initial: offer.travelerInitial,
          ),
          shipmentId: widget.shipmentId,
          offerId: offer.id,
          parcelCategory: delivery?.parcelCategory ?? 'documents',
          paysReceiverFee: delivery != null
              ? PlatformFees.senderPaysReceiverFee(delivery)
              : false,
        ),
      );
    } on ApiException catch (e) {
      if (!mounted) return;
      if (e.statusCode == 404 || e.code == 'NOT_FOUND') {
        AppToast.info(
          context,
          context.l10n.waitingForAcceptPay(bid.travelerName),
        );
        return;
      }
      AppToast.error(context, e.message);
    } catch (_) {
      if (!mounted) return;
      AppToast.error(context, context.l10n.unableToStartPaymentNow);
    } finally {
      if (mounted) setState(() => _paying = false);
    }
  }

  bool get _atRequestLimit =>
      _travelerRequests.length >= PlatformFees.maxTravelerRequestsPerDelivery;

  Future<void> _selectTraveler(Bid bid) async {
    if (_requesting) return;
    if (_requestFor(bid) != null) return;
    if (_atRequestLimit) {
      AppToast.error(context, PlatformFees.travelerRequestLimitMessage);
      return;
    }

    final parcelWeight = _delivery?.weightKg;
    if (parcelWeight != null && !bid.canCarryWeightKg(parcelWeight)) {
      AppToast.error(
        context,
        context.l10n.travelerInsufficientLuggageCapacity,
      );
      return;
    }

    setState(() => _requesting = true);
    try {
      await _repository().requestTraveler(
        deliveryId: widget.shipmentId,
        tripId: bid.id,
        matchScore: bid.routeMatchConfidence,
      );
    } catch (e) {
      if (!mounted) return;
      final message = e is ApiException
          ? e.message
          : context.l10n.unableToSendRequestToTraveler;
      AppToast.error(context, message);
      return;
    } finally {
      if (mounted) setState(() => _requesting = false);
    }

    await _load();
    if (!mounted) return;
    context.push(
      '/traveler-selected-confirmation',
      extra: BidAcceptanceContext(
        bid: bid,
        shipmentId: widget.shipmentId,
        activeRequestCount: _travelerRequests.length,
      ),
    );
  }

  List<Bid> _visibleBids() {
    final sorted = BidSortOption.sorted(_apiBids ?? const [], _sort);
    final selected = <Bid>[];
    final rest = <Bid>[];
    for (final bid in sorted) {
      if (_requestFor(bid) != null) {
        selected.add(bid);
      } else {
        rest.add(bid);
      }
    }
    return [...selected, ...rest];
  }

  @override
  Widget build(BuildContext context) {
    final typo = context.typo;
    final delivery = _delivery;
    final bids = _visibleBids();

    if (_loading) {
      return Scaffold(
        backgroundColor: AppColors.background,
        appBar: BackHeader(title: context.l10n.matchingTravelers),
        body: const Center(
          child: SizedBox(
            width: 28,
            height: 28,
            child: CircularProgressIndicator(strokeWidth: 2.5),
          ),
        ),
      );
    }

    if (_error != null || delivery == null) {
      return Scaffold(
        backgroundColor: AppColors.background,
        appBar: BackHeader(title: context.l10n.matchingTravelers),
        body: Center(
          child: Padding(
            padding: context.pagePadding,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  context.tr(_error ?? 'This delivery could not be found.'),
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

    final summary = _ParcelSummary(
      id: delivery.displayId,
      from: delivery.exactDisplayFrom,
      to: delivery.exactDisplayTo,
      route: delivery.exactDisplayRoute.isNotEmpty
          ? delivery.exactDisplayRoute
          : '—',
      travelDate: delivery.travelDateParsed ?? DateTime.now(),
      weightKg: delivery.weightKg,
    );

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: BackHeader(title: context.l10n.matchingTravelers),
      body: ListView.builder(
        physics: PlatformUi.scrollPhysics,
        padding: context.pagePadding,
        itemCount: bids.length + 3,
        itemBuilder: (context, i) {
          if (i == 0) {
            return Padding(
              padding: EdgeInsets.only(bottom: bids.isEmpty ? 0 : 12),
              child: _ParcelSummaryCard(summary: summary),
            );
          }

          if (i == 1) {
            return Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: _SelectedTravelersCard(
                requests: _travelerRequests,
                maxCount: PlatformFees.maxTravelerRequestsPerDelivery,
              ),
            );
          }

          if (i == 2) {
            return Padding(
              padding: EdgeInsets.only(bottom: bids.isEmpty ? 0 : 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    context.l10n.sortBy,
                    style: context.typo.sm.copyWith(
                      fontWeight: FontWeight.w600,
                      color: AppColors.textSecondary,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    context.l10n.matchingListHint,
                    style: context.typo.sm.copyWith(
                      color: AppColors.textSecondary,
                    ),
                  ),
                  const SizedBox(height: 6),
                  _SortOptionGrid(
                    options: BidSortOption.labels,
                    selected: _sort.label,
                    onSelected: (label) {
                      setState(() => _sort = BidSortOption.fromLabel(label));
                    },
                  ),
                  if (bids.isEmpty) ...[
                    const SizedBox(height: 16),
                    AppCard(
                      child: Text(
                        context.l10n.noMatchingTravelersOnRoute,
                        style: typo.sm.copyWith(color: AppColors.textSecondary),
                      ),
                    ),
                  ],
                ],
              ),
            );
          }

          final bid = bids[i - 3];
          final status = _reviewStatusFor(bid);
          return _MatchingTravelerCard(
            bid: bid,
            status: status,
            paying: _paying,
            atLimit: _atRequestLimit,
            requesting: _requesting,
            onViewProfile: () => context.push(
              '/bid-traveler-profile',
              extra: BidAcceptanceContext(
                bid: bid,
                shipmentId: widget.shipmentId,
                activeRequestCount: _travelerRequests.length,
              ),
            ),
            onSelectTraveler: () => _selectTraveler(bid),
            onPayNow: () => _payNow(bid),
          );
        },
      ),
    );
  }
}

class _ParcelSummary {
  const _ParcelSummary({
    required this.id,
    required this.from,
    required this.to,
    required this.route,
    required this.travelDate,
    required this.weightKg,
  });

  final String id;
  final String from;
  final String to;
  final String route;
  final DateTime travelDate;
  final double weightKg;
}

class _ParcelSummaryCard extends StatelessWidget {
  const _ParcelSummaryCard({required this.summary});

  final _ParcelSummary summary;

  @override
  Widget build(BuildContext context) {
    final typo = context.typo;

    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            summary.id,
            style: typo.h3.copyWith(
              fontWeight: FontWeight.w700,
              color: AppColors.primary,
            ),
          ),
          const SizedBox(height: 8),
          StackedRouteEndpoints(
            from: summary.from,
            to: summary.to,
            fallbackRoute: summary.route,
          ),
          const SizedBox(height: 4),
          Text(
            '${context.l10n.travelDateColon(DateFormat('MMM d, yyyy', context.l10n.locale.toString()).format(summary.travelDate))}'
            ' · ${context.l10n.weightColon('${summary.weightKg} kg')}',
            style: typo.sm.copyWith(color: AppColors.textSecondary),
          ),
          const SizedBox(height: 12),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.kycBackground,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(Icons.auto_awesome, size: 18, color: AppColors.primary),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        context.l10n.receiverHasAcceptedRequest,
                        style: typo.sm.copyWith(
                          fontWeight: FontWeight.w700,
                          color: AppColors.primaryDark,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        context.l10n.bestMatchingTravelersIntro,
                        style: typo.sm.copyWith(color: AppColors.primary),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _SelectedTravelersCard extends StatelessWidget {
  const _SelectedTravelersCard({
    required this.requests,
    required this.maxCount,
  });

  final List<TravelerRequestSummary> requests;
  final int maxCount;

  @override
  Widget build(BuildContext context) {
    final typo = context.typo;
    final remaining = maxCount - requests.length;

    String hint;
    if (requests.isEmpty) {
      hint = context.l10n.canRequestUpToTwoTravelers;
    } else if (remaining > 0) {
      hint = remaining == 1
          ? context.l10n.canRequestOneMoreTraveler
          : context.l10n.canRequestMoreTravelersCount('$remaining');
    } else {
      hint = context.l10n.maximumTravelersRequestedForParcel('$maxCount');
    }

    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            context.l10n.selectedTravelersCount(
              '${requests.length}',
              '$maxCount',
            ),
            style: typo.bodyBold.copyWith(fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 4),
          Text(
            hint,
            style: typo.sm.copyWith(color: AppColors.textSecondary),
          ),
          if (requests.isNotEmpty) ...[
            const SizedBox(height: 12),
            for (var i = 0; i < requests.length; i++) ...[
              if (i > 0) const SizedBox(height: 10),
              _SelectedTravelerRow(request: requests[i]),
            ],
          ],
        ],
      ),
    );
  }
}

class _SelectedTravelerRow extends StatelessWidget {
  const _SelectedTravelerRow({required this.request});

  final TravelerRequestSummary request;

  @override
  Widget build(BuildContext context) {
    final typo = context.typo;
    final name = request.travelerName;
    final initial = name.isNotEmpty ? name[0] : '?';
    final accepted = request.isAccepted;

    return Row(
      children: [
        AppAvatar(initial: initial, size: AvatarSize.small),
        const SizedBox(width: 10),
        Expanded(
          child: Text(name, style: typo.sm.copyWith(fontWeight: FontWeight.w600)),
        ),
        AppBadge(
          label: accepted ? context.tr('Accepted') : context.tr('Requested'),
          color: accepted ? AppColors.primary : AppColors.warning,
          backgroundColor: (accepted ? AppColors.primary : AppColors.warning)
              .withValues(alpha: 0.12),
        ),
      ],
    );
  }
}

class _MatchingTravelerCard extends StatelessWidget {
  const _MatchingTravelerCard({
    required this.bid,
    required this.status,
    required this.paying,
    required this.atLimit,
    required this.requesting,
    required this.onViewProfile,
    required this.onSelectTraveler,
    required this.onPayNow,
  });

  final Bid bid;
  final BidReviewStatus status;
  final bool paying;
  final bool atLimit;
  final bool requesting;
  final VoidCallback onViewProfile;
  final VoidCallback onSelectTraveler;
  final VoidCallback onPayNow;

  @override
  Widget build(BuildContext context) {
    final typo = context.typo;
    final requested = status == BidReviewStatus.deliveryRequested;
    final accepted = status == BidReviewStatus.approved ||
        status == BidReviewStatus.accepted;
    final alreadyChosen = requested || accepted;
    final canSendRequest = !alreadyChosen && !requesting;

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: AppCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                AppAvatar(initial: bid.initial, size: AvatarSize.medium),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(bid.travelerName, style: typo.bodyBold),
                      Text(
                        '★ ${context.l10n.ratingReviewsCount(bid.rating.toStringAsFixed(1), '${bid.reviewCount}')}',
                        style: typo.sm.copyWith(color: AppColors.textSecondary),
                      ),
                    ],
                  ),
                ),
                if (accepted)
                  AppBadge(
                    label: context.tr('Accepted'),
                    color: AppColors.primary,
                    backgroundColor: AppColors.primary.withValues(alpha: 0.12),
                  )
                else if (requested)
                  AppBadge(
                    label: context.tr('Requested'),
                    color: AppColors.warning,
                    backgroundColor: AppColors.warning.withValues(alpha: 0.12),
                  )
                else if (bid.featured)
                  AppBadge.success(context.l10n.bestMatchBadge),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              context.l10n.amountProposed(WalletService.formatMajor(bid.price)),
              style: typo.sm.copyWith(color: AppColors.textSecondary),
            ),
            const SizedBox(height: 4),
            Text(
              [
                context.l10n.travelDateColon(
                  DateFormat(
                    'MMM d, yyyy',
                    context.l10n.locale.toString(),
                  ).format(bid.travelDate),
                ),
                context.l10n.matchPercentLabel('${bid.routeMatchConfidence}'),
              ].join(' · '),
              style: typo.sm.copyWith(color: AppColors.textSecondary),
            ),
            if (bid.departureTime?.trim().isNotEmpty == true) ...[
              const SizedBox(height: 4),
              Text(
                context.l10n.departureTimeColon(
                  LocalTime.formatDepartureTime(
                    bid.departureTime,
                    context.l10n.locale.toString(),
                  ),
                ),
                style: typo.sm.copyWith(color: AppColors.textSecondary),
              ),
            ],
            if (bid.travelMethodLabel != null) ...[
              const SizedBox(height: 4),
              Text(
                context.l10n.travelMethodColon(
                  context.tr(bid.travelMethodLabel!),
                ),
                style: typo.sm.copyWith(color: AppColors.textSecondary),
              ),
            ],
            const SizedBox(height: 12),
            Row(
              children: [
                _rowActionButton(
                  context,
                  label: context.l10n.viewProfile,
                  onPressed: onViewProfile,
                ),
                const SizedBox(width: 8),
                _rowActionButton(
                  context,
                  label: accepted || requested
                      ? context.l10n.requestedLabel
                      : atLimit
                          ? context.l10n.limitReached
                          : requesting
                              ? context.l10n.sendingEllipsis
                              : context.l10n.sendRequest,
                  onPressed: canSendRequest ? onSelectTraveler : null,
                ),
              ],
            ),
            const SizedBox(height: 8),
            AppButton(
              label: paying ? context.l10n.openingPaymentEllipsis : context.l10n.payNow,
              small: true,
              // Enabled only after this traveler accepted the sender request.
              onPressed: paying || !accepted ? null : onPayNow,
            ),
          ],
        ),
      ),
    );
  }

  Widget _rowActionButton(
    BuildContext context, {
    required String label,
    required VoidCallback? onPressed,
  }) {
    final typo = context.typo;
    return Expanded(
      child: SizedBox(
        height: 40,
        child: OutlinedButton(
          onPressed: onPressed,
          style: OutlinedButton.styleFrom(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
            minimumSize: Size.zero,
            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
            side: BorderSide(color: AppColors.border, width: 1.5),
            foregroundColor: AppColors.textPrimary,
            disabledForegroundColor: AppColors.textDisabled,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
          ),
          child: FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(
              label,
              maxLines: 1,
              textAlign: TextAlign.center,
              style: typo.buttonSm.copyWith(
                color: onPressed == null
                    ? AppColors.textDisabled
                    : AppColors.textPrimary,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Equal-size 2x2 grid of sort chips (mirrors the traveler home quick
/// actions layout) so labels of different lengths don't distort chip size.
class _SortOptionGrid extends StatelessWidget {
  const _SortOptionGrid({
    required this.options,
    required this.selected,
    required this.onSelected,
  });

  final List<String> options;
  final String selected;
  final ValueChanged<String> onSelected;

  @override
  Widget build(BuildContext context) {
    final typo = context.typo;
    final labelStyle = typo.chip.copyWith(height: 1.2);
    const horizontalPad = 20.0; // 10 + 10
    const verticalPad = 20.0; // 10 + 10
    const gridGap = 8.0;
    const borderWidth = 1.5;

    return LayoutBuilder(
      builder: (context, constraints) {
        final tileWidth = (constraints.maxWidth - gridGap) / 2;
        final labelMaxWidth =
            (tileWidth - horizontalPad).clamp(0.0, double.infinity);
        final textScaler = MediaQuery.textScalerOf(context);
        final textDirection = Directionality.of(context);

        var labelBlockHeight = 0.0;
        for (final option in options) {
          final painter = TextPainter(
            text: TextSpan(
              text: context.tr(option),
              style: labelStyle,
            ),
            textAlign: TextAlign.center,
            textDirection: textDirection,
            textScaler: textScaler,
            maxLines: 2,
            ellipsis: '…',
          )..layout(maxWidth: labelMaxWidth);
          if (painter.height > labelBlockHeight) {
            labelBlockHeight = painter.height;
          }
        }
        // Buffer for glyph metrics / rounding across locales.
        labelBlockHeight += 4;

        final tileHeight =
            verticalPad + labelBlockHeight + (borderWidth * 2);

        return GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: options.length,
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            mainAxisSpacing: gridGap,
            crossAxisSpacing: gridGap,
            mainAxisExtent: tileHeight,
          ),
          itemBuilder: (context, index) {
            final option = options[index];
            final isSelected = option == selected;
            return GestureDetector(
              onTap: () => onSelected(option),
              child: Container(
                alignment: Alignment.center,
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
                decoration: BoxDecoration(
                  color: isSelected
                      ? AppColors.primary.withValues(alpha: 0.08)
                      : null,
                  border: Border.all(
                    color: isSelected ? AppColors.primary : AppColors.border,
                    width: borderWidth,
                  ),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Text(
                  context.tr(option),
                  maxLines: 2,
                  textAlign: TextAlign.center,
                  overflow: TextOverflow.ellipsis,
                  style: labelStyle.copyWith(
                    color: isSelected
                        ? AppColors.primary
                        : AppColors.textSecondary,
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }
}
