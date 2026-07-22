import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../core/layout/responsive.dart';
import '../../core/navigation/app_navigation.dart';
import '../../core/platform/platform_ui.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_typography.dart';
import '../../core/widgets/app_avatar.dart';
import '../../core/widgets/app_badge.dart';
import '../../core/widgets/app_button.dart';
import '../../core/widgets/app_card.dart';
import '../../core/widgets/app_svg_icon.dart';
import '../../core/widgets/back_header.dart';
import '../../core/widgets/back_link.dart';
import '../../core/widgets/cancel_request_confirmation_dialog.dart';
import '../../core/widgets/role_switch_card.dart';
import '../../core/widgets/screen_body.dart';
import '../../core/widgets/star_rating_display.dart';
import '../../data/models/incoming_parcel_request.dart';
import '../../data/models/shipment.dart';
import '../../data/models/chat_message.dart';
import '../../data/models/wallet_role.dart';
import '../../data/static_data.dart';
import '../../data/wallet_service.dart';
import '../../providers/auth_provider.dart';
import '../notifications/role_notifications_screen.dart';
import '../profile/widgets/profile_header_card.dart';
import '../profile/widgets/profile_trust_indicators.dart';
import '../tracking/widgets/shipment_tracking_section.dart';
import '../chat/chat_conversation_mixin.dart';
import '../chat/widgets/chat_composer.dart';
import '../chat/widgets/chat_image_attachment.dart';

class ReceiverProfileScreen extends StatelessWidget {
  const ReceiverProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final typo = context.typo;
    final authUser = context.watch<AuthProvider>().user;
    final user = authUser?.toUserProfile() ?? StaticData.receiverUser;
    final activeCount = StaticData.receiverShipments.length;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: ScreenBody(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            BackLink(onTap: () => context.go('/receiver-home')),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Profile', style: typo.h1),
                GestureDetector(
                  onTap: () => context.push('/settings?role=receiver'),
                  child: AppSvgIcon(
                    asset: AppIcons.settings,
                    size: 24,
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            ProfileHeaderCard(
              role: WalletRole.receiver,
              name: user.name,
              initial: user.initial,
              subtitle: 'Receiver',
              memberSince: user.memberSince,
              bio: user.bio,
              rating: user.rating,
              authUser: authUser,
            ),
            const SizedBox(height: 16),
            const RoleSwitchCard(currentRole: ShipmentRole.receiver),
            const SizedBox(height: 16),
            IntrinsicHeight(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _stat(
                    context,
                    '',
                    'Rating',
                    trailing: StarRatingDisplay(rating: user.rating, size: 12),
                  ),
                  const SizedBox(width: 10),
                  _stat(context, '$activeCount', 'Incoming shipments'),
                  const SizedBox(width: 10),
                  _stat(context, '${StaticData.receiverReceivedShipmentCount}', 'Delivered Parcels'),
                ],
              ),
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                ValueListenableBuilder<int>(
                  valueListenable: WalletService.walletVersion,
                  builder: (context, _, __) => _stat(
                    context,
                    WalletService.formatCents(
                      WalletService.availableCents(WalletRole.receiver),
                    ),
                    'Wallet',
                    onTap: () => context.push('/wallet?role=receiver'),
                  ),
                ),
                const SizedBox(width: 10),
                _stat(
                  context,
                  'History',
                  'Transactions',
                  onTap: () => context.push('/transaction-history?role=receiver'),
                ),
              ],
            ),
            const SizedBox(height: 16),
            ProfileTrustIndicators(
              metrics: StaticData.receiverTrustMetrics,
              authUser: authUser,
            ),
            const SizedBox(height: 16),
            Text('Quick actions', style: typo.h3.copyWith(fontWeight: FontWeight.w700)),
            const SizedBox(height: 12),
            Row(
              children: [
                _quickAction(context, AppIcons.parcel, 'My Incoming Parcels', () => context.go('/receiver-shipments')),
                const SizedBox(width: 10),
                _quickAction(context, AppIcons.track, 'Parcel Tracking', () => context.push('/receiver-tracking')),
                const SizedBox(width: 10),
                _quickAction(context, AppIcons.history, 'Delivery history', () => context.push('/receiver-shipments?tab=past')),
              ],
            ),
            const SizedBox(height: 16),
            Text('Delivery preferences', style: typo.h3.copyWith(fontWeight: FontWeight.w700)),
            const SizedBox(height: 10),
            AppCard(
              child: Column(
                children: [
                  _prefRow(context, 'Handover location', 'Murtala Muhammed Airport, Lagos'),
                  const Divider(height: 24),
                  _prefRow(context, 'Preferred contact', user.phone),
                  const Divider(height: 24),
                  _prefRow(context, 'NFC ready', 'Yes â€” phone supports tap'),
                ],
              ),
            ),
            const SizedBox(height: 16),
            AppButton(
              label: 'Log out',
              variant: AppButtonVariant.danger,
              onPressed: () => logoutToLoginScreen(context),
            ),
          ],
        ),
      ),
    );
  }

  Widget _stat(BuildContext context, String value, String label, {VoidCallback? onTap, Widget? trailing}) {
    final typo = context.typo;
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: AppCard(
        margin: EdgeInsets.zero,
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 14),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            trailing ??
                Text(
                  value,
                  textAlign: TextAlign.center,
                  style: typo.h2.copyWith(color: AppColors.primary),
                ),
            const SizedBox(height: 4),
            Text(
              label,
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: typo.sm,
            ),
          ],
        ),
      ),
      ),
    );
  }

  Widget _quickAction(BuildContext context, String iconAsset, String label, VoidCallback onTap) {
    final typo = context.typo;
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          constraints: const BoxConstraints(minHeight: 98),
          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 16),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: AppColors.border),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              AppSvgIcon(asset: iconAsset, size: 28),
              const SizedBox(height: 10),
              Text(
                label,
                textAlign: TextAlign.center,
                style: typo.actionLabel.copyWith(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textPrimary,
                  height: 1.2,
                ),
                maxLines: 2,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _prefRow(BuildContext context, String label, String value) {
    final typo = context.typo;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(child: Text(label, style: typo.sm)),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            value,
            textAlign: TextAlign.right,
            style: typo.bodyBold.copyWith(fontWeight: FontWeight.w600),
          ),
        ),
      ],
    );
  }
}

class ReceiverShipmentsScreen extends StatefulWidget {
  const ReceiverShipmentsScreen({super.key});

  @override
  State<ReceiverShipmentsScreen> createState() => _ReceiverShipmentsScreenState();
}

class _ReceiverShipmentsScreenState extends State<ReceiverShipmentsScreen> {
  bool _showActive = true;
  bool _tabInitialized = false;

  @override
  void initState() {
    super.initState();
    // One Traveler Selected card only (e.g. keep WW-48291, drop extras).
    StaticData.purgeExtraReceiverTravelerSelected();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_tabInitialized) return;
    _tabInitialized = true;
    final tab = GoRouterState.of(context).uri.queryParameters['tab'];
    if (tab == 'past') _showActive = false;
  }

  List<Shipment> _shipmentsForTab() {
    return StaticData.receiverShipments.where((s) {
      final status = StaticData.effectiveStatus(s);
      final isDelivered = status == ShipmentStatus.delivered;
      return _showActive ? !isDelivered : isDelivered;
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final horizontal = context.horizontalPadding;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: EdgeInsets.fromLTRB(horizontal, 20, horizontal, 0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  BackLink(onTap: () => context.go('/receiver-home')),
                  const SizedBox(height: 16),
                  Text('My Shipments', style: context.typo.h1),
                ],
              ),
            ),
            const SizedBox(height: 8),
            Padding(
              padding: EdgeInsets.symmetric(horizontal: horizontal),
              child: Text('Parcels addressed to you', style: context.typo.sm),
            ),
            const SizedBox(height: 12),
            Container(
              width: double.infinity,
              padding: EdgeInsets.symmetric(horizontal: horizontal),
              decoration: const BoxDecoration(
                border: Border(bottom: BorderSide(color: AppColors.border, width: 1)),
              ),
              child: Row(
                children: [
                  _tab(context, 'Incoming', _showActive, () => setState(() => _showActive = true)),
                  const SizedBox(width: 28),
                  _tab(context, 'Past', !_showActive, () => setState(() => _showActive = false)),
                ],
              ),
            ),
            Expanded(
              child: ValueListenableBuilder<int>(
                valueListenable: StaticData.incomingParcelRequestsVersion,
                builder: (context, _, __) {
                  return ValueListenableBuilder<int>(
                    valueListenable: StaticData.nfcCheckpointVersion,
                    builder: (context, _, __) {
                      final shipments = _shipmentsForTab();
                      final pendingRequests = _showActive
                          ? StaticData.pendingIncomingParcelRequests
                          : const <IncomingParcelRequest>[];
                      if (shipments.isEmpty && pendingRequests.isEmpty) {
                        return _EmptyShipmentsState(showActive: _showActive);
                      }
                      return ListView.builder(
                        physics: PlatformUi.scrollPhysics,
                        padding: EdgeInsets.fromLTRB(horizontal, 20, horizontal, 24),
                        itemCount: pendingRequests.length + shipments.length,
                        itemBuilder: (context, i) {
                          if (i < pendingRequests.length) {
                            final request = pendingRequests[i];
                            return GestureDetector(
                              onTap: () => context.push(
                                '/receiver-incoming-request/${request.id}',
                              ),
                              child: AppCard(
                                padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
                                margin: const EdgeInsets.only(bottom: 14),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                      children: [
                                        Text(
                                          request.id,
                                          style: context.typo.h3.copyWith(
                                            fontSize: 16,
                                            fontWeight: FontWeight.w700,
                                          ),
                                        ),
                                        AppBadge(
                                          label: request.status.label,
                                          color: request.status.color,
                                          backgroundColor: request.status.backgroundColor,
                                          semiBold: true,
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 10),
                                    Text(request.route, style: context.typo.sm.copyWith(color: AppColors.textPrimary)),
                                    const SizedBox(height: 8),
                                    Text(
                                      'From ${request.senderName}',
                                      style: context.typo.sm,
                                    ),
                                    const SizedBox(height: 12),
                                    Text(
                                      'Review and accept or decline this request',
                                      style: context.typo.sm.copyWith(color: AppColors.primary),
                                    ),
                                  ],
                                ),
                              ),
                            );
                          }

                          final s = shipments[i - pendingRequests.length];
                          return GestureDetector(
                            onTap: () {
                              if (StaticData.isIncomingParcelRequestPending(s.id)) {
                                context.push('/receiver-incoming-request/${s.id}');
                              } else if (StaticData.needsReceiverPayment(s)) {
                                context.push('/receiver-home/payment-approval', extra: s);
                              } else if (StaticData.canReceiverAccessParcelFeatures(s.id)) {
                                context.push('/receiver-tracking?shipmentId=${s.id}');
                              } else {
                                context.push('/receiver-incoming-request/${s.id}');
                              }
                            },
                        child: AppCard(
                          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
                          margin: const EdgeInsets.only(bottom: 14),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    s.id,
                                    style: context.typo.h3.copyWith(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                  AppBadge.status(StaticData.effectiveStatus(s), semiBold: true, wide: true),
                                ],
                              ),
                              const SizedBox(height: 10),
                              Text(s.route, style: context.typo.sm.copyWith(color: AppColors.textPrimary)),
                              const SizedBox(height: 8),
                              Text(s.description, style: context.typo.sm),
                              const SizedBox(height: 12),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Text('From ${s.travelerName ?? 'Traveler'}', style: context.typo.sm),
                                  Text(DateFormat('MMM d, yyyy').format(s.travelDate), style: context.typo.sm),
                                ],
                              ),
                            ],
                          ),
                        ),
                      );
                        },
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _tab(BuildContext context, String label, bool active, VoidCallback onTap) {
    final typo = context.typo;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.only(top: 4, bottom: 12),
        decoration: BoxDecoration(
          border: Border(
            bottom: BorderSide(
              color: active ? AppColors.primary : Colors.transparent,
              width: 2,
            ),
          ),
        ),
        child: Text(
          label,
          style: typo.body.copyWith(
            fontSize: 14,
            fontWeight: FontWeight.w700,
            color: active ? AppColors.primary : AppColors.textSecondary,
          ),
        ),
      ),
    );
  }
}

class _EmptyShipmentsState extends StatelessWidget {
  const _EmptyShipmentsState({required this.showActive});

  final bool showActive;

  @override
  Widget build(BuildContext context) {
    final typo = context.typo;
    return Center(
      child: Padding(
        padding: context.pagePadding,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            AppSvgIcon(asset: AppIcons.parcel, size: 56, color: AppColors.textDisabled),
            const SizedBox(height: 16),
            Text(
              showActive ? 'No incoming parcels' : 'No past deliveries',
              style: typo.h3.copyWith(fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 8),
            Text(
              showActive
                  ? 'When someone sends a parcel to you, it will appear here.'
                  : 'Completed deliveries will show up in this tab.',
              textAlign: TextAlign.center,
              style: typo.sm,
            ),
          ],
        ),
      ),
    );
  }
}

class ReceiverNotificationsScreen extends StatelessWidget {
  const ReceiverNotificationsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const RoleNotificationsScreen(
      role: WalletRole.receiver,
      useBackLink: true,
    );
  }
}

class ReceiverChatScreen extends StatefulWidget {
  const ReceiverChatScreen({super.key, this.backFallback, this.contactName});

  final String? backFallback;
  /// When opened from inbox, show this contact instead of active shipment traveler.
  final String? contactName;

  @override
  State<ReceiverChatScreen> createState() => _ReceiverChatScreenState();
}

class _ReceiverChatScreenState extends State<ReceiverChatScreen> with ChatConversationMixin {
  @override
  ChatThread? get chatThread => ChatThread.travelerReceiver;

  @override
  void initState() {
    super.initState();
    initChatMessages(StaticData.chatMessagesForThread(ChatThread.travelerReceiver));
  }

  @override
  void dispose() {
    disposeChatConversation();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final typo = context.typo;
    final shipment = StaticData.receiverActiveShipment;
    final traveler = widget.contactName ?? shipment.travelerName ?? 'Traveler';
    final unlocked = StaticData.isThreadUnlocked(ChatThread.travelerReceiver);
    final lockReasons = StaticData.chatThreadLockReasons(ChatThread.travelerReceiver);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: BackHeader(
        title: traveler,
        showBottomBorder: false,
        fallbackRoute: widget.backFallback ?? '/receiver-chats',
      ),
      body: Column(
        children: [
          Container(
            width: double.infinity,
            padding: EdgeInsets.fromLTRB(context.horizontalPadding, 0, context.horizontalPadding, 12),
            color: AppColors.surface,
            child: Text(
              'Traveler â†” Receiver Â· ${shipment.id}',
              textAlign: TextAlign.center,
              style: typo.sm,
            ),
          ),
          if (!unlocked)
            Container(
              width: double.infinity,
              padding: EdgeInsets.fromLTRB(
                context.horizontalPadding,
                8,
                context.horizontalPadding,
                8,
              ),
              color: AppColors.warning.withValues(alpha: 0.12),
              child: Text(
                'Thread locked: ${lockReasons.join(' Â· ')}',
                style: typo.sm.copyWith(
                  color: AppColors.warning,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          Expanded(
            child: ValueListenableBuilder<int>(
              valueListenable: StaticData.chatThreadsVersion,
              builder: (context, _, __) {
                chatMessages = List.of(
                  StaticData.chatMessagesForThread(ChatThread.travelerReceiver),
                );
                return ListView(
                  controller: chatScrollController,
                  physics: PlatformUi.scrollPhysics,
                  padding: EdgeInsets.all(context.horizontalPadding),
                  children: [
                    Center(
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                        decoration: BoxDecoration(
                          color: AppColors.background,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Text('Today', style: typo.datePill),
                      ),
                    ),
                    const SizedBox(height: 14),
                    ...chatMessages.map(
                      (m) => _ChatBubble(message: m, travelerInitial: traveler[0]),
                    ),
                  ],
                );
              },
            ),
          ),
          ChatComposer(
            controller: chatController,
            hintText: 'Message $travelerâ€¦',
            onSend: sendChatTextMessage,
            onAttach: showChatAttachmentOptions,
            borderRadius: 12,
            circularSendButton: false,
            enabled: unlocked,
          ),
        ],
      ),
    );
  }
}

class _ChatBubble extends StatelessWidget {
  const _ChatBubble({required this.message, required this.travelerInitial});

  final ChatMessage message;
  final String travelerInitial;

  @override
  Widget build(BuildContext context) {
    final typo = context.typo;
    final isMine = message.isMine;

    if (message.isImage) {
      return Padding(
        padding: const EdgeInsets.only(bottom: 12),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            Flexible(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  ClipRRect(
                    borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(14),
                      topRight: Radius.circular(14),
                      bottomLeft: Radius.circular(14),
                      bottomRight: Radius.circular(4),
                    ),
                    child: ChatImageAttachment(message: message),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    message.time,
                    style: typo.caption.copyWith(color: AppColors.textSecondary),
                  ),
                ],
              ),
            ),
          ],
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        mainAxisAlignment: isMine ? MainAxisAlignment.end : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          if (!isMine) ...[
            AppAvatar(initial: travelerInitial, size: AvatarSize.small),
            const SizedBox(width: 8),
          ],
          Flexible(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                color: isMine ? AppColors.primary : AppColors.surface,
                borderRadius: BorderRadius.only(
                  topLeft: const Radius.circular(14),
                  topRight: const Radius.circular(14),
                  bottomLeft: Radius.circular(isMine ? 14 : 4),
                  bottomRight: Radius.circular(isMine ? 4 : 14),
                ),
                border: isMine ? null : Border.all(color: AppColors.border),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    message.text,
                    style: typo.body.copyWith(
                      color: isMine ? Colors.white : AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    message.time,
                    style: typo.caption.copyWith(
                      color: isMine ? Colors.white70 : AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class ReceiverTrackingScreen extends StatelessWidget {
  const ReceiverTrackingScreen({super.key, this.shipmentId});

  final String? shipmentId;

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<int>(
      valueListenable: StaticData.bidRequestsVersion,
      builder: (context, _, __) {
        return ValueListenableBuilder<int>(
          valueListenable: StaticData.nfcCheckpointVersion,
          builder: (context, _, __) {
        final typo = context.typo;
        final shipment =
            StaticData.receiverShipmentById(shipmentId) ??
            StaticData.receiverShipmentById(
              StaticData.receiverActiveShipment.id,
            ) ??
            StaticData.receiverActiveShipment;
        final status = StaticData.effectiveStatus(shipment);
        final stepProgress = StaticData.effectiveStepIndex(shipment);
        final featuresUnlocked = StaticData.canReceiverAccessParcelFeatures(shipment.id);

        return Scaffold(
          backgroundColor: AppColors.background,
          appBar: BackHeader(title: 'Track ${shipment.id}'),
          body: SafeArea(
            child: SingleChildScrollView(
              physics: PlatformUi.scrollPhysics,
              padding: context.pagePadding,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  AppBadge.status(status),
                  const SizedBox(height: 16),
                  AppCard(
                    margin: EdgeInsets.zero,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (featuresUnlocked) ...[
                          ShipmentTrackingSection(
                            shipment: shipment,
                            stepProgress: stepProgress,
                          ),
                          const Padding(
                            padding: EdgeInsets.symmetric(vertical: 20),
                            child: Divider(height: 1),
                          ),
                        ],
                        Text('Shipment details', style: typo.h3.copyWith(fontWeight: FontWeight.w700)),
                        const SizedBox(height: 12),
                        _detailRow(context, 'Route', shipment.route),
                        _detailRow(context, 'Travel date', DateFormat('MMM d, yyyy').format(shipment.travelDate)),
                        _detailRow(context, 'Traveler', shipment.travelerName ?? '—'),
                        _detailRow(context, 'Flight', shipment.flightNumber ?? '—'),
                        _detailRow(context, 'Parcel type', '${shipment.parcelCategory} · ${shipment.parcelWeightKg}kg'),
                        if (featuresUnlocked) ...[
                          const SizedBox(height: 16),
                          ValueListenableBuilder<int>(
                            valueListenable: WalletService.walletVersion,
                            builder: (context, _, __) {
                              final escrow = WalletService.escrowCentsForShipment(shipment.id);
                              final frozen = WalletService.isEscrowFrozen(shipment.id);
                              final statusText = frozen
                                  ? 'Frozen — dispute'
                                  : escrow > 0
                                      ? 'Held until NFC CP2'
                                      : WalletService.isEscrowReleased(shipment.id)
                                          ? 'Released to traveler'
                                          : 'No active escrow';
                              return Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text('Shipment escrow', style: typo.h3.copyWith(fontWeight: FontWeight.w700)),
                                  const SizedBox(height: 8),
                                  _detailRow(context, 'Amount', WalletService.formatCents(escrow)),
                                  _detailRow(context, 'Status', statusText),
                                  const SizedBox(height: 8),
                                ],
                              );
                            },
                          ),
                          Wrap(
                            spacing: 8,
                            runSpacing: 8,
                            children: [
                              if (WalletService.escrowCentsForShipment(shipment.id) > 0 ||
                                  WalletService.isEscrowReleased(shipment.id))
                                AppBadge.success('✓ Escrow active')
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
                        ] else ...[
                          const SizedBox(height: 8),
                          Text(
                            'Accept the parcel request to unlock tracking, NFC, and chat.',
                            style: typo.sm.copyWith(color: AppColors.textSecondary),
                          ),
                        ],
                      ],
                    ),
                  ),
                  if (featuresUnlocked) ...[
                    const SizedBox(height: 24),
                    AppCard(
                      margin: EdgeInsets.zero,
                      child: _ReceiverNfcDeliverySection(
                        status: status,
                        shipmentId: shipment.id,
                      ),
                    ),
                    const SizedBox(height: 24),
                    AppButton(
                      label: 'Chat with traveler',
                      variant: AppButtonVariant.ghost,
                      textStyle: typo.button.copyWith(fontWeight: FontWeight.w700, color: AppColors.primary),
                      onPressed: () => context.go('/receiver-chats'),
                    ),
                    if (StaticData.isReceiverBookingCancellable(shipment)) ...[
                      const SizedBox(height: AppButton.stackGap),
                      AppButton(
                        label: 'Cancel Request',
                        variant: AppButtonVariant.danger,
                        onPressed: () => _cancelReceiverRequest(context, shipment),
                      ),
                    ],
                    if (status == ShipmentStatus.delivered) ...[
                      const SizedBox(height: AppButton.stackGap),
                      AppButton(
                        label: 'Leave a review',
                        onPressed: () => context.push('/delivery-review'),
                      ),
                    ],
                    ..._buildDisputeActions(context, shipment, status),
                  ],
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

  Future<void> _cancelReceiverRequest(
    BuildContext context,
    Shipment shipment,
  ) async {
    if (!StaticData.isReceiverBookingCancellable(shipment)) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('This request can no longer be cancelled.'),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    final canonical =
        StaticData.shipmentById(shipment.id) ??
        StaticData.receiverShipmentById(shipment.id) ??
        shipment;
    final feesRefundable =
        StaticData.isPlatformFeeRefundableOnCancel(canonical.travelDate);
    final confirmed = await showCancelRequestConfirmation(context);
    if (!confirmed || !context.mounted) return;

    final cancelled = StaticData.cancelReceiverBooking(shipment.id);
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
          StaticData.receiverBookingCancelResultMessage(
            platformFeesRefunded: feesRefundable,
          ),
        ),
        behavior: SnackBarBehavior.floating,
      ),
    );
    context.go('/receiver-shipments');
  }

  List<Widget> _buildDisputeActions(
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

    if (StaticData.isShipmentDisputed(shipment.id)) {
      addAction(
        AppButton(
          label: 'View dispute',
          variant: AppButtonVariant.danger,
          onPressed: () => appNavigatePush(
            disputeRoute(shipment.id, role: 'receiver'),
          ),
        ),
      );
      return [
        const SizedBox(height: AppButton.stackGap),
        ...actions,
      ];
    }

    final canReportIssue = switch (status) {
      ShipmentStatus.bidAccepted => true,
      ShipmentStatus.photosUploaded => true,
      ShipmentStatus.collected => true,
      ShipmentStatus.inTransit => true,
      _ => false,
    };

    if (canReportIssue) {
      addAction(
        AppButton(
          label: 'Dispute',
          variant: AppButtonVariant.danger,
          textStyle: typo.buttonDanger.copyWith(fontWeight: FontWeight.w700),
          onPressed: () => appNavigatePush(
            disputeFormRoute(shipment.id, role: 'receiver'),
          ),
        ),
      );
    }

    if (actions.isEmpty) return actions;

    return [
      const SizedBox(height: AppButton.stackGap),
      ...actions,
    ];
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

class _ReceiverNfcDeliverySection extends StatelessWidget {
  const _ReceiverNfcDeliverySection({
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
    // Traveler enables NFC CP2 for both traveler and receiver.
    final cp2Active = !isDelivered &&
        (StaticData.isNfcCheckpoint2Activated(shipmentId) ||
            StaticData.isNfcCheckpoint2Available(shipmentId));
    final waitingForTravelerNfc =
        !isDelivered && status == ShipmentStatus.inTransit && !cp2Active;

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
            'Delivery confirmed via NFC. Parcel is Delivered, escrow released, and Leave a review is available.',
            style: typo.sm.copyWith(height: 1.5, color: AppColors.success),
          ),
          const SizedBox(height: 12),
          AppBadge.success('✓ NFC CP2 confirmed'),
        ] else if (cp2Active) ...[
          Text(
            'Traveler enabled NFC for delivery. Match phones with the traveler to mark the parcel Delivered.',
            style: typo.sm.copyWith(height: 1.5),
          ),
          const SizedBox(height: 12),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: const Color(0xFFEFF6FF),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color(0xFFBFDBFE)),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(Icons.info_outline, size: 20, color: Color(0xFF1D4ED8)),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Traveler enabled NFC for receiver.',
                        style: typo.sm.copyWith(
                          height: 1.4,
                          fontWeight: FontWeight.w700,
                          color: const Color(0xFF1D4ED8),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Start NFC verification. Both traveler and receiver must match to mark Delivered.',
                        style: typo.sm.copyWith(
                          height: 1.4,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          AppButton(
            label: 'Start NFC Verification',
            icon: const Icon(Icons.nfc, size: 18, color: Colors.white),
            onPressed: () => context.push(
              '/nfc-confirm',
              extra: {
                'shipmentId': shipmentId,
                'checkpoint': 2,
                'isTraveler': false,
              },
            ),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Icon(
                Icons.lock_outline,
                size: 14,
                color: AppColors.textSecondary,
              ),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  'Tap to open NFC screen and verify with traveler\'s device.',
                  style: typo.caption.copyWith(color: AppColors.textSecondary),
                ),
              ),
            ],
          ),
        ] else if (waitingForTravelerNfc) ...[
          Text(
            'Parcel is In Transit. NFC Checkpoint 2 unlocks when the traveler enables NFC for you.',
            style: typo.sm.copyWith(height: 1.5),
          ),
          const SizedBox(height: 12),
          AppBadge(
            label: '○ Awaiting traveler Enable NFC',
            color: AppColors.textDisabled,
            backgroundColor: AppColors.textDisabled.withValues(alpha: 0.4),
            small: true,
          ),
        ] else ...[
          Text(
            'Awaiting sender↔traveler handoff (NFC Checkpoint 1). After In Transit, the traveler enables NFC for final delivery.',
            style: typo.sm.copyWith(height: 1.5),
          ),
          const SizedBox(height: 12),
          AppBadge(
            label: '○ Awaiting In Transit',
            color: AppColors.textDisabled,
            backgroundColor: AppColors.textDisabled.withValues(alpha: 0.4),
            small: true,
          ),
        ],
      ],
    );
  }
}

class ReceiverNfcDeliverySuccessScreen extends StatelessWidget {
  const ReceiverNfcDeliverySuccessScreen({
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
        ? 'Waiting for traveler'
        : 'NFC Checkpoint 2 complete';
    final body = waitingForPeer
        ? 'Your NFC tap for $shipmentId is recorded. Ask the traveler to complete their NFC Checkpoint 2 tap to confirm delivery and release escrow.'
        : 'Final delivery confirmed for $shipmentId. Parcel marked Delivered. Escrow released to traveler. Leave a review is now available.';

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
                      _nfcSuccessRow(context, 'NFC Verified'),
                      const SizedBox(height: 12),
                      _nfcSuccessRow(context, 'Parcel Delivered'),
                      const SizedBox(height: 12),
                      _nfcSuccessRow(context, 'Payment Completed'),
                    ],
                  ),
                ),
              ],
              const SizedBox(height: 32),
              AppButton(
                label: waitingForPeer ? 'Back to tracking' : 'View completed',
                onPressed: () => context.go(
                  waitingForPeer
                      ? '/receiver-tracking'
                      : '/receiver-shipments?tab=past',
                ),
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

  Widget _nfcSuccessRow(BuildContext context, String label) {
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
