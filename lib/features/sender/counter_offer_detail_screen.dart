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
import '../../core/widgets/app_toast.dart';
import '../../core/widgets/back_header.dart';
import '../../core/widgets/stacked_route_endpoints.dart';
import '../../data/models/bid.dart';
import '../../data/models/sender_counter_offer.dart';
import '../../data/models/traveler_bid.dart';
import '../../data/platform_fees.dart';
import '../../data/services/delivery_repository.dart';
import '../../data/services/trip_repository.dart';
import '../../data/wallet_service.dart';
import '../../data/static_data.dart';
import '../../providers/auth_provider.dart';
import '../../providers/sender_offer_flow_lock.dart';
import 'bid_acceptance_payment_screen.dart';

/// Sender reviews a traveler counter offer and can Accept or Reject.
class CounterOfferDetailScreen extends StatefulWidget {
  const CounterOfferDetailScreen({
    super.key,
    this.offerId,
    this.deliveryPublicId,
  });

  final String? offerId;
  final String? deliveryPublicId;

  @override
  State<CounterOfferDetailScreen> createState() =>
      _CounterOfferDetailScreenState();
}

class _CounterOfferDetailScreenState extends State<CounterOfferDetailScreen> {
  bool _loading = true;
  bool _acting = false;
  String? _error;
  SenderCounterOffer? _offer;

  @override
  void initState() {
    super.initState();
    SenderOfferFlowLock.instance.addListener(_onFlowLockChanged);
    WidgetsBinding.instance.addPostFrameCallback((_) => _load());
  }

  @override
  void dispose() {
    SenderOfferFlowLock.instance.removeListener(_onFlowLockChanged);
    super.dispose();
  }

  void _onFlowLockChanged() {
    if (mounted) setState(() {});
  }

  TripRepository _repo() {
    final auth = context.read<AuthProvider>();
    final demoMode = context.read<DemoModeProvider>();
    return TripRepository(
      apiClient: auth.repository.apiClient,
      demoMode: demoMode,
    );
  }

  Future<void> _load() async {
    final offerId = (widget.offerId ?? '').trim();
    final deliveryId = (widget.deliveryPublicId ?? '').trim();

    final demo = context.read<DemoModeProvider>().enabled;
    if (demo) {
      final demoOffer = StaticData.senderCounterOfferFor(
        offerId: offerId.isEmpty ? null : offerId,
        deliveryPublicId: deliveryId.isEmpty ? null : deliveryId,
      );
      setState(() {
        _offer = demoOffer;
        _loading = false;
        _error = demoOffer == null ? 'Counter offer not found.' : null;
      });
      return;
    }

    if (offerId.isEmpty && deliveryId.isEmpty) {
      setState(() {
        _loading = false;
        _error = 'Counter offer not found.';
      });
      return;
    }

    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final offer = offerId.isNotEmpty
          ? await _repo().getSenderCounterOffer(offerId)
          : await _repo().getSenderCounterOfferByDelivery(deliveryId);
      if (!mounted) return;
      setState(() {
        _offer = offer;
        _loading = false;
        _error = null;
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
        _error = 'Unable to load counter offer details.';
      });
    }
  }

  Bid _bidFromOffer(SenderCounterOffer offer) {
    return Bid(
      id: offer.id,
      travelerName: offer.travelerName,
      initial: offer.travelerInitial,
      rating: offer.travelerRating ?? 0,
      reviewCount: offer.travelerReviewCount,
      price: offer.amount,
      travelDate: offer.travelDate,
      routeMatchConfidence: 90,
      bio: offer.travelerBio,
      message: (offer.message ?? '').trim().isNotEmpty
          ? offer.message!.trim()
          : 'Counter offer',
      featured: true,
    );
  }

  Future<void> _accept() async {
    final offer = _offer;
    if (offer == null || _acting) return;
    if (!offer.isOpen && !offer.awaitsPayment) return;

    final lock = SenderOfferFlowLock.instance;
    if (lock.isPayCompleted(
          offerId: offer.id,
          shipmentId: offer.deliveryPublicId,
        ) ||
        (offer.isOpen && lock.isAcceptConsumed(offer.id))) {
      return;
    }

    final shipmentId = (offer.deliveryPublicId ?? '').trim();
    if (shipmentId.isEmpty) {
      AppToast.error(context, context.l10n.shipmentDetailsAreMissing);
      return;
    }

    setState(() => _acting = true);
    if (offer.isOpen) {
      lock.markAcceptConsumed(offer.id);
    }

    final demo = context.read<DemoModeProvider>().enabled;
    if (demo) {
      StaticData.acceptFinalBudgetProposal(shipmentId);
    }

    var parcelCategory = 'documents';
    var paysReceiverFee = false;
    if (demo) {
      final shipment = StaticData.shipmentById(shipmentId);
      if (shipment != null) {
        parcelCategory = shipment.parcelCategory;
        paysReceiverFee = StaticData.paysReceiverFeeFor(shipmentId);
      }
    } else {
      try {
        final auth = context.read<AuthProvider>();
        final delivery = await DeliveryRepository(
          apiClient: auth.repository.apiClient,
          demoMode: context.read<DemoModeProvider>(),
        ).getDelivery(shipmentId, role: 'sender');
        parcelCategory = delivery.parcelCategory;
        paysReceiverFee = PlatformFees.senderPaysReceiverFee(delivery);
      } catch (_) {
        // Payment screen falls back to defaults.
      }
    }

    if (!mounted) return;
    final bid = _bidFromOffer(offer);
    await context.push(
      '/bid-acceptance-payment',
      extra: BidAcceptanceContext(
        bid: bid,
        shipmentId: shipmentId,
        offerId: offer.id,
        parcelCategory: parcelCategory,
        paysReceiverFee: paysReceiverFee,
      ),
    );
    if (!mounted) return;
    setState(() => _acting = false);
    await _load();
  }

  Future<void> _reject() async {
    final offer = _offer;
    if (offer == null || _acting || !offer.isOpen) return;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) {
        final dialogL10n = ctx.l10n;
        return AlertDialog(
          title: Text(dialogL10n.rejectCounterOfferTitle),
          content: Text(
            dialogL10n.rejectCounterOfferBody(
              offer.travelerName,
              WalletService.formatMajor(offer.amount),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: Text(dialogL10n.cancel),
            ),
            TextButton(
              onPressed: () => Navigator.pop(ctx, true),
              style: TextButton.styleFrom(foregroundColor: AppColors.danger),
              child: Text(dialogL10n.reject),
            ),
          ],
        );
      },
    );
    if (confirmed != true || !mounted) return;

    final demo = context.read<DemoModeProvider>().enabled;
    setState(() => _acting = true);

    try {
      if (demo) {
        StaticData.rejectSenderCounterOffer(
          offerId: offer.id,
          deliveryPublicId: offer.deliveryPublicId,
        );
        setState(() {
          _offer = SenderCounterOffer(
            id: offer.id,
            requestId: offer.requestId,
            tripId: offer.tripId,
            travelerName: offer.travelerName,
            travelerInitial: offer.travelerInitial,
            travelerRating: offer.travelerRating,
            travelerReviewCount: offer.travelerReviewCount,
            travelerBio: offer.travelerBio,
            message: offer.message,
            fromCity: offer.fromCity,
            toCity: offer.toCity,
            travelDate: offer.travelDate,
            amount: offer.amount,
            maxBudget: offer.maxBudget,
            status: TravelerBidStatus.rejected,
            sentAt: offer.sentAt,
            parcelPhotoCount: offer.parcelPhotoCount,
            parcelPhotoUrls: offer.parcelPhotoUrls,
            deliveryPublicId: offer.deliveryPublicId,
            originCountry: offer.originCountry,
            originAirport: offer.originAirport,
            destinationCountry: offer.destinationCountry,
            destinationAirport: offer.destinationAirport,
            apiRoute: offer.apiRoute,
          );
        });
      } else {
        final updated = await _repo().rejectSenderCounterOffer(offer.id);
        if (!mounted) return;
        setState(() => _offer = updated);
      }

      if (!mounted) return;
      AppToast.success(context, context.l10n.counterOfferRejectedToast);
    } on ApiException catch (e) {
      if (!mounted) return;
      AppToast.error(context, e.message);
    } catch (_) {
      if (!mounted) return;
      AppToast.error(context, context.l10n.unableToRejectCounterOffer);
    } finally {
      if (mounted) setState(() => _acting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final typo = context.typo;

    if (_loading && _offer == null) {
      return Scaffold(
        backgroundColor: AppColors.background,
        appBar: BackHeader(title: context.l10n.counterOfferDetails),
        body: Center(
          child: SizedBox(
            width: 22,
            height: 22,
            child: CircularProgressIndicator(
              strokeWidth: 2.5,
              color: AppColors.primary,
            ),
          ),
        ),
      );
    }

    final offer = _offer;
    if (_error != null || offer == null) {
      return Scaffold(
        backgroundColor: AppColors.background,
        appBar: BackHeader(title: context.l10n.counterOfferDetails),
        body: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                context.tr(_error ?? 'Counter offer not found.'),
                style: typo.sm.copyWith(color: AppColors.textSecondary),
                textAlign: TextAlign.center,
              ),
              TextButton(onPressed: _load, child: Text(context.tr('Retry'))),
            ],
          ),
        ),
      );
    }

    final lock = SenderOfferFlowLock.instance;
    final acceptConsumed = lock.isAcceptConsumed(offer.id);
    final payCompleted = lock.isPayCompleted(
      offerId: offer.id,
      shipmentId: offer.deliveryPublicId,
    );
    final payLocked = lock.isPayConsumed(
      offerId: offer.id,
      shipmentId: offer.deliveryPublicId,
    );
    final acceptLocked = _acting || acceptConsumed || payLocked;
    final showAccepted = offer.isAccepted || payCompleted;
    final l10n = context.l10n;

    final travelDate = DateFormat(
      'MMM d, yyyy',
      l10n.locale.toString(),
    ).format(offer.travelDate);
    final ratingLabel = offer.travelerRating != null
        ? '⭐ ${l10n.ratingReviewsCount(offer.travelerRating!.toStringAsFixed(1), '${offer.travelerReviewCount}')}'
        : l10n.traveler;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: BackHeader(title: l10n.counterOfferDetails),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: RefreshIndicator(
                onRefresh: _load,
                child: SingleChildScrollView(
                  physics: AlwaysScrollableScrollPhysics(
                    parent: PlatformUi.scrollPhysics,
                  ),
                  padding: context.pagePadding,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _StatusBadge(
                        status: showAccepted
                            ? TravelerBidStatus.accepted
                            : offer.status,
                        paymentPending:
                            offer.awaitsPayment && !payCompleted,
                      ),
                      const SizedBox(height: 16),
                      AppCard(
                        margin: EdgeInsets.zero,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                AppAvatar(
                                  initial: offer.travelerInitial,
                                  size: AvatarSize.large,
                                ),
                                const SizedBox(width: 14),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        offer.travelerName,
                                        style: typo.h3.copyWith(
                                          fontWeight: FontWeight.w700,
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      Text(ratingLabel, style: typo.sm),
                                      const SizedBox(height: 8),
                                      AppBadge.verified(label: l10n.traveler),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                            if ((offer.travelerBio ?? '').trim().isNotEmpty) ...[
                              const SizedBox(height: 14),
                              Text(
                                offer.travelerBio!.trim(),
                                style: typo.sm.copyWith(height: 1.4),
                              ),
                            ],
                            const Padding(
                              padding: EdgeInsets.symmetric(vertical: 20),
                              child: Divider(height: 1),
                            ),
                            Text(
                              l10n.counterOffer,
                              style: typo.h3
                                  .copyWith(fontWeight: FontWeight.w700),
                            ),
                            const SizedBox(height: 12),
                            _detailRow(
                              context,
                              l10n.offerAmount,
                              WalletService.formatMajor(offer.amount),
                              valueStyle:
                                  typo.priceSmall.copyWith(fontSize: 18),
                            ),
                            if (offer.maxBudget > 0)
                              _detailRow(
                                context,
                                l10n.yourOriginalBudget,
                                WalletService.formatMajor(offer.maxBudget),
                              ),
                            _detailRow(
                              context,
                              l10n.shipmentIdLabel,
                              offer.deliveryPublicId ?? '—',
                            ),
                            StackedRouteEndpoints(
                              from: offer.displayFrom,
                              to: offer.displayTo,
                              fallbackRoute: offer.route,
                              sectionLabel: l10n.route,
                              bottomPadding: 8,
                            ),
                            _detailRow(
                              context,
                              l10n.travelDate,
                              travelDate,
                            ),
                            _detailRow(
                              context,
                              l10n.status,
                              l10n.travelerBidStatusLabel(offer.status.label),
                            ),
                            if ((offer.message ?? '').trim().isNotEmpty) ...[
                              const SizedBox(height: 8),
                              Text(l10n.travelerMessage, style: typo.sm),
                              const SizedBox(height: 8),
                              Container(
                                width: double.infinity,
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: AppColors.primary
                                      .withValues(alpha: 0.06),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Text(
                                  '"${offer.message!.trim()}"',
                                  style: typo.italicQuote,
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            if (showAccepted)
              Padding(
                padding: context.pagePadding.copyWith(top: 8, bottom: 16),
                child: AppBadge.success(l10n.counterOfferAcceptedBadge),
              )
            else if (offer.isOpen)
              Padding(
                padding: context.pagePadding.copyWith(top: 8, bottom: 16),
                child: Row(
                  children: [
                    Expanded(
                      child: AppButton(
                        label: _acting
                            ? l10n.pleaseWaitEllipsis
                            : l10n.reject,
                        variant: AppButtonVariant.danger,
                        onPressed: _acting || payLocked ? null : _reject,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: AppButton(
                        label: _acting
                            ? l10n.pleaseWaitEllipsis
                            : l10n.accept,
                        onPressed: acceptLocked ? null : _accept,
                      ),
                    ),
                  ],
                ),
              )
            else if (offer.awaitsPayment)
              Padding(
                padding: context.pagePadding.copyWith(top: 8, bottom: 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    AppBadge(
                      label: l10n.paymentPendingBadge,
                      color: AppColors.warning,
                      backgroundColor: AppColors.warning.withValues(alpha: 0.12),
                      small: true,
                      semiBold: true,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      l10n.counterOfferReservedPaymentIncomplete,
                      style: typo.sm.copyWith(
                        color: AppColors.textSecondary,
                        height: 1.4,
                      ),
                    ),
                    const SizedBox(height: 12),
                    AppButton(
                      label: payLocked
                          ? (payCompleted
                              ? l10n.paidLabel
                              : l10n.processing)
                          : _acting
                              ? l10n.pleaseWaitEllipsis
                              : l10n.completePayment,
                      onPressed: _acting || payLocked ? null : _accept,
                    ),
                  ],
                ),
              )
            else if (offer.isRejected)
              Padding(
                padding: context.pagePadding.copyWith(top: 8, bottom: 16),
                child: AppBadge(
                  label: l10n.counterOfferRejectedBadge,
                  color: AppColors.danger,
                  backgroundColor: AppColors.danger.withValues(alpha: 0.12),
                  small: true,
                  semiBold: true,
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _detailRow(
    BuildContext context,
    String label,
    String value, {
    TextStyle? valueStyle,
  }) {
    final typo = context.typo;
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: typo.sm),
          const SizedBox(width: 16),
          Flexible(
            child: Text(
              value,
              textAlign: TextAlign.right,
              style: valueStyle ??
                  typo.bodyBold.copyWith(fontWeight: FontWeight.w700),
            ),
          ),
        ],
      ),
    );
  }
}

class _StatusBadge extends StatelessWidget {
  const _StatusBadge({
    required this.status,
    this.paymentPending = false,
  });

  final TravelerBidStatus status;
  final bool paymentPending;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    if (paymentPending) {
      return AppBadge(
        label: l10n.paymentPendingBadge,
        color: AppColors.warning,
        backgroundColor: AppColors.warning.withValues(alpha: 0.12),
        small: true,
        semiBold: true,
      );
    }
    if (status == TravelerBidStatus.accepted) {
      return AppBadge.success(l10n.offerAcceptedBadge);
    }
    if (status == TravelerBidStatus.rejected) {
      return AppBadge(
        label: l10n.offerRejectedBadge,
        color: AppColors.danger,
        backgroundColor: AppColors.danger.withValues(alpha: 0.12),
        small: true,
        semiBold: true,
      );
    }
    return AppBadge(
      label: l10n.travelerBidStatusLabel(status.label),
      color: status.color,
      backgroundColor: status.color.withValues(alpha: 0.12),
      small: true,
      semiBold: true,
    );
  }
}
