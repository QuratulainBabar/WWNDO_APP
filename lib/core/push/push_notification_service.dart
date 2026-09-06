import 'dart:io';

import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

import '../../firebase_options.dart';
import '../../data/services/auth_repository.dart';
import '../../router/app_router.dart';
import '../navigation/app_navigation.dart';
import 'push_notification_banner.dart';

/// Android channel id — must match AndroidManifest meta-data.
const String kPushChannelId = 'wwngo_alerts';
const String kPushChannelName = 'WWNGO Alerts';

final FlutterLocalNotificationsPlugin _localNotifications =
    FlutterLocalNotificationsPlugin();

const AndroidNotificationChannel _androidChannel = AndroidNotificationChannel(
  kPushChannelId,
  kPushChannelName,
  description: 'Delivery updates, bids, and account alerts',
  importance: Importance.max,
  playSound: true,
  enableVibration: true,
);

/// Background FCM handler (must be top-level).
@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  if (!DefaultFirebaseOptions.isConfigured) return;
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  // When the payload includes a notification block, Android/iOS already show
  // a system tray alert — skip our local duplicate.
  if (message.notification != null) return;
  await _ensureLocalNotificationsReady();
  await _showLocalNotification(message);
}

/// Registers the device FCM token with the WWNGO backend after login.
abstract final class PushNotificationService {
  static bool _initialized = false;
  static String? _lastRegisteredToken;

  /// Invoked when a chat-message push arrives while the app is foregrounded, so
  /// listeners can refresh the badge and any open matching thread.
  /// [conversationId] comes from the push data when present.
  static void Function(String? conversationId)? onForegroundChatMessage;

  /// When true, skip the in-app banner for this chat push (thread already open).
  static bool Function(String? conversationId)? shouldSuppressChatBanner;

  /// Invoked for delivery-related pushes (status, NFC, cancel, etc.) while the
  /// app is foregrounded so open tracking screens can reload immediately.
  static void Function(String? type)? onForegroundDeliveryRelated;

  static Future<void> initialize() async {
    if (_initialized) return;
    if (!DefaultFirebaseOptions.isConfigured) {
      if (kDebugMode) {
        debugPrint(
          '[Push] Firebase client not configured — add keys to lib/firebase_options.dart',
        );
      }
      return;
    }

    try {
      await Firebase.initializeApp(
        options: DefaultFirebaseOptions.currentPlatform,
      );
      FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);

      await _ensureLocalNotificationsReady();
      await _requestNotificationPermission();

      FirebaseMessaging.onMessage.listen(_handleForegroundMessage);
      FirebaseMessaging.onMessageOpenedApp.listen(_navigateFromMessage);

      final initialMessage = await FirebaseMessaging.instance.getInitialMessage();
      if (initialMessage != null) {
        _navigateFromMessage(initialMessage);
      }

      FirebaseMessaging.instance.onTokenRefresh.listen((token) {
        _lastRegisteredToken = null;
      });

      await FirebaseMessaging.instance.setAutoInitEnabled(true);
      _initialized = true;
      if (kDebugMode) {
        debugPrint('[Push] Firebase initialized');
      }
    } catch (e, st) {
      if (kDebugMode) {
        debugPrint('[Push] init failed: $e\n$st');
      }
    }
  }

  static Future<void> registerIfAuthenticated(AuthRepository repository) async {
    if (!_initialized) {
      if (kDebugMode) {
        debugPrint('[Push] skip register — Firebase not initialized');
      }
      return;
    }
    if (repository.currentUser == null) {
      if (kDebugMode) {
        debugPrint('[Push] skip register — not logged in');
      }
      return;
    }

    try {
      final token = await _fetchFcmToken();
      if (token == null || token.isEmpty) {
        if (kDebugMode) {
          debugPrint(
            '[Push] skip register — FCM token unavailable (rebuild app after google-services.json)',
          );
        }
        return;
      }
      if (token == _lastRegisteredToken) return;

      final platform = _platformLabel();
      await repository.registerFcmToken(token, platform: platform);
      _lastRegisteredToken = token;
      if (kDebugMode) {
        debugPrint(
          '[Push] FCM token registered ($platform): '
          '${token.substring(0, 12)}...${token.substring(token.length - 6)}',
        );
      }
    } catch (e, st) {
      if (kDebugMode) {
        debugPrint('[Push] token registration failed: $e\n$st');
      }
    }
  }

  static Future<String?> _fetchFcmToken({int attempts = 3}) async {
    for (var i = 0; i < attempts; i++) {
      final token = await FirebaseMessaging.instance.getToken();
      if (token != null && token.isNotEmpty) return token;
      if (i < attempts - 1) {
        await Future<void>.delayed(const Duration(seconds: 1));
      }
    }
    return null;
  }

  static String _platformLabel() {
    if (kIsWeb) return 'web';
    if (Platform.isAndroid) return 'android';
    if (Platform.isIOS) return 'ios';
    return 'unknown';
  }
}

Future<void> _ensureLocalNotificationsReady() async {
  const androidInit = AndroidInitializationSettings('@mipmap/ic_launcher');
  const iosInit = DarwinInitializationSettings();
  const initSettings = InitializationSettings(
    android: androidInit,
    iOS: iosInit,
  );

  await _localNotifications.initialize(
    settings: initSettings,
    onDidReceiveNotificationResponse: (response) {
      final route = response.payload;
      if (route != null && route.isNotEmpty) {
        appRouter.go(route);
      }
    },
  );

  if (!kIsWeb && Platform.isAndroid) {
    await _localNotifications
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(_androidChannel);
  }
}

Future<void> _requestNotificationPermission() async {
  if (kIsWeb) return;

  if (Platform.isAndroid) {
    await _localNotifications
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.requestNotificationsPermission();
    return;
  }

  await FirebaseMessaging.instance.requestPermission(
    alert: true,
    badge: true,
    sound: true,
  );
}

void _handleForegroundMessage(RemoteMessage message) {
  final type = message.data['type']?.toString();
  final conversationId = message.data['conversationId']?.toString();

  // Live-refresh the chat tab badge / open thread for incoming messages.
  if (type == 'chatMessage') {
    PushNotificationService.onForegroundChatMessage?.call(conversationId);
  } else if (_isDeliveryRelatedPushType(type)) {
    PushNotificationService.onForegroundDeliveryRelated?.call(type);
  }

  final suppressChatBanner = type == 'chatMessage' &&
      (PushNotificationService.shouldSuppressChatBanner?.call(conversationId) ??
          false);
  if (suppressChatBanner) return;

  final payload = _extractPayload(message);
  if (payload == null) return;

  if (kDebugMode) {
    debugPrint('[Push] foreground: ${payload.title}');
  }

  PushNotificationBanner.show(
    title: payload.title,
    body: payload.body,
    onTap: () => _openRoute(payload.route),
  );
}

void _navigateFromMessage(RemoteMessage message) {
  final payload = _extractPayload(message);
  if (payload == null) return;
  _openRoute(payload.route);
}

void _openRoute(String? route) {
  if (route == null || route.isEmpty) return;
  appRouter.go(normalizeNotificationRoute(route));
}

bool _isDeliveryRelatedPushType(String? type) {
  switch (type) {
    case 'deliveryStatus':
    case 'nfcPrompt':
    case 'cancellation':
    case 'parcelRequest':
    case 'matching':
    case 'bidAccepted':
    case 'offerAccepted':
    case 'counterOffer':
    case 'receiverPayment':
    case 'platformFee':
      return true;
    default:
      return false;
  }
}

({String title, String? body, String? route})? _extractPayload(
  RemoteMessage message,
) {
  final notification = message.notification;
  final title = notification?.title ?? message.data['title']?.toString();
  final body = notification?.body ?? message.data['body']?.toString();
  if (title == null || title.trim().isEmpty) return null;

  return (
    title: title.trim(),
    body: body?.trim(),
    route: message.data['route']?.toString(),
  );
}

Future<void> _showLocalNotification(RemoteMessage message) async {
  final payload = _extractPayload(message);
  if (payload == null) return;

  final androidDetails = AndroidNotificationDetails(
    _androidChannel.id,
    _androidChannel.name,
    channelDescription: _androidChannel.description,
    importance: Importance.max,
    priority: Priority.max,
    icon: '@mipmap/ic_launcher',
    category: AndroidNotificationCategory.message,
    visibility: NotificationVisibility.public,
    playSound: true,
    enableVibration: true,
  );

  await _localNotifications.show(
    id: message.hashCode,
    title: payload.title,
    body: payload.body,
    payload: payload.route,
    notificationDetails: NotificationDetails(
      android: androidDetails,
      iOS: const DarwinNotificationDetails(
        presentAlert: true,
        presentBadge: true,
        presentSound: true,
      ),
    ),
  );
}
