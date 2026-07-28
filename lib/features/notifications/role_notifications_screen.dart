import 'package:flutter/material.dart';
import 'dart:async';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../core/api/api_exception.dart';
import '../../core/config/demo_mode.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_typography.dart';
import '../../core/widgets/app_card.dart';
import '../../core/widgets/back_header.dart';
import '../../core/widgets/back_link.dart';
import '../../core/widgets/screen_body.dart';
import '../../data/models/app_notification.dart';
import '../../data/models/wallet_role.dart';
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
    _pollTimer = Timer.periodic(const Duration(seconds: 45), (_) {
      if (!mounted) return;
      final connected = _realtimeProvider?.isConnected ?? false;
      if (!connected) {
        _load(silent: _apiNotifications.isNotEmpty);
      }
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

  /// Marks the notification read on open and updates the role unread badge.
  Future<void> _markRead(AppNotification n) async {
    if (!n.unread) return;

    // Optimistic UI: clear unread styling and badge immediately.
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
      // Reconcile badge with server in case of concurrent updates.
      final auth = context.read<AuthProvider>();
      final demoMode = context.read<DemoModeProvider>();
      unawaited(
        realtime.refreshUnread(
          role: widget.role,
          authRepository: auth.repository,
          demoMode: demoMode,
        ),
      );
    } catch (_) {
      // Keep optimistic read state; still navigate even if mark-read fails.
    }
  }

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
      body: ScreenBody(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (widget.useBackLink) ...[
              BackLink(onTap: () => context.go(backRoute)),
              const SizedBox(height: 16),
              Text('Notifications', style: typo.h1),
              const SizedBox(height: 8),
            ],
            Text(
              'Real-time system alerts\nfor your ${role.name} account',
              style: typo.sm,
            ),
            const SizedBox(height: 16),
            _buildApiList(typo),
          ],
        ),
      ),
    );
  }

  Widget _buildApiList(AppTypography typo) {
    if (_loading && _apiNotifications.isEmpty) {
      return const Padding(
        padding: EdgeInsets.only(top: 24),
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

    if (_error != null && _apiNotifications.isEmpty) {
      return Padding(
        padding: const EdgeInsets.only(top: 24),
        child: Column(
          children: [
            Text(
              _error!,
              style: typo.sm.copyWith(color: AppColors.textSecondary),
            ),
            TextButton(onPressed: () => _load(), child: const Text('Retry')),
          ],
        ),
      );
    }

    if (_apiNotifications.isEmpty) {
      return Padding(
        padding: const EdgeInsets.only(top: 24),
        child: Text(
          'No notifications yet.',
          style: typo.sm.copyWith(color: AppColors.textSecondary),
        ),
      );
    }

    return Column(
      children: _apiNotifications
          .map(
            (n) => _NotificationTile(
              notification: n,
              role: widget.role,
              onOpen: () => _markRead(n),
            ),
          )
          .toList(),
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

  /// Trip / receiver-accepted alerts for senders should not show a type badge.
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
    return n.title;
  }

  static bool _isTripAvailableNotification(AppNotification n) {
    final route = n.route ?? '';
    return n.type == AppNotificationType.tripAvailable ||
        route.startsWith('/discover-trips') ||
        n.title == 'New traveler trip on your routes' ||
        n.title == 'New Traveler Trip Available';
  }

  /// Subtitle + route for trip alerts (strips trip ID / date / CTA from older bodies).
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

  @override
  Widget build(BuildContext context) {
    final typo = context.typo;
    final n = notification;
    final isTripAlert = _isTripAvailableNotification(n);
    final tripParts = isTripAlert ? _tripBodyParts(n) : null;

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: GestureDetector(
        onTap: () {
          onOpen();
          final rawRoute = n.route?.trim();
          if (rawRoute == null || rawRoute.isEmpty) return;

          // Trip detail is a stacked page, never a shell tab.
          if (rawRoute.startsWith('/discover-trips/')) {
            context.push(rawRoute);
            return;
          }

          if (_isShellTabRoute(rawRoute)) {
            context.go(rawRoute);
          } else {
            context.push(rawRoute);
          }
        },
        child: AppCard(
          highlighted: n.unread,
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (n.unread)
                Container(
                  width: 8,
                  height: 8,
                  margin: const EdgeInsets.only(top: 6, right: 10),
                  decoration: const BoxDecoration(
                    color: AppColors.primary,
                    shape: BoxShape.circle,
                  ),
                )
              else
                const SizedBox(width: 18),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            _displayTitle(n),
                            style: typo.bodyBold
                                .copyWith(fontWeight: FontWeight.w700),
                          ),
                        ),
                        if (_showsTypeChip(n)) _TypeChip(type: n.type),
                      ],
                    ),
                    const SizedBox(height: 4),
                    if (tripParts != null) ...[
                      Text(tripParts.subtitle, style: typo.sm),
                      if (tripParts.routeLabel != null) ...[
                        const SizedBox(height: 2),
                        Text(tripParts.routeLabel!, style: typo.sm),
                      ],
                    ] else
                      Text(_displayBody(n), style: typo.sm),
                    const SizedBox(height: 6),
                    Text(n.time, style: typo.caption),
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
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
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
