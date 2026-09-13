import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../core/platform/keyboard_utils.dart';
import '../../core/config/demo_mode.dart';
import '../../core/api/api_exception.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_typography.dart';
import '../../core/widgets/app_badge.dart';
import '../../core/widgets/app_button.dart';
import '../../core/widgets/app_card.dart';
import '../../core/widgets/app_chip.dart';
import '../../core/layout/responsive.dart';
import '../../core/navigation/app_navigation.dart';
import '../../core/payments/platform_fee_payment.dart';
import '../../core/nfc/nfc_handoff_service.dart';
import '../../core/platform/platform_ui.dart';
import '../../core/widgets/app_labeled_field.dart';
import '../../core/widgets/app_toast.dart';
import '../../core/widgets/back_header.dart';
import '../../core/widgets/back_link.dart';
import '../../core/widgets/cancel_request_confirmation_dialog.dart';
import '../../core/widgets/dispute_warning_icon.dart';
import '../../core/utils/external_links.dart';
import '../../core/widgets/scrollable_form_screen.dart';
import '../../core/widgets/stacked_route_endpoints.dart';
import '../chat/open_delivery_chat.dart';
import '../../data/models/delivery_tracking.dart';
import '../../data/models/shipment.dart';
import '../../data/services/delivery_repository.dart';
import '../../data/services/fulfillment_repository.dart';
import '../../data/services/platform_repository.dart';
import '../../data/delivery_cancel_policy.dart';
import '../../data/delivery_lifecycle.dart';
import '../../data/delivery_status_mapper.dart';
import '../../data/models/wallet_role.dart';
import '../../data/services/delivery_live_loader.dart';
import '../../data/wallet_gate.dart';
import '../../data/wallet_service.dart';
import '../../providers/auth_provider.dart';
import '../../providers/notification_realtime_provider.dart';
import '../../providers/wallet_provider.dart';
import '../../data/delivery_review_store.dart';
import '../../data/review_context.dart';
import '../../data/services/review_repository.dart';
import '../sender/bid_acceptance_payment_screen.dart';
import '../sender/my_posted_parcels_screen.dart';
import '../sender/sender_delivery_status.dart';
import 'widgets/shipment_escrow_section.dart';
import 'widgets/shipment_tracking_section.dart';

/// Track tab — same list/flow as My Posted Deliveries, with Track heading.
class MyShipmentsScreen extends StatelessWidget {
  const MyShipmentsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const MyPostedParcelsScreen(
      title: 'My Shipments',
      fallbackRoute: '/home',
    );
  }
}

class ShipmentDetailScreen extends StatefulWidget {
  const ShipmentDetailScreen({
    super.key,
    required this.shipmentId,
    this.isTravelerView = false,
  });

  final String shipmentId;
  final bool isTravelerView;

  @override
  State<ShipmentDetailScreen> createState() => _ShipmentDetailScreenState();
}

class _ShipmentDetailScreenState extends State<ShipmentDetailScreen> {
  late ShipmentStatus _selectedStatus;
  DeliveryLiveSnapshot? _snapshot;
  bool _loading = true;
  String? _loadError;
  bool _travelerReviewedSender = false;
  bool _travelerReviewedReceiver = false;
  bool _senderReviewedTraveler = false;

  NotificationRealtimeProvider? _realtimeProvider;
  VoidCallback? _realtimeListener;
  VoidCallback? _reviewStoreListener;
  int _lastDeliveryUpdateTick = 0;

  @override
  void initState() {
    super.initState();
    _selectedStatus = ShipmentStatus.inTransit;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadSnapshot();
      _attachRealtimeListener();
      _attachReviewStoreListener();
      _loadReviewFlags();
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
        _loadSnapshot(silent: true);
      }
    };
    realtime.addListener(_realtimeListener!);
  }

  void _attachReviewStoreListener() {
    if (_reviewStoreListener != null) return;
    _reviewStoreListener = () {
      if (!mounted) return;
      _loadReviewFlags();
    };
    DeliveryReviewStore.version.addListener(_reviewStoreListener!);
  }

  Future<void> _loadReviewFlags() async {
    final userId = context.read<AuthProvider>().user?.id ?? '';
    final shipmentId = widget.shipmentId;
    if (widget.isTravelerView) {
      final senderDone = await DeliveryReviewStore.hasSubmitted(
        reviewerUserId: userId,
        shipmentId: shipmentId,
        reviewerRole: WalletRole.traveler,
        revieweeRole: WalletRole.sender,
      );
      final receiverDone = await DeliveryReviewStore.hasSubmitted(
        reviewerUserId: userId,
        shipmentId: shipmentId,
        reviewerRole: WalletRole.traveler,
        revieweeRole: WalletRole.receiver,
      );
      if (!mounted) return;
      setState(() {
        _travelerReviewedSender = senderDone;
        _travelerReviewedReceiver = receiverDone;
      });
      return;
    }

    final travelerDone = await DeliveryReviewStore.hasSubmitted(
      reviewerUserId: userId,
      shipmentId: shipmentId,
      reviewerRole: WalletRole.sender,
      revieweeRole: WalletRole.traveler,
    );
    if (!mounted) return;
    setState(() => _senderReviewedTraveler = travelerDone);
  }

  @override
  void dispose() {
    if (_realtimeListener != null) {
      _realtimeProvider?.removeListener(_realtimeListener!);
    }
    if (_reviewStoreListener != null) {
      DeliveryReviewStore.version.removeListener(_reviewStoreListener!);
    }
    super.dispose();
  }

  DeliveryRepository _deliveryRepository() {
    final auth = context.read<AuthProvider>();
    final demoMode = context.read<DemoModeProvider>();
    return DeliveryRepository(
      apiClient: auth.repository.apiClient,
      demoMode: demoMode,
    );
  }

  FulfillmentRepository _fulfillmentRepository() {
    final auth = context.read<AuthProvider>();
    return FulfillmentRepository(apiClient: auth.repository.apiClient);
  }

  Future<void> _loadSnapshot({bool silent = false}) async {
    final demoMode = context.read<DemoModeProvider>().enabled;
    if (demoMode) {
      setState(() {
        _loading = false;
        _loadError = 'Turn off Demo mode to view live shipment tracking.';
      });
      return;
    }

    if (!silent) {
      setState(() {
        _loading = true;
        _loadError = null;
      });
    }

    try {
      final role = widget.isTravelerView ? 'traveler' : 'sender';
      final snapshot = await DeliveryLiveLoader.load(
        deliveryRepo: _deliveryRepository(),
        fulfillmentRepo: _fulfillmentRepository(),
        deliveryId: widget.shipmentId,
        role: role,
        includeMatchingCount: !widget.isTravelerView,
      );
      if (!mounted) return;
      setState(() {
        _snapshot = snapshot;
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
        _loadError = 'Unable to load shipment details.';
      });
    }
  }

  Shipment? get _shipment {
    final snap = _snapshot;
    if (snap == null) return null;
    return Shipment.fromDelivery(
      snap.delivery,
      status: snap.status,
      role: widget.isTravelerView ? ShipmentRole.traveler : ShipmentRole.sender,
      travelerName: snap.delivery.senderName,
    );
  }

  Future<void> _loadFulfillmentFromApi() async {
    await _loadSnapshot();
  }

  bool _isSenderBookingCancellable() {
    if (_snapshot?.disputed ?? false) return false;
    final status = _snapshot?.status;
    if (status == null) return false;
    return DeliveryLifecycle.isSenderCancellable(status);
  }

  Future<void> _cancelSenderBooking(BuildContext context) async {
    final shipment = _shipment;
    if (shipment == null) return;

    final hoursUntil =
        shipment.travelDate.difference(DateTime.now()).inHours;
    final confirmed = await showCancelRequestConfirmation(context);
    if (!confirmed || !context.mounted) return;

    try {
      final result = await _deliveryRepository().cancelDelivery(shipment.id);
      await _loadSnapshot();
      if (!context.mounted) return;
      await WalletGate.refreshRoles(context, WalletRole.values);
      if (!context.mounted) return;
      final feesRefundable =
          result.platformFeesRefunded ??
          hoursUntil >= DeliveryCancelPolicy.senderCancelMinHoursBeforeTravel;
      AppToast.success(
        context,
        DeliveryCancelPolicy.senderBookingCancelResultMessage(
          platformFeesRefunded: feesRefundable,
        ),
      );
    } on ApiException catch (e) {
      if (!context.mounted) return;
      AppToast.error(context, e.message);
    }
  }

  String _senderPostedBadgeLabel(SenderPostedPhase phase) {
    if (phase == SenderPostedPhase.matchingTravelers) {
      final count = _snapshot?.matchingTravelerCount;
      return SenderDeliveryStatus.matchingTravelersLabel(count);
    }
    return phase.badgeLabel;
  }

  List<ShipmentStatus> _statusOptionsFor(ShipmentStatus current) {
    if (current == ShipmentStatus.inTransit) {
      // CP2 is enabled via a dedicated button, not a Delivered radio option.
      return const [];
    }
    return const [ShipmentStatus.inTransit];
  }

  ShipmentStatus _selectedOptionFor(ShipmentStatus current) {
    final options = _statusOptionsFor(current);
    if (options.isEmpty) return current;
    if (options.contains(_selectedStatus)) return _selectedStatus;
    return options.first;
  }

  void _updateStatus(ShipmentStatus selected) async {
    if (selected != ShipmentStatus.inTransit) {
      setState(() => _selectedStatus = selected);
      return;
    }

    try {
      final auth = context.read<AuthProvider>();
      final repo = PlatformRepository(apiClient: auth.repository.apiClient);
      await repo.markInTransit(widget.shipmentId);
      await _loadSnapshot();
    } catch (e) {
        if (!mounted) return;
        AppToast.error(context, 'Unable to mark in transit: $e');
        return;
      }

    setState(() => _selectedStatus = selected);
    if (!mounted) return;
    AppToast.success(context, 'Parcel status updated to In Transit.');
  }

  void _openBidAcceptancePayment(BuildContext context, String shipmentId) {
    context.push('/sender-counter-offer?delivery=$shipmentId');
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return Scaffold(
        backgroundColor: AppColors.background,
        appBar: BackHeader(
          title: widget.shipmentId,
          fallbackRoute:
              widget.isTravelerView ? '/traveler-deliveries' : '/track',
        ),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    if (_loadError != null || _shipment == null || _snapshot == null) {
      return Scaffold(
        backgroundColor: AppColors.background,
        appBar: BackHeader(
          title: widget.shipmentId,
          fallbackRoute:
              widget.isTravelerView ? '/traveler-deliveries' : '/track',
        ),
        body: Center(
          child: Padding(
            padding: context.pagePadding,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  _loadError ?? 'Shipment not found.',
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 16),
                TextButton(onPressed: _loadSnapshot, child: const Text('Retry')),
              ],
            ),
          ),
        ),
      );
    }

    final shipment = _shipment!;
    final snap = _snapshot!;
    final typo = context.typo;
    final status = DeliveryStatusMapper.toShipmentStatus(snap.status);
    final tracking = snap.tracking;
    final postedPhase = status == ShipmentStatus.open && !widget.isTravelerView
        ? DeliveryStatusMapper.postedPhaseFor(
            delivery: snap.delivery,
            travelerRequests: snap.travelerRequests,
          )
        : null;
    final isDisputed = snap.disputed;
    final cp1Confirmed = snap.cp1Confirmed;
    final cp2Confirmed = snap.cp2Confirmed;
    // Traveler marks In Transit after NFC CP1 matching sets Collected.
    final canMarkInTransit = status == ShipmentStatus.collected &&
        cp1Confirmed &&
        !cp2Confirmed;
    final showStatusUpdate =
        widget.isTravelerView && !isDisputed && canMarkInTransit;
    final statusOptions = _statusOptionsFor(status);
    final selectedStatus = _selectedOptionFor(status);
    const statusUpdateHint =
        'NFC handoff is complete. Tap Start Transit when you begin travel with this parcel.';
    return Scaffold(
          backgroundColor: AppColors.background,
          appBar: BackHeader(
            title: shipment.id,
            fallbackRoute: widget.isTravelerView ? '/traveler-deliveries' : '/track',
          ),
          body: SafeArea(
            child: SingleChildScrollView(
              physics: PlatformUi.scrollPhysics,
              padding: context.pagePadding,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Actionable sender phases only (not a duplicate status badge).
                  if (!widget.isTravelerView &&
                      status == ShipmentStatus.open &&
                      postedPhase != null) ...[
                    Builder(
                      builder: (context) {
                        final phase = postedPhase!;
                        final label = _senderPostedBadgeLabel(phase);
                        final badge = AppBadge(
                          label: label,
                          color: phase.color,
                          backgroundColor: phase.backgroundColor,
                          semiBold: true,
                          wide: true,
                        );

                        if (phase == SenderPostedPhase.matchingTravelers ||
                            phase == SenderPostedPhase.travelerReviewing) {
                          return GestureDetector(
                            onTap: () => context.push(
                              '/bid-requests/${shipment.id}',
                            ),
                            child: badge,
                          );
                        }

                        if (phase == SenderPostedPhase.travelerAccepted) {
                          return GestureDetector(
                            onTap: () => _openBidAcceptancePayment(
                              context,
                              shipment.id,
                            ),
                            child: badge,
                          );
                        }

                        // Waiting-for-receiver etc. — timeline covers status.
                        return const SizedBox.shrink();
                      },
                    ),
                    if (postedPhase == SenderPostedPhase.matchingTravelers ||
                        postedPhase == SenderPostedPhase.travelerReviewing ||
                        postedPhase == SenderPostedPhase.travelerAccepted)
                      const SizedBox(height: 16),
                  ],
                  AppCard(
                    margin: EdgeInsets.zero,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        ShipmentTrackingSection(
                          shipment: shipment,
                          stepProgress: tracking.progress,
                          stepLabels: tracking.stepLabels,
                        ),
                        const Padding(
                          padding: EdgeInsets.symmetric(vertical: 20),
                          child: Divider(height: 1),
                        ),
                        Text('Delivery details', style: typo.h3.copyWith(fontWeight: FontWeight.w700)),
                        const SizedBox(height: 12),
                        StackedRouteEndpoints(
                          from: shipment.fromCity,
                          to: shipment.toCity,
                          fallbackRoute: shipment.route,
                          sectionLabel: 'Route',
                          bottomPadding: 8,
                        ),
                        _detailRow(context, 'Travel date', DateFormat('MMM d, yyyy').format(shipment.travelDate)),
                        _detailRow(context, 'Parcel type', '${shipment.parcelCategory} · ${shipment.parcelWeightKg}kg'),
                        const SizedBox(height: 16),
                        ShipmentEscrowSection(shipmentId: shipment.id),
                        const SizedBox(height: 16),
                        ValueListenableBuilder<int>(
                          valueListenable: WalletService.walletVersion,
                          builder: (context, _, __) {
                            // Traveler + Sender: no Escrow active / ID verified
                            // badges — only party checkpoints (and refunded/frozen).
                            final showEscrowRefunded =
                                WalletService.isEscrowRefunded(shipment.id);
                            final showEscrowFrozen =
                                WalletService.isEscrowFrozen(shipment.id);

                            return Wrap(
                              spacing: 8,
                              runSpacing: 8,
                              children: [
                                if (showEscrowRefunded)
                                  AppBadge(
                                    label: 'Escrow refunded',
                                    color: AppColors.warning,
                                    backgroundColor: AppColors.warning
                                        .withValues(alpha: 0.12),
                                    small: true,
                                  )
                                else if (showEscrowFrozen)
                                  AppBadge(
                                    label: 'Escrow frozen',
                                    color: AppColors.danger,
                                    backgroundColor: AppColors.danger
                                        .withValues(alpha: 0.12),
                                    small: true,
                                  ),
                                if (isDisputed)
                                  AppBadge(
                                    label: 'Dispute open',
                                    color: AppColors.danger,
                                    backgroundColor: AppColors.danger
                                        .withValues(alpha: 0.12),
                                    small: true,
                                  ),
                                if (cp1Confirmed)
                                  AppBadge.success('✓ Sender ↔ Traveler')
                                else
                                  AppBadge(
                                    label: '○ Sender ↔ Traveler',
                                    color: AppColors.textDisabled,
                                    backgroundColor: AppColors.textDisabled
                                        .withValues(alpha: 0.4),
                                    small: true,
                                  ),
                                if (cp2Confirmed ||
                                    status == ShipmentStatus.delivered)
                                  AppBadge.success('✓ Traveler ↔ Receiver')
                                else
                                  AppBadge(
                                    label: '○ Traveler ↔ Receiver',
                                    color: AppColors.textDisabled,
                                    backgroundColor: AppColors.textDisabled
                                        .withValues(alpha: 0.4),
                                    small: true,
                                  ),
                              ],
                            );
                          },
                        ),
                      ],
                    ),
                  ),
                  if (showStatusUpdate) ...[
                    const SizedBox(height: 24),
                    Text(
                      'Update Shipment Status',
                      style: typo.h3.copyWith(fontWeight: FontWeight.w700),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      statusUpdateHint,
                      style: typo.sm.copyWith(height: 1.5, color: AppColors.textSecondary),
                    ),
                    const SizedBox(height: 12),
                    ...statusOptions.map(
                      (option) => Padding(
                        padding: const EdgeInsets.only(bottom: 10),
                        child: AppCard(
                          highlighted: selectedStatus == option,
                          padding: EdgeInsets.zero,
                          margin: EdgeInsets.zero,
                          child: Material(
                            color: Colors.transparent,
                            child: InkWell(
                              onTap: () => setState(() => _selectedStatus = option),
                              borderRadius: BorderRadius.circular(16),
                              child: Padding(
                                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                                child: Row(
                                  children: [
                                    Expanded(
                                      child: Text(
                                        option.label,
                                        style: typo.bodyBold.copyWith(fontWeight: FontWeight.w700),
                                      ),
                                    ),
                                    Icon(
                                      selectedStatus == option
                                          ? Icons.check_circle_rounded
                                          : Icons.radio_button_unchecked_rounded,
                                      color: selectedStatus == option
                                          ? AppColors.primary
                                          : AppColors.textSecondary,
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    AppButton(
                      label: 'Start Transit',
                      onPressed: () => _updateStatus(selectedStatus),
                    ),
                  ],
                  if (_showNfcCheckpoint1()) ...[
                    const SizedBox(height: 24),
                    AppCard(
                      margin: EdgeInsets.zero,
                      child: _NfcCheckpoint1Section(
                        shipmentId: shipment.id,
                        isTravelerView: widget.isTravelerView,
                      ),
                    ),
                  ],
                  // Traveler CP2 / transit NFC only after CP1 is done.
                  if (widget.isTravelerView && cp1Confirmed && !isDisputed) ...[
                    const SizedBox(height: 24),
                    AppCard(
                      margin: EdgeInsets.zero,
                      child: _TravelerNfcDeliverySection(
                        status: status,
                        shipmentId: shipment.id,
                      ),
                    ),
                  ],
                  const SizedBox(height: 24),
                  ..._buildActions(context, shipment, status),
                  const SizedBox(height: 16),
                ],
              ),
            ),
          ),
        );
  }

  bool _showNfcCheckpoint1() {
    final snap = _snapshot;
    if (snap == null) return false;
    if (snap.disputed) return false;
    if (snap.cp1Confirmed) return false;
    // After escrow booking until CP1 is confirmed (sender + traveler detail).
    final status = DeliveryStatusMapper.toShipmentStatus(snap.status);
    return status == ShipmentStatus.bidAccepted ||
        status == ShipmentStatus.photosUploaded ||
        status == ShipmentStatus.collected;
  }

  List<Widget> _buildActions(
    BuildContext context,
    Shipment shipment,
    ShipmentStatus status,
  ) {
    final snap = _snapshot;
    final cp2Confirmed = snap?.cp2Confirmed ?? false;
    final typo = context.typo;
    final actions = <Widget>[];

    void addAction(Widget action) {
      if (actions.isNotEmpty) {
        actions.add(const SizedBox(height: AppButton.stackGap));
      }
      actions.add(action);
    }

    void addSenderDisputeButton() {
      final disputed = snap?.disputed ?? false;
      final canOpen = DeliveryLifecycle.isDisputable(snap?.status);
      if (!disputed && !canOpen) return;
      addAction(
        AppButton(
          label: disputed ? 'View dispute' : 'Dispute',
          variant: AppButtonVariant.danger,
          textStyle: typo.buttonDanger.copyWith(fontWeight: FontWeight.w700),
          onPressed: () => appNavigatePush(
            disputed
                ? disputeRoute(shipment.id)
                : disputeFormRoute(shipment.id),
          ),
        ),
      );
    }

    void addSenderChatButton() {
      addAction(
        AppButton(
          label: 'Chat with Traveler',
          onPressed: () => openDeliveryChat(
            context,
            chatBasePath: '/sender-chats',
            threadType: 'sender_traveler',
            deliveryKey: shipment.id,
          ),
        ),
      );
    }

    void addSenderReceiverChatButton() {
      if (snap?.isReceiverAccepted != true) return;
      addAction(
        AppButton(
          label: 'Chat with Receiver',
          onPressed: () => openDeliveryChat(
            context,
            chatBasePath: '/sender-chats',
            threadType: 'sender_receiver',
            deliveryKey: shipment.id,
          ),
        ),
      );
    }

    void addTravelerReviewButton({
      required String label,
      required WalletRole revieweeRole,
    }) {
      final alreadyReviewed = revieweeRole == WalletRole.sender
          ? _travelerReviewedSender
          : _travelerReviewedReceiver;
      addAction(
        AppButton(
          label: label,
          onPressed: alreadyReviewed
              ? null
              : () => context.push(
                    deliveryReviewRoute(
                      shipmentId: shipment.id,
                      reviewerRole: WalletRole.traveler,
                      revieweeRole: revieweeRole,
                    ),
                  ),
        ),
      );
    }

    // Sender detail (non-traveler route): same bottom actions across lifecycle stages.
    if (!widget.isTravelerView) {
      // Open: Chat with Receiver (after they accept) + Chat with Traveler + Cancel.
      // Matching travelers CTA is in the status row / My Posted Deliveries.
      if (status == ShipmentStatus.open) {
        addSenderReceiverChatButton();
        addSenderChatButton();
        addAction(
          AppButton(
            label: 'Cancel',
            variant: AppButtonVariant.danger,
            onPressed: () => appNavigatePush(
              '/cancel-posted-delivery/${shipment.id}',
            ),
          ),
        );
        return actions;
      }

      if (snap?.disputed ?? false) {
        addSenderReceiverChatButton();
        addSenderChatButton();
        addSenderDisputeButton();
        return actions;
      }

      final showDisputeAndChat = DeliveryLifecycle.isDisputable(snap?.status);

      // Bid Accepted / In Transit / Delivered (+ mid stages):
      // Chat with Receiver, Chat with Traveler, then Dispute.
      if (showDisputeAndChat) {
        addSenderReceiverChatButton();
        addSenderChatButton();
        addSenderDisputeButton();
      }

      // Cancel booking allowed through collected (including when parcel is
      // already collected). ≥24h → fees refunded; <24h → fees kept.
      if (_isSenderBookingCancellable()) {
        addAction(
          AppButton(
            label: 'Cancel booking (refund escrow)',
            variant: AppButtonVariant.danger,
            onPressed: () => _cancelSenderBooking(context),
          ),
        );
      }

      if (status == ShipmentStatus.delivered || cp2Confirmed) {
        addAction(
          AppButton(
            label: 'Leave a review',
            onPressed: _senderReviewedTraveler
                ? null
                : () => context.push(
                      deliveryReviewRoute(
                        shipmentId: shipment.id,
                        reviewerRole: WalletRole.sender,
                      ),
                    ),
          ),
        );
      }
      return actions;
    }

    if (snap?.disputed ?? false) {
      addAction(
        AppButton(
          label: 'View dispute',
          variant: AppButtonVariant.danger,
          onPressed: () => appNavigatePush(
            disputeRoute(
              shipment.id,
              travelerView: true,
            ),
          ),
        ),
      );
      if (status == ShipmentStatus.delivered || cp2Confirmed) {
        addTravelerReviewButton(
          label: 'Leave a review for receiver',
          revieweeRole: WalletRole.receiver,
        );
        addTravelerReviewButton(
          label: 'Leave a review for a sender',
          revieweeRole: WalletRole.sender,
        );
      }
      return actions;
    }

    if (status == ShipmentStatus.delivered || cp2Confirmed) {
      if (DeliveryLifecycle.isDisputable(snap?.status)) {
        addAction(
          AppButton(
            label: 'Dispute',
            variant: AppButtonVariant.danger,
            textStyle: typo.buttonDanger.copyWith(fontWeight: FontWeight.w700),
            onPressed: () => appNavigatePush(
              disputeFormRoute(
                shipment.id,
                travelerView: true,
              ),
            ),
          ),
        );
      }
      addTravelerReviewButton(
        label: 'Leave a review for receiver',
        revieweeRole: WalletRole.receiver,
      );
      addTravelerReviewButton(
        label: 'Leave a review for a sender',
        revieweeRole: WalletRole.sender,
      );
      return actions;
    }

    final canReportIssue = DeliveryLifecycle.isDisputable(snap?.status);

    if (widget.isTravelerView && canReportIssue) {
      addAction(
        AppButton(
          label: 'Chat with sender',
          variant: AppButtonVariant.ghost,
          textStyle: typo.button.copyWith(
            fontWeight: FontWeight.w700,
            color: AppColors.primary,
          ),
          onPressed: () => openDeliveryChat(
            context,
            chatBasePath: '/traveler-chats',
            threadType: 'sender_traveler',
            deliveryKey: shipment.id,
          ),
        ),
      );
      addAction(
        AppButton(
          label: 'Chat with receiver',
          variant: AppButtonVariant.ghost,
          textStyle: typo.button.copyWith(
            fontWeight: FontWeight.w700,
            color: AppColors.primary,
          ),
          onPressed: () => openDeliveryChat(
            context,
            chatBasePath: '/traveler-chats',
            threadType: 'traveler_receiver',
            deliveryKey: shipment.id,
          ),
        ),
      );
      addAction(
        AppButton(
          label: 'Dispute',
          variant: AppButtonVariant.danger,
          textStyle: typo.buttonDanger.copyWith(fontWeight: FontWeight.w700),
          onPressed: () => appNavigatePush(
            disputeFormRoute(
              shipment.id,
              travelerView: true,
            ),
          ),
        ),
      );
      // Cancel allowed through collected (incl. already collected). ≥24h →
      // fees refunded; <24h → fees kept. Not available once in-transit.
      // Traveler cancel requires a backend endpoint — hidden in live mode.
      if (false && widget.isTravelerView) {
        addAction(
          AppButton(
            label: 'Cancel Request',
            variant: AppButtonVariant.danger,
            onPressed: () => _cancelTravelerRequest(context, shipment),
          ),
        );
      }
    }

    return actions;
  }

  Future<void> _cancelTravelerRequest(
    BuildContext context,
    Shipment shipment,
  ) async {
    AppToast.info(
      context,
      'Traveler cancellation is not available in the app yet.',
    );
  }

  Widget _detailRow(BuildContext context, String label, String value) {
    final typo = context.typo;
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: typo.sm),
          Flexible(
            child: Text(
              value,
              textAlign: TextAlign.end,
              style: typo.bodyBold.copyWith(fontWeight: FontWeight.w400),
            ),
          ),
        ],
      ),
    );
  }
}

class _NfcCheckpoint1Section extends StatelessWidget {
  const _NfcCheckpoint1Section({
    required this.shipmentId,
    required this.isTravelerView,
  });

  final String shipmentId;
  final bool isTravelerView;

  @override
  Widget build(BuildContext context) {
    final typo = context.typo;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Icon(Icons.nfc, size: 20, color: AppColors.primary),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                'NFC Checkpoint Traveler & Sender',
                style: typo.h3.copyWith(fontWeight: FontWeight.w700),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Text(
          isTravelerView
              ? 'This NFC checkpoint confirms the sender handed over the parcel. '
                  'Tap your phones with the sender so both of you can confirm on your own devices. '
                  'After both confirm, the parcel is marked Collected. '
                  'The sender should confirm on their device after the tap.'
              : 'Tap phones with the traveler to confirm handoff. When both parties confirm, the parcel becomes Collected. '
                  'Waiting for the traveler to confirm on their device after your tap.',
          style: typo.sm.copyWith(height: 1.5),
        ),
        const SizedBox(height: 16),
        AppButton(
          label: isTravelerView
              ? 'Start NFC with Sender'
              : 'Start NFC with Traveler',
          onPressed: () => context.push(
            '/nfc-confirm',
            extra: {
              'shipmentId': shipmentId,
              'isTraveler': isTravelerView,
              'checkpoint': 1,
            },
          ),
        ),
      ],
    );
  }
}
class _TravelerNfcDeliverySection extends StatelessWidget {
  const _TravelerNfcDeliverySection({
    required this.status,
    required this.shipmentId,
  });

  final ShipmentStatus status;
  final String shipmentId;

  @override
  Widget build(BuildContext context) {
    final typo = context.typo;
    final isDelivered = status == ShipmentStatus.delivered;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(
              Icons.nfc,
              size: 20,
              color: isDelivered ? AppColors.success : AppColors.primary,
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                'NFC Checkpoint Traveler & Receiver',
                style: typo.h3.copyWith(fontWeight: FontWeight.w700),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        if (isDelivered) ...[
          Text(
            'Final delivery confirmed with the receiver via NFC. Escrow released to your wallet.',
            style: typo.sm.copyWith(height: 1.5, color: AppColors.success),
          ),
          const SizedBox(height: 12),
          AppBadge.success('✓ NFC Traveler & Receiver confirmed'),
        ] else ...[
          Text(
            'Meet the receiver and tap phones to confirm final delivery. Both parties must complete NFC Checkpoint Traveler & Receiver to release escrow.',
            style: typo.sm.copyWith(height: 1.5),
          ),
          const SizedBox(height: 16),
          AppButton(
            label: 'Start NFC with Receiver',
            onPressed: () => context.push(
              '/nfc-confirm',
              extra: {
                'shipmentId': shipmentId,
                'isTraveler': true,
                'checkpoint': 2,
              },
            ),
          ),
        ],
      ],
    );
  }
}

class NfcConfirmScreen extends StatefulWidget {
  const NfcConfirmScreen({
    super.key,
    this.shipmentId,
    this.checkpoint = 1,
    this.isTraveler = false,
  });

  final String? shipmentId;
  /// 1 = sender/traveler handoff, 2 = receiver delivery.
  final int checkpoint;
  final bool isTraveler;

  @override
  State<NfcConfirmScreen> createState() => _NfcConfirmScreenState();
}

class _NfcConfirmScreenState extends State<NfcConfirmScreen> {
  bool _confirmed = false;
  bool _cancelled = false;
  bool _listening = false;
  String _status = 'Preparing NFC…';
  Timer? _peerPollTimer;

  bool get _isCheckpoint2 => widget.checkpoint == 2;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _startNfc());
  }

  @override
  void dispose() {
    _peerPollTimer?.cancel();
    NfcHandoffService.stop();
    super.dispose();
  }

  void _cancel() {
    if (_confirmed || _cancelled) return;
    _cancelled = true;
    _peerPollTimer?.cancel();
    NfcHandoffService.stop();
    final shipmentId = widget.shipmentId ?? '';
    final fallback = _isCheckpoint2
        ? (widget.isTraveler
            ? '/shipment/$shipmentId?traveler=true'
            : '/receiver-tracking')
        : (widget.isTraveler
            ? '/shipment/$shipmentId?traveler=true'
            : '/track');
    appNavigateBackFromContext(context, fallback: fallback);
  }

  Future<void> _startNfc({bool forceSimulate = false}) async {
    if (_confirmed || _cancelled) return;
    // While a real NFC session is open, only force-simulate may interrupt it.
    if (_listening && !forceSimulate) return;

    if (_listening && forceSimulate) {
      await NfcHandoffService.stop();
    }

    final useSimulate =
        forceSimulate || kIsWeb || !(await NfcHandoffService.isAvailable());

    setState(() {
      _listening = true;
      _status = useSimulate
          ? 'Confirming secure tap…'
          : 'Matching with the other phone…';
    });

    try {
      final deviceId = useSimulate
          ? 'sim-${DateTime.now().millisecondsSinceEpoch}'
          : await NfcHandoffService.waitForTap(
              allowSimulate: true,
              onStatus: (s) {
                if (mounted) setState(() => _status = s);
              },
            );
      if (_cancelled || !mounted) return;
      await _complete(deviceId: deviceId);
    } catch (e) {
      if (!mounted || _cancelled) return;
      setState(() {
        _listening = false;
        _status = 'NFC failed. Tap below to retry or simulate.';
      });
      AppToast.error(context, 'NFC error: $e');
    }
  }

  void _startPeerPoll(String shipmentId) {
    _peerPollTimer?.cancel();
    _peerPollTimer = Timer.periodic(const Duration(milliseconds: 800), (_) {
      unawaited(_checkPeerConfirmed(shipmentId));
    });
    // Immediate first check so we don't wait a full interval.
    unawaited(_checkPeerConfirmed(shipmentId));
  }

  Future<void> _checkPeerConfirmed(String shipmentId) async {
    if (!mounted || _cancelled || _confirmed) return;
    try {
      final auth = context.read<AuthProvider>();
      final repo = FulfillmentRepository(apiClient: auth.repository.apiClient);
      final checkpoints = await repo.listNfcCheckpoints(shipmentId);
      final target = _isCheckpoint2
          ? 'delivery_traveler_receiver'
          : 'handoff_sender_traveler';
      Map<String, dynamic>? row;
      for (final c in checkpoints) {
        if ((c['checkpoint']?.toString() ?? '') == target) {
          row = c;
          break;
        }
      }
      final confirmedAt = row?['confirmedAt'] ?? row?['confirmed_at'];
      if (confirmedAt == null) return;

      _peerPollTimer?.cancel();
      if (!mounted || _cancelled) return;
      _confirmed = true;
      await _goToSuccess(shipmentId);
    } catch (_) {
      // Keep polling; transient network errors are fine.
    }
  }

  Future<void> _goToSuccess(String shipmentId) async {
    if (!mounted) return;
    if (_isCheckpoint2) {
      await WalletGate.refreshRoles(
        context,
        [WalletRole.sender, WalletRole.traveler, WalletRole.receiver],
      );
      if (!mounted) return;
      if (widget.isTraveler) {
        context.pushReplacement(
          '/traveler-nfc-success',
          extra: {'shipmentId': shipmentId, 'waitingForPeer': false},
        );
      } else {
        context.pushReplacement(
          '/receiver-nfc-success',
          extra: {'shipmentId': shipmentId, 'waitingForPeer': false},
        );
      }
      return;
    }

    context.pushReplacement(
      '/nfc-confirm/success',
      extra: {
        'shipmentId': shipmentId,
        'isTraveler': widget.isTraveler,
        'waitingForPeer': false,
      },
    );
  }

  Future<void> _complete({String? deviceId}) async {
    if (!mounted || _confirmed || _cancelled) return;
    final shipmentId = widget.shipmentId;
    if (shipmentId == null || shipmentId.isEmpty) {
      if (mounted) {
        AppToast.error(context, 'Delivery ID is missing for NFC confirm.');
      }
      setState(() => _listening = false);
      return;
    }

    _confirmed = true;
    setState(() => _status = 'Confirming checkpoint…');

    try {
      final auth = context.read<AuthProvider>();
      final repo = FulfillmentRepository(apiClient: auth.repository.apiClient);

      Future<Map<String, dynamic>> confirm(String? paymentIntentId) => repo.confirmNfc(
            deliveryId: shipmentId,
            checkpoint: _isCheckpoint2 ? 2 : 1,
            deviceId: deviceId,
            paymentIntentId: paymentIntentId,
          );

      late final Map<String, dynamic> result;
      try {
        result = await confirm(null);
      } on ApiException catch (e) {
        if (e.requiresPayment && e.paymentRole == 'traveler' && !widget.isTraveler) {
          throw ApiException(
            message:
                'Traveler must add funds to their wallet (or pay with card) '
                'before handoff can complete.',
            code: e.code,
            statusCode: e.statusCode,
          );
        }
        // Fee is normally collected at Pay Now; if a legacy unpaid fee remains,
        // let the traveler complete card payment on their device.
        if (!_isCheckpoint2 &&
            widget.isTraveler &&
            e.requiresPayment &&
            e.clientSecret != null) {
          result = await PlatformFeePayment.withStripeRetry(
            context: context,
            role: WalletRole.traveler,
            attempt: confirm,
          );
        } else {
          rethrow;
        }
      }

      final pendingPeer = result['pendingPeer'] == true;
      if (pendingPeer && mounted) {
        setState(() {
          _confirmed = false;
          _listening = false;
          _status = 'Your tap is recorded — waiting for the other phone…';
        });
        _startPeerPoll(shipmentId);
        return;
      }
    } on ApiException catch (e) {
      if (e.code == 'NFC_PENDING_PEER') {
        if (mounted) {
          setState(() {
            _confirmed = false;
            _listening = false;
            _status = 'Your tap is recorded — waiting for the other phone…';
          });
          _startPeerPoll(shipmentId);
        }
        return;
      }
      if (mounted) {
        AppToast.error(context, 'NFC checkpoint failed: ${e.message}');
      }
      setState(() {
        _confirmed = false;
        _listening = false;
      });
      return;
    } catch (e) {
      if (mounted) {
        AppToast.error(context, 'NFC checkpoint failed: $e');
      }
      setState(() {
        _confirmed = false;
        _listening = false;
      });
      return;
    }

    if (!mounted) return;
    await _goToSuccess(shipmentId);
  }

  @override
  Widget build(BuildContext context) {
    final typo = context.typo;
    final title = _isCheckpoint2
        ? 'NFC Checkpoint Traveler & Receiver'
        : 'NFC Checkpoint Traveler & Sender';
    final body = _isCheckpoint2
        ? (widget.isTraveler
            ? "Hold your phone near the receiver's phone to confirm delivery. Both of you must match NFC to mark Delivered and release escrow."
            : "Hold your phone near the traveler's phone to confirm delivery. Both of you must match NFC to mark Delivered.")
        : widget.isTraveler
            ? "Open this screen on the sender's phone too. When both of you confirm, the parcel becomes Collected."
            : "Open this screen on the traveler's phone too. When both of you confirm, the parcel becomes Collected.";

    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [AppColors.nfcGradientStart, AppColors.primary],
          ),
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 32),
            child: Column(
              children: [
                const Spacer(flex: 2),
                GestureDetector(
                  onTap: _confirmed
                      ? null
                      : () => _startNfc(forceSimulate: true),
                  child: const _NfcPulseGraphic(),
                ),
                const SizedBox(height: 36),
                Text(
                  title,
                  textAlign: TextAlign.center,
                  style: typo.nfcTitle,
                ),
                if (widget.shipmentId != null &&
                    widget.shipmentId!.isNotEmpty) ...[
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.14),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: Colors.white.withValues(alpha: 0.28),
                      ),
                    ),
                    child: Text(
                      'Trip / Delivery ID: ${widget.shipmentId}',
                      textAlign: TextAlign.center,
                      style: typo.bodyBold.copyWith(
                        color: Colors.white,
                        fontSize: 16,
                      ),
                    ),
                  ),
                ],
                const SizedBox(height: 14),
                Text(
                  body,
                  textAlign: TextAlign.center,
                  style: typo.nfcBody,
                ),
                const SizedBox(height: 16),
                Text(
                  _status,
                  textAlign: TextAlign.center,
                  style: typo.sm.copyWith(color: Colors.white70),
                ),
                const SizedBox(height: 24),
                if (!_listening && !_confirmed)
                  TextButton(
                    onPressed: () => _startNfc(),
                    child: Text(
                      'Retry NFC',
                      style: typo.button.copyWith(color: Colors.white),
                    ),
                  ),
                TextButton(
                  onPressed: _confirmed
                      ? null
                      : () => _startNfc(forceSimulate: true),
                  child: Text(
                    'Simulate tap (dev)',
                    style: typo.button.copyWith(
                      color: Colors.white,
                      fontSize: 16,
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'One phone? Simulate as sender, then login as traveler and simulate again.',
                  textAlign: TextAlign.center,
                  style: typo.sm.copyWith(color: Colors.white60),
                ),
                const SizedBox(height: 24),
                Center(
                  child: OutlinedButton(
                    onPressed: _cancel,
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.white,
                      backgroundColor: Colors.white.withValues(alpha: 0.1),
                      side: BorderSide(color: Colors.white.withValues(alpha: 0.38), width: 1.5),
                      padding: const EdgeInsets.symmetric(horizontal: 44, vertical: 14),
                      minimumSize: Size.zero,
                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    ),
                    child: Text(
                      'Cancel',
                      style: typo.button.copyWith(color: Colors.white, fontSize: 14),
                    ),
                  ),
                ),
                const Spacer(flex: 3),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _NfcPulseGraphic extends StatelessWidget {
  const _NfcPulseGraphic();

  @override
  Widget build(BuildContext context) {
    final typo = context.typo;
    return SizedBox(
      width: 220,
      height: 220,
      child: Stack(
        alignment: Alignment.center,
        children: [
          Container(
            width: 220,
            height: 220,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
            ),
          ),
          Container(
            width: 164,
            height: 164,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: Colors.white.withValues(alpha: 0.12)),
            ),
          ),
          Container(
            width: 88,
            height: 88,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.14),
              shape: BoxShape.circle,
            ),
            alignment: Alignment.center,
            child: Text('📱', style: typo.emojiLg),
          ),
        ],
      ),
    );
  }
}

class NfcConfirmSuccessScreen extends StatefulWidget {
  const NfcConfirmSuccessScreen({
    super.key,
    required this.shipmentId,
    this.isTraveler = false,
    this.waitingForPeer = false,
  });

  final String shipmentId;
  final bool isTraveler;
  final bool waitingForPeer;

  @override
  State<NfcConfirmSuccessScreen> createState() => _NfcConfirmSuccessScreenState();
}

class _NfcConfirmSuccessScreenState extends State<NfcConfirmSuccessScreen> {
  @override
  Widget build(BuildContext context) {
    final typo = context.typo;
    final shipmentId = widget.shipmentId;
    final shipmentRoute = widget.isTraveler
        ? '/shipment/$shipmentId?traveler=true'
        : '/shipment/$shipmentId';
    final listRoute = widget.isTraveler ? '/traveler-deliveries' : '/track';
    final otherParty = widget.isTraveler ? 'sender' : 'traveler';
    final waiting = widget.waitingForPeer;

    final title = waiting
        ? 'Waiting for $otherParty'
        : 'NFC Checkpoint Traveler & Sender complete';
    final body = waiting
        ? 'Your NFC tap for $shipmentId is recorded. Ask the $otherParty to complete their NFC tap. When both match, the parcel becomes Collected.'
        : widget.isTraveler
            ? 'You and the Sender successfully verified the same trip/delivery. You are connected to the correct Sender, and this parcel belongs to this exact trip/delivery.'
            : 'You and the Traveler successfully verified the same trip/delivery. The Traveler is connected to you (the correct Sender), and this parcel belongs to this exact trip/delivery.';

    return Scaffold(
      backgroundColor: AppColors.surface,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  color: (waiting ? AppColors.primary : AppColors.success)
                      .withValues(alpha: 0.12),
                  shape: BoxShape.circle,
                ),
                alignment: Alignment.center,
                child: Icon(
                  waiting ? Icons.hourglass_top_rounded : Icons.check_circle_rounded,
                  size: 40,
                  color: waiting ? AppColors.primary : AppColors.success,
                ),
              ),
              const SizedBox(height: 20),
              Text(title, style: typo.h1, textAlign: TextAlign.center),
              const SizedBox(height: 16),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                decoration: BoxDecoration(
                  color: AppColors.success.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                    color: AppColors.success.withValues(alpha: 0.28),
                  ),
                ),
                child: Column(
                  children: [
                    Text(
                      'Trip / Delivery ID',
                      textAlign: TextAlign.center,
                      style: typo.sm.copyWith(
                        color: AppColors.success,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      shipmentId,
                      textAlign: TextAlign.center,
                      style: typo.h2.copyWith(color: AppColors.success),
                    ),
                    if (!waiting) ...[
                      const SizedBox(height: 8),
                      Text(
                        'Sender ↔ Traveler verified this exact ID',
                        textAlign: TextAlign.center,
                        style: typo.sm.copyWith(
                          color: AppColors.success,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(height: 16),
              Text(
                body,
                textAlign: TextAlign.center,
                style: typo.sm.copyWith(height: 1.5),
              ),
              if (!waiting) ...[
                const SizedBox(height: 12),
                Text(
                  'Parcel status is now Collected. Traveler can mark In Transit when ready.',
                  textAlign: TextAlign.center,
                  style: typo.sm.copyWith(height: 1.5),
                ),
              ],
              const SizedBox(height: 32),
              AppButton(
                label: 'View shipment',
                onPressed: () => context.go(shipmentRoute),
              ),
              const SizedBox(height: AppButton.stackGap),
              AppButton(
                label: widget.isTraveler ? 'Back to deliveries' : 'Back to shipments',
                variant: AppButtonVariant.outline,
                onPressed: () => context.go(listRoute),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class TravelerNfcDeliverySuccessScreen extends StatelessWidget {
  const TravelerNfcDeliverySuccessScreen({
    super.key,
    required this.shipmentId,
    this.waitingForPeer = false,
  });

  final String shipmentId;
  final bool waitingForPeer;

  @override
  Widget build(BuildContext context) {
    final typo = context.typo;
    final title = waitingForPeer
        ? 'Waiting for receiver'
        : 'NFC Checkpoint Traveler & Receiver complete';
    final body = waitingForPeer
        ? 'Your NFC tap for $shipmentId is recorded. Ask the receiver to complete their NFC Checkpoint Traveler & Receiver tap to confirm delivery and release escrow.'
        : 'You and the Receiver successfully verified the same trip/delivery. You are handing over the parcel to the correct Receiver, and this parcel belongs to this exact trip/delivery.';

    return Scaffold(
      backgroundColor: AppColors.surface,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const SizedBox(height: 24),
              Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  color: (waitingForPeer ? AppColors.primary : AppColors.success)
                      .withValues(alpha: 0.12),
                  shape: BoxShape.circle,
                ),
                alignment: Alignment.center,
                child: Icon(
                  waitingForPeer
                      ? Icons.hourglass_top_rounded
                      : Icons.check_circle_rounded,
                  size: 40,
                  color: waitingForPeer ? AppColors.primary : AppColors.success,
                ),
              ),
              const SizedBox(height: 20),
              Text(title, style: typo.h1, textAlign: TextAlign.center),
              const SizedBox(height: 16),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                decoration: BoxDecoration(
                  color: AppColors.success.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                    color: AppColors.success.withValues(alpha: 0.28),
                  ),
                ),
                child: Column(
                  children: [
                    Text(
                      'Trip / Delivery ID',
                      textAlign: TextAlign.center,
                      style: typo.sm.copyWith(
                        color: AppColors.success,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      shipmentId,
                      textAlign: TextAlign.center,
                      style: typo.h2.copyWith(color: AppColors.success),
                    ),
                    if (!waitingForPeer) ...[
                      const SizedBox(height: 8),
                      Text(
                        'Traveler ↔ Receiver verified this exact ID',
                        textAlign: TextAlign.center,
                        style: typo.sm.copyWith(
                          color: AppColors.success,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(height: 16),
              Text(
                body,
                textAlign: TextAlign.center,
                style: typo.sm.copyWith(height: 1.5),
              ),
              if (!waitingForPeer) ...[
                const SizedBox(height: 12),
                Text(
                  'Parcel status is now Delivered. Escrow has been released to your wallet.',
                  textAlign: TextAlign.center,
                  style: typo.sm.copyWith(height: 1.5),
                ),
                const SizedBox(height: 24),
                AppCard(
                  margin: EdgeInsets.zero,
                  child: Column(
                    children: [
                      _travelerNfcSuccessRow(context, 'NFC Verified'),
                      const SizedBox(height: 12),
                      _travelerNfcSuccessRow(context, 'Parcel Delivered'),
                      const SizedBox(height: 12),
                      _travelerNfcSuccessRow(context, 'Payment Completed'),
                    ],
                  ),
                ),
              ],
              const SizedBox(height: 32),
              AppButton(
                label: 'Back to tracking',
                onPressed: () => context.go('/shipment/$shipmentId?traveler=true'),
              ),
              if (!waitingForPeer) ...[
                const SizedBox(height: AppButton.stackGap),
                AppButton(
                  label: 'Leave a review for receiver',
                  variant: AppButtonVariant.outline,
                  onPressed: () => context.push(
                    deliveryReviewRoute(
                      shipmentId: shipmentId,
                      reviewerRole: WalletRole.traveler,
                      revieweeRole: WalletRole.receiver,
                    ),
                  ),
                ),
                const SizedBox(height: AppButton.stackGap),
                AppButton(
                  label: 'Leave a review for sender',
                  variant: AppButtonVariant.outline,
                  onPressed: () => context.push(
                    deliveryReviewRoute(
                      shipmentId: shipmentId,
                      reviewerRole: WalletRole.traveler,
                      revieweeRole: WalletRole.sender,
                    ),
                  ),
                ),
              ],
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }

  Widget _travelerNfcSuccessRow(BuildContext context, String label) {
    final typo = context.typo;
    return Row(
      children: [
        Container(
          width: 28,
          height: 28,
          decoration: BoxDecoration(
            color: AppColors.success.withValues(alpha: 0.12),
            shape: BoxShape.circle,
          ),
          alignment: Alignment.center,
          child: const Icon(Icons.check, size: 16, color: AppColors.success),
        ),
        const SizedBox(width: 12),
        Text(label, style: typo.bodyBold.copyWith(fontWeight: FontWeight.w700)),
      ],
    );
  }
}

class DisputeFormScreen extends StatefulWidget {
  const DisputeFormScreen({super.key, required this.shipmentId});

  final String shipmentId;

  @override
  State<DisputeFormScreen> createState() => _DisputeFormScreenState();
}

class _DisputeFormScreenState extends State<DisputeFormScreen> {
  static const _categories = [
    'Damaged parcel',
    'Not delivered',
    'Wrong item',
    'Missing contents',
    'Other',
  ];

  String? _category;
  String? _error;
  final _descriptionController = TextEditingController();

  @override
  void dispose() {
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    FocusManager.instance.primaryFocus?.unfocus();
    final category = _category;
    if (category == null) {
      setState(() => _error = 'Select an issue type');
      return;
    }
    final description = _descriptionController.text.trim();
    if (description.length < 10) {
      setState(() => _error = 'Description must be at least 10 characters');
      return;
    }
    final reason = '$category — $description';

    try {
      final auth = context.read<AuthProvider>();
      final repo = FulfillmentRepository(apiClient: auth.repository.apiClient);
      await repo.openDispute(
        deliveryId: widget.shipmentId,
        reason: reason,
      );
    } catch (e) {
      if (mounted) {
        AppToast.error(context, 'Could not open dispute: $e');
      }
      return;
    }

    if (!mounted) return;
    final ctx = disputeContextFromUri(GoRouterState.of(context).uri);
    appNavigatePushReplacement(
      disputeRoute(
        widget.shipmentId,
        travelerView: ctx.travelerView,
        role: ctx.role,
      ),
      extra: reason,
    );
  }

  @override
  Widget build(BuildContext context) {
    final typo = context.typo;
    final fieldLabelStyle = typo.inputLabel.copyWith(fontWeight: FontWeight.w600);
    final ctx = disputeContextFromUri(GoRouterState.of(context).uri);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: BackHeader(
        title: 'Report an issue',
        fallbackRoute: disputeOriginFallback(
          widget.shipmentId,
          travelerView: ctx.travelerView,
          role: ctx.role,
        ),
      ),
      body: ScrollableFormScreen(
        actions: [
          AppButton(
            label: 'Submit dispute',
            variant: AppButtonVariant.danger,
            onPressed: _submit,
          ),
        ],
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Tell us what went wrong with shipment ${widget.shipmentId}. Escrow will be frozen while we investigate.',
              style: typo.subheading.copyWith(color: AppColors.textSecondary, height: 1.5),
            ),
            SizedBox(height: context.sectionGap),
            Text('Issue type', style: fieldLabelStyle),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: _categories
                  .map(
                    (c) => AppChip(
                      label: c,
                      selected: _category == c,
                      onTap: () => setState(() => _category = c),
                    ),
                  )
                  .toList(),
            ),
            SizedBox(height: context.sectionGap),
            AppLabeledField(
              label: 'Description',
              labelStyle: fieldLabelStyle,
              padding: const EdgeInsets.only(top: AppFieldSpacing.top),
              child: TextField(
                controller: _descriptionController,
                onTap: ensureSoftKeyboardVisible,
                onTapOutside: dismissKeyboardOnTapOutside,
                maxLines: 5,
                style: typo.input,
                onChanged: (_) {
                  if (_error != null) setState(() => _error = null);
                },
                decoration: InputDecoration(
                  hintText: 'Describe the issue in detail (min. 10 characters)...',
                  hintStyle: typo.chatInput,
                ),
              ),
            ),
            if (_error != null) ...[
              const SizedBox(height: 8),
              Text(_error!, style: typo.sm.copyWith(color: AppColors.danger)),
            ],
            const SizedBox(height: 12),
            Text(
              'Include what happened, when you noticed it, and any evidence you can provide.',
              style: typo.subheading.copyWith(color: AppColors.textSecondary, height: 1.5),
            ),
          ],
        ),
      ),
    );
  }
}

class DisputeScreen extends StatefulWidget {
  const DisputeScreen({super.key, required this.shipmentId, this.reason});

  final String shipmentId;
  final String? reason;

  @override
  State<DisputeScreen> createState() => _DisputeScreenState();
}

class _DisputeScreenState extends State<DisputeScreen> {
  String? _reason;

  @override
  void initState() {
    super.initState();
    _reason = widget.reason;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      context.read<WalletProvider>().refreshShipmentEscrow(widget.shipmentId);
      _loadReason();
    });
  }

  Future<void> _loadReason() async {
    if ((_reason ?? '').trim().isNotEmpty) return;
    try {
      final auth = context.read<AuthProvider>();
      final repo = FulfillmentRepository(apiClient: auth.repository.apiClient);
      final data = await repo.getOpenDispute(widget.shipmentId);
      if (!mounted) return;
      final dispute = data['dispute'];
      final loaded = dispute is Map ? dispute['reason'] as String? : null;
      if (loaded != null && loaded.trim().isNotEmpty) {
        setState(() => _reason = loaded.trim());
      }
    } catch (_) {
      // Keep submitted reason or empty fallback.
    }
  }

  @override
  Widget build(BuildContext context) {
    final shipmentId = widget.shipmentId;
    final typo = context.typo;
    final ctx = disputeContextFromUri(GoRouterState.of(context).uri);
    final disputeReason = (_reason ?? '').trim().isNotEmpty
        ? _reason!.trim()
        : 'Your dispute is on file. The WWNGO team will review it.';
    return Scaffold(
      backgroundColor: AppColors.surface,
      appBar: BackHeader(
        title: shipmentId,
        fallbackRoute: disputeListFallback(
          travelerView: ctx.travelerView,
          role: ctx.role,
        ),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            children: [
              Expanded(
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    return SingleChildScrollView(
                      physics: PlatformUi.scrollPhysics,
                      child: ConstrainedBox(
                        constraints: BoxConstraints(minHeight: constraints.maxHeight),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Container(
                              width: 72,
                              height: 72,
                              decoration: BoxDecoration(
                                color: AppColors.danger.withValues(alpha: 0.1),
                                shape: BoxShape.circle,
                              ),
                              alignment: Alignment.center,
                              child: const DisputeWarningIcon(size: 36),
                            ),
                            const SizedBox(height: 16),
                            Text('Dispute open', style: typo.h1, textAlign: TextAlign.center),
                            const SizedBox(height: 8),
                            Text(
                              'Your dispute has been filed. Escrow funds are frozen pending investigation. WWNGO team will review within 14 days.',
                              textAlign: TextAlign.center,
                              style: typo.sm.copyWith(height: 1.5),
                            ),
                            const SizedBox(height: 20),
                            Container(
                              width: double.infinity,
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                color: AppColors.danger.withValues(alpha: 0.06),
                                borderRadius: BorderRadius.circular(14),
                                border: Border.all(color: AppColors.danger.withValues(alpha: 0.2)),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text('Dispute reason', style: typo.policyTitle),
                                  const SizedBox(height: 4),
                                  Text(
                                    disputeReason,
                                    style: typo.sm.copyWith(height: 1.4),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 20),
                            ValueListenableBuilder<int>(
                              valueListenable: WalletService.walletVersion,
                              builder: (context, _, __) {
                                final escrow = WalletService.escrowCentsForShipment(shipmentId);
                                return Container(
                                  width: double.infinity,
                                  padding: const EdgeInsets.all(14),
                                  decoration: BoxDecoration(
                                    color: AppColors.background,
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                        children: [
                                          Text('Escrow status', style: typo.sm),
                                          AppBadge(
                                            label: 'Frozen',
                                            color: AppColors.danger,
                                            backgroundColor:
                                                AppColors.danger.withValues(alpha: 0.12),
                                          ),
                                        ],
                                      ),
                                      if (escrow > 0) ...[
                                        const SizedBox(height: 8),
                                        Text(
                                          '${WalletService.formatCents(escrow)} held pending investigation',
                                          style: typo.sm.copyWith(color: AppColors.textSecondary),
                                        ),
                                      ],
                                    ],
                                  ),
                                );
                              },
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
              AppButton(
                label: 'Back to shipments',
                onPressed: () => context.go(
                  disputeListFallback(
                    travelerView: ctx.travelerView,
                    role: ctx.role,
                  ),
                ),
              ),
              const SizedBox(height: AppButton.stackGap),
              AppButton(
                label: 'Contact support',
                variant: AppButtonVariant.outline,
                onPressed: () => appNavigatePush('/contact-support', extra: shipmentId),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class ContactSupportScreen extends StatefulWidget {
  const ContactSupportScreen({super.key, this.shipmentId});

  final String? shipmentId;

  @override
  State<ContactSupportScreen> createState() => _ContactSupportScreenState();
}

class _ContactSupportScreenState extends State<ContactSupportScreen> {
  final _messageController = TextEditingController();
  String? _error;

  @override
  void dispose() {
    _messageController.dispose();
    super.dispose();
  }

  Future<void> _send() async {
    final message = _messageController.text.trim();
    if (message.isEmpty) {
      setState(() => _error = 'Please enter a message');
      return;
    }

    final shipmentLine = widget.shipmentId != null
        ? 'Related shipment: ${widget.shipmentId}\n\n'
        : '';
    final body = '$shipmentLine$message';

    final sent = await ExternalLinks.emailSupport(
      subject: widget.shipmentId != null
          ? 'WWNGO support — ${widget.shipmentId}'
          : 'WWNGO support request',
      body: body,
    );

    if (!mounted) return;

    if (sent) {
      context.pushReplacement('/contact-support/success', extra: widget.shipmentId);
    } else {
      setState(() => _error = 'Could not open email app. Try support@wwngo.com');
    }
  }

  @override
  Widget build(BuildContext context) {
    final typo = context.typo;
    final supportLabelStyle = typo.inputLabel.copyWith(fontWeight: FontWeight.w600);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: const BackHeader(title: 'Contact support'),
      body: ScrollableFormScreen(
        actions: [
          AppButton(label: 'Send message', onPressed: _send),
        ],
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Tell us how we can help. Our support team typically responds within 24 hours.',
              style: typo.subheading.copyWith(color: AppColors.textSecondary, height: 1.5),
            ),
            if (widget.shipmentId != null) ...[
              SizedBox(height: context.sectionGap),
              Text('Related shipment', style: supportLabelStyle),
              const SizedBox(height: 8),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.border),
                ),
                child: Text(
                  widget.shipmentId!,
                  style: typo.bodyBold.copyWith(fontWeight: FontWeight.w700),
                ),
              ),
            ],
            SizedBox(height: context.sectionGap),
            AppLabeledField(
              label: 'Your message',
              labelStyle: supportLabelStyle,
              padding: const EdgeInsets.only(top: AppFieldSpacing.top),
              child: TextField(
                controller: _messageController,
                onTap: ensureSoftKeyboardVisible,
                onTapOutside: dismissKeyboardOnTapOutside,
                maxLines: 6,
                style: typo.input,
                onChanged: (_) {
                  if (_error != null) setState(() => _error = null);
                },
                decoration: InputDecoration(
                  hintText: 'Describe your issue or question...',
                  hintStyle: typo.chatInput,
                  errorText: _error,
                ),
              ),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: Text(
                    'You can also email us at ',
                    style: typo.sm.copyWith(height: 1.5),
                  ),
                ),
                GestureDetector(
                  onTap: () => ExternalLinks.emailSupport(
                    subject: 'WWNGO support',
                    body: '',
                  ),
                  child: Text('support@wwngo.com', style: typo.link),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class ContactSupportSuccessScreen extends StatelessWidget {
  const ContactSupportSuccessScreen({super.key, this.shipmentId});

  final String? shipmentId;

  @override
  Widget build(BuildContext context) {
    final typo = context.typo;

    return Scaffold(
      backgroundColor: AppColors.surface,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const BackLink(),
              Expanded(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      width: 80,
                      height: 80,
                      decoration: BoxDecoration(
                        color: AppColors.success.withValues(alpha: 0.12),
                        shape: BoxShape.circle,
                      ),
                      alignment: Alignment.center,
                      child: const Icon(Icons.mark_email_read_outlined, size: 40, color: AppColors.success),
                    ),
                    const SizedBox(height: 20),
                    Text('Message sent', style: typo.h1, textAlign: TextAlign.center),
                    const SizedBox(height: 8),
                    Text(
                      shipmentId != null
                          ? 'We received your message about $shipmentId. Our team will respond within 24 hours.'
                          : 'We received your message. Our team will respond within 24 hours.',
                      textAlign: TextAlign.center,
                      style: typo.sm.copyWith(height: 1.5),
                    ),
                    const SizedBox(height: 32),
                    AppButton(
                      label: 'Back to shipments',
                      onPressed: () => context.go('/track'),
                    ),
                    if (shipmentId != null) ...[
                      const SizedBox(height: AppButton.stackGap),
                      AppButton(
                        label: 'View dispute',
                        variant: AppButtonVariant.outline,
                        onPressed: () => appNavigatePush('/dispute/$shipmentId'),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class ReviewSubmittedRouteData {
  const ReviewSubmittedRouteData({
    required this.shipmentId,
    required this.rating,
    required this.reviewerRole,
  });

  final String shipmentId;
  final int rating;
  final WalletRole reviewerRole;
}

class ReviewSubmittedSuccessScreen extends StatelessWidget {
  const ReviewSubmittedSuccessScreen({
    super.key,
    required this.shipmentId,
    required this.rating,
    required this.reviewerRole,
  });

  final String shipmentId;
  final int rating;
  final WalletRole reviewerRole;

  @override
  Widget build(BuildContext context) {
    final typo = context.typo;

    return Scaffold(
      backgroundColor: AppColors.surface,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  color: AppColors.success.withValues(alpha: 0.12),
                  shape: BoxShape.circle,
                ),
                alignment: Alignment.center,
                child: const Icon(Icons.check, size: 40, color: AppColors.success),
              ),
              const SizedBox(height: 20),
              Text('Review submitted!', style: typo.h1, textAlign: TextAlign.center),
              const SizedBox(height: 8),
              Text(
                'Thanks for sharing your feedback on $shipmentId. Your $rating-star review helps keep WWNGO safe and reliable.',
                textAlign: TextAlign.center,
                style: typo.sm.copyWith(height: 1.5),
              ),
              const SizedBox(height: 32),
              AppButton(
                label: 'Back to home',
                onPressed: () => context.go(homeRouteForWalletRole(reviewerRole)),
              ),
              const SizedBox(height: AppButton.stackGap),
              AppButton(
                label: 'View my shipments',
                variant: AppButtonVariant.outline,
                onPressed: () => context.go(
                  reviewerRole == WalletRole.traveler
                      ? '/traveler-deliveries'
                      : reviewerRole == WalletRole.receiver
                          ? '/receiver-tracking'
                          : '/track',
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class DeliveryReviewScreen extends StatefulWidget {
  const DeliveryReviewScreen({super.key});

  @override
  State<DeliveryReviewScreen> createState() => _DeliveryReviewScreenState();
}

class _DeliveryReviewScreenState extends State<DeliveryReviewScreen> {
  int _rating = 5;
  late final TextEditingController _reviewController;
  bool _loading = true;
  bool _submitting = false;
  String? _loadError;
  ReviewContext? _context;
  String _shipmentId = '';
  WalletRole _reviewerRole = WalletRole.sender;

  @override
  void initState() {
    super.initState();
    _reviewController = TextEditingController();
    WidgetsBinding.instance.addPostFrameCallback((_) => _load());
  }

  @override
  void dispose() {
    _reviewController.dispose();
    super.dispose();
  }

  DeliveryRepository _deliveryRepository() {
    final auth = context.read<AuthProvider>();
    final demoMode = context.read<DemoModeProvider>();
    return DeliveryRepository(
      apiClient: auth.repository.apiClient,
      demoMode: demoMode,
    );
  }

  ReviewRepository _reviewRepository() {
    final auth = context.read<AuthProvider>();
    final demoMode = context.read<DemoModeProvider>();
    return ReviewRepository(
      apiClient: auth.repository.apiClient,
      demoMode: demoMode,
    );
  }

  Future<void> _load() async {
    final state = GoRouterState.of(context);
    final shipmentId = state.uri.queryParameters['shipmentId']?.trim() ?? '';
    final reviewerRole =
        WalletRole.fromQuery(state.uri.queryParameters['role']);
    final revieweeRaw = state.uri.queryParameters['reviewee']?.trim();
    final WalletRole? revieweeRole = switch (revieweeRaw) {
      'sender' => WalletRole.sender,
      'traveler' => WalletRole.traveler,
      'receiver' => WalletRole.receiver,
      _ => null,
    };

    if (shipmentId.isEmpty) {
      setState(() {
        _loading = false;
        _loadError = 'Missing shipment ID. Open review from a completed delivery.';
      });
      return;
    }

    setState(() {
      _loading = true;
      _loadError = null;
      _shipmentId = shipmentId;
      _reviewerRole = reviewerRole;
    });

    if (context.read<DemoModeProvider>().enabled) {
      final demoContext = switch (reviewerRole) {
        WalletRole.traveler when revieweeRole == WalletRole.sender =>
          ReviewContext(
            revieweeId: 'demo-sender',
            revieweeRole: WalletRole.sender,
            revieweeName: 'Sender',
            confirmationMessage:
                'Delivery $shipmentId complete. How was your experience with the sender?',
          ),
        WalletRole.traveler => ReviewContext(
            revieweeId: 'demo-receiver',
            revieweeRole: WalletRole.receiver,
            revieweeName: 'Receiver',
            confirmationMessage:
                'Delivery $shipmentId complete. How was the handoff with the receiver?',
          ),
        WalletRole.receiver => ReviewContext(
            revieweeId: 'demo-traveler',
            revieweeRole: WalletRole.traveler,
            revieweeName: 'Traveler',
            confirmationMessage:
                'Delivery $shipmentId confirmed. How was your experience with the traveler?',
          ),
        WalletRole.sender => ReviewContext(
            revieweeId: 'demo-traveler',
            revieweeRole: WalletRole.traveler,
            revieweeName: 'Traveler',
            confirmationMessage:
                'Delivery $shipmentId confirmed. How was your experience with the traveler?',
          ),
      };
      setState(() {
        _context = demoContext;
        _loading = false;
      });
      return;
    }

    try {
      final delivery = await _deliveryRepository().getDelivery(
        shipmentId,
        role: reviewerRole.queryParam,
      );
      final reviewContext = resolveReviewContext(
        delivery: delivery,
        reviewerRole: reviewerRole,
        revieweeRole: revieweeRole,
      );
      if (!mounted) return;
      if (reviewContext == null) {
        setState(() {
          _loading = false;
          _loadError =
              'Unable to determine who to review for this delivery. Try again from shipment details.';
        });
        return;
      }
      setState(() {
        _context = reviewContext;
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
        _loadError = 'Unable to load delivery details.';
      });
    }
  }

  Future<void> _submit() async {
    final reviewContext = _context;
    if (reviewContext == null || _submitting) return;

    final text = _reviewController.text.trim();
    if (text.isEmpty) {
      AppToast.error(context, 'Please write a short review before submitting.');
      return;
    }

    setState(() => _submitting = true);
    try {
      await _reviewRepository().createReview(
        revieweeId: reviewContext.revieweeId,
        revieweeRole: reviewContext.revieweeRole,
        rating: _rating,
        text: text,
        shipmentId: _shipmentId,
      );
      if (!mounted) return;
      await _markReviewSubmitted(reviewContext.revieweeRole);
      if (!mounted) return;
      await context.read<AuthProvider>().refreshUser();
      if (!mounted) return;
      context.pushReplacement(
        '/delivery-review/success',
        extra: ReviewSubmittedRouteData(
          shipmentId: _shipmentId,
          rating: _rating,
          reviewerRole: _reviewerRole,
        ),
      );
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() => _submitting = false);
      if (e.code == 'REVIEW_EXISTS') {
        await _markReviewSubmitted(reviewContext.revieweeRole);
        if (!mounted) return;
        AppToast.info(context, e.message);
        context.go(homeRouteForWalletRole(_reviewerRole));
        return;
      }
      AppToast.error(context, e.message);
    } catch (_) {
      if (!mounted) return;
      setState(() => _submitting = false);
      AppToast.error(context, 'Unable to submit review. Please try again.');
    }
  }

  Future<void> _markReviewSubmitted(WalletRole revieweeRole) async {
    final userId = context.read<AuthProvider>().user?.id ?? '';
    await DeliveryReviewStore.markSubmitted(
      reviewerUserId: userId,
      shipmentId: _shipmentId,
      reviewerRole: _reviewerRole,
      revieweeRole: revieweeRole,
    );
  }

  @override
  Widget build(BuildContext context) {
    final typo = context.typo;
    final reviewContext = _context;

    if (_loading) {
      return Scaffold(
        backgroundColor: AppColors.surface,
        appBar: const BackHeader(title: 'Leave a review'),
        body: const Center(
          child: SizedBox(
            width: 24,
            height: 24,
            child: CircularProgressIndicator(strokeWidth: 2),
          ),
        ),
      );
    }

    if (_loadError != null || reviewContext == null) {
      return Scaffold(
        backgroundColor: AppColors.surface,
        appBar: const BackHeader(title: 'Leave a review'),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(28),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  _loadError ?? 'Review unavailable.',
                  textAlign: TextAlign.center,
                  style: typo.sm.copyWith(color: AppColors.textSecondary, height: 1.5),
                ),
                const SizedBox(height: 16),
                AppButton(label: 'Retry', onPressed: _load),
              ],
            ),
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: AppColors.surface,
      appBar: const BackHeader(title: 'Leave a review'),
      body: SafeArea(
        top: false,
        child: SingleChildScrollView(
          physics: PlatformUi.scrollPhysics,
          padding: const EdgeInsets.all(28),
          child: Column(
            children: [
              const SizedBox(height: 8),
              Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  color: AppColors.success.withValues(alpha: 0.12),
                  shape: BoxShape.circle,
                ),
                alignment: Alignment.center,
                child: const Icon(Icons.celebration_outlined, size: 40, color: AppColors.success),
              ),
              const SizedBox(height: 16),
              Text('Delivery confirmed!', style: typo.h1, textAlign: TextAlign.center),
              const SizedBox(height: 8),
              Text(
                reviewContext.confirmationMessage,
                textAlign: TextAlign.center,
                style: typo.sm.copyWith(height: 1.5),
              ),
              const SizedBox(height: 8),
              Text(
                'How was your experience with ${reviewContext.revieweeName}?',
                style: typo.sm,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 20),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(5, (i) {
                  return GestureDetector(
                    onTap: _submitting ? null : () => setState(() => _rating = i + 1),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 5),
                      child: Text(
                        '★',
                        style: typo.starRating.copyWith(
                          fontSize: 34,
                          color: i < _rating ? AppColors.warning : AppColors.border,
                        ),
                      ),
                    ),
                  );
                }),
              ),
              const SizedBox(height: 20),
              Padding(
                padding: const EdgeInsets.only(top: AppFieldSpacing.top),
                child: TextField(
                  controller: _reviewController,
                  enabled: !_submitting,
                  onTap: ensureSoftKeyboardVisible,
                  onTapOutside: dismissKeyboardOnTapOutside,
                  maxLines: 3,
                  decoration: const InputDecoration(
                    hintText: 'Share how the delivery went…',
                  ),
                ),
              ),
              const SizedBox(height: 24),
              AppButton(
                label: _submitting ? 'Submitting…' : 'Submit review',
                onPressed: _submitting ? null : _submit,
              ),
              const SizedBox(height: 10),
              TextButton(
                onPressed: _submitting
                    ? null
                    : () => context.go(homeRouteForWalletRole(_reviewerRole)),
                child: Text('Skip for now', style: typo.link),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
