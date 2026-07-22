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
  static const _seedGeneration = 5;
  static int _appliedSeedGeneration = 0;

  /// Traveler Alerts tab shows a short demo inbox only.
  static const _travelerInboxLimit = 2;

  static void seedDemoInbox() {
    if (_appliedSeedGeneration == _seedGeneration) return;
    _appliedSeedGeneration = _seedGeneration;

    _inbox[WalletRole.sender] = [
      AppNotification(
        id: 'snd-seed-final-budget',
        role: WalletRole.sender,
        type: AppNotificationType.counterOffer,
        title: 'Traveler sent the final budget.',
        body:
            'Ama Serwaa proposed a final budget for WW-35102. Review parcel details to accept.',
        time: 'Just now',
        route: '/shipment/WW-35102',
      ),
      AppNotification(
        id: 'snd-seed-1',
        role: WalletRole.sender,
        type: AppNotificationType.matching,
        title: 'Matching travelers ready',
        body: 'Receiver accepted WW-27490. View matching travelers for Dubai → Casablanca.',
        time: '1h ago',
        route: '/bid-requests/WW-27490',
      ),
      AppNotification(
        id: 'snd-seed-2',
        role: WalletRole.sender,
        type: AppNotificationType.deliveryStatus,
        title: 'Traveler accepted delivery',
        body: 'Aissatou D. will carry WW-48291 on AF718.',
        time: 'Yesterday',
        route: '/shipment/WW-48291',
      ),
    ];

    _inbox[WalletRole.traveler] = [
      AppNotification(
        id: 'trv-seed-1',
        role: WalletRole.traveler,
        type: AppNotificationType.bidAccepted,
        title: 'Bid accepted',
        body: 'Your bid on WW-48291 was accepted by the sender.',
        time: 'Yesterday',
        route: '/traveler-bids',
      ),
      AppNotification(
        id: 'trv-seed-3',
        role: WalletRole.traveler,
        type: AppNotificationType.deliveryStatus,
        title: 'Traveler selected',
        body: 'You are selected for WW-48291 (Paris → Dakar). Await sender NFC handoff.',
        time: 'Jun 10',
        unread: false,
        route: '/traveler-deliveries',
      ),
    ];

    _inbox[WalletRole.receiver] = [
      AppNotification(
        id: 'rcv-seed-2',
        role: WalletRole.receiver,
        type: AppNotificationType.parcelRequest,
        title: 'Incoming Parcel Request',
        body:
            'A sender has requested to send you a parcel. Please review the parcel details and accept or decline the request.',
        time: 'Just now',
        route: '/receiver-incoming-request/WW-61050',
      ),
      AppNotification(
        id: 'rcv-seed-1',
        role: WalletRole.receiver,
        type: AppNotificationType.deliveryStatus,
        title: 'Traveler selected',
        body: 'Aissatou D. is booked for WW-48291 (Paris → Dakar). Tracking updates will follow.',
        time: '2h ago',
        unread: false,
        route: '/receiver-tracking?shipmentId=WW-48291',
      ),
    ];
    version.value++;
  }

  static List<AppNotification> inboxFor(WalletRole role) {
    seedDemoInbox();
    final list = _inbox[role] ?? const <AppNotification>[];
    if (role == WalletRole.traveler && list.length > _travelerInboxLimit) {
      return List<AppNotification>.unmodifiable(
        list.take(_travelerInboxLimit),
      );
    }
    return List<AppNotification>.unmodifiable(list);
  }

  static int unreadCount(WalletRole role) =>
      inboxFor(role).where((n) => n.unread).length;

  static void push(AppNotification notification) {
    seedDemoInbox();
    final list = _inbox[notification.role]!;
    list.insert(0, notification);
    if (notification.role == WalletRole.traveler &&
        list.length > _travelerInboxLimit) {
      list.removeRange(_travelerInboxLimit, list.length);
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
    required String otpCode,
  }) {
    pushToRoles(
      roles: WalletRole.values,
      type: AppNotificationType.otp,
      title: 'Password reset code sent',
      body: 'Demo OTP $otpCode was sent to $maskedContact.',
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
