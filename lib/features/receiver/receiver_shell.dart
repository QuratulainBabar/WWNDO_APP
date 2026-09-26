import 'dart:async';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../core/config/demo_mode.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_typography.dart';
import '../../core/widgets/app_svg_icon.dart';
import '../../data/models/wallet_role.dart';
import '../../providers/auth_provider.dart';
import '../../providers/chat_realtime_provider.dart';
import '../../providers/notification_realtime_provider.dart';
import '../../l10n/app_localizations.dart';

class ReceiverShell extends StatefulWidget {
  const ReceiverShell({super.key, required this.navigationShell});

  final StatefulNavigationShell navigationShell;

  @override
  State<ReceiverShell> createState() => _ReceiverShellState();
}

class _ReceiverShellState extends State<ReceiverShell>
    with WidgetsBindingObserver {
  Timer? _fallbackPollTimer;
  VoidCallback? _realtimeListener;
  NotificationRealtimeProvider? _realtimeProvider;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      _startRealtime();
      _refreshUnread();
    });
    _fallbackPollTimer = Timer.periodic(const Duration(seconds: 20), (_) {
      if (!mounted) return;
      _refreshUnread();
    });
  }

  @override
  void dispose() {
    _fallbackPollTimer?.cancel();
    final realtime = _realtimeProvider;
    if (_realtimeListener != null && realtime != null) {
      realtime.removeListener(_realtimeListener!);
    }
    realtime?.stop();
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _startRealtime();
      _refreshUnread();
    }
  }

  void _startRealtime() {
    final auth = context.read<AuthProvider>();
    final demoMode = context.read<DemoModeProvider>();
    final realtime = context.read<NotificationRealtimeProvider>();
    _realtimeProvider = realtime;

    if (_realtimeListener == null) {
      _realtimeListener = () {
        if (mounted) setState(() {});
      };
      realtime.addListener(_realtimeListener!);
    }

    realtime.start(
      role: WalletRole.receiver,
      authRepository: auth.repository,
      demoMode: demoMode,
    );
    context.read<ChatRealtimeProvider>().start(
          getAccessToken: auth.repository.tokenStorage.getAccessToken,
          userId: auth.repository.currentUser?.id,
          demoMode: demoMode.enabled,
        );
  }

  Future<void> _refreshUnread() async {
    final demoMode = context.read<DemoModeProvider>();
    final auth = context.read<AuthProvider>();
    final realtime =
        _realtimeProvider ?? context.read<NotificationRealtimeProvider>();
    await realtime.refreshUnread(
      role: WalletRole.receiver,
      authRepository: auth.repository,
      demoMode: demoMode,
    );
    await realtime.refreshChatUnread(
      authRepository: auth.repository,
      demoMode: demoMode,
      threadType: WalletRole.receiver.chatInboxThreadType,
    );
  }

  int get _unreadAlerts =>
      context.watch<NotificationRealtimeProvider>().unreadCount;

  int get _unreadChats =>
      context.watch<NotificationRealtimeProvider>().chatUnreadCount;

  void _onTabTap(int index) {
    widget.navigationShell.goBranch(index, initialLocation: true);
    if (index == 3) {
      Future<void>.delayed(const Duration(milliseconds: 400), _refreshUnread);
    } else {
      _refreshUnread();
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return Scaffold(
      body: widget.navigationShell,
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: AppColors.surface,
          border: Border(top: BorderSide(color: AppColors.border)),
        ),
        child: SafeArea(
          top: false,
          child: SizedBox(
            height: 72,
            child: Row(
              children: [
                _Tab(
                  navigationShell: widget.navigationShell,
                  index: 0,
                  icon: _TabIcon.svg(AppIcons.home),
                  label: l10n.home,
                  onTap: () => _onTabTap(0),
                ),
                _Tab(
                  navigationShell: widget.navigationShell,
                  index: 1,
                  icon: _TabIcon.svg(AppIcons.parcel),
                  label: l10n.shipments,
                  onTap: () => _onTabTap(1),
                ),
                _Tab(
                  navigationShell: widget.navigationShell,
                  index: 2,
                  icon: const _TabIcon.material(Icons.notifications_outlined),
                  label: l10n.alert,
                  badge: _unreadAlerts,
                  onTap: () => _onTabTap(2),
                ),
                _Tab(
                  navigationShell: widget.navigationShell,
                  index: 3,
                  icon: _TabIcon.svg(AppIcons.chat),
                  label: l10n.chat,
                  badge: _unreadChats,
                  onTap: () => _onTabTap(3),
                ),
                _Tab(
                  navigationShell: widget.navigationShell,
                  index: 4,
                  icon: _TabIcon.svg(AppIcons.profile),
                  label: l10n.profile,
                  onTap: () => _onTabTap(4),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _TabIcon {
  const _TabIcon.svg(this.asset) : icon = null;
  const _TabIcon.material(this.icon) : asset = null;

  final String? asset;
  final IconData? icon;
}

class _Tab extends StatelessWidget {
  const _Tab({
    required this.navigationShell,
    required this.index,
    required this.icon,
    required this.label,
    required this.onTap,
    this.badge = 0,
  });

  final StatefulNavigationShell navigationShell;
  final int index;
  final _TabIcon icon;
  final String label;
  final VoidCallback onTap;
  final int badge;

  @override
  Widget build(BuildContext context) {
    final typo = context.typo;
    final active = navigationShell.currentIndex == index;
    final color = active ? AppColors.primary : AppColors.textSecondary;

    return Expanded(
      child: InkWell(
        onTap: onTap,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Stack(
              clipBehavior: Clip.none,
              children: [
                if (icon.asset != null)
                  AppSvgIcon(asset: icon.asset!, size: 22, color: color)
                else
                  Icon(icon.icon, size: 22, color: color),
                if (badge > 0)
                  Positioned(
                    right: -8,
                    top: -4,
                    child: Container(
                      constraints: const BoxConstraints(minWidth: 16),
                      padding: const EdgeInsets.symmetric(horizontal: 4),
                      height: 16,
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
