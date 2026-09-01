import 'package:flutter/material.dart';
import 'dart:async';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../core/api/api_exception.dart';
import '../../core/config/demo_mode.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_typography.dart';
import '../../core/widgets/back_header.dart';
import '../../core/widgets/back_link.dart';
import '../../core/layout/responsive.dart';
import '../../core/platform/platform_ui.dart';
import '../../data/models/app_notification.dart';
import '../../data/models/wallet_role.dart';
import '../../data/notification_service.dart';
import '../../data/services/notification_repository.dart';
import '../../providers/auth_provider.dart';
import '../../providers/notification_realtime_provider.dart';

class RoleNotificationsScreen extends StatefulWidget {
  const RoleNotificationsScreen({
    super.key,
    required this.role,
    this.useBackLink = false,
    this.fallbackRoute,
  });

  final WalletRole role;
  final bool useBackLink;
  final String? fallbackRoute;

  @override
  State<RoleNotificationsScreen> createState() =>
      _RoleNotificationsScreenState();
}

class _RoleNotificationsScreenState extends State<RoleNotificationsScreen>
    with WidgetsBindingObserver {
  bool _loading = true;
  bool _markingAll = false;
  String? _error;
  List<AppNotification> _apiNotifications = const [];
  String? _lastMatchedLocation;
  Timer? _pollTimer;
  VoidCallback? _realtimeListener;
  NotificationRealtimeProvider? _realtimeProvider;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _load();
    });
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _attachRealtimeListener();
    });
    _pollTimer = Timer.periodic(const Duration(seconds: 20), (_) {
      if (!mounted) return;
      _load(silent: _apiNotifications.isNotEmpty);
    });
  }

  void _attachRealtimeListener() {
    final realtime = context.read<NotificationRealtimeProvider>();
    _realtimeProvider = realtime;

    _realtimeListener ??= () {
      final incoming = realtime.consumeIncoming();
      if (!mounted || incoming.isEmpty) return;
      setState(() {
        for (final notification in incoming.reversed) {
          _apiNotifications.removeWhere((item) => item.id == notification.id);
          _apiNotifications.insert(0, notification);
        }
        _trimInbox();
      });
    };
    realtime.addListener(_realtimeListener!);
  }

  @override
  void dispose() {
    _pollTimer?.cancel();
    if (_realtimeListener != null) {
      _realtimeProvider?.removeListener(_realtimeListener!);
    }
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _load(silent: true);
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final location = GoRouterState.of(context).matchedLocation;
    final isAlerts = location.contains('notifications');
    if (isAlerts && _lastMatchedLocation != location) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _load(silent: _apiNotifications.isNotEmpty);
      });
    }
    _lastMatchedLocation = location;
  }

  void _trimInbox() {
    final keep = NotificationService.inboxLimit;
    if (_apiNotifications.length > keep) {
      _apiNotifications = _apiNotifications.take(keep).toList();
    }
  }

  NotificationRepository _repo() {
    final auth = context.read<AuthProvider>();
    final demoMode = context.read<DemoModeProvider>();
    return NotificationRepository(
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
      final list = await _repo().list(role: widget.role);
      if (!mounted) return;
      setState(() {
        _apiNotifications = list;
        _trimInbox();
        _loading = false;
        _error = null;
      });
      final auth = context.read<AuthProvider>();
      final demoMode = context.read<DemoModeProvider>();
      unawaited(
        context.read<NotificationRealtimeProvider>().refreshUnread(
              role: widget.role,
              authRepository: auth.repository,
              demoMode: demoMode,
            ),
      );
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
        _error = 'Unable to load notifications.';
      });
    }
  }

  Future<void> _markRead(AppNotification n) async {
    if (!n.unread) return;

    setState(() {
      _apiNotifications = _apiNotifications
          .map((item) => item.id == n.id ? item.markRead() : item)
          .toList();
    });
    final realtime = context.read<NotificationRealtimeProvider>();
    realtime.setUnreadCount((realtime.unreadCount - 1).clamp(0, 999));

    try {
      await _repo().markRead(role: widget.role, id: n.id);
      if (!mounted) return;
      final auth = context.read<AuthProvider>();
      final demoMode = context.read<DemoModeProvider>();
      unawaited(
        realtime.refreshUnread(
          role: widget.role,
          authRepository: auth.repository,
          demoMode: demoMode,
        ),
      );
    } catch (_) {}
  }

  Future<void> _markAllRead() async {
    final unread = _apiNotifications.where((n) => n.unread).toList();
    if (unread.isEmpty || _markingAll) return;

    setState(() {
      _markingAll = true;
      _apiNotifications =
          _apiNotifications.map((item) => item.markRead()).toList();
    });
    context.read<NotificationRealtimeProvider>().setUnreadCount(0);

    try {
      await _repo().markAllRead(role: widget.role);
    } catch (_) {
      if (mounted) await _load(silent: true);
    } finally {
      if (mounted) setState(() => _markingAll = false);
    }
  }

  int get _unreadCount =>
      _apiNotifications.where((n) => n.unread).length;

  @override
  Widget build(BuildContext context) {
    final typo = context.typo;
    final role = widget.role;
    final backRoute = widget.fallbackRoute ??
        switch (role) {
          WalletRole.receiver => '/receiver-home',
          WalletRole.traveler => '/traveler-home',
          WalletRole.sender => '/home',
        };

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: widget.useBackLink
          ? null
          : BackHeader(title: 'Notifications', fallbackRoute: backRoute),
      body: SafeArea(
        child: Padding(
          padding: context.pagePadding,
          child: RefreshIndicator(
            color: AppColors.primary,
            onRefresh: () => _load(),
            child: CustomScrollView(
              physics: AlwaysScrollableScrollPhysics(
                parent: PlatformUi.scrollPhysics,
              ),
              slivers: [
                SliverToBoxAdapter(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (widget.useBackLink) ...[
                        BackLink(onTap: () => context.go(backRoute)),
                        const SizedBox(height: 12),
                      ],
                      _InboxHeader(
                        unreadCount: _unreadCount,
                        showTitle: widget.useBackLink,
                        markingAll: _markingAll,
                        onMarkAllRead:
                            _unreadCount > 0 ? _markAllRead : null,
                      ),
                      const SizedBox(height: 16),
                    ],
                  ),
                ),
                ..._buildSlivers(typo),
              ],
            ),
          ),
        ),
      ),
    );
  }

  List<Widget> _buildSlivers(AppTypography typo) {
    if (_loading && _apiNotifications.isEmpty) {
      return [
        const SliverFillRemaining(
          hasScrollBody: false,
          child: Center(
            child: SizedBox(
              width: 28,
              height: 28,
              child: CircularProgressIndicator(
                strokeWidth: 2.5,
                color: AppColors.primary,
              ),
            ),
          ),
        ),
      ];
    }

    if (_error != null && _apiNotifications.isEmpty) {
      return [
        SliverFillRemaining(
          hasScrollBody: false,
          child: _EmptyState(
            icon: Icons.wifi_off_rounded,
            title: 'Couldn’t load alerts',
            subtitle: _error!,
            actionLabel: 'Retry',
            onAction: () => _load(),
          ),
        ),
      ];
    }

    if (_apiNotifications.isEmpty) {
      return [
        const SliverFillEmpty(
          child: _EmptyState(
            icon: Icons.notifications_none_rounded,
            title: 'You’re all caught up',
            subtitle:
                'New delivery updates, bids, and requests will show up here.',
          ),
        ),
      ];
    }

    final unread = _apiNotifications.where((n) => n.unread).toList();
    final read = _apiNotifications.where((n) => !n.unread).toList();

    return [
      if (unread.isNotEmpty) ...[
        SliverToBoxAdapter(
          child: _SectionLabel(
            label: 'New',
            count: unread.length,
          ),
        ),
        SliverList(
          delegate: SliverChildBuilderDelegate(
            (context, index) => _NotificationTile(
              notification: unread[index],
              role: widget.role,
              onOpen: () => _markRead(unread[index]),
            ),
            childCount: unread.length,
          ),
        ),
      ],
      if (read.isNotEmpty) ...[
        SliverToBoxAdapter(
          child: Padding(
            padding: EdgeInsets.only(top: unread.isEmpty ? 0 : 8),
            child: const _SectionLabel(label: 'Earlier'),
          ),
        ),
        SliverList(
          delegate: SliverChildBuilderDelegate(
            (context, index) => _NotificationTile(
              notification: read[index],
              role: widget.role,
              onOpen: () => _markRead(read[index]),
            ),
            childCount: read.length,
          ),
        ),
      ],
      const SliverToBoxAdapter(child: SizedBox(height: 24)),
    ];
  }
}

/// Full-viewport empty / error placeholder inside a CustomScrollView.
class SliverFillEmpty extends StatelessWidget {
  const SliverFillEmpty({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return SliverFillRemaining(
      hasScrollBody: false,
      child: child,
    );
  }
}

class _InboxHeader extends StatelessWidget {
  const _InboxHeader({
    required this.unreadCount,
    required this.showTitle,
    required this.markingAll,
    this.onMarkAllRead,
  });

  final int unreadCount;
  final bool showTitle;
  final bool markingAll;
  final VoidCallback? onMarkAllRead;

  @override
  Widget build(BuildContext context) {
    final typo = context.typo;

    return Container(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppColors.primary.withValues(alpha: 0.10),
            AppColors.kycBackground,
          ],
        ),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.primary.withValues(alpha: 0.12)),
      ),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.14),
              borderRadius: BorderRadius.circular(14),
            ),
            child: const Icon(
              Icons.notifications_active_rounded,
              color: AppColors.primary,
              size: 26,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (showTitle)
                  Text(
                    'Notifications',
                    style: typo.h2.copyWith(fontWeight: FontWeight.w800),
                  )
                else
                  Text(
                    'Your alerts',
                    style: typo.bodyBold.copyWith(fontWeight: FontWeight.w700),
                  ),
                const SizedBox(height: 2),
                Text(
                  unreadCount > 0
                      ? '$unreadCount unread update${unreadCount == 1 ? '' : 's'}'
                      : 'No unread alerts',
                  style: typo.sm.copyWith(color: AppColors.textSecondary),
                ),
              ],
            ),
          ),
          if (onMarkAllRead != null)
            TextButton(
              onPressed: markingAll ? null : onMarkAllRead,
              style: TextButton.styleFrom(
                foregroundColor: AppColors.primary,
                padding: const EdgeInsets.symmetric(horizontal: 8),
              ),
              child: Text(
                markingAll ? '…' : 'Mark all read',
                style: typo.caption.copyWith(
                  color: AppColors.primary,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _SectionLabel extends StatelessWidget {
  const _SectionLabel({required this.label, this.count});

  final String label;
  final int? count;

  @override
  Widget build(BuildContext context) {
    final typo = context.typo;
    return Padding(
      padding: const EdgeInsets.only(bottom: 10, top: 4),
      child: Row(
        children: [
          Text(
            label.toUpperCase(),
            style: typo.caption.copyWith(
              letterSpacing: 0.8,
              fontWeight: FontWeight.w800,
              color: AppColors.textSecondary,
            ),
          ),
          if (count != null) ...[
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(999),
              ),
              child: Text(
                '$count',
                style: typo.caption.copyWith(
                  color: AppColors.primary,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState({
    required this.icon,
    required this.title,
    required this.subtitle,
    this.actionLabel,
    this.onAction,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final String? actionLabel;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) {
    final typo = context.typo;
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 28),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 88,
              height: 88,
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.08),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, size: 42, color: AppColors.primary),
            ),
            const SizedBox(height: 18),
            Text(
              title,
              textAlign: TextAlign.center,
              style: typo.h3.copyWith(fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 8),
            Text(
              subtitle,
              textAlign: TextAlign.center,
              style: typo.sm.copyWith(
                color: AppColors.textSecondary,
                height: 1.45,
              ),
            ),
            if (actionLabel != null && onAction != null) ...[
              const SizedBox(height: 16),
              TextButton(onPressed: onAction, child: Text(actionLabel!)),
            ],
          ],
        ),
      ),
    );
  }
}

class _NotificationTile extends StatelessWidget {
  const _NotificationTile({
    required this.notification,
    required this.role,
    required this.onOpen,
  });

  final AppNotification notification;
  final WalletRole role;
  final VoidCallback onOpen;

  static bool _isShellTabRoute(String route) {
    const shellRoutes = {
      '/home',
      '/track',
      '/sender-chats',
      '/profile',
      '/traveler-home',
      '/traveler-trips',
      '/traveler-chats',
      '/traveler-profile',
      '/receiver-home',
      '/receiver-shipments',
      '/receiver-chats',
      '/receiver-notifications',
      '/receiver-profile',
      '/discover-travelers',
    };
    final path = Uri.tryParse(route)?.path ?? route;
    return shellRoutes.contains(path);
  }

  static bool _showsTypeChip(AppNotification n) {
    if (n.type == AppNotificationType.tripAvailable) return false;
    if (n.type == AppNotificationType.matching) return false;
    if (n.title == 'Receiver accepted') return false;
    final route = n.route ?? '';
    if (route.startsWith('/discover-trips')) return false;
    return true;
  }

  static String _displayTitle(AppNotification n) {
    final route = n.route ?? '';
    if (route.startsWith('/discover-trips') ||
        n.type == AppNotificationType.tripAvailable ||
        n.title == 'New traveler trip on your routes') {
      return 'New Traveler Trip Available';
    }
    if (n.type == AppNotificationType.counterOffer) {
      final lower = n.title.toLowerCase();
      if (lower.contains('accepted')) return n.title;
      if (lower.contains('updated')) return 'Counter offer updated';
      if (lower.contains('new') || lower.contains('sent')) {
        return 'New counter offer';
      }
    }
    return n.title;
  }

  static bool _isTripAvailableNotification(AppNotification n) {
    final route = n.route ?? '';
    return n.type == AppNotificationType.tripAvailable ||
        route.startsWith('/discover-trips') ||
        n.title == 'New traveler trip on your routes' ||
        n.title == 'New Traveler Trip Available';
  }

  static ({String subtitle, String? routeLabel}) _tripBodyParts(
    AppNotification n,
  ) {
    final raw = n.body.trim();
    final lines = raw
        .split('\n')
        .map((line) => line.trim())
        .where((line) => line.isNotEmpty)
        .toList();

    if (lines.length >= 2 &&
        !lines.first.contains('(') &&
        !lines.first.contains('TR-')) {
      return (subtitle: lines.first, routeLabel: lines[1]);
    }

    final legacy = RegExp(
      r'^(.+? posted a (?:city-to-city|country-to-country) trip)'
      r'(?:\s+TR-\d+)?'
      r'\s*\(([^)]+)\)',
      caseSensitive: false,
    ).firstMatch(raw);
    if (legacy != null) {
      return (
        subtitle: legacy.group(1)!.trim(),
        routeLabel: legacy.group(2)!.trim(),
      );
    }

    return (subtitle: raw, routeLabel: null);
  }

  static String _displayBody(AppNotification n) {
    if (n.type == AppNotificationType.parcelRequest ||
        n.title == 'Incoming Parcel Request') {
      return 'A sender wants to send a parcel through you. '
          'Please review the request and accept or decline it.';
    }
    return n.body;
  }

  static ({IconData icon, Color color}) _visualFor(AppNotification n) {
    if (_isTripAvailableNotification(n) ||
        n.title.toLowerCase().contains('matching traveler')) {
      return (icon: Icons.flight_takeoff_rounded, color: AppColors.transit);
    }
    return switch (n.type) {
      AppNotificationType.parcelRequest => (
          icon: Icons.inventory_2_rounded,
          color: AppColors.primary,
        ),
      AppNotificationType.senderRequest => (
          icon: Icons.person_add_alt_1_rounded,
          color: AppColors.primary,
        ),
      AppNotificationType.counterOffer => (
          icon: Icons.local_offer_rounded,
          color: AppColors.warning,
        ),
      AppNotificationType.bid ||
      AppNotificationType.bidAccepted ||
      AppNotificationType.offerAccepted => (
          icon: Icons.check_circle_rounded,
          color: AppColors.success,
        ),
      AppNotificationType.deliveryStatus => (
          icon: Icons.local_shipping_rounded,
          color: AppColors.primary,
        ),
      AppNotificationType.nfcPrompt => (
          icon: Icons.nfc_rounded,
          color: AppColors.darkNavy,
        ),
      AppNotificationType.receiverPayment => (
          icon: Icons.account_balance_wallet_rounded,
          color: AppColors.success,
        ),
      AppNotificationType.cancellation => (
          icon: Icons.cancel_rounded,
          color: AppColors.danger,
        ),
      AppNotificationType.kycUpdate => (
          icon: Icons.verified_user_rounded,
          color: AppColors.primary,
        ),
      AppNotificationType.otp => (
          icon: Icons.lock_rounded,
          color: AppColors.secondary,
        ),
      AppNotificationType.matching || AppNotificationType.tripAvailable => (
          icon: Icons.flight_takeoff_rounded,
          color: AppColors.transit,
        ),
      AppNotificationType.general => (
          icon: Icons.notifications_rounded,
          color: AppColors.primary,
        ),
    };
  }

  void _open(BuildContext context) {
    onOpen();
    final n = notification;
    final rawRoute = n.route?.trim();

    if ((n.type == AppNotificationType.counterOffer ||
            n.type == AppNotificationType.offerAccepted) &&
        role == WalletRole.sender) {
      final path = Uri.tryParse(rawRoute ?? '')?.path ?? rawRoute ?? '';
      if (path.startsWith('/sender-counter-offer')) {
        context.push(rawRoute!);
        return;
      }
      final shipmentMatch = RegExp(r'^/shipment/([^/?#]+)').firstMatch(path);
      if (shipmentMatch != null) {
        final deliveryId = shipmentMatch.group(1)!;
        context.push('/sender-counter-offer?delivery=$deliveryId');
        return;
      }
      if (rawRoute != null && rawRoute.isNotEmpty) {
        context.push(rawRoute);
      }
      return;
    }

    if (rawRoute == null || rawRoute.isEmpty) return;

    if (rawRoute.startsWith('/discover-trips/')) {
      context.push(rawRoute);
      return;
    }

    if (_isShellTabRoute(rawRoute)) {
      context.go(rawRoute);
    } else {
      context.push(rawRoute);
    }
  }

  @override
  Widget build(BuildContext context) {
    final typo = context.typo;
    final n = notification;
    final isTripAlert = _isTripAvailableNotification(n);
    final tripParts = isTripAlert ? _tripBodyParts(n) : null;
    final visual = _visualFor(n);
    final hasRoute = (n.route ?? '').trim().isNotEmpty;

    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Material(
        color: n.unread
            ? AppColors.primary.withValues(alpha: 0.06)
            : AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        child: InkWell(
          onTap: () => _open(context),
          borderRadius: BorderRadius.circular(16),
          child: Container(
            padding: const EdgeInsets.fromLTRB(12, 14, 12, 14),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: n.unread
                    ? AppColors.primary.withValues(alpha: 0.22)
                    : AppColors.border,
              ),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Stack(
                  clipBehavior: Clip.none,
                  children: [
                    Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        color: visual.color.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: Icon(visual.icon, color: visual.color, size: 22),
                    ),
                    if (n.unread)
                      Positioned(
                        right: -2,
                        top: -2,
                        child: Container(
                          width: 10,
                          height: 10,
                          decoration: BoxDecoration(
                            color: AppColors.primary,
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: AppColors.surface,
                              width: 1.5,
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: Text(
                              _displayTitle(n),
                              style: typo.bodyBold.copyWith(
                                fontWeight:
                                    n.unread ? FontWeight.w800 : FontWeight.w600,
                                color: AppColors.textPrimary,
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            n.time,
                            style: typo.caption.copyWith(
                              color: AppColors.textSecondary,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      if (tripParts != null) ...[
                        Text(
                          tripParts.subtitle,
                          style: typo.sm.copyWith(
                            color: AppColors.textSecondary,
                            height: 1.35,
                          ),
                        ),
                        if (tripParts.routeLabel != null) ...[
                          const SizedBox(height: 2),
                          Text(
                            tripParts.routeLabel!,
                            style: typo.sm.copyWith(
                              color: AppColors.textPrimary,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ] else
                        Text(
                          _displayBody(n),
                          maxLines: 3,
                          overflow: TextOverflow.ellipsis,
                          style: typo.sm.copyWith(
                            color: AppColors.textSecondary,
                            height: 1.4,
                          ),
                        ),
                      if (_showsTypeChip(n)) ...[
                        const SizedBox(height: 8),
                        _TypeChip(type: n.type),
                      ],
                    ],
                  ),
                ),
                if (hasRoute) ...[
                  const SizedBox(width: 4),
                  const Padding(
                    padding: EdgeInsets.only(top: 10),
                    child: Icon(
                      Icons.chevron_right_rounded,
                      color: AppColors.textDisabled,
                      size: 22,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _TypeChip extends StatelessWidget {
  const _TypeChip({required this.type});

  final AppNotificationType type;

  @override
  Widget build(BuildContext context) {
    final label = switch (type) {
      AppNotificationType.otp => 'OTP',
      AppNotificationType.kycUpdate => 'KYC',
      AppNotificationType.bid => 'Bid',
      AppNotificationType.bidAccepted => 'Accepted',
      AppNotificationType.offerAccepted => 'Offer Accepted',
      AppNotificationType.counterOffer => 'Counter Offer',
      AppNotificationType.matching => 'Delivery',
      AppNotificationType.tripAvailable => 'Trip',
      AppNotificationType.parcelRequest => 'Request',
      AppNotificationType.senderRequest => 'Request',
      AppNotificationType.receiverPayment => 'Payment',
      AppNotificationType.nfcPrompt => 'NFC',
      AppNotificationType.deliveryStatus => 'Delivery',
      AppNotificationType.cancellation => 'Cancel',
      AppNotificationType.general => 'Alert',
    };
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: AppColors.primary.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        label,
        style: context.typo.caption.copyWith(
          color: AppColors.primary,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}
