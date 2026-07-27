import 'dart:async';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../core/platform/keyboard_utils.dart';
import '../../core/config/demo_mode.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_typography.dart';
import '../../core/widgets/app_badge.dart';
import '../../core/widgets/app_button.dart';
import '../../core/widgets/app_card.dart';
import '../../core/widgets/app_chip.dart';
import '../../core/layout/responsive.dart';
import '../../core/navigation/app_navigation.dart';
import '../../core/platform/platform_ui.dart';
import '../../core/widgets/app_labeled_field.dart';
import '../../core/widgets/back_header.dart';
import '../../core/widgets/back_link.dart';
import '../../core/widgets/cancel_request_confirmation_dialog.dart';
import '../../core/widgets/dispute_warning_icon.dart';
import '../../core/widgets/scrollable_form_screen.dart';
import '../../data/models/shipment.dart';
import '../../data/services/delivery_repository.dart';
import '../../data/static_data.dart';
import '../../data/wallet_service.dart';
import '../../providers/auth_provider.dart';
import '../sender/bid_acceptance_payment_screen.dart';
import '../sender/my_posted_parcels_screen.dart';
import '../sender/sender_delivery_status.dart';
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
  int? _apiMatchingTravelerCount;

  @override
  void initState() {
    super.initState();
    _selectedStatus = ShipmentStatus.inTransit;
    WidgetsBinding.instance.addPostFrameCallback((_) => _loadApiMatchingCount());
    StaticData.bidRequestsVersion.addListener(_onBidDataChanged);
  }

  @override
  void dispose() {
    StaticData.bidRequestsVersion.removeListener(_onBidDataChanged);
    super.dispose();
  }

  void _onBidDataChanged() {
    _loadApiMatchingCount();
  }

  DeliveryRepository _deliveryRepository() {
    final auth = context.read<AuthProvider>();
    final demoMode = context.read<DemoModeProvider>();
    return DeliveryRepository(
      apiClient: auth.repository.apiClient,
      demoMode: demoMode,
    );
  }

  Future<void> _loadApiMatchingCount() async {
    final demoMode = context.read<DemoModeProvider>();
    if (demoMode.enabled) return;

    final shipment = StaticData.shipmentById(
      widget.shipmentId,
      travelerView: widget.isTravelerView,
    );
    if (shipment == null) return;

    final phase = StaticData.senderPostedPhase(shipment);
    if (phase != SenderPostedPhase.matchingTravelers &&
        phase != SenderPostedPhase.travelerReviewing) {
      return;
    }

    try {
      final travelers = await _deliveryRepository().listMatchingTravelers(
        widget.shipmentId,
      );
      if (!mounted) return;
      setState(() => _apiMatchingTravelerCount = travelers.length);
    } catch (_) {
      // Badge falls back to StaticData demo count.
    }
  }

  String _senderPostedBadgeLabel(SenderPostedPhase phase, String shipmentId) {
    if (phase == SenderPostedPhase.matchingTravelers) {
      final count = _apiMatchingTravelerCount ??
          StaticData.matchingTravelerCountForShipment(shipmentId);
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

  void _updateStatus(ShipmentStatus selected) {
    if (selected == ShipmentStatus.inTransit) {
      StaticData.setShipmentStatus(widget.shipmentId, selected);
    }
    setState(() => _selectedStatus = selected);
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Parcel status updated to In Transit.'),
      ),
    );
  }

  void _enableNfcForReceiver() {
    StaticData.activateNfcCheckpoint2(widget.shipmentId);
    setState(() {});
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text(
          'NFC enabled for the receiver. Complete NFC matching to mark Delivered.',
        ),
      ),
    );
  }

  void _openBidAcceptancePayment(BuildContext context, String shipmentId) {
    final selected = StaticData.selectedMatchingTravelerFor(shipmentId);
    if (selected == null) return;
    context.push(
      '/bid-acceptance-payment',
      extra: BidAcceptanceContext(
        bid: selected,
        shipmentId: shipmentId,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<int>(
      valueListenable: StaticData.bidRequestsVersion,
      builder: (context, _, __) {
        return ValueListenableBuilder<int>(
          valueListenable: StaticData.nfcCheckpointVersion,
          builder: (context, _, __) {
        final typo = context.typo;
        final shipment = StaticData.shipmentById(
              widget.shipmentId,
              travelerView: widget.isTravelerView,
            ) ??
            StaticData.activeShipment;
        final status = StaticData.effectiveStatus(shipment);
        final stepProgress = StaticData.effectiveStepIndex(shipment);
        final isDisputed = StaticData.isShipmentDisputed(shipment.id);
        // Traveler marks In Transit after NFC CP1 matching sets Collected.
        final canMarkInTransit = status == ShipmentStatus.collected &&
            StaticData.isNfcCheckpoint1Confirmed(shipment.id) &&
            !StaticData.isNfcCheckpoint2Activated(shipment.id) &&
            !StaticData.isNfcCheckpoint2Confirmed(shipment.id);
        // Traveler enables NFC for receiver while In Transit (before CP2 matching).
        final canEnableNfcForReceiver = status == ShipmentStatus.inTransit &&
            StaticData.isNfcCheckpoint1Confirmed(shipment.id) &&
            !StaticData.isNfcCheckpoint2Activated(shipment.id) &&
            !StaticData.isNfcCheckpoint2Confirmed(shipment.id);
        final showStatusUpdate = widget.isTravelerView &&
            !isDisputed &&
            (canMarkInTransit || canEnableNfcForReceiver);
        final statusOptions = _statusOptionsFor(status);
        final selectedStatus = _selectedOptionFor(status);
        final statusUpdateHint = canEnableNfcForReceiver
            ? 'When you meet the receiver, enable NFC so both of you can match phones. After matching, the parcel becomes Delivered.'
            : 'NFC handoff is complete. Mark In Transit when you begin travel with this parcel.';
        final canEnableNfcCheckpoint1 = !widget.isTravelerView &&
            !isDisputed &&
            (status == ShipmentStatus.bidAccepted ||
                status == ShipmentStatus.photosUploaded) &&
            !StaticData.isNfcCheckpoint1Confirmed(shipment.id) &&
            !StaticData.nfcCheckpoint1ActivatedShipmentIds.contains(shipment.id);

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
                  // Sender open parcels: Receiver Pending or tappable Matching Travelers (n).
                  Builder(
                    builder: (context) {
                      final status = StaticData.effectiveStatus(shipment);
                      final phase = widget.isTravelerView ||
                              status != ShipmentStatus.open
                          ? null
                          : StaticData.senderPostedPhase(shipment);
                      if (phase == null) {
                        return AppBadge.status(status);
                      }

                      final label = _senderPostedBadgeLabel(
                        phase,
                        shipment.id,
                      );
                      final badge = AppBadge(
                        label: label,
                        color: phase.color,
                        backgroundColor: phase.backgroundColor,
                        semiBold: true,
                        wide: true,
                      );

                      if (!widget.isTravelerView &&
                          (phase == SenderPostedPhase.matchingTravelers ||
                              phase == SenderPostedPhase.travelerReviewing)) {
                        return GestureDetector(
                          onTap: () => context.push(
                            '/bid-requests/${shipment.id}',
                          ),
                          child: badge,
                        );
                      }

                      if (!widget.isTravelerView &&
                          phase == SenderPostedPhase.travelerAccepted) {
                        return GestureDetector(
                          onTap: () => _openBidAcceptancePayment(context, shipment.id),
                          child: badge,
                        );
                      }

                      return badge;
                    },
                  ),
                  const SizedBox(height: 16),
                  AppCard(
                    margin: EdgeInsets.zero,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        ShipmentTrackingSection(
                          shipment: shipment,
                          stepProgress: stepProgress,
                        ),
                        const Padding(
                          padding: EdgeInsets.symmetric(vertical: 20),
                          child: Divider(height: 1),
                        ),
                        Text('Delivery details', style: typo.h3.copyWith(fontWeight: FontWeight.w700)),
                        const SizedBox(height: 12),
                        _detailRow(context, 'Route', shipment.route),
                        _detailRow(context, 'Travel date', DateFormat('MMM d, yyyy').format(shipment.travelDate)),
                        _detailRow(context, 'Parcel type', '${shipment.parcelCategory} · ${shipment.parcelWeightKg}kg'),
                        const SizedBox(height: 16),
                        _ShipmentEscrowSection(shipmentId: shipment.id),
                        const SizedBox(height: 16),
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: [
                            if (StaticData.escrowCentsForShipment(shipment.id) > 0 ||
                                WalletService.isEscrowReleased(shipment.id))
                              AppBadge.success('✓ Escrow active')
                            else if (WalletService.isEscrowRefunded(shipment.id))
                              AppBadge(
                                label: 'Escrow refunded',
                                color: AppColors.warning,
                                backgroundColor: AppColors.warning.withValues(alpha: 0.12),
                                small: true,
                              )
                            else if (WalletService.isEscrowFrozen(shipment.id))
                              AppBadge(
                                label: 'Escrow frozen',
                                color: AppColors.danger,
                                backgroundColor: AppColors.danger.withValues(alpha: 0.12),
                                small: true,
                              ),
                            AppBadge.success('✓ ID verified'),
                            if (StaticData.isNfcCheckpoint1Confirmed(shipment.id))
                              AppBadge.success('✓ NFC CP1')
                            else
                              AppBadge(
                                label: '○ NFC CP1',
                                color: AppColors.textDisabled,
                                backgroundColor: AppColors.textDisabled.withValues(alpha: 0.4),
                                small: true,
                              ),
                            if (StaticData.isNfcCheckpoint2Confirmed(shipment.id) ||
                                status == ShipmentStatus.delivered)
                              AppBadge.success('✓ NFC CP2')
                            else
                              AppBadge(
                                label: '○ NFC CP2',
                                color: AppColors.textDisabled,
                                backgroundColor: AppColors.textDisabled.withValues(alpha: 0.4),
                                small: true,
                              ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  if (showStatusUpdate) ...[
                    const SizedBox(height: 24),
                    Text(
                      canEnableNfcForReceiver
                          ? 'Enable NFC for Receiver'
                          : 'Update Shipment Status',
                      style: typo.h3.copyWith(fontWeight: FontWeight.w700),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      statusUpdateHint,
                      style: typo.sm.copyWith(height: 1.5, color: AppColors.textSecondary),
                    ),
                    if (canMarkInTransit) ...[
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
                    ] else if (canEnableNfcForReceiver) ...[
                      const SizedBox(height: 12),
                      AppButton(
                        label: 'Enable NFC for Receiver',
                        icon: const Icon(Icons.nfc, size: 18, color: Colors.white),
                        onPressed: _enableNfcForReceiver,
                      ),
                    ],
                  ],
                  if (canEnableNfcCheckpoint1) ...[
                    const SizedBox(height: 24),
                    AppCard(
                      margin: EdgeInsets.zero,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              const Icon(Icons.nfc, size: 20, color: AppColors.primary),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  'Enable NFC Handoff',
                                  style: typo.h3.copyWith(fontWeight: FontWeight.w700),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Meet the traveler and enable NFC. After both of you complete NFC matching, the parcel status becomes Collected.',
                            style: typo.sm.copyWith(height: 1.5),
                          ),
                          const SizedBox(height: 16),
                          AppButton(
                            label: 'Enable NFC',
                            icon: const Icon(Icons.nfc, size: 18, color: Colors.white),
                            onPressed: () {
                              StaticData.activateNfcCheckpoint1(shipment.id);
                              setState(() {});
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text(
                                    'NFC enabled. Complete NFC matching with the traveler to mark Collected.',
                                  ),
                                ),
                              );
                            },
                          ),
                        ],
                      ),
                    ),
                  ],
                  if (!widget.isTravelerView &&
                      StaticData.senderPostedPhase(shipment) ==
                          SenderPostedPhase.travelerAccepted) ...[
                    const SizedBox(height: 16),
                    AppCard(
                      margin: EdgeInsets.zero,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Traveler accepted',
                            style: typo.h3.copyWith(fontWeight: FontWeight.w700),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            SenderPostedPhase.travelerAccepted.description,
                            style: typo.sm.copyWith(
                              color: AppColors.textSecondary,
                              height: 1.4,
                            ),
                          ),
                          Builder(
                            builder: (context) {
                              final accepted =
                                  StaticData.selectedMatchingTravelerFor(
                                shipment.id,
                              );
                              if (accepted == null) {
                                return const SizedBox.shrink();
                              }
                              return Padding(
                                padding: const EdgeInsets.only(top: 12),
                                child: GestureDetector(
                                  onTap: () => _openBidAcceptancePayment(
                                    context,
                                    shipment.id,
                                  ),
                                  behavior: HitTestBehavior.opaque,
                                  child: _detailRow(
                                    context,
                                    'Accepted traveler',
                                    accepted.travelerName,
                                  ),
                                ),
                              );
                            },
                          ),
                          const SizedBox(height: 16),
                          AppButton(
                            label: 'View Payment Summary',
                            onPressed: () => _openBidAcceptancePayment(
                              context,
                              shipment.id,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                  if (!widget.isTravelerView) ...[
                    Builder(
                      builder: (context) {
                        final proposal =
                            StaticData.finalBudgetProposalFor(shipment.id);
                        if (proposal == null) return const SizedBox.shrink();
                        return Padding(
                          padding: const EdgeInsets.only(top: 16),
                          child: AppCard(
                            margin: EdgeInsets.zero,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Parcel details',
                                  style: typo.h3.copyWith(
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                                const SizedBox(height: 12),
                                _detailRow(
                                  context,
                                  'Sender\'s original budget',
                                  '\$${proposal.originalBudgetUsd.toStringAsFixed(2)}',
                                ),
                                _detailRow(
                                  context,
                                  'Traveler\'s final proposed budget',
                                  '\$${proposal.proposedBudgetUsd.toStringAsFixed(2)}',
                                ),
                                _detailRow(
                                  context,
                                  'Traveler',
                                  proposal.travelerName,
                                ),
                                if (!proposal.accepted) ...[
                                  const SizedBox(height: 16),
                                  AppButton(
                                    label: 'Accept',
                                    onPressed: () {
                                      final proposalAccepted =
                                          StaticData.acceptFinalBudgetProposal(
                                        shipment.id,
                                      );
                                      final bid = (proposalAccepted != null
                                              ? StaticData.bidById(
                                                  proposalAccepted.bidId,
                                                )
                                              : null) ??
                                          StaticData.bidById(proposal.bidId) ??
                                          StaticData
                                              .selectedMatchingTravelerFor(
                                            shipment.id,
                                          );
                                      if (bid == null) {
                                        setState(() {});
                                        return;
                                      }
                                      // Use traveler's final proposed amount for escrow.
                                      final pricedBid = bid.price ==
                                              proposal.proposedBudgetUsd
                                          ? bid
                                          : bid.copyWith(
                                              price: proposal.proposedBudgetUsd,
                                            );
                                      context.push(
                                        '/bid-acceptance-payment',
                                        extra: BidAcceptanceContext(
                                          bid: pricedBid,
                                          shipmentId: shipment.id,
                                        ),
                                      );
                                    },
                                  ),
                                ] else ...[
                                  const SizedBox(height: 12),
                                  AppBadge.success('Final budget accepted'),
                                ],
                              ],
                            ),
                          ),
                        );
                      },
                    ),
                  ],
                  if (_showNfcCheckpoint1(shipment, status)) ...[
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
                  if (widget.isTravelerView &&
                      StaticData.isNfcCheckpoint1Confirmed(shipment.id)) ...[
                    const SizedBox(height: 24),
                    AppCard(
                      margin: EdgeInsets.zero,
                      child: _TravelerNfcDeliverySection(
                        status: status,
                        shipmentId: shipment.id,
                      ),
                    ),
                  ] else if (widget.isTravelerView &&
                      StaticData.nfcCheckpoint1ActivatedShipmentIds
                          .contains(shipment.id) &&
                      !StaticData.isNfcCheckpoint1Confirmed(shipment.id) &&
                      !StaticData.isNfcCheckpoint1SenderTapped(shipment.id)) ...[
                    const SizedBox(height: 24),
                    AppCard(
                      margin: EdgeInsets.zero,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Waiting for sender NFC',
                            style: typo.h3.copyWith(fontWeight: FontWeight.w700),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Sender enabled NFC. After they complete their NFC tap, your NFC button unlocks here. Matching both phones marks the parcel Collected.',
                            style: typo.sm.copyWith(height: 1.5),
                          ),
                          const SizedBox(height: 12),
                          AppBadge(
                            label: '○ Awaiting sender NFC tap',
                            color: AppColors.textDisabled,
                            backgroundColor:
                                AppColors.textDisabled.withValues(alpha: 0.4),
                            small: true,
                          ),
                        ],
                      ),
                    ),
                  ] else if (widget.isTravelerView &&
                      (status == ShipmentStatus.bidAccepted ||
                          status == ShipmentStatus.photosUploaded) &&
                      !StaticData.isNfcCheckpoint1Confirmed(shipment.id) &&
                      !StaticData.nfcCheckpoint1ActivatedShipmentIds
                          .contains(shipment.id)) ...[
                    const SizedBox(height: 24),
                    AppCard(
                      margin: EdgeInsets.zero,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Waiting for sender to enable NFC',
                            style: typo.h3.copyWith(fontWeight: FontWeight.w700),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Meet the sender for handoff. Once they enable NFC and you both complete matching, the parcel becomes Collected.',
                            style: typo.sm.copyWith(height: 1.5),
                          ),
                          const SizedBox(height: 12),
                          AppBadge(
                            label: '○ Awaiting sender Enable NFC',
                            color: AppColors.textDisabled,
                            backgroundColor:
                                AppColors.textDisabled.withValues(alpha: 0.4),
                            small: true,
                          ),
                        ],
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
          },
        );
      },
    );
  }

  bool _showNfcCheckpoint1(Shipment shipment, ShipmentStatus status) {
    // NFC CP1 after sender enables it (Traveler Selected) until matching completes.
    if (StaticData.isShipmentDisputed(shipment.id)) return false;
    if (StaticData.isNfcCheckpoint1Confirmed(shipment.id)) return false;
    final nfcEnabled =
        StaticData.nfcCheckpoint1ActivatedShipmentIds.contains(shipment.id) ||
            status == ShipmentStatus.collected;
    if (!nfcEnabled) return false;
    // Traveler button unlocks only after sender completes their NFC tap.
    if (widget.isTravelerView &&
        !StaticData.isNfcCheckpoint1SenderTapped(shipment.id)) {
      return false;
    }
    return true;
  }

  List<Widget> _buildActions(
    BuildContext context,
    Shipment shipment,
    ShipmentStatus status,
  ) {
    final typo = context.typo;
    final actions = <Widget>[];

    void addAction(Widget action) {
      if (actions.isNotEmpty) {
        actions.add(const SizedBox(height: AppButton.stackGap));
      }
      actions.add(action);
    }

    void addSenderDisputeButton() {
      final disputed = StaticData.isShipmentDisputed(shipment.id);
      addAction(
        AppButton(
          label: 'Dispute',
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
          onPressed: () => context.go('/sender-chats'),
        ),
      );
    }

    // Sender detail (non-traveler route): same bottom actions across lifecycle stages.
    if (!widget.isTravelerView) {
      // Open: Chat with Traveler + Dispute + Cancel.
      // Matching travelers CTA is in the status row / My Posted Deliveries.
      if (status == ShipmentStatus.open) {
        addSenderChatButton();
        addSenderDisputeButton();
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

      final showDisputeAndChat = switch (status) {
        ShipmentStatus.bidAccepted => true,
        ShipmentStatus.photosUploaded => true,
        ShipmentStatus.collected => true,
        ShipmentStatus.inTransit => true,
        ShipmentStatus.delivered => true,
        _ => false,
      };

      // Bid Accepted / In Transit / Delivered (+ mid stages): Chat with Traveler then Dispute.
      // Dispute opens the existing form, or the existing open-dispute screen if already filed.
      if (showDisputeAndChat) {
        addSenderChatButton();
        addSenderDisputeButton();
      }

      // Cancel booking allowed through collected (including when parcel is
      // already collected). ≥24h → fees refunded; <24h → fees kept.
      if (StaticData.isSenderBookingCancellable(shipment)) {
        final feesRefundable =
            StaticData.isPlatformFeeRefundableOnCancel(shipment.travelDate);
        addAction(
          AppButton(
            label: 'Cancel booking (refund escrow)',
            variant: AppButtonVariant.danger,
            onPressed: () async {
              final confirmed =
                  await showCancelRequestConfirmation(context);
              if (!confirmed || !context.mounted) return;

              final cancelled =
                  StaticData.cancelShipmentBooking(shipment.id);
              if (!cancelled) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text(
                      'This booking can no longer be cancelled.',
                    ),
                    behavior: SnackBarBehavior.floating,
                  ),
                );
                return;
              }

              setState(() {});
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(
                    StaticData.senderBookingCancelResultMessage(
                      platformFeesRefunded: feesRefundable,
                    ),
                  ),
                ),
              );
            },
          ),
        );
      }

      if (status == ShipmentStatus.delivered ||
          StaticData.isNfcCheckpoint2Confirmed(shipment.id)) {
        addAction(
          AppButton(
            label: 'Leave a review',
            onPressed: () => context.push('/delivery-review'),
          ),
        );
      }
      return actions;
    }

    if (status == ShipmentStatus.delivered ||
        StaticData.isNfcCheckpoint2Confirmed(shipment.id)) {
      if (widget.isTravelerView) {
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
      addAction(
        AppButton(
          label: 'Leave a review',
          onPressed: () => context.push('/delivery-review'),
        ),
      );
      return actions;
    }

    if (StaticData.isShipmentDisputed(shipment.id)) {
      addAction(
        AppButton(
          label: 'View dispute',
          variant: AppButtonVariant.danger,
          onPressed: () => appNavigatePush(
            disputeRoute(
              shipment.id,
              travelerView: widget.isTravelerView,
            ),
          ),
        ),
      );
      return actions;
    }

    final canReportIssue = switch (status) {
      ShipmentStatus.bidAccepted => true,
      ShipmentStatus.photosUploaded => true,
      ShipmentStatus.collected => true,
      ShipmentStatus.inTransit => true,
      _ => false,
    };

    if (widget.isTravelerView && canReportIssue) {
      addAction(
        AppButton(
          label: 'Chat with sender',
          variant: AppButtonVariant.ghost,
          textStyle: typo.button.copyWith(
            fontWeight: FontWeight.w700,
            color: AppColors.primary,
          ),
          onPressed: () => context.go('/sender-chats'),
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
          onPressed: () => context.go('/receiver-chats'),
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
      if (StaticData.isTravelerBookingCancellable(shipment)) {
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
    if (!StaticData.isTravelerBookingCancellable(shipment)) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('This request can no longer be cancelled.'),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    // Match fee window to the same shipment cancelTravelerBooking uses.
    final canonical =
        StaticData.shipmentById(shipment.id) ?? shipment;
    final feesRefundable =
        StaticData.isPlatformFeeRefundableOnCancel(canonical.travelDate);
    final confirmed = await showCancelRequestConfirmation(context);
    if (!confirmed || !context.mounted) return;

    final cancelled = StaticData.cancelTravelerBooking(shipment.id);
    if (!cancelled) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('This request can no longer be cancelled.'),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          StaticData.travelerBookingCancelResultMessage(
            platformFeesRefunded: feesRefundable,
          ),
        ),
        behavior: SnackBarBehavior.floating,
      ),
    );
    context.go('/traveler-deliveries');
  }

  Widget _detailRow(BuildContext context, String label, String value) {
    final typo = context.typo;
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: typo.sm),
          Text(value, style: typo.bodyBold.copyWith(fontWeight: FontWeight.w700)),
        ],
      ),
    );
  }
}

class _ShipmentEscrowSection extends StatelessWidget {
  const _ShipmentEscrowSection({required this.shipmentId});

  final String shipmentId;

  @override
  Widget build(BuildContext context) {
    final typo = context.typo;
    return ValueListenableBuilder<int>(
      valueListenable: WalletService.walletVersion,
      builder: (context, _, __) {
        final escrow = WalletService.escrowCentsForShipment(shipmentId);
        final frozen = WalletService.isEscrowFrozen(shipmentId);
        final refunded = WalletService.isEscrowRefunded(shipmentId);
        final released = WalletService.isEscrowReleased(shipmentId);

        String statusLabel;
        if (released) {
          statusLabel = 'Released to traveler (NFC CP2)';
        } else if (refunded) {
          statusLabel = 'Refunded to sender';
        } else if (frozen) {
          statusLabel = 'Frozen — dispute under review';
        } else if (escrow > 0) {
          statusLabel = 'Held until NFC Checkpoint 2';
        } else {
          statusLabel = 'No active escrow';
        }

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Shipment escrow', style: typo.h3.copyWith(fontWeight: FontWeight.w700)),
            const SizedBox(height: 8),
            _detailRow(context, 'Amount', WalletService.formatCents(escrow)),
            _detailRow(context, 'Status', statusLabel),
          ],
        );
      },
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
              style: typo.bodyBold.copyWith(fontWeight: FontWeight.w700),
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
    final myTapDone = isTravelerView
        ? StaticData.isNfcCheckpoint1TravelerTapped(shipmentId)
        : StaticData.isNfcCheckpoint1SenderTapped(shipmentId);
    final otherTapDone = isTravelerView
        ? StaticData.isNfcCheckpoint1SenderTapped(shipmentId)
        : StaticData.isNfcCheckpoint1TravelerTapped(shipmentId);
    final otherLabel = isTravelerView ? 'sender' : 'traveler';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Icon(Icons.nfc, size: 20, color: AppColors.primary),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                'NFC Checkpoint 1 — Handoff',
                style: typo.h3.copyWith(fontWeight: FontWeight.w700),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Text(
          isTravelerView
              ? 'Sender completed their NFC tap. Tap phones with the sender to confirm NFC matching. When both taps are done, the parcel becomes Collected.'
              : 'NFC is enabled. Tap phones with the traveler to confirm handoff. After both of you match, the parcel becomes Collected.',
          style: typo.sm.copyWith(height: 1.5),
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            if (myTapDone)
              AppBadge.success('✓ Your NFC tap')
            else
              AppBadge(
                label: '○ Your NFC tap',
                color: AppColors.primary,
                backgroundColor: AppColors.primary.withValues(alpha: 0.12),
                small: true,
              ),
            if (otherTapDone)
              AppBadge.success('✓ $otherLabel NFC tap')
            else
              AppBadge(
                label: '○ Awaiting $otherLabel',
                color: AppColors.textDisabled,
                backgroundColor: AppColors.textDisabled.withValues(alpha: 0.4),
                small: true,
              ),
          ],
        ),
        if (!myTapDone) ...[
          const SizedBox(height: 16),
          AppButton(
            label: 'Confirm handoff (NFC CP1)',
            onPressed: () => context.push(
              '/nfc-confirm',
              extra: {
                'shipmentId': shipmentId,
                'checkpoint': 1,
                'isTraveler': isTravelerView,
              },
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Demo: opens phone tap screen. Both sender and traveler must complete this step.',
            style: typo.caption.copyWith(color: AppColors.textSecondary),
          ),
        ] else if (!otherTapDone) ...[
          const SizedBox(height: 12),
          Text(
            'Your tap is recorded. Waiting for the $otherLabel to complete NFC Checkpoint 1.',
            style: typo.sm.copyWith(height: 1.5, color: AppColors.primary),
          ),
        ],
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
    final isDelivered = status == ShipmentStatus.delivered ||
        StaticData.isNfcCheckpoint2Confirmed(shipmentId);
    final cp2Available = StaticData.isNfcCheckpoint2Available(shipmentId) ||
        StaticData.isNfcCheckpoint2Activated(shipmentId);
    final cp1Done = StaticData.isNfcCheckpoint1Confirmed(shipmentId);
    final myTapDone = StaticData.isNfcCheckpoint2TravelerTapped(shipmentId);
    final otherTapDone = StaticData.isNfcCheckpoint2ReceiverTapped(shipmentId);

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
                'NFC Checkpoint 2 — Delivery',
                style: typo.h3.copyWith(fontWeight: FontWeight.w700),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        if (isDelivered) ...[
          Text(
            'Final delivery confirmed with the receiver via NFC. Escrow released to your wallet. Leave a review is now available.',
            style: typo.sm.copyWith(height: 1.5, color: AppColors.success),
          ),
          const SizedBox(height: 12),
          AppBadge.success('✓ NFC CP2 confirmed'),
        ] else if (cp2Available || myTapDone || otherTapDone) ...[
          Text(
            'Meet the receiver and tap phones to confirm final delivery. Both traveler and receiver must complete NFC Checkpoint 2 to release escrow.',
            style: typo.sm.copyWith(height: 1.5),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              if (myTapDone)
                AppBadge.success('✓ Your NFC tap')
              else
                AppBadge(
                  label: '○ Your NFC tap',
                  color: AppColors.primary,
                  backgroundColor: AppColors.primary.withValues(alpha: 0.12),
                  small: true,
                ),
              if (otherTapDone)
                AppBadge.success('✓ Receiver NFC tap')
              else
                AppBadge(
                  label: '○ Awaiting receiver',
                  color: AppColors.textDisabled,
                  backgroundColor: AppColors.textDisabled.withValues(alpha: 0.4),
                  small: true,
                ),
            ],
          ),
          if (!myTapDone) ...[
            const SizedBox(height: 16),
            AppButton(
              label: 'Confirm delivery (NFC CP2)',
              onPressed: () => context.push(
                '/nfc-confirm',
                extra: {
                  'shipmentId': shipmentId,
                  'checkpoint': 2,
                  'isTraveler': true,
                },
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Demo: opens phone tap screen. Both traveler and receiver must complete this step.',
              style: typo.caption.copyWith(color: AppColors.textSecondary),
            ),
          ] else if (!otherTapDone) ...[
            const SizedBox(height: 12),
            Text(
              'Your tap is recorded. Waiting for the receiver to complete NFC Checkpoint 2.',
              style: typo.sm.copyWith(height: 1.5, color: AppColors.primary),
            ),
          ],
        ] else if (status == ShipmentStatus.collected && cp1Done) ...[
          Text(
            'Parcel is Collected. Mark In Transit above when you begin travel. Then enable NFC for the receiver at delivery.',
            style: typo.sm.copyWith(height: 1.5),
          ),
          const SizedBox(height: 12),
          AppBadge(
            label: '○ Mark In Transit to continue',
            color: AppColors.primary,
            backgroundColor: AppColors.primary.withValues(alpha: 0.12),
            small: true,
          ),
        ] else if (status == ShipmentStatus.inTransit && cp1Done) ...[
          Text(
            'Enable NFC for the receiver above to unlock Checkpoint 2. After both of you match phones, the parcel becomes Delivered.',
            style: typo.sm.copyWith(height: 1.5),
          ),
          const SizedBox(height: 12),
          AppBadge(
            label: '○ Enable NFC for receiver',
            color: AppColors.primary,
            backgroundColor: AppColors.primary.withValues(alpha: 0.12),
            small: true,
          ),
        ] else ...[
          Text(
            'NFC Checkpoint 2 unlocks after you mark In Transit and enable NFC for the receiver.',
            style: typo.sm.copyWith(height: 1.5),
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
  Timer? _autoCompleteTimer;

  bool get _isCheckpoint2 => widget.checkpoint == 2;

  @override
  void initState() {
    super.initState();
    _autoCompleteTimer = Timer(const Duration(seconds: 2), _complete);
  }

  @override
  void dispose() {
    _autoCompleteTimer?.cancel();
    super.dispose();
  }

  void _cancel() {
    if (_confirmed || _cancelled) return;
    _cancelled = true;
    _autoCompleteTimer?.cancel();
    final shipmentId = widget.shipmentId ??
        (_isCheckpoint2
            ? StaticData.receiverActiveShipment.id
            : StaticData.activeShipment.id);
    final fallback = _isCheckpoint2
        ? (widget.isTraveler
            ? '/shipment/$shipmentId?traveler=true'
            : '/receiver-tracking')
        : (widget.isTraveler
            ? '/shipment/$shipmentId?traveler=true'
            : '/track');
    appNavigateBackFromContext(context, fallback: fallback);
  }

  void _complete() {
    if (!mounted || _confirmed || _cancelled) return;
    _confirmed = true;
    _autoCompleteTimer?.cancel();
    final shipmentId = widget.shipmentId ??
        (_isCheckpoint2
            ? (widget.isTraveler
                ? StaticData.travelerActiveDelivery.id
                : StaticData.receiverActiveShipment.id)
            : StaticData.activeShipment.id);

    if (_isCheckpoint2) {
      // Both traveler and receiver must complete NFC matching before Delivered.
      final bothDone = StaticData.confirmNfcCheckpoint2Party(
        shipmentId,
        isTraveler: widget.isTraveler,
      );
      if (widget.isTraveler) {
        context.pushReplacement(
          '/traveler-nfc-success',
          extra: {
            'shipmentId': shipmentId,
            'waitingForPeer': !bothDone,
          },
        );
      } else {
        context.pushReplacement(
          '/receiver-nfc-success',
          extra: {
            'shipmentId': shipmentId,
            'waitingForPeer': !bothDone,
          },
        );
      }
      return;
    }

    final bothDone = StaticData.confirmNfcCheckpoint1Party(
      shipmentId,
      isTraveler: widget.isTraveler,
    );
    context.pushReplacement(
      '/nfc-confirm/success',
      extra: {
        'shipmentId': shipmentId,
        'isTraveler': widget.isTraveler,
        'waitingForPeer': !bothDone,
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final typo = context.typo;
    final title = _isCheckpoint2 ? 'NFC Checkpoint 2' : 'NFC Checkpoint 1';
    final body = _isCheckpoint2
        ? (widget.isTraveler
            ? "Hold your phone near the receiver's phone to confirm delivery. Both of you must match NFC to mark Delivered and release escrow."
            : "Hold your phone near the traveler's phone to confirm delivery. Both of you must match NFC to mark Delivered.")
        : widget.isTraveler
            ? "Hold your phone near the sender's phone to confirm handoff. Both of you must match NFC to mark Collected."
            : "Hold your phone near the traveler's phone to confirm handoff. Both of you must match NFC to mark Collected.";

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
                  onTap: _complete,
                  child: const _NfcPulseGraphic(),
                ),
                const SizedBox(height: 36),
                Text(
                  title,
                  textAlign: TextAlign.center,
                  style: typo.nfcTitle,
                ),
                const SizedBox(height: 14),
                Text(
                  body,
                  textAlign: TextAlign.center,
                  style: typo.nfcBody,
                ),
                const SizedBox(height: 48),
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

    final title = widget.waitingForPeer
        ? 'Waiting for $otherParty'
        : 'NFC Checkpoint 1 complete';
    final body = widget.waitingForPeer
        ? 'Your NFC tap for $shipmentId is recorded. Ask the $otherParty to complete their NFC tap. When both match, the parcel becomes Collected.'
        : 'NFC matching complete for $shipmentId. Parcel is now Collected. Traveler can mark In Transit when ready.';

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
                  color: (widget.waitingForPeer ? AppColors.primary : AppColors.success)
                      .withValues(alpha: 0.12),
                  shape: BoxShape.circle,
                ),
                alignment: Alignment.center,
                child: Icon(
                  widget.waitingForPeer ? Icons.hourglass_top_rounded : Icons.nfc,
                  size: 40,
                  color: widget.waitingForPeer ? AppColors.primary : AppColors.success,
                ),
              ),
              const SizedBox(height: 20),
              Text(title, style: typo.h1, textAlign: TextAlign.center),
              const SizedBox(height: 8),
              Text(
                body,
                textAlign: TextAlign.center,
                style: typo.sm.copyWith(height: 1.5),
              ),
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
        : 'NFC Checkpoint 2 complete';
    final body = waitingForPeer
        ? 'Your NFC tap for $shipmentId is recorded. Ask the receiver to complete their NFC Checkpoint 2 tap to confirm delivery and release escrow.'
        : 'Final delivery confirmed for $shipmentId. Parcel marked Delivered. Escrow released to your wallet. Leave a review is now available.';

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
                  color: (waitingForPeer ? AppColors.primary : AppColors.success)
                      .withValues(alpha: 0.12),
                  shape: BoxShape.circle,
                ),
                alignment: Alignment.center,
                child: Icon(
                  waitingForPeer ? Icons.hourglass_top_rounded : Icons.nfc,
                  size: 40,
                  color: waitingForPeer ? AppColors.primary : AppColors.success,
                ),
              ),
              const SizedBox(height: 20),
              Text(title, style: typo.h1, textAlign: TextAlign.center),
              const SizedBox(height: 8),
              Text(
                body,
                textAlign: TextAlign.center,
                style: typo.sm.copyWith(height: 1.5),
              ),
              if (!waitingForPeer) ...[
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
                  label: 'Leave a review',
                  variant: AppButtonVariant.outline,
                  onPressed: () => context.push('/delivery-review'),
                ),
              ],
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

  void _submit() {
    FocusManager.instance.primaryFocus?.unfocus();
    final category = _category ?? 'Damaged parcel';
    final description = _descriptionController.text.trim();
    if (description.isNotEmpty && description.length < 10) {
      setState(() => _error = 'Description must be at least 10 characters');
      return;
    }
    final reason = description.isNotEmpty
        ? '$category — $description'
        : 'Parcel arrived damaged — screen cracked on electronics item. Photos submitted.';
    StaticData.fileDispute(widget.shipmentId, reason: reason);
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

class DisputeScreen extends StatelessWidget {
  const DisputeScreen({super.key, required this.shipmentId, this.reason});

  final String shipmentId;
  final String? reason;

  @override
  Widget build(BuildContext context) {
    final typo = context.typo;
    final ctx = disputeContextFromUri(GoRouterState.of(context).uri);
    final disputeReason = reason ??
        'Parcel arrived damaged — screen cracked on electronics item. Photos submitted.';
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

  void _send() {
    final message = _messageController.text.trim();
    if (message.isEmpty) {
      setState(() => _error = 'Please enter a message');
      return;
    }
    context.pushReplacement('/contact-support/success', extra: widget.shipmentId);
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
            Text(
              'You can also email us at support@wwngo.com',
              style: typo.sm.copyWith(height: 1.5),
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
  });

  final String shipmentId;
  final int rating;
}

class ReviewSubmittedSuccessScreen extends StatelessWidget {
  const ReviewSubmittedSuccessScreen({
    super.key,
    required this.shipmentId,
    required this.rating,
  });

  final String shipmentId;
  final int rating;

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
                onPressed: () => context.go('/home'),
              ),
              const SizedBox(height: AppButton.stackGap),
              AppButton(
                label: 'View my shipments',
                variant: AppButtonVariant.outline,
                onPressed: () => context.go('/track'),
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

  @override
  void initState() {
    super.initState();
    _reviewController = TextEditingController(
      text: 'Aissatou was super reliable and communicated perfectly! ✨',
    );
  }

  @override
  void dispose() {
    _reviewController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final typo = context.typo;
    final shipmentId = 'WW-48291';
    final bid = StaticData.acceptedBidForShipment(shipmentId);
    final payoutLabel = bid != null
        ? WalletService.formatCents((bid.price * 100).round())
        : '\$18.00';
    final travelerName = bid?.travelerName ?? 'Aissatou';
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
                '$payoutLabel has been released to $travelerName\'s wallet for $shipmentId.',
                textAlign: TextAlign.center,
                style: typo.sm.copyWith(height: 1.5),
              ),
              const SizedBox(height: 8),
              Text('How was your experience?', style: typo.sm),
              const SizedBox(height: 20),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(5, (i) {
                  return GestureDetector(
                    onTap: () => setState(() => _rating = i + 1),
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
                  onTapOutside: dismissKeyboardOnTapOutside,
                  maxLines: 3,
                  decoration: const InputDecoration(),
                ),
              ),
              const SizedBox(height: 24),
              AppButton(
                label: 'Submit review',
                onPressed: () {
                  context.pushReplacement(
                    '/delivery-review/success',
                    extra: ReviewSubmittedRouteData(
                      shipmentId: 'WW-48291',
                      rating: _rating,
                    ),
                  );
                },
              ),
              const SizedBox(height: 10),
              TextButton(
                onPressed: () => context.go('/home'),
                child: Text('Skip for now', style: typo.link),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
