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
import '../../core/widgets/app_toast.dart';
import '../../core/time/local_time.dart';
import '../../data/models/bid.dart';
import '../../data/models/traveler_request_summary.dart';
import '../../data/platform_fees.dart';
import '../../data/services/delivery_repository.dart';
import '../../data/services/trip_repository.dart';
import '../../data/static_data.dart';
import '../../providers/auth_provider.dart';
import 'bid_acceptance_payment_screen.dart';

/// Public traveler profile opened from Matching Travelers.
class BidTravelerProfileScreen extends StatefulWidget {
  const BidTravelerProfileScreen({
    super.key,
    required this.bid,
    this.shipmentId,
  });

  final Bid bid;
  final String? shipmentId;

  @override
  State<BidTravelerProfileScreen> createState() =>
      _BidTravelerProfileScreenState();
}

class _BidTravelerProfileScreenState extends State<BidTravelerProfileScreen> {
  bool _requesting = false;
  bool _paying = false;
  bool _sentThisSession = false;
  bool _requestsLoaded = false;
  List<TravelerRequestSummary> _travelerRequests = const [];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _loadTravelerRequests();
    });
  }

  /// Whether the sender has already sent a request to this traveler for this
  /// delivery — authoritative from the backend, so re-opening the profile
  /// cannot offer "Send Request" a second time.
  TravelerRequestSummary? get _requestForBid {
    for (final r in _travelerRequests) {
      if (r.tripId == widget.bid.id || r.tripPublicId == widget.bid.id) {
        return r;
      }
    }
    return null;
  }

  bool get _alreadyRequested {
    if (_sentThisSession) return true;
    return _requestForBid != null;
  }

  bool get _travelerAcceptedOffer => _requestForBid?.isAccepted ?? false;

  Future<void> _loadTravelerRequests() async {
    final id = widget.shipmentId;
    final demoMode = context.read<DemoModeProvider>();
    if (id == null || demoMode.enabled) {
      setState(() => _requestsLoaded = true);
      return;
    }
    try {
      final auth = context.read<AuthProvider>();
      final requests = await DeliveryRepository(
        apiClient: auth.repository.apiClient,
        demoMode: demoMode,
      ).listTravelerRequests(id);
      if (!mounted) return;
      setState(() {
        _travelerRequests = requests;
        _requestsLoaded = true;
      });
    } catch (_) {
      if (!mounted) return;
      // Non-fatal: leave the button usable if we couldn't confirm state.
      setState(() => _requestsLoaded = true);
    }
  }

  bool get _atRequestLimit =>
      _travelerRequests.length >= PlatformFees.maxTravelerRequestsPerDelivery;

  Future<void> _selectTraveler() async {
    final id = widget.shipmentId;
    if (id == null || _requesting) return;
    if (_alreadyRequested) return;
    if (_atRequestLimit) {
      AppToast.error(context, PlatformFees.travelerRequestLimitMessage);
      return;
    }

    final demoMode = context.read<DemoModeProvider>();
    if (!demoMode.enabled) {
      final parcelWeight = StaticData.shipmentById(id)?.parcelWeightKg;
      if (parcelWeight != null &&
          !widget.bid.canCarryWeightKg(parcelWeight)) {
        AppToast.error(
          context,
          context.l10n.travelerInsufficientLuggageCapacity,
        );
        return;
      }
      setState(() => _requesting = true);
      try {
        final auth = context.read<AuthProvider>();
        await DeliveryRepository(
          apiClient: auth.repository.apiClient,
          demoMode: demoMode,
        ).requestTraveler(
          deliveryId: id,
          tripId: widget.bid.id,
          matchScore: widget.bid.routeMatchConfidence,
        );
      } on ApiException catch (e) {
        if (!mounted) return;
        setState(() => _requesting = false);
        AppToast.error(context, e.message);
        return;
      } catch (_) {
        if (!mounted) return;
        setState(() => _requesting = false);
        AppToast.error(context, context.l10n.unableToSendRequestToTraveler);
        return;
      }
      if (!mounted) return;
      setState(() => _requesting = false);
      await _loadTravelerRequests();
    }

    StaticData.selectMatchingTraveler(shipmentId: id, bid: widget.bid);
    if (!mounted) return;
    setState(() => _sentThisSession = true);
    context.push(
      '/traveler-selected-confirmation',
      extra: BidAcceptanceContext(
        bid: widget.bid,
        shipmentId: id,
        activeRequestCount: _travelerRequests.isEmpty
            ? 1
            : _travelerRequests.length,
      ),
    );
  }

  Future<void> _payNow() async {
    final shipmentId = widget.shipmentId;
    if (shipmentId == null || _paying) return;
    final demoMode = context.read<DemoModeProvider>();
    if (demoMode.enabled) {
      AppToast.error(context, context.l10n.demoModeCompleteLivePayment);
      return;
    }
    if (!_travelerAcceptedOffer) {
      AppToast.info(
        context,
        context.l10n.payNowAfterAccept(widget.bid.travelerName),
      );
      return;
    }

    setState(() => _paying = true);
    try {
      final auth = context.read<AuthProvider>();
      final tripRepo = TripRepository(
        apiClient: auth.repository.apiClient,
        demoMode: demoMode,
      );
      final offer = await tripRepo.getSenderCounterOfferByDelivery(shipmentId);
      if (!mounted) return;

      final request = _requestForBid;
      final matchesRequest = request == null ||
          offer.requestId.isEmpty ||
          offer.requestId == request.id;
      final matchesTrip = offer.tripId.isEmpty ||
          widget.bid.id.isEmpty ||
          offer.tripId == widget.bid.id ||
          offer.tripId == (request?.tripPublicId ?? '');
      if (!matchesRequest || !matchesTrip) {
        AppToast.info(
          context,
          context.l10n.noPayableOfferFrom(widget.bid.travelerName),
        );
        return;
      }

      if (!offer.isOpen && !offer.awaitsPayment) {
        context.push('/sender-counter-offer/${offer.id}');
        return;
      }

      var parcelCategory = 'documents';
      var paysReceiverFee = false;
      try {
        final delivery = await DeliveryRepository(
          apiClient: auth.repository.apiClient,
          demoMode: demoMode,
        ).getDelivery(shipmentId, role: 'sender');
        parcelCategory = delivery.parcelCategory;
        paysReceiverFee = PlatformFees.senderPaysReceiverFee(delivery);
      } catch (_) {}

      if (!mounted) return;
      context.push(
        '/bid-acceptance-payment',
        extra: BidAcceptanceContext(
          bid: widget.bid.copyWith(
            id: offer.id,
            price: offer.amount,
            travelerName: offer.travelerName,
            initial: offer.travelerInitial,
          ),
          shipmentId: shipmentId,
          offerId: offer.id,
          parcelCategory: parcelCategory,
          paysReceiverFee: paysReceiverFee,
        ),
      );
    } on ApiException catch (e) {
      if (!mounted) return;
      if (e.statusCode == 404 || e.code == 'NOT_FOUND') {
        AppToast.info(
          context,
          context.l10n.waitingForAcceptPay(widget.bid.travelerName),
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

  @override
  Widget build(BuildContext context) {
    final bid = widget.bid;
    final shipmentId = widget.shipmentId;
    final typo = context.typo;
    final travelDate = DateFormat(
      'MMM d, yyyy',
      context.l10n.locale.toString(),
    ).format(bid.travelDate);
    final matchColor = bid.routeMatchConfidence >= 90
        ? AppColors.success
        : bid.routeMatchConfidence >= 80
            ? AppColors.primary
            : AppColors.warning;
    final shipment =
        shipmentId == null ? null : StaticData.shipmentById(shipmentId);
    final demoMode = context.watch<DemoModeProvider>().enabled;
    final reviewStatus = demoMode
        ? StaticData.bidReviewStatus(bid.id)
        : (_travelerAcceptedOffer
            ? BidReviewStatus.approved
            : _alreadyRequested
                ? BidReviewStatus.deliveryRequested
                : BidReviewStatus.open);
    final isSelected = reviewStatus == BidReviewStatus.deliveryRequested ||
        reviewStatus == BidReviewStatus.accepted ||
        reviewStatus == BidReviewStatus.approved;
    final isLocked = reviewStatus == BidReviewStatus.locked;
    final alreadyRequested = _alreadyRequested;
    final atLimit = _atRequestLimit && !alreadyRequested;
    final canSelect =
        shipmentId != null && !isSelected && !isLocked && !alreadyRequested;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: BackHeader(title: context.l10n.travelerProfile),
      body: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              physics: PlatformUi.scrollPhysics,
              padding: context.pagePadding,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  AppCard(
                    margin: EdgeInsets.zero,
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        AppAvatar(initial: bid.initial, size: AvatarSize.large),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                bid.travelerName,
                                style: typo.h2.copyWith(fontWeight: FontWeight.w700),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                '⭐ ${context.l10n.ratingReviewsCount('${bid.rating}', '${bid.reviewCount}')}',
                                style: typo.sm,
                              ),
                              const SizedBox(height: 8),
                              AppBadge.verified(label: context.tr('Verified')),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),
                  AppCard(
                    margin: EdgeInsets.zero,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          context.l10n.about,
                          style: typo.h3.copyWith(fontWeight: FontWeight.w700),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          bid.bio ??
                              context.l10n.verifiedTravelerRouteFallback,
                          style: typo.body,
                        ),
                        const SizedBox(height: 16),
                        _row(
                          context,
                          context.l10n.completedDeliveriesLabel,
                          '${bid.completedDeliveries}',
                        ),
                        _row(context, context.l10n.travelDate, travelDate),
                        if (bid.departureTime?.trim().isNotEmpty == true)
                          _row(
                            context,
                            context.l10n.departureTime,
                            LocalTime.formatDepartureTime(
                              bid.departureTime,
                              context.l10n.locale.toString(),
                            ),
                          ),
                        if (bid.travelMethodLabel != null)
                          _row(
                            context,
                            context.l10n.travelMethod,
                            context.tr(bid.travelMethodLabel!),
                          ),
                        if (bid.flightNumber != null)
                          _row(context, context.l10n.flight, bid.flightNumber!),
                        const SizedBox(height: 8),
                        AppBadge(
                          label: context.l10n.matchPercentLabel(
                            '${bid.routeMatchConfidence}',
                          ),
                          color: matchColor,
                          backgroundColor: matchColor.withValues(alpha: 0.12),
                          semiBold: true,
                        ),
                      ],
                    ),
                  ),
                  if (shipment != null) ...[
                    const SizedBox(height: 12),
                    AppCard(
                      margin: EdgeInsets.zero,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            context.l10n.routeDetails,
                            style: typo.h3.copyWith(fontWeight: FontWeight.w700),
                          ),
                          const SizedBox(height: 12),
                          _row(
                            context,
                            context.l10n.from,
                            '${shipment.fromCity} (${shipment.fromCode})',
                          ),
                          _row(
                            context,
                            context.l10n.to,
                            '${shipment.toCity} (${shipment.toCode})',
                          ),
                          _row(context, context.l10n.travelDate, travelDate),
                          if (bid.departureTime?.trim().isNotEmpty == true)
                            _row(
                              context,
                              context.l10n.departureTime,
                              LocalTime.formatDepartureTime(
                                bid.departureTime,
                                context.l10n.locale.toString(),
                              ),
                            ),
                          if (bid.travelMethodLabel != null)
                            _row(
                              context,
                              context.l10n.travelMethod,
                              context.tr(bid.travelMethodLabel!),
                            ),
                        ],
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
          if (shipmentId != null)
            SafeArea(
              top: false,
              child: Padding(
                padding: EdgeInsets.fromLTRB(
                  context.horizontalPadding,
                  8,
                  context.horizontalPadding,
                  16,
                ),
                child: Column(
                  children: [
                    AppButton(
                      label: isSelected || alreadyRequested
                          ? context.l10n.requestSent
                          : isLocked
                              ? context.l10n.unavailable
                              : atLimit
                                  ? context.l10n.limitReached
                                  : context.l10n.sendRequest,
                      variant: AppButtonVariant.outline,
                      onPressed: canSelect && !_requesting && _requestsLoaded
                          ? _selectTraveler
                          : null,
                    ),
                    const SizedBox(height: AppButton.stackGap),
                    AppButton(
                      label: _paying
                          ? context.l10n.openingPaymentEllipsis
                          : context.l10n.payNow,
                      onPressed: _travelerAcceptedOffer &&
                              !demoMode &&
                              !_paying
                          ? _payNow
                          : null,
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _row(BuildContext context, String label, String value) {
    final typo = context.typo;
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: typo.sm.copyWith(color: AppColors.textSecondary)),
          Flexible(
            child: Text(
              value,
              textAlign: TextAlign.right,
              style: typo.sm.copyWith(fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }
}
