import 'wallet_role.dart';

enum AppNotificationType {
  otp,
  kycUpdate,
  bid,
  bidAccepted,
  offerAccepted,
  counterOffer,
  matching,
  tripAvailable,
  parcelRequest,
  senderRequest,
  receiverPayment,
  platformFee,
  nfcPrompt,
  deliveryStatus,
  cancellation,
  reviewReceived,
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

  /// Whether this notification should trigger a delivery / bid list refresh.
  bool get isDeliveryRelated {
    switch (type) {
      case AppNotificationType.parcelRequest:
      case AppNotificationType.senderRequest:
      case AppNotificationType.counterOffer:
      case AppNotificationType.bid:
      case AppNotificationType.bidAccepted:
      case AppNotificationType.offerAccepted:
      case AppNotificationType.deliveryStatus:
      case AppNotificationType.matching:
      case AppNotificationType.tripAvailable:
      case AppNotificationType.cancellation:
      case AppNotificationType.nfcPrompt:
      case AppNotificationType.receiverPayment:
      case AppNotificationType.platformFee:
        return true;
      default:
        return false;
    }
  }

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
      case 'offerAccepted':
        return AppNotificationType.offerAccepted;
      case 'counterOffer':
        return AppNotificationType.counterOffer;
      case 'matching':
        // Legacy backend type — treat as delivery status so "Matching" badge never shows.
        return AppNotificationType.deliveryStatus;
      case 'tripAvailable':
        return AppNotificationType.tripAvailable;
      case 'parcelRequest':
        return AppNotificationType.parcelRequest;
      case 'senderRequest':
        return AppNotificationType.senderRequest;
      case 'receiverPayment':
        return AppNotificationType.receiverPayment;
      case 'platformFee':
        return AppNotificationType.platformFee;
      case 'nfcPrompt':
        return AppNotificationType.nfcPrompt;
      case 'deliveryStatus':
        return AppNotificationType.deliveryStatus;
      case 'cancellation':
        return AppNotificationType.cancellation;
      case 'reviewReceived':
        return AppNotificationType.reviewReceived;
      default:
        return AppNotificationType.general;
    }
  }
}

/// Back-compat alias used by older screens.
typedef ReceiverNotification = AppNotification;
