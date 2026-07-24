import 'package:flutter/material.dart';
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
import '../../data/notification_service.dart';
import '../../data/services/notification_repository.dart';
import '../../providers/auth_provider.dart';

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

  bool get _useApi =>
      widget.role == WalletRole.receiver || widget.role == WalletRole.sender;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _load();
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed && _useApi) {
      _load(silent: true);
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_useApi) return;
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
    if (!_useApi) {
      setState(() {
        _loading = false;
        _error = null;
      });
      return;
    }

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
    if (_useApi) {
      try {
        await _repo().markRead(role: widget.role, id: n.id);
        if (!mounted) return;
        setState(() {
          _apiNotifications = _apiNotifications
              .map((item) => item.id == n.id ? item.markRead() : item)
              .toList();
        });
      } catch (_) {
        // Still navigate even if mark-read fails.
      }
    } else {
      NotificationService.markRead(widget.role, n.id);
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
            if (_useApi)
              _buildApiList(typo)
            else
              ValueListenableBuilder<int>(
                valueListenable: NotificationService.version,
                builder: (context, _, __) {
                  final notifications = NotificationService.inboxFor(role);
                  if (notifications.isEmpty) {
                    return Padding(
                      padding: const EdgeInsets.only(top: 24),
                      child: Text(
                        'No notifications yet.',
                        style: typo.sm.copyWith(color: AppColors.textSecondary),
                      ),
                    );
                  }
                  return Column(
                    children: notifications
                        .map(
                          (n) => _NotificationTile(
                            notification: n,
                            role: role,
                            onOpen: () => _markRead(n),
                          ),
                        )
                        .toList(),
                  );
                },
              ),
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
    };
    final path = Uri.tryParse(route)?.path ?? route;
    return shellRoutes.contains(path);
  }

  @override
  Widget build(BuildContext context) {
    final typo = context.typo;
    final n = notification;

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: GestureDetector(
        onTap: () {
          onOpen();
          final route = n.route;
          if (route == null || route.isEmpty) return;
          if (_isShellTabRoute(route)) {
            context.go(route);
          } else {
            context.push(route);
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
                            n.title,
                            style: typo.bodyBold
                                .copyWith(fontWeight: FontWeight.w700),
                          ),
                        ),
                        _TypeChip(type: n.type),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(n.body, style: typo.sm),
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
      AppNotificationType.matching => 'Matching',
      AppNotificationType.parcelRequest => 'Request',
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
