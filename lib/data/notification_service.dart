import 'package:flutter/foundation.dart';

import 'models/app_notification.dart';
import 'models/wallet_role.dart';

/// Role-aware in-app notification inbox (static demo layer).
abstract final class NotificationService {
  static final version = ValueNotifier(0);


  

  static final Map<WalletRole, List<AppNotification>> _inbox = {
    WalletRole.sender: [],
    WalletRole.traveler: [],
    WalletRole.receiver: [],
  };

  /// Bump when demo inbox contents change so hot reload picks up removals.
  static const _seedGeneration = 8;
  static int _appliedSeedGeneration = 0;

  /// Newest notifications kept per role; older items are dropped from the bottom.
  static const inboxLimit = 20;

  static void seedDemoInbox() {
    if (_appliedSeedGeneration == _seedGeneration) return;
    _appliedSeedGeneration = _seedGeneration;

    // Sender notifications come from the backend API — no demo seed.
    _inbox[WalletRole.sender] = [];

    _inbox[WalletRole.traveler] = [];

    _inbox[WalletRole.receiver] = [];
    version.value++;
  }

  static List<AppNotification> inboxFor(WalletRole role) {
    seedDemoInbox();
    final list = _inbox[role] ?? const <AppNotification>[];
    if (list.length > inboxLimit) {
      return List<AppNotification>.unmodifiable(list.take(inboxLimit));
    }
    return List<AppNotification>.unmodifiable(list);
  }

  static int unreadCount(WalletRole role) =>
      inboxFor(role).where((n) => n.unread).length;

  static void push(AppNotification notification) {
    seedDemoInbox();
    final list = _inbox[notification.role]!;
    list.insert(0, notification);
    if (list.length > inboxLimit) {
      list.removeRange(inboxLimit, list.length);
    }
    version.value++;
  }

  static void pushToRoles({
    required Iterable<WalletRole> roles,
    required AppNotificationType type,
    required String title,
    required String body,
    String? route,
  }) {
    final id = 'ntf-${DateTime.now().microsecondsSinceEpoch}';
    for (final role in roles) {
      push(
        AppNotification(
          id: '$id-${role.name}',
          role: role,
          type: type,
          title: title,
          body: body,
          time: 'Just now',
          route: route,
        ),
      );
    }
  }

  static void markRead(WalletRole role, String id) {
    seedDemoInbox();
    final list = _inbox[role]!;
    final index = list.indexWhere((n) => n.id == id);
    if (index < 0) return;
    list[index] = list[index].markRead();
    version.value++;
  }

  static void markAllRead(WalletRole role) {
    seedDemoInbox();
    final list = _inbox[role]!;
    for (var i = 0; i < list.length; i++) {
      if (list[i].unread) list[i] = list[i].markRead();
    }
    version.value++;
  }

  static void notifyPasswordResetOtp({
    required String maskedContact,
  }) {
    pushToRoles(
      roles: WalletRole.values,
      type: AppNotificationType.otp,
      title: 'Password reset code sent',
      body: 'A verification code was sent to $maskedContact.',
      route: '/forgot-password',
    );
  }

  static void notifyKycApproved() {
    pushToRoles(
      roles: [WalletRole.sender, WalletRole.traveler, WalletRole.receiver],
      type: AppNotificationType.kycUpdate,
      title: 'Identity verified',
      body: 'Your KYC was approved. You can now use all WWNGO features.',
      route: '/kyc-status',
    );
  }

  static void notifyKycRejected({String? reason}) {
    final detail = reason?.trim();
    pushToRoles(
      roles: [WalletRole.sender, WalletRole.traveler, WalletRole.receiver],
      type: AppNotificationType.kycUpdate,
      title: 'Verification failed',
      body: detail == null || detail.isEmpty
          ? 'Your ID could not be verified. Please resubmit your documents.'
          : detail,
      route: '/kyc',
    );
  }
}
