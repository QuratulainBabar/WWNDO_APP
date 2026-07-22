import 'wallet_role.dart';

enum AppNotificationType {
  otp,
  kycUpdate,
  bid,
  bidAccepted,
  counterOffer,
  matching,
  parcelRequest,
  receiverPayment,
  nfcPrompt,
  deliveryStatus,
  cancellation,
  general,
}

class AppNotification {
  const AppNotification({
    required this.id,
    required this.role,
    required this.type,
    required this.title,
    required this.body,
    required this.time,
    this.unread = true,
    this.route,
  });

  final String id;
  final WalletRole role;
  final AppNotificationType type;
  final String title;
  final String body;
  final String time;
  final bool unread;
  final String? route;

  AppNotification markRead() => AppNotification(
        id: id,
        role: role,
        type: type,
        title: title,
        body: body,
        time: time,
        unread: false,
        route: route,
      );
}

/// Back-compat alias used by older screens.
typedef ReceiverNotification = AppNotification;
