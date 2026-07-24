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

  factory AppNotification.fromJson(
    Map<String, dynamic> json, {
    WalletRole? fallbackRole,
  }) {
    return AppNotification(
      id: json['id'] as String? ?? '',
      role: WalletRole.values.firstWhere(
        (r) => r.name == (json['role'] as String?),
        orElse: () => fallbackRole ?? WalletRole.receiver,
      ),
      type: _typeFromApi(json['type'] as String?),
      title: json['title'] as String? ?? '',
      body: json['body'] as String? ?? '',
      time: json['time'] as String? ?? '',
      unread: json['unread'] as bool? ?? true,
      route: json['route'] as String?,
    );
  }

  static AppNotificationType _typeFromApi(String? raw) {
    switch (raw) {
      case 'otp':
        return AppNotificationType.otp;
      case 'kycUpdate':
        return AppNotificationType.kycUpdate;
      case 'bid':
        return AppNotificationType.bid;
      case 'bidAccepted':
        return AppNotificationType.bidAccepted;
      case 'counterOffer':
        return AppNotificationType.counterOffer;
      case 'matching':
        return AppNotificationType.matching;
      case 'parcelRequest':
        return AppNotificationType.parcelRequest;
      case 'receiverPayment':
        return AppNotificationType.receiverPayment;
      case 'nfcPrompt':
        return AppNotificationType.nfcPrompt;
      case 'deliveryStatus':
        return AppNotificationType.deliveryStatus;
      case 'cancellation':
        return AppNotificationType.cancellation;
      default:
        return AppNotificationType.general;
    }
  }
}

/// Back-compat alias used by older screens.
typedef ReceiverNotification = AppNotification;
