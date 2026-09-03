import 'dart:async';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../core/api/api_exception.dart';
import '../../core/config/demo_mode.dart';
import '../../core/layout/responsive.dart';
import '../../core/navigation/app_navigation.dart';
import '../../core/platform/platform_ui.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_typography.dart';
import '../../core/widgets/app_badge.dart';
import '../../core/widgets/app_button.dart';
import '../../core/widgets/app_card.dart';
import '../../core/widgets/app_svg_icon.dart';
import '../../core/widgets/back_header.dart';
import '../../core/widgets/back_link.dart';
import '../../core/widgets/role_switch_card.dart';
import '../../core/widgets/screen_body.dart';
import '../../core/widgets/star_rating_display.dart';
import '../../data/models/created_delivery.dart';
import '../../data/models/profile_trust_metrics.dart';
import '../../data/models/delivery_tracking.dart';
import '../../data/models/receiver_delivery_status.dart';
import '../../data/models/shipment.dart';
import '../../data/models/chat_message.dart';
import '../../data/models/wallet_role.dart';
import '../../data/services/chat_repository.dart';
import '../../data/services/delivery_repository.dart';
import '../../data/services/trust_metrics_repository.dart';
import '../../data/static_data.dart';
import '../../data/wallet_service.dart';
import '../../providers/auth_provider.dart';
import '../../providers/chat_realtime_provider.dart';
import '../../providers/notification_realtime_provider.dart';
import '../../providers/wallet_provider.dart';
import '../chat/open_delivery_chat.dart';
import '../notifications/role_notifications_screen.dart';
import '../tracking/widgets/shipment_escrow_section.dart';
import '../profile/widgets/profile_header_card.dart';
import '../profile/widgets/profile_trust_indicators.dart';
import '../profile/widgets/recent_reviews_section.dart';
import '../tracking/widgets/shipment_tracking_section.dart';
import '../chat/chat_conversation_mixin.dart';
import '../chat/widgets/chat_composer.dart';
import '../chat/widgets/chat_thread_widgets.dart';

class ReceiverProfileScreen extends StatefulWidget {
  const ReceiverProfileScreen({super.key});

  @override
  State<ReceiverProfileScreen> createState() => _ReceiverProfileScreenState();
}

class _ReceiverProfileScreenState extends State<ReceiverProfileScreen> {
  int _incomingCount = 0;
  int _deliveredCount = 0;
  ProfileTrustMetrics? _trustMetrics;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      context
          .read<WalletProvider>()
          .refresh(WalletRole.receiver, silent: true)
          .ignore();
      _loadCounts();
      _loadTrust();
    });
  }

  DeliveryRepository _deliveryRepository() {
    final auth = context.read<AuthProvider>();
    final demoMode = context.read<DemoModeProvider>();
    return DeliveryRepository(
      apiClient: auth.repository.apiClient,
      demoMode: demoMode,
    );
  }

  TrustMetricsRepository _trustRepository() {
    final auth = context.read<AuthProvider>();
    final demoMode = context.read<DemoModeProvider>();
    return TrustMetricsRepository(
      apiClient: auth.repository.apiClient,
      demoMode: demoMode,
    );
  }

  Future<void> _loadCounts() async {
    try {
      final list = await _deliveryRepository().listDeliveries(role: 'receiver');
      if (!mounted) return;
      var incoming = 0;
      var delivered = 0;
      for (final d in list) {
        final status = ReceiverDeliveryStatus.fromDelivery(d);
        if (status.isPast) {
          if (d.status == 'delivered') delivered++;
        } else {
          incoming++;
        }
      }
      setState(() {
        _incomingCount = incoming;
        _deliveredCount = delivered;
      });
    } catch (_) {
      // Keep zeros on failure.
    }
  }

  Future<void> _loadTrust() async {
    try {
      final metrics =
          await _trustRepository().fetch(WalletRole.receiver);
      if (!mounted) return;
      setState(() => _trustMetrics = metrics);
    } catch (_) {
      // Keep null → fall back below.
    }
  }

  @override
  Widget build(BuildContext context) {
    final typo = context.typo;
    final authUser = context.watch<AuthProvider>().user;
    final user = authUser?.toUserProfile() ?? StaticData.receiverUser;
    final activeCount = _incomingCount;
    final trust = _trustMetrics ?? StaticData.receiverTrustMetrics;

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
                  _stat(context, '$_deliveredCount', 'Delivered Parcels'),
                ],
              ),
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(
                  child: ValueListenableBuilder<int>(
                    valueListenable: WalletService.walletVersion,
                    builder: (context, _, __) => _stat(
                      context,
                      WalletService.formatCents(
                        WalletService.availableCents(WalletRole.receiver),
                      ),
                      'Wallet',
                      onTap: () => context.push('/wallet?role=receiver'),
                      expand: false,
                    ),
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
              metrics: trust,
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
                  _prefRow(
                    context,
                    'Handover location',
                    user.bio.trim().isNotEmpty ? user.bio : 'Not set',
                  ),
                  const Divider(height: 24),
                  _prefRow(context, 'Preferred contact', user.phone),
                  const Divider(height: 24),
                  _prefRow(context, 'NFC ready', 'Yes phone supports tap'),
                ],
              ),
            ),
            const SizedBox(height: 16),
            const RecentReviewsSection(role: WalletRole.receiver),
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

  Widget _stat(
    BuildContext context,
    String value,
    String label, {
    VoidCallback? onTap,
    Widget? trailing,
    bool expand = true,
  }) {
    final typo = context.typo;
    final content = GestureDetector(
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
    );
    return expand ? Expanded(child: content) : content;
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

class _ReceiverShipmentsScreenState extends State<ReceiverShipmentsScreen>
    with WidgetsBindingObserver {
  bool _showActive = true;
  bool _tabInitialized = false;
  bool _loading = true;
  String? _error;
  List<CreatedDelivery> _deliveries = const [];
  String? _lastMatchedLocation;
  VoidCallback? _realtimeListener;
  NotificationRealtimeProvider? _realtimeProvider;
  int _lastDeliveryUpdateTick = 0;
  Timer? _fallbackPollTimer;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      _attachRealtimeListener();
    });
    _fallbackPollTimer = Timer.periodic(const Duration(seconds: 45), (_) {
      if (!mounted) return;
      if (!(_realtimeProvider?.isConnected ?? false)) {
        _load(silent: _deliveries.isNotEmpty);
      }
    });
  }

  void _attachRealtimeListener() {
    final realtime = context.read<NotificationRealtimeProvider>();
    _realtimeProvider = realtime;
    _lastDeliveryUpdateTick = realtime.deliveryUpdateTick;

    _realtimeListener ??= () {
      if (!mounted) return;
      final tick = realtime.deliveryUpdateTick;
      if (tick != _lastDeliveryUpdateTick) {
        _lastDeliveryUpdateTick = tick;
        _load(silent: _deliveries.isNotEmpty);
      }
    };
    realtime.addListener(_realtimeListener!);
  }

  @override
  void dispose() {
    _fallbackPollTimer?.cancel();
    if (_realtimeListener != null) {
      _realtimeProvider?.removeListener(_realtimeListener!);
    }
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) _load(silent: true);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final location = GoRouterState.of(context).matchedLocation;
    if (!_tabInitialized) {
      _tabInitialized = true;
      final tab = GoRouterState.of(context).uri.queryParameters['tab'];
      if (tab == 'past') _showActive = false;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _load();
      });
    } else if (location.startsWith('/receiver-shipments') &&
        _lastMatchedLocation != location) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _load(silent: true);
      });
    }
    _lastMatchedLocation = location;
  }

  DeliveryRepository _repo() {
    final auth = context.read<AuthProvider>();
    final demoMode = context.read<DemoModeProvider>();
    return DeliveryRepository(
      apiClient: auth.repository.apiClient,
      demoMode: demoMode,
    );
  }

  Future<void> _load({bool silent = false}) async {
    if (!silent) {
      setState(() {
        _loading = true;
        _error = null;
      });
    }
    try {
      final list = await _repo().listDeliveries(role: 'receiver');
      if (!mounted) return;
      setState(() {
        _deliveries = list;
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
        _error = 'Unable to load shipments.';
      });
    }
  }

  List<CreatedDelivery> get _visible {
    return _deliveries.where((d) {
      final status = ReceiverDeliveryStatus.fromDelivery(d);
      return _showActive ? !status.isPast : status.isPast;
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final horizontal = context.horizontalPadding;
    final items = _visible;

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
            Expanded(child: _body(context, horizontal, items)),
          ],
        ),
      ),
    );
  }

  Widget _body(BuildContext context, double horizontal, List<CreatedDelivery> items) {
    if (_loading && _deliveries.isEmpty) {
      return const Center(
        child: SizedBox(
          width: 22,
          height: 22,
          child: CircularProgressIndicator(
            strokeWidth: 2.5,
            color: AppColors.primary,
          ),
        ),
      );
    }

    if (_error != null && _deliveries.isEmpty) {
      return Center(
        child: Padding(
          padding: context.pagePadding,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                _error!,
                textAlign: TextAlign.center,
                style: context.typo.sm.copyWith(color: AppColors.textSecondary),
              ),
              const SizedBox(height: 12),
              TextButton(onPressed: () => _load(), child: const Text('Retry')),
            ],
          ),
        ),
      );
    }

    if (items.isEmpty) {
      return _EmptyShipmentsState(showActive: _showActive);
    }

    return RefreshIndicator(
      onRefresh: () => _load(silent: true),
      child: ListView.builder(
        physics: PlatformUi.scrollPhysics,
        padding: EdgeInsets.fromLTRB(horizontal, 20, horizontal, 24),
        itemCount: items.length,
        itemBuilder: (context, i) {
          final d = items[i];
          final status = ReceiverDeliveryStatus.fromDelivery(d);
          final travelDate = d.travelDateParsed;
          return GestureDetector(
            onTap: () async {
              if (status.isPendingRequest) {
                await context.push('/receiver-incoming-request/${d.displayId}');
              } else {
                await context.push('/receiver-tracking?shipmentId=${d.displayId}');
              }
              if (mounted) _load(silent: true);
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
                        d.displayId,
                        style: context.typo.h3.copyWith(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      AppBadge(
                        label: status.label,
                        color: status.color,
                        backgroundColor: status.backgroundColor,
                        semiBold: true,
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Text(
                    d.route.isNotEmpty ? d.route : '—',
                    style: context.typo.sm.copyWith(color: AppColors.textPrimary),
                  ),
                  if (d.description.trim().isNotEmpty) ...[
                    const SizedBox(height: 8),
                    Text(d.description, style: context.typo.sm),
                  ],
                  if (status.isPendingRequest) ...[
                    const SizedBox(height: 8),
                    Text(
                      'From ${d.senderName ?? 'Sender'}',
                      style: context.typo.sm,
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'Review and accept or decline this request',
                      style: context.typo.sm.copyWith(color: AppColors.primary),
                    ),
                  ] else ...[
                    const SizedBox(height: 12),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'From ${d.senderName ?? 'Sender'}',
                          style: context.typo.sm,
                        ),
                        if (travelDate != null)
                          Text(
                            DateFormat('MMM d, yyyy').format(travelDate),
                            style: context.typo.sm,
                          ),
                      ],
                    ),
                  ],
                ],
              ),
            ),
          );
        },
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
  const ReceiverChatScreen({
    super.key,
    this.backFallback,
    this.contactName,
    this.conversationId,
  });

  final String? backFallback;
  /// When opened from inbox, show this contact instead of active shipment traveler.
  final String? contactName;
  final String? conversationId;

  @override
  State<ReceiverChatScreen> createState() => _ReceiverChatScreenState();
}

class _ReceiverChatScreenState extends State<ReceiverChatScreen>
    with ChatConversationMixin {
  @override
  ChatThread? get chatThread => null;

  @override
  String? get liveChatConversationId => _conversationId;

  @override
  Future<ChatMessage> Function(String conversationId, String filePath)?
      get uploadLiveChatImage =>
          (id, path) => _repo().sendImage(id, path);

  bool _loading = true;
  String? _error;
  String _peerName = 'Contact';
  String _shipmentId = '';
  String? _conversationId;
  ChatRealtimeProvider? _chatRealtime;

  @override
  void initState() {
    super.initState();
    initChatMessages(const []);
    _conversationId = widget.conversationId;
    _peerName = widget.contactName ?? 'Contact';
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _load();
    });
  }

  @override
  void dispose() {
    if (_conversationId != null) {
      _chatRealtime?.leaveConversation(_conversationId!);
    }
    disposeChatConversation();
    super.dispose();
  }

  ChatRepository _repo() {
    final auth = context.read<AuthProvider>();
    final demoMode = context.read<DemoModeProvider>();
    return ChatRepository(
      apiClient: auth.repository.apiClient,
      demoMode: demoMode,
    );
  }

  Future<void> _load() async {
    final id = _conversationId;
    if (id == null || id.isEmpty) {
      setState(() {
        _loading = false;
        _error = 'Conversation not found.';
      });
      return;
    }

    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final detail = await _repo().getConversation(id);
      if (!mounted) return;

      final auth = context.read<AuthProvider>();
      final myId = auth.repository.currentUser?.id;
      final chatRt = context.read<ChatRealtimeProvider>();
      _chatRealtime = chatRt;
      await chatRt.start(
        getAccessToken: auth.repository.tokenStorage.getAccessToken,
        userId: myId,
        demoMode: context.read<DemoModeProvider>().enabled,
      );
      attachLiveChatListeners(
        realtime: chatRt,
        conversationId: id,
        myId: myId,
      );

      setState(() {
        chatMessages = List.of(detail.messages);
        _peerName = widget.contactName ?? detail.name;
        _shipmentId = detail.shipmentId;
        _loading = false;
      });
      scrollChatToBottom();
      // Opening the thread marked it read server-side — clear the tab badge now
      // instead of waiting for the next poll.
      if (mounted) {
        context.read<NotificationRealtimeProvider>().refreshChatUnread(
              authRepository: auth.repository,
              demoMode: context.read<DemoModeProvider>(),
              threadType: WalletRole.receiver.chatInboxThreadType,
            );
      }
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
        _error = 'Unable to load conversation.';
      });
    }
  }

  Future<void> _sendApiMessage() async {
    final text = chatController.text.trim();
    final id = _conversationId;
    if (text.isEmpty || id == null) return;

    chatController.clear();
    // Show the message immediately, then reconcile with the server response.
    final tempId = addOptimisticMessage(
      ChatMessage(
        text: text,
        isMine: true,
        time: chatNowTime,
        createdAt: DateTime.now(),
        id: nextLocalMessageId(),
        pending: true,
      ),
    );
    try {
      final message = await _repo().sendMessage(id, text);
      confirmOptimisticMessage(tempId, message);
      scrollChatToBottom();
    } on ApiException catch (e) {
      if (!mounted) return;
      removeOptimisticMessage(tempId);
      chatController.text = text;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.message)),
      );
    } catch (_) {
      if (!mounted) return;
      removeOptimisticMessage(tempId);
      chatController.text = text;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Unable to send message.')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final typo = context.typo;
    final traveler = _peerName;
    final initial = traveler.isNotEmpty ? traveler[0] : '?';

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
            padding: EdgeInsets.fromLTRB(
              context.horizontalPadding,
              0,
              context.horizontalPadding,
              12,
            ),
            color: AppColors.surface,
            child: Text(
              _shipmentId.isEmpty
                  ? 'Traveler ↔ Receiver'
                  : 'Traveler ↔ Receiver · $_shipmentId',
              textAlign: TextAlign.center,
              style: typo.sm,
            ),
          ),
          Expanded(
            child: _loading
                ? const Center(
                    child: SizedBox(
                      width: 22,
                      height: 22,
                      child: CircularProgressIndicator(
                        strokeWidth: 2.5,
                        color: AppColors.primary,
                      ),
                    ),
                  )
                : _error != null
                    ? Center(
                        child: Padding(
                          padding: context.pagePadding,
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                _error!,
                                textAlign: TextAlign.center,
                                style: typo.sm.copyWith(
                                  color: AppColors.textSecondary,
                                ),
                              ),
                              TextButton(
                                onPressed: _load,
                                child: const Text('Retry'),
                              ),
                            ],
                          ),
                        ),
                      )
                    : chatMessages.isEmpty
                        ? const ChatEmptyState()
                        : ListView(
                            controller: chatScrollController,
                            physics: PlatformUi.scrollPhysics,
                            padding: EdgeInsets.fromLTRB(
                              context.horizontalPadding,
                              4,
                              context.horizontalPadding,
                              12,
                            ),
                            children: buildChatThreadChildren(
                              chatMessages,
                              peerInitial: initial,
                            ),
                          ),
          ),
          ChatComposer(
            controller: chatController,
            hintText: 'Message $traveler…',
            onSend: _sendApiMessage,
            onAttach: showChatAttachmentOptions,
            borderRadius: 12,
            circularSendButton: false,
            enabled: !_loading && _error == null && _conversationId != null,
          ),
        ],
      ),
    );
  }
}

class ReceiverTrackingScreen extends StatefulWidget {
  const ReceiverTrackingScreen({super.key, this.shipmentId});

  final String? shipmentId;

  @override
  State<ReceiverTrackingScreen> createState() => _ReceiverTrackingScreenState();
}

class _ReceiverTrackingScreenState extends State<ReceiverTrackingScreen> {
  bool _loading = true;
  String? _error;
  CreatedDelivery? _delivery;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _load();
    });
  }

  DeliveryRepository _repo() {
    final auth = context.read<AuthProvider>();
    final demoMode = context.read<DemoModeProvider>();
    return DeliveryRepository(
      apiClient: auth.repository.apiClient,
      demoMode: demoMode,
    );
  }

  Future<void> _load() async {
    final id = widget.shipmentId;
    if (id == null || id.isEmpty) {
      // Fallback: pick first non-pending active delivery.
      setState(() {
        _loading = true;
        _error = null;
      });
      try {
        final list = await _repo().listDeliveries(role: 'receiver');
        if (!mounted) return;
        CreatedDelivery? pick;
        for (final d in list) {
          final status = ReceiverDeliveryStatus.fromDelivery(d);
          if (!status.isPast && !status.isPendingRequest) {
            pick = d;
            break;
          }
        }
        pick ??= list.isEmpty ? null : list.first;
        if (pick == null) {
          setState(() {
            _loading = false;
            _error = 'No shipments to track.';
          });
          return;
        }
        setState(() {
          _delivery = pick;
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
          _error = 'Unable to load tracking.';
        });
      }
      return;
    }

    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final delivery = await _repo().getDelivery(id, role: 'receiver');
      if (!mounted) return;
      final status = ReceiverDeliveryStatus.fromDelivery(delivery);
      if (status.isPendingRequest) {
        context.go('/receiver-incoming-request/${delivery.displayId}');
        return;
      }
      setState(() {
        _delivery = delivery;
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
        _error = 'Unable to load tracking.';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return Scaffold(
        backgroundColor: AppColors.background,
        appBar: const BackHeader(title: 'Track parcel'),
        body: const Center(
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

    if (_error != null || _delivery == null) {
      return Scaffold(
        backgroundColor: AppColors.background,
        appBar: const BackHeader(title: 'Track parcel'),
        body: Center(
          child: Padding(
            padding: context.pagePadding,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  _error ?? 'Shipment not found.',
                  textAlign: TextAlign.center,
                  style: context.typo.sm.copyWith(color: AppColors.textSecondary),
                ),
                TextButton(onPressed: _load, child: const Text('Retry')),
              ],
            ),
          ),
        ),
      );
    }

    final typo = context.typo;
    final delivery = _delivery!;
    final shipment = delivery.toShipment();
    final tracking = DeliveryTracking.fromDelivery(delivery);
    final status = (delivery.status ?? '').toLowerCase();
    final featuresUnlocked = delivery.isReceiverAccepted ||
        status == 'matched' ||
        status == 'bid_accepted' ||
        status == 'collected' ||
        status == 'in_transit' ||
        status == 'delivered';
    final canConfirmNfcCp2 =
        status == 'in_transit' || status == 'collected';
    // A traveler is only reachable for chat once one has been matched to the
    // parcel. Right after the receiver accepts, none is assigned yet.
    final hasTraveler = (delivery.travelerId?.trim().isNotEmpty ?? false) ||
        status == 'matched' ||
        status == 'bid_accepted' ||
        status == 'collected' ||
        status == 'in_transit' ||
        status == 'delivered';

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
              AppCard(
                margin: EdgeInsets.zero,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (featuresUnlocked) ...[
                      ShipmentTrackingSection(
                        shipment: shipment,
                        stepProgress: tracking.progress,
                        stepLabels: tracking.stepLabels,
                      ),
                      const Padding(
                        padding: EdgeInsets.symmetric(vertical: 20),
                        child: Divider(height: 1),
                      ),
                    ],
                    Text(
                      'Shipment details',
                      style: typo.h3.copyWith(fontWeight: FontWeight.w700),
                    ),
                    const SizedBox(height: 12),
                    _detailRow(
                      context,
                      'Route',
                      delivery.route.isNotEmpty ? delivery.route : shipment.route,
                    ),
                    _detailRow(
                      context,
                      'Travel date',
                      DateFormat('MMM d, yyyy').format(shipment.travelDate),
                    ),
                    _detailRow(
                      context,
                      'Sender',
                      delivery.senderName ?? '—',
                    ),
                    _detailRow(
                      context,
                      'Parcel type',
                      '${shipment.parcelCategory} · ${shipment.parcelWeightKg}kg',
                    ),
                    const SizedBox(height: 16),
                    ShipmentEscrowSection(shipmentId: shipment.id),
                    if (!featuresUnlocked) ...[
                      const SizedBox(height: 8),
                      Text(
                        'Accept the parcel request to unlock tracking, NFC, and chat.',
                        style: typo.sm.copyWith(color: AppColors.textSecondary),
                      ),
                    ],
                  ],
                ),
              ),
              if (canConfirmNfcCp2) ...[
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
                              'NFC Checkpoint 2 — Confirm delivery',
                              style: typo.h3.copyWith(fontWeight: FontWeight.w700),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Meet the traveler and tap phones (or use Simulate tap) to confirm you received the parcel. Both of you must complete NFC Checkpoint 2.',
                        style: typo.sm.copyWith(height: 1.5),
                      ),
                      const SizedBox(height: 16),
                      AppButton(
                        label: 'Confirm delivery (NFC)',
                        icon: const Icon(Icons.nfc, size: 18, color: Colors.white),
                        onPressed: () async {
                          await context.push(
                            '/nfc-confirm',
                            extra: {
                              'shipmentId': delivery.displayId,
                              'isTraveler': false,
                              'checkpoint': 2,
                            },
                          );
                          if (mounted) await _load();
                        },
                      ),
                    ],
                  ),
                ),
              ],
              if (featuresUnlocked) ...[
                const SizedBox(height: 24),
                if (hasTraveler)
                  AppButton(
                    label: 'Chat with traveler',
                    variant: AppButtonVariant.ghost,
                    textStyle: typo.button.copyWith(
                      fontWeight: FontWeight.w700,
                      color: AppColors.primary,
                    ),
                    onPressed: () => openDeliveryChat(
                      context,
                      chatBasePath: '/receiver-chats',
                      threadType: 'traveler_receiver',
                      deliveryKey: delivery.displayId,
                    ),
                  )
                else
                  AppButton(
                    label: 'Waiting for traveler to chat',
                    variant: AppButtonVariant.ghost,
                    icon: const Icon(
                      Icons.hourglass_empty,
                      size: 18,
                      color: AppColors.textDisabled,
                    ),
                    textStyle: typo.button.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                    onPressed: null,
                  ),
                if (status == 'delivered') ...[
                  const SizedBox(height: AppButton.stackGap),
                  AppButton(
                    label: 'Leave a review',
                    onPressed: () => context.push(
                      deliveryReviewRoute(
                        shipmentId: delivery.displayId,
                        reviewerRole: WalletRole.receiver,
                      ),
                    ),
                  ),
                ],
              ],
            ],
          ),
        ),
      ),
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
              textAlign: TextAlign.right,
              style: typo.bodyBold.copyWith(fontWeight: FontWeight.w400),
            ),
          ),
        ],
      ),
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
                  onPressed: () => context.push(
                    deliveryReviewRoute(
                      shipmentId: shipmentId,
                      reviewerRole: WalletRole.receiver,
                    ),
                  ),
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
