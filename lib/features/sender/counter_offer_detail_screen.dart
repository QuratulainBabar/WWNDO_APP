import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

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
import '../../data/models/bid.dart';
import '../../data/models/sender_counter_offer.dart';
import '../../data/models/traveler_bid.dart';
import '../../data/services/delivery_repository.dart';
import '../../data/services/trip_repository.dart';
import '../../data/static_data.dart';
import '../../providers/auth_provider.dart';
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
    WidgetsBinding.instance.addPostFrameCallback((_) => _load());
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
      message: 'Counter offer',
      featured: true,
    );
  }

  Future<void> _accept() async {
    final offer = _offer;
    if (offer == null || _acting || !offer.isOpen) return;

    final shipmentId = (offer.deliveryPublicId ?? '').trim();
    if (shipmentId.isEmpty) {
      AppToast.error(context, 'Shipment details are missing for this offer.');
      return;
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
        paysReceiverFee = (delivery.platformFeeShare ?? 0) <= 0;
      } catch (_) {
        // Payment screen falls back to defaults.
      }
    }

    if (!mounted) return;
    final bid = _bidFromOffer(offer);
    context.push(
      '/bid-acceptance-payment',
      extra: BidAcceptanceContext(
        bid: bid,
        shipmentId: shipmentId,
        offerId: offer.id,
        parcelCategory: parcelCategory,
        paysReceiverFee: paysReceiverFee,
      ),
    );
  }

  Future<void> _reject() async {
    final offer = _offer;
    if (offer == null || _acting || !offer.isOpen) return;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Reject counter offer?'),
        content: Text(
          'Reject ${offer.travelerName}\'s offer of '
          '\$${offer.amount.toStringAsFixed(2)}?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: TextButton.styleFrom(foregroundColor: AppColors.danger),
            child: const Text('Reject'),
          ),
        ],
      ),
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
            fromCity: offer.fromCity,
            toCity: offer.toCity,
            travelDate: offer.travelDate,
            amount: offer.amount,
            maxBudget: offer.maxBudget,
            status: TravelerBidStatus.rejected,
            sentAt: offer.sentAt,
            parcelPhotoCount: offer.parcelPhotoCount,
            deliveryPublicId: offer.deliveryPublicId,
          );
        });
      } else {
        final updated = await _repo().rejectSenderCounterOffer(offer.id);
        if (!mounted) return;
        setState(() => _offer = updated);
      }

      if (!mounted) return;
      AppToast.success(context, 'Counter offer rejected.');
    } on ApiException catch (e) {
      if (!mounted) return;
      AppToast.error(context, e.message);
    } catch (_) {
      if (!mounted) return;
      AppToast.error(context, 'Unable to reject this counter offer.');
    } finally {
      if (mounted) setState(() => _acting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final typo = context.typo;

    if (_loading && _offer == null) {
      return const Scaffold(
        backgroundColor: AppColors.background,
        appBar: BackHeader(title: 'Counter Offer Details'),
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
        appBar: const BackHeader(title: 'Counter Offer Details'),
        body: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                _error ?? 'Counter offer not found.',
                style: typo.sm.copyWith(color: AppColors.textSecondary),
                textAlign: TextAlign.center,
              ),
              TextButton(onPressed: _load, child: const Text('Retry')),
            ],
          ),
        ),
      );
    }

    final travelDate = DateFormat('MMM d, yyyy').format(offer.travelDate);
    final ratingLabel = offer.travelerRating != null
        ? '⭐ ${offer.travelerRating!.toStringAsFixed(1)}'
            '${offer.travelerReviewCount > 0 ? ' · ${offer.travelerReviewCount} reviews' : ''}'
        : 'Traveler';

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: const BackHeader(title: 'Counter Offer Details'),
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
                      _StatusBadge(status: offer.status),
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
                                      AppBadge.verified(label: 'Traveler'),
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
                              'Counter offer',
                              style: typo.h3
                                  .copyWith(fontWeight: FontWeight.w700),
                            ),
                            const SizedBox(height: 12),
                            _detailRow(
                              context,
                              'Offer amount',
                              '\$${offer.amount.toStringAsFixed(2)}',
                              valueStyle:
                                  typo.priceSmall.copyWith(fontSize: 18),
                            ),
                            if (offer.maxBudget > 0)
                              _detailRow(
                                context,
                                'Your original budget',
                                '\$${offer.maxBudget.toStringAsFixed(2)}',
                              ),
                            _detailRow(
                              context,
                              'Shipment ID',
                              offer.deliveryPublicId ?? '—',
                            ),
                            _detailRow(
                              context,
                              'Route',
                              offer.route.isNotEmpty ? offer.route : '—',
                            ),
                            _detailRow(context, 'Travel date', travelDate),
                            _detailRow(
                              context,
                              'Status',
                              offer.status.label,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            if (offer.isOpen)
              Padding(
                padding: context.pagePadding.copyWith(top: 8, bottom: 16),
                child: Row(
                  children: [
                    Expanded(
                      child: AppButton(
                        label: _acting ? 'Please wait…' : 'Reject',
                        variant: AppButtonVariant.danger,
                        onPressed: _acting ? null : _reject,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: AppButton(
                        label: _acting ? 'Please wait…' : 'Accept',
                        onPressed: _acting ? null : _accept,
                      ),
                    ),
                  ],
                ),
              )
            else if (offer.isAccepted)
              Padding(
                padding: context.pagePadding.copyWith(top: 8, bottom: 16),
                child: AppBadge.success('Counter offer accepted'),
              )
            else if (offer.isRejected)
              Padding(
                padding: context.pagePadding.copyWith(top: 8, bottom: 16),
                child: AppBadge(
                  label: 'Counter offer rejected',
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
  const _StatusBadge({required this.status});

  final TravelerBidStatus status;

  @override
  Widget build(BuildContext context) {
    if (status == TravelerBidStatus.accepted) {
      return AppBadge.success('Offer accepted');
    }
    if (status == TravelerBidStatus.rejected) {
      return AppBadge(
        label: 'Offer rejected',
        color: AppColors.danger,
        backgroundColor: AppColors.danger.withValues(alpha: 0.12),
        small: true,
        semiBold: true,
      );
    }
    return AppBadge(
      label: status.label,
      color: status.color,
      backgroundColor: status.color.withValues(alpha: 0.12),
      small: true,
      semiBold: true,
    );
  }
}
