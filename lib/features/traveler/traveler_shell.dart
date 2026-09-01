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
import '../../providers/notification_realtime_provider.dart';

class TravelerShell extends StatefulWidget {
  const TravelerShell({super.key, required this.navigationShell});

  final StatefulNavigationShell navigationShell;

  @override
  State<TravelerShell> createState() => _TravelerShellState();
}

class _TravelerShellState extends State<TravelerShell>
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
    _fallbackPollTimer = Timer.periodic(const Duration(seconds: 45), (_) {
      if (!mounted) return;
      final realtime = context.read<NotificationRealtimeProvider>();
      if (!realtime.isConnected) _refreshUnread();
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
      role: WalletRole.traveler,
      authRepository: auth.repository,
      demoMode: demoMode,
    );
  }

  Future<void> _refreshUnread() async {
    final demoMode = context.read<DemoModeProvider>();
    final auth = context.read<AuthProvider>();
    final realtime =
        _realtimeProvider ?? context.read<NotificationRealtimeProvider>();
    await realtime.refreshUnread(
      role: WalletRole.traveler,
      authRepository: auth.repository,
      demoMode: demoMode,
    );
    await realtime.refreshChatUnread(
      authRepository: auth.repository,
      demoMode: demoMode,
    );
  }

  int get _unreadAlerts =>
      context.watch<NotificationRealtimeProvider>().unreadCount;

  int get _unreadChats =>
      context.watch<NotificationRealtimeProvider>().chatUnreadCount;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: widget.navigationShell,
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
                _Tab(
                  navigationShell: widget.navigationShell,
                  index: 0,
                  icon: _TabIcon.svg(AppIcons.home),
                  label: 'Home',
                ),
                _Tab(
                  navigationShell: widget.navigationShell,
                  index: 1,
                  icon: _TabIcon.svg(AppIcons.trips),
                  label: 'Trip',
                ),
                _Tab(
                  navigationShell: widget.navigationShell,
                  index: 2,
                  icon: const _TabIcon.material(Icons.notifications_outlined),
                  label: 'Alert',
                  badge: _unreadAlerts,
                ),
                _Tab(
                  navigationShell: widget.navigationShell,
                  index: 3,
                  icon: _TabIcon.svg(AppIcons.chat),
                  label: 'Chat',
                  badge: _unreadChats,
                ),
                _Tab(
                  navigationShell: widget.navigationShell,
                  index: 4,
                  icon: _TabIcon.svg(AppIcons.profile),
                  label: 'Profile',
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
    this.badge = 0,
  });

  final StatefulNavigationShell navigationShell;
  final int index;
  final _TabIcon icon;
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
                if (icon.asset != null)
                  AppSvgIcon(asset: icon.asset!, size: 22, color: color)
                else
                  Icon(icon.icon, size: 22, color: color),
                if (badge > 0)
                  Positioned(
                    right: -10,
                    top: -6,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 5,
                        vertical: 1,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.danger,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        badge > 99 ? '99+' : '$badge',
                        style: typo.caption.copyWith(
                          color: Colors.white,
                          fontWeight: FontWeight.w700,
                          fontSize: 10,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: typo.caption.copyWith(
                color: color,
                fontWeight: active ? FontWeight.w700 : FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
