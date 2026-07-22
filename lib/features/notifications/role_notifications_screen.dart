import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_typography.dart';
import '../../core/widgets/app_card.dart';
import '../../core/widgets/back_header.dart';
import '../../core/widgets/back_link.dart';
import '../../core/widgets/screen_body.dart';
import '../../data/models/app_notification.dart';
import '../../data/models/wallet_role.dart';
import '../../data/notification_service.dart';

class RoleNotificationsScreen extends StatelessWidget {
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
  Widget build(BuildContext context) {
    final typo = context.typo;
    final backRoute = fallbackRoute ?? switch (role) {
      WalletRole.receiver => '/receiver-home',
      WalletRole.traveler => '/traveler-home',
      WalletRole.sender => '/home',
    };

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: useBackLink
          ? null
          : BackHeader(title: 'Notifications', fallbackRoute: backRoute),
      body: ScreenBody(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (useBackLink) ...[
              BackLink(onTap: () => context.go(backRoute)),
              const SizedBox(height: 16),
              Text('Notifications', style: typo.h1),
              const SizedBox(height: 8),
            ],
            Text(
              'Real-time system alerts for your ${role.name} account',
              style: typo.sm,
            ),
            const SizedBox(height: 16),
            ValueListenableBuilder<int>(
              valueListenable: NotificationService.version,
              builder: (context, _, __) {
                final notifications = NotificationService.inboxFor(role);
                if (notifications.isEmpty) {
                  return Text('No notifications yet.', style: typo.sm);
                }
                return Column(
                  children: notifications
                      .map((n) => _NotificationTile(notification: n, role: role))
                      .toList(),
                );
              },
            ),
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
  });

  final AppNotification notification;
  final WalletRole role;

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
          NotificationService.markRead(role, n.id);
          final route = n.route;
          if (route == null || route.isEmpty) return;
          // Shell tab routes must use go(); push from a root stack causes
          // Navigator GlobalKey conflicts.
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
                            style: typo.bodyBold.copyWith(fontWeight: FontWeight.w700),
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
