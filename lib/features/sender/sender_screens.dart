import 'dart:async';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../core/config/demo_mode.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_typography.dart';
import '../../core/widgets/app_avatar.dart';
import '../../core/widgets/app_badge.dart';
import '../../core/widgets/app_button.dart';
import '../../core/widgets/app_card.dart';
import '../../core/widgets/app_chip.dart';
import '../../core/layout/responsive.dart';
import '../../core/platform/platform_ui.dart';
import '../../core/widgets/app_labeled_field.dart';
import '../../core/widgets/app_toast.dart';
import '../../core/widgets/app_value_field.dart';
import '../../core/widgets/back_header.dart';
import '../../core/widgets/stacked_route_endpoints.dart';
import '../../data/models/bid.dart';
import '../../data/models/created_delivery.dart';
import '../../data/models/parcel_creation_result.dart';
import '../../data/models/shipment.dart';
import '../../data/delivery_status_mapper.dart';
import '../../data/route_display.dart';
import '../../data/services/delivery_repository.dart';
import '../../data/static_data.dart';
import '../../data/wallet_service.dart';
import '../../l10n/app_localizations.dart';
import '../../providers/auth_provider.dart';
import '../../providers/notification_realtime_provider.dart';
import '../../providers/sender_deliveries_provider.dart';
import 'bid_sort.dart';

class BrowseBidsScreen extends StatefulWidget {
  const BrowseBidsScreen({super.key});

  @override
  State<BrowseBidsScreen> createState() => _BrowseBidsScreenState();
}

class _BrowseBidsScreenState extends State<BrowseBidsScreen> {
  BidSortOption _sort = BidSortOption.lowestPrice;

  @override
  void initState() {
    super.initState();
    StaticData.bidRequestsVersion.addListener(_onBidsChanged);
  }

  @override
  void dispose() {
    StaticData.bidRequestsVersion.removeListener(_onBidsChanged);
    super.dispose();
  }

  void _onBidsChanged() {
    if (mounted) setState(() {});
  }

  void _showSnack(String message) {
    AppToast.success(context, message);
  }

  @override
  Widget build(BuildContext context) {
    final openBids = StaticData.bids
        .where((b) => StaticData.bidReviewStatus(b.id) != BidReviewStatus.rejected)
        .toList();
    final bids = BidSortOption.sorted(openBids, _sort);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: BackHeader(title: 'Bids (${bids.length})'),
      body: ListView.builder(
        physics: PlatformUi.scrollPhysics,
        padding: context.pagePadding,
        itemCount: bids.length + 1,
        itemBuilder: (context, i) {
          if (i == 0) {
            return Padding(
              padding: EdgeInsets.only(bottom: bids.isEmpty ? 0 : 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Sort by',
                    style: context.typo.sm.copyWith(
                      fontWeight: FontWeight.w600,
                      color: AppColors.textSecondary,
                    ),
                  ),
                  const SizedBox(height: 6),
                  AppChipRow(
                    options: BidSortOption.labels,
                    selected: _sort.label,
                    onSelected: (label) {
                      setState(() => _sort = BidSortOption.fromLabel(label));
                    },
                  ),
                ],
              ),
            );
          }

          final bid = bids[i - 1];
          final status = StaticData.bidReviewStatus(bid.id);
          return _BidCard(
            bid: bid,
            status: status,
            negotiatedMeetup: StaticData.negotiatedMeetupByBidId[bid.id],
            onAccept: () => context.push('/payment'),
            onReject: () {
              StaticData.rejectBid('', bid.id);
              _showSnack('Bid from ${bid.travelerName} rejected');
            },
            onViewProfile: () => context.push('/bid-traveler-profile', extra: bid),
            onSendDeliveryRequest: () => context.push('/payment'),
            onApproveRequest: () {
              StaticData.approveRequest(bid.id);
              _showSnack('Request from ${bid.travelerName} approved');
            },
            onNegotiateMeetup: () => context.push('/negotiate-meetup', extra: bid),
          );
        },
      ),
    );
  }
}

class _BidCard extends StatelessWidget {
  const _BidCard({
    required this.bid,
    required this.status,
    required this.onAccept,
    required this.onReject,
    required this.onViewProfile,
    required this.onSendDeliveryRequest,
    required this.onApproveRequest,
    required this.onNegotiateMeetup,
    this.negotiatedMeetup,
  });

  final Bid bid;
  final BidReviewStatus status;
  final String? negotiatedMeetup;
  final VoidCallback onAccept;
  final VoidCallback onReject;
  final VoidCallback onViewProfile;
  final VoidCallback onSendDeliveryRequest;
  final VoidCallback onApproveRequest;
  final VoidCallback onNegotiateMeetup;

  @override
  Widget build(BuildContext context) {
    final typo = context.typo;
    final matchColor = bid.routeMatchConfidence >= 90
        ? AppColors.success
        : bid.routeMatchConfidence >= 80
            ? AppColors.primary
            : AppColors.warning;

    return AppCard(
      highlighted: bid.featured,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              GestureDetector(
                onTap: onViewProfile,
                child: AppAvatar(initial: bid.initial),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        GestureDetector(
                          onTap: onViewProfile,
                          child: Text(
                            bid.travelerName,
                            style: typo.bodyBold.copyWith(fontWeight: FontWeight.w700),
                          ),
                        ),
                        const SizedBox(width: 8),
                        AppBadge.verified(),
                      ],
                    ),
                    Text('★ ${bid.rating} · ${bid.reviewCount} reviews', style: typo.sm),
                  ],
                ),
              ),
              Text(WalletService.formatMajor(bid.price), style: typo.priceLarge),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: Text(
                  bid.flightNumber != null
                      ? '✈️ ${bid.flightNumber} · Travelling ${DateFormat('MMM d').format(bid.travelDate)}'
                      : 'Travelling ${DateFormat('MMM d').format(bid.travelDate)}',
                  style: typo.sm,
                ),
              ),
              AppBadge(
                label: bid.routeMatchLabel,
                color: matchColor,
                backgroundColor: matchColor.withValues(alpha: 0.12),
                semiBold: true,
              ),
            ],
          ),
          if (status == BidReviewStatus.accepted) ...[
            const SizedBox(height: 8),
            Align(
              alignment: Alignment.centerRight,
              child: AppBadge.success('Selected · Locked'),
            ),
          ],
          if (status == BidReviewStatus.locked) ...[
            const SizedBox(height: 8),
            Align(
              alignment: Alignment.centerRight,
              child: AppBadge(
                label: 'Locked',
                color: AppColors.textSecondary,
                backgroundColor: AppColors.border.withValues(alpha: 0.35),
                semiBold: true,
              ),
            ),
          ],
          if (status == BidReviewStatus.deliveryRequested) ...[
            const SizedBox(height: 8),
            Align(
              alignment: Alignment.centerRight,
              child: AppBadge.success('Delivery request sent'),
            ),
          ],
          if (status == BidReviewStatus.approved) ...[
            const SizedBox(height: 8),
            Align(
              alignment: Alignment.centerRight,
              child: AppBadge.success('Request approved'),
            ),
          ],
          if (negotiatedMeetup != null) ...[
            const SizedBox(height: 8),
            Text(
              'Proposed meetup: $negotiatedMeetup',
              style: typo.sm.copyWith(color: AppColors.primary),
            ),
          ],
          if (bid.message != null) ...[
            const SizedBox(height: 8),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.06),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text('"${bid.message}"', style: typo.italicQuote),
            ),
          ],
          const SizedBox(height: 10),
          if (status == BidReviewStatus.accepted) ...[
            AppButton(
              label: 'Bid accepted · Locked',
              small: true,
              onPressed: null,
            ),
            const SizedBox(height: 8),
            AppButton(
              label: 'View traveler profile',
              small: true,
              variant: AppButtonVariant.outline,
              onPressed: onViewProfile,
            ),
            const SizedBox(height: 8),
            AppButton(
              label: 'Negotiate meetup location',
              small: true,
              variant: AppButtonVariant.ghost,
              onPressed: onNegotiateMeetup,
            ),
          ] else if (status == BidReviewStatus.locked) ...[
            AppButton(
              label: 'Bid locked',
              small: true,
              onPressed: null,
            ),
            const SizedBox(height: 8),
            AppButton(
              label: 'View traveler profile',
              small: true,
              variant: AppButtonVariant.outline,
              onPressed: onViewProfile,
            ),
          ] else ...[
            AppButton(label: 'Accept bid', small: true, onPressed: onAccept),
            const SizedBox(height: 8),
            AppButton(
              label: 'Reject bid',
              small: true,
              variant: AppButtonVariant.danger,
              onPressed: onReject,
            ),
            const SizedBox(height: 8),
            AppButton(
              label: 'View traveler profile',
              small: true,
              variant: AppButtonVariant.outline,
              onPressed: onViewProfile,
            ),
            const SizedBox(height: 8),
            AppButton(
              label: status == BidReviewStatus.deliveryRequested
                  ? 'Delivery request sent'
                  : 'Send delivery request',
              small: true,
              variant: AppButtonVariant.outline,
              onPressed: status == BidReviewStatus.deliveryRequested ||
                      status == BidReviewStatus.approved
                  ? null
                  : onSendDeliveryRequest,
            ),
            const SizedBox(height: 8),
            AppButton(
              label: status == BidReviewStatus.approved
                  ? 'Request approved'
                  : 'Approve request',
              small: true,
              variant: AppButtonVariant.outline,
              onPressed:
                  status == BidReviewStatus.approved ? null : onApproveRequest,
            ),
            const SizedBox(height: 8),
            AppButton(
              label: 'Negotiate meetup location',
              small: true,
              variant: AppButtonVariant.ghost,
              onPressed: onNegotiateMeetup,
            ),
          ],
        ],
      ),
    );
  }
}

class EscrowPaymentScreen extends StatelessWidget {
  const EscrowPaymentScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final typo = context.typo;
    final bid = StaticData.bids.first;
    final shipment = StaticData.activeShipment;
    final paysReceiver =
        StaticData.paysReceiverFeeFor(shipment.id);
    final platformFee = StaticData.senderPlatformFeeUsd(
      category: shipment.parcelCategory,
      paysReceiverFee: paysReceiver,
    );
    final total = bid.price + platformFee;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: const BackHeader(title: 'Confirm payment'),
      body: SingleChildScrollView(
        physics: PlatformUi.scrollPhysics,
        padding: context.pagePadding,
        child: Column(
          children: [
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(color: AppColors.primary, borderRadius: BorderRadius.circular(16)),
              child: Column(
                children: [
                  Text('Funds held in escrow until delivery confirmed', style: typo.captionOnDarkSoft),
                  const SizedBox(height: 8),
                  Text(WalletService.formatMajor(total), style: typo.priceHero),
                  Text('🔒 Secured by Stripe', style: typo.captionOnDark),
                ],
              ),
            ),
            const SizedBox(height: 20),
            AppCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _row(context, 'Traveler payout (${bid.travelerName})', WalletService.formatMajor(bid.price)),
                  const Divider(),
                  _row(context, 'Your platform fee', WalletService.formatMajor(platformFee)),
                  _row(context, 'Total charged today', WalletService.formatMajor(total), bold: true, primary: true),
                ],
              ),
            ),
            const SizedBox(height: 12),
            Align(
              alignment: Alignment.centerLeft,
              child: Wrap(
                spacing: 6,
                runSpacing: 6,
                children: [
                  AppBadge.success('✓ Escrow protected'),
                  AppBadge.success('✓ ID verified traveler'),
                  AppBadge.success('✓ Zero hidden fees'),
                ],
              ),
            ),
            const SizedBox(height: 20),
            AppButton(
              label: 'Pay \$${total.toStringAsFixed(2)} securely',
              onPressed: () {
                final ok = StaticData.acceptBid(
                  shipmentId: StaticData.activeShipment.id,
                  bid: bid,
                );
                if (!ok) {
                  AppToast.error(
                    context,
                    'Payment failed. Booking was not created. Check wallet or card and try again.',
                  );
                  return;
                }
                context.push('/payment-confirmed');
              },
            ),
            const SizedBox(height: 10),
            Text(
              'Powered by Stripe · Your card is never stored by WWNGO',
              textAlign: TextAlign.center,
              style: typo.caption,
            ),
          ],
        ),
      ),
    );
  }

  Widget _row(BuildContext context, String label, String value, {bool bold = false, bool primary = false}) {
    final typo = context.typo;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: bold ? typo.bodyBold.copyWith(fontWeight: FontWeight.w700) : typo.smPrimary),
          Text(
            value,
            style: (primary ? typo.bodyBold.copyWith(fontSize: 16, color: AppColors.primary) : typo.body).copyWith(
              fontWeight: bold ? FontWeight.w700 : FontWeight.w800,
              color: primary ? AppColors.primary : AppColors.textPrimary,
            ),
          ),
        ],
      ),
    );
  }
}

class PaymentConfirmedScreen extends StatelessWidget {
  const PaymentConfirmedScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final typo = context.typo;
    final bid = StaticData.bids.first;
    final shipment = StaticData.activeShipment;
    final total = StaticData.totalPayment(
      bid.price,
      category: shipment.parcelCategory,
      shipmentId: shipment.id,
    );

    return Scaffold(
      backgroundColor: AppColors.surface,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text('🔒', style: typo.emojiXl.copyWith(fontSize: 64)),
              const SizedBox(height: 16),
              Text('Funds secured!', style: typo.h1),
              const SizedBox(height: 8),
              Text('${WalletService.formatMajor(total)} is held in escrow.', style: typo.sm),
              const SizedBox(height: 8),
              Text(
                'Selected bid locked · Receiver notified',
                textAlign: TextAlign.center,
                style: typo.sm.copyWith(color: AppColors.textSecondary),
              ),
              const SizedBox(height: 8),
              Text(
                'Arrange collection with ${bid.travelerName} via in-app chat. You\'ll be notified at every step.',
                textAlign: TextAlign.center,
                style: typo.sm.copyWith(height: 1.5),
              ),
              const SizedBox(height: 32),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  children: [
                    Text('Tracking ID', style: typo.sm),
                    Text(shipment.id, style: typo.trackingId),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              AppButton(
                label: 'Track delivery',
                onPressed: () => context.go('/track'),
              ),
              const SizedBox(height: AppButton.stackGap),
              AppButton(
                label: 'Open chat',
                variant: AppButtonVariant.outline,
                textStyle: typo.button.copyWith(fontWeight: FontWeight.w700, color: AppColors.textPrimary),
                onPressed: () => context.go('/sender-chats'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class PostDeliveryPostedSuccessScreen extends StatefulWidget {
  const PostDeliveryPostedSuccessScreen({
    super.key,
    this.delivery,
    this.result,
    this.route,
  });

  final CreatedDelivery? delivery;
  final ParcelCreationResult? result;
  final String? route;

  @override
  State<PostDeliveryPostedSuccessScreen> createState() =>
      _PostDeliveryPostedSuccessScreenState();
}

class _PostDeliveryPostedSuccessScreenState
    extends State<PostDeliveryPostedSuccessScreen> with WidgetsBindingObserver {
  CreatedDelivery? _liveDelivery;
  bool _polling = false;
  Timer? _pollTimer;

  String? get _deliveryId =>
      widget.delivery?.displayId ??
      _liveDelivery?.displayId ??
      widget.result?.requestId;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _liveDelivery = widget.delivery;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _refreshStatus();
      _pollTimer = Timer.periodic(const Duration(seconds: 8), (_) {
        if (_isWaitingForReceiver) _refreshStatus();
      });
    });
  }

  @override
  void dispose() {
    _pollTimer?.cancel();
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _refreshStatus();
    }
  }

  Future<void> _refreshStatus() async {
    final id = _deliveryId;
    if (id == null || _polling) return;
    if (context.read<DemoModeProvider>().enabled) return;

    _polling = true;
    try {
      final auth = context.read<AuthProvider>();
      final repo = DeliveryRepository(
        apiClient: auth.repository.apiClient,
        demoMode: context.read<DemoModeProvider>(),
      );
      final delivery = await repo.getDelivery(id, role: 'sender');
      if (!mounted) return;
      setState(() => _liveDelivery = delivery);
    } catch (_) {
      // Keep showing last known / static state.
    } finally {
      _polling = false;
    }
  }

  SenderPostedPhase? get _phase {
    final delivery = _liveDelivery ?? widget.delivery;
    if (delivery == null) return null;
    return DeliveryStatusMapper.postedPhaseFor(
      delivery: delivery,
      activeTravelerRequestCount: 0,
    );
  }

  bool get _receiverAccepted {
    final delivery = _liveDelivery ?? widget.delivery;
    if (delivery != null) return delivery.isReceiverAccepted;
    final phase = _phase;
    return phase != null && phase != SenderPostedPhase.waitingForReceiver;
  }

  bool get _isWaitingForReceiver {
    final delivery = _liveDelivery ?? widget.delivery;
    if (delivery == null) return true;
    if (delivery.status != 'posted') return false;
    return !_receiverAccepted;
  }

  @override
  Widget build(BuildContext context) {
    final typo = context.typo;
    final delivery = _liveDelivery ?? widget.delivery;
    final fallbackRoute = widget.result?.route ??
        widget.route ??
        StaticData.activeShipment.route;
    final fromLocation = delivery != null
        ? delivery.exactDisplayFrom
        : routeLeft(fallbackRoute);
    final toLocation = delivery != null
        ? delivery.exactDisplayTo
        : routeRight(fallbackRoute);
    final deliveryId = _deliveryId;
    final waiting = _isWaitingForReceiver;

    return Scaffold(
      backgroundColor: AppColors.surface,
      appBar: BackHeader(
        title: context.l10n.postDelivery,
        fallbackRoute: '/home',
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          physics: PlatformUi.scrollPhysics,
          padding: context.pagePadding,
          child: Column(
            children: [
              const SizedBox(height: 12),
              Container(
                width: 72,
                height: 72,
                decoration: BoxDecoration(
                  color: AppColors.success.withValues(alpha: 0.14),
                  shape: BoxShape.circle,
                ),
                alignment: Alignment.center,
                child: const Icon(
                  Icons.check,
                  size: 36,
                  color: AppColors.success,
                ),
              ),
              const SizedBox(height: 20),
              Text(
                context.l10n.deliveryPostedSuccessfully,
                style: typo.h1.copyWith(fontWeight: FontWeight.w700),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 10),
              Text(
                context.l10n.parcelRequestIsLive,
                style: typo.sm.copyWith(
                  height: 1.5,
                  color: AppColors.textSecondary,
                ),
                textAlign: TextAlign.center,
              ),
              if (fromLocation.isNotEmpty || toLocation.isNotEmpty) ...[
                const SizedBox(height: 18),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: AppColors.border),
                  ),
                  child: StackedRouteEndpoints(
                    from: fromLocation,
                    to: toLocation,
                    emphasized: true,
                  ),
                ),
              ],
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
                child: Column(
                  children: [
                    Text(
                      waiting
                          ? context.l10n.waitingForReceiverAcceptance
                          : context.l10n.receiverAcceptedTitle,
                      style: typo.bodyBold.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      waiting
                          ? context.l10n.emailedReceiverMatchingStarts
                          : context.l10n.receiverAcceptedChooseMatchingBody,
                      style: typo.sm.copyWith(
                        height: 1.5,
                        color: AppColors.textSecondary,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              if (!waiting && deliveryId != null) ...[
                AppButton(
                  label: delivery?.status == 'posted'
                      ? context.l10n.viewMatchingTravelers
                      : context.l10n.viewDeliveryDetails,
                  onPressed: () {
                    if (delivery != null) {
                      context.go(
                        DeliveryStatusMapper.senderDetailRouteFor(delivery),
                      );
                      return;
                    }
                    context.go('/shipment/$deliveryId');
                  },
                ),
                const SizedBox(height: AppButton.stackGap),
              ],
              AppButton(
                label: context.l10n.viewMyDeliveries,
                onPressed: () {
                  final auth = context.read<AuthProvider>();
                  final demoMode = context.read<DemoModeProvider>();
                  context.read<SenderDeliveriesProvider>().refresh(
                        authRepository: auth.repository,
                        demoMode: demoMode,
                        silent: true,
                      );
                  context
                      .read<NotificationRealtimeProvider>()
                      .notifyDeliveryUpdated();
                  context.go('/my-posted-parcels');
                },
              ),
              const SizedBox(height: AppButton.stackGap),
              AppButton(
                label: context.l10n.backToHome,
                variant: AppButtonVariant.outline,
                onPressed: () {
                  final auth = context.read<AuthProvider>();
                  final demoMode = context.read<DemoModeProvider>();
                  context.read<SenderDeliveriesProvider>().refresh(
                        authRepository: auth.repository,
                        demoMode: demoMode,
                        silent: true,
                      );
                  context
                      .read<NotificationRealtimeProvider>()
                      .notifyDeliveryUpdated();
                  context.go('/home');
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}
