import 'package:flutter/material.dart';
import 'dart:async';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../core/auth/selected_role.dart';
import '../../core/config/demo_mode.dart';
import '../../core/theme/app_typography.dart';
import '../../core/theme/app_colors.dart';
import '../../core/layout/responsive.dart';
import '../../core/widgets/app_badge.dart';
import '../../core/widgets/app_card.dart';
import '../../core/widgets/app_svg_icon.dart';
import '../../core/widgets/back_link.dart';
import '../../core/widgets/screen_body.dart';
import '../../core/widgets/wallet_card.dart';
import '../../data/models/created_delivery.dart';
import '../../data/models/shipment.dart';
import '../../data/models/wallet_role.dart';
import '../../core/auth/auth_verification_guard.dart';
import '../../core/auth/kyc_verification_guard.dart';
import '../../providers/auth_provider.dart';
import '../../providers/chat_realtime_provider.dart';
import '../../providers/notification_realtime_provider.dart';
import '../../providers/sender_deliveries_provider.dart';
import '../../providers/wallet_provider.dart';
import '../sender/delivery_posting_actions.dart';
import '../sender/sender_delivery_status.dart';

class MainShell extends StatelessWidget {
  const MainShell({super.key, required this.navigationShell});

  final StatefulNavigationShell navigationShell;

  @override
  Widget build(BuildContext context) {
    final unreadChats =
        context.watch<NotificationRealtimeProvider>().chatUnreadCount;
    final unreadAlerts =
        context.watch<NotificationRealtimeProvider>().unreadCount;
    return Scaffold(
      body: navigationShell,
      bottomNavigationBar: Container(
        decoration: const BoxDecoration(
          color: AppColors.surface,
          border: Border(top: BorderSide(color: AppColors.border)),
        ),
        child: SafeArea(
          top: false,
          child: SizedBox(
            height: 72,
            child: Row(
              children: [
                _Tab(navigationShell: navigationShell, index: 0, iconAsset: AppIcons.home, label: 'Home'),
                _Tab(navigationShell: navigationShell, index: 1, iconAsset: AppIcons.track, label: 'Track'),
                _Tab(navigationShell: navigationShell, index: 2, iconAsset: AppIcons.notification, label: 'Alert', badge: unreadAlerts),
                _Tab(navigationShell: navigationShell, index: 3, iconAsset: AppIcons.chat, label: 'Chat', badge: unreadChats),
                _Tab(navigationShell: navigationShell, index: 4, iconAsset: AppIcons.profile, label: 'Profile'),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _Tab extends StatelessWidget {
  const _Tab({
    required this.navigationShell,
    required this.index,
    required this.iconAsset,
    required this.label,
    this.badge = 0,
  });

  final StatefulNavigationShell navigationShell;
  final int index;
  final String iconAsset;
  final String label;
  final int badge;

  @override
  Widget build(BuildContext context) {
    final typo = context.typo;
    final active = navigationShell.currentIndex == index;
    final color = active ? AppColors.primary : AppColors.textSecondary;
    return Expanded(
      child: InkWell(
        onTap: () => navigationShell.goBranch(index, initialLocation: true),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Stack(
              clipBehavior: Clip.none,
              children: [
                AppSvgIcon(asset: iconAsset, size: 22, color: color),
                if (badge > 0)
                  Positioned(
                    right: -8,
                    top: -4,
                    child: Container(
                      constraints: const BoxConstraints(minWidth: 16),
                      height: 16,
                      padding: const EdgeInsets.symmetric(horizontal: 4),
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: AppColors.danger,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        badge > 99 ? '99+' : '$badge',
                        style: typo.caption.copyWith(
                          color: Colors.white,
                          fontSize: 9,
                          fontWeight: FontWeight.w700,
                          height: 1,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 3),
            Text(
              label,
              style: typo.tabLabelActive(color),
            ),
          ],
        ),
      ),
    );
  }
}

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with WidgetsBindingObserver {
  String? _lastMatchedLocation;
  Timer? _notificationPollTimer;
  VoidCallback? _realtimeListener;
  NotificationRealtimeProvider? _realtimeProvider;
  int _lastDeliveryUpdateTick = 0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      context.read<AuthProvider>().refreshUser();
      _startNotificationRealtime();
      _attachRealtimeListener();
      _loadUnreadNotifications();
      _loadActiveDeliveries(silent: false);
    });
    _notificationPollTimer = Timer.periodic(const Duration(seconds: 20), (_) {
      if (!mounted) return;
      _loadUnreadNotifications();
      _loadActiveDeliveries(silent: true);
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final location = GoRouterState.of(context).matchedLocation;
    if (location == '/home' && _lastMatchedLocation != '/home') {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          _loadActiveDeliveries(
            silent: context.read<SenderDeliveriesProvider>().activeDeliveries.isNotEmpty,
          );
          _loadUnreadNotifications();
        }
      });
    }
    _lastMatchedLocation = location;
  }

  @override
  void dispose() {
    _notificationPollTimer?.cancel();
    if (_realtimeListener != null) {
      _realtimeProvider?.removeListener(_realtimeListener!);
    }
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _loadActiveDeliveries(silent: true);
      _startNotificationRealtime();
      _attachRealtimeListener();
      _loadUnreadNotifications();
    }
  }

  void _startNotificationRealtime() {
    final auth = context.read<AuthProvider>();
    final demoMode = context.read<DemoModeProvider>();
    context.read<NotificationRealtimeProvider>().start(
          role: WalletRole.sender,
          authRepository: auth.repository,
          demoMode: demoMode,
        );
    context.read<ChatRealtimeProvider>().start(
          getAccessToken: auth.repository.tokenStorage.getAccessToken,
          userId: auth.repository.currentUser?.id,
          demoMode: demoMode.enabled,
        );
  }

  void _attachRealtimeListener() {
    final realtime = context.read<NotificationRealtimeProvider>();
    if (_realtimeProvider == realtime && _realtimeListener != null) {
      // Do not sync tick forward here — that would drop in-flight create bumps.
      return;
    }
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
        _loadActiveDeliveries(
          silent: context.read<SenderDeliveriesProvider>().activeDeliveries.isNotEmpty,
        );
      }
    };
    realtime.addListener(_realtimeListener!);
  }

  Future<void> _loadUnreadNotifications() async {
    final auth = context.read<AuthProvider>();
    final demoMode = context.read<DemoModeProvider>();
    final realtime = context.read<NotificationRealtimeProvider>();
    try {
      await realtime.refreshUnread(
            role: WalletRole.sender,
            authRepository: auth.repository,
            demoMode: demoMode,
          );
      await realtime.refreshChatUnread(
            authRepository: auth.repository,
            demoMode: demoMode,
          );
    } catch (_) {
      // Badge is non-critical; keep last known count.
    }
  }

  Future<void> _loadActiveDeliveries({bool silent = false}) async {
    final auth = context.read<AuthProvider>();
    final demoMode = context.read<DemoModeProvider>();
    await context.read<SenderDeliveriesProvider>().refresh(
          authRepository: auth.repository,
          demoMode: demoMode,
          silent: silent,
        );
  }

  Future<void> _onPullRefresh() async {
    await Future.wait([
      context.read<AuthProvider>().refreshUser(),
      _loadActiveDeliveries(silent: true),
      _loadUnreadNotifications(),
      context.read<WalletProvider>().refresh(WalletRole.sender, silent: true),
    ]);
  }

  Widget _activeDeliveriesSection(BuildContext context) {
    final typo = context.typo;
    final provider = context.watch<SenderDeliveriesProvider>();
    final activeItems = provider.activeDeliveries;
    final activeLoading = provider.loading;
    final activeError = provider.error;
    final matchingTravelerCounts = provider.matchingTravelerCounts;

    if (activeLoading && activeItems.isEmpty) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 12),
        child: Center(
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

    if (activeError != null && activeItems.isEmpty) {
      return AppCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              activeError,
              style: typo.sm.copyWith(color: AppColors.textSecondary),
            ),
            const SizedBox(height: 8),
            TextButton(
              onPressed: () => _loadActiveDeliveries(),
              child: const Text('Retry'),
            ),
          ],
        ),
      );
    }

    if (activeItems.isEmpty) {
      return AppCard(
        child: Text(
          'No active deliveries yet.',
          style: typo.sm.copyWith(color: AppColors.textSecondary),
        ),
      );
    }

    return Column(
      children: [
        for (var i = 0; i < activeItems.length; i++) ...[
          if (i > 0) const SizedBox(height: 8),
          _activeDeliveryCard(
            context,
            activeItems[i],
            matchingTravelerCounts,
            provider,
          ),
        ],
      ],
    );
  }

  Widget _activeDeliveryCard(
    BuildContext context,
    CreatedDelivery delivery,
    Map<String, int> matchingTravelerCounts,
    SenderDeliveriesProvider provider,
  ) {
    final typo = context.typo;
    final status = SenderDeliveryStatus.fromDelivery(
      delivery,
      matchingTravelerCount: SenderDeliveryStatus.countFromMap(
        delivery,
        matchingTravelerCounts,
      ),
      travelerRequests: provider.travelerRequestsFor(delivery),
      postedPhase: provider.postedPhaseFor(delivery),
    );
    final phase = provider.postedPhaseFor(delivery);
    final idLabel =
        delivery.publicId.isNotEmpty ? delivery.publicId : delivery.id;

    Future<void> openMatchingTravelers() async {
      await context.push('/bid-requests/${delivery.displayId}');
      if (mounted) _loadActiveDeliveries(silent: true);
    }

    Future<void> openPostedDeliveries() async {
      await context.push('/my-posted-parcels');
      if (mounted) _loadActiveDeliveries(silent: true);
    }

    final matchingTravelers = phase == SenderPostedPhase.matchingTravelers ||
        status.label.startsWith('Matching Travelers');

    return GestureDetector(
      onTap: matchingTravelers ? openMatchingTravelers : openPostedDeliveries,
      child: AppCard(
        margin: EdgeInsets.zero,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Flexible(
                  child: Text(
                    idLabel,
                    style: typo.h3.copyWith(fontWeight: FontWeight.w700),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                const SizedBox(width: 8),
                GestureDetector(
                  onTap: matchingTravelers
                      ? openMatchingTravelers
                      : openPostedDeliveries,
                  child: AppBadge(
                    label: status.label,
                    color: status.color,
                    backgroundColor: status.backgroundColor,
                    semiBold: true,
                    wide: true,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              delivery.route.isNotEmpty ? delivery.route : '—',
              style: typo.sm,
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final typo = context.typo;
    final authUser = context.watch<AuthProvider>().user;
    final unreadNotifications =
        context.watch<NotificationRealtimeProvider>().unreadCount;
    final firstName = (authUser?.firstName.trim().isNotEmpty ?? false)
        ? authUser!.firstName
        : 'there';

    return Scaffold(
      backgroundColor: AppColors.background,
      body: ScreenBody(
        onRefresh: _onPullRefresh,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            BackLink(onTap: () => context.go('/role-selection')),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Flexible(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Hey, $firstName 👋', style: typo.h1, overflow: TextOverflow.ellipsis),
                      Text(
                        SelectedRoleStore.homeRatingSubtitle(
                          authUser,
                          WalletRole.sender,
                        ),
                        style: typo.sm,
                      ),
                    ],
                  ),
                ),
                WalletCard(role: WalletRole.sender),
              ],
            ),
            const SizedBox(height: 24),
            GestureDetector(
              onTap: () async {
                // Wallet balance gate first — must not be masked by auth/KYC dialogs.
                if (!await DeliveryPostingActions.ensureWalletAllowsParcelCreation(context)) return;
                if (!AuthVerificationGuard.ensureVerifiedForTransaction(context)) return;
                if (!KycVerificationGuard.ensureKycApproved(context)) return;
                await context.push('/delivery-type');
                if (mounted) _loadActiveDeliveries(silent: true);
              },
              child: Container(
              padding: const EdgeInsets.fromLTRB(18, 16, 12, 16),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: AppColors.border, width: 1.5),
                boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 8, offset: const Offset(0, 2))],
              ),
              child: Row(
                children: [
                  Expanded(child: Text('Where does your parcel need to go?', style: typo.searchHint)),
                  Container(
                    width: 32,
                    height: 32,
                    decoration: BoxDecoration(
                      color: AppColors.primary,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    alignment: Alignment.center,
                    child: Text('→', style: typo.body.copyWith(color: Colors.white, fontWeight: FontWeight.w700)),
                  ),
                ],
              ),
            ),
            ),
            const SizedBox(height: 24),
            Text('Quick actions', style: typo.h3.copyWith(fontWeight: FontWeight.w700)),
            const SizedBox(height: 12),
            _menuLink(
              context,
              iconAsset: AppIcons.parcel,
              title: 'Create Delivery',
              subtitle: 'Post a new delivery request.',
              route: '/delivery-type',
              requireVerification: true,
              requireWalletBalance: true,
            ),
            _menuLink(
              context,
              iconAsset: AppIcons.postedParcels,
              title: 'My Posted Deliveries',
              subtitle: 'View all deliveries you have posted.',
              route: '/my-posted-parcels',
            ),
            _menuLink(
              context,
              iconAsset: AppIcons.notification,
              title: 'Notifications',
              subtitle: 'View delivery updates and important alerts.',
              route: '/sender-notifications',
              badge: unreadNotifications,
              refreshUnreadOnReturn: true,
            ),
            SizedBox(height: context.blockGap),
            Text('Active deliveries', style: typo.h3.copyWith(fontWeight: FontWeight.w700)),
            const SizedBox(height: 12),
            _activeDeliveriesSection(context),
          ],
        ),
      ),
    );
  }


  Widget _menuLink(
    BuildContext context, {
    String? iconAsset,
    IconData? icon,
    required String title,
    required String subtitle,
    required String route,
    int badge = 0,
    bool refreshUnreadOnReturn = false,
    bool requireVerification = false,
    bool requireWalletBalance = false,
  }) {
    final typo = context.typo;
    return _menuLinkBody(
      context,
      typo: typo,
      iconAsset: iconAsset,
      icon: icon,
      title: title,
      subtitle: subtitle,
      route: route,
      badge: badge,
      refreshUnreadOnReturn: refreshUnreadOnReturn,
      requireVerification: requireVerification,
      requireWalletBalance: requireWalletBalance,
    );
  }

  Widget _menuLinkBody(
    BuildContext context, {
    required AppTypography typo,
    String? iconAsset,
    IconData? icon,
    required String title,
    required String subtitle,
    required String route,
    int badge = 0,
    bool refreshUnreadOnReturn = false,
    bool requireVerification = false,
    bool requireWalletBalance = false,
  }) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 10),
      child: Material(
        color: AppColors.surface,
        clipBehavior: Clip.antiAlias,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(14),
          side: const BorderSide(color: AppColors.border),
        ),
        child: InkWell(
          onTap: () async {
            if (requireWalletBalance &&
                !await DeliveryPostingActions.ensureWalletAllowsParcelCreation(context)) {
              return;
            }
            if (requireVerification && !AuthVerificationGuard.ensureVerifiedForTransaction(context)) {
              return;
            }
            if (requireVerification && !KycVerificationGuard.ensureKycApproved(context)) {
              return;
            }
            await context.push(route);
            if (!mounted) return;
            _loadActiveDeliveries(silent: true);
            if (refreshUnreadOnReturn) _loadUnreadNotifications();
          },
          hoverColor: Colors.transparent,
          splashColor: Colors.transparent,
          highlightColor: Colors.transparent,
          splashFactory: NoSplash.splashFactory,
          overlayColor: const WidgetStatePropertyAll(Colors.transparent),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                if (iconAsset != null)
                  AppSvgIcon(asset: iconAsset, size: 28)
                else
                  Icon(icon, size: 28, color: AppColors.textPrimary),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(title, style: typo.bodyBold.copyWith(fontWeight: FontWeight.w700)),
                      const SizedBox(height: 2),
                      Text(subtitle, style: typo.sm),
                    ],
                  ),
                ),
                if (badge > 0) ...[
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: AppColors.primary,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(
                      '$badge',
                      style: typo.caption.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                ],
                const Icon(Icons.chevron_right_rounded, size: 22, color: AppColors.textSecondary),
              ],
            ),
          ),
        ),
      ),
    );
  }

}
