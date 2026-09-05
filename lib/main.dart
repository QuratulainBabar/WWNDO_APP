import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'app.dart';
import 'core/config/demo_mode.dart';
import 'core/push/push_notification_service.dart';
import 'data/models/wallet_role.dart';
import 'providers/auth_provider.dart';
import 'providers/chat_realtime_provider.dart';
import 'providers/kyc_provider.dart';
import 'providers/notification_realtime_provider.dart';
import 'providers/sender_deliveries_provider.dart';
import 'providers/wallet_provider.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);

  final demoMode = DemoModeProvider();
  final authProvider = AuthProvider(demoMode: demoMode);
  await Future.wait([
    demoMode.init(),
    authProvider.init(),
    PushNotificationService.initialize(),
  ]);

  if (authProvider.isAuthenticated) {
    await PushNotificationService.registerIfAuthenticated(
      authProvider.repository,
    );
  }

  final kycProvider = KycProvider(
    authRepository: authProvider.repository,
    demoMode: demoMode,
  );
  final walletProvider = WalletProvider(
    authRepository: authProvider.repository,
    demoMode: demoMode,
  );
  final notificationRealtimeProvider = NotificationRealtimeProvider();
  final chatRealtimeProvider = ChatRealtimeProvider();
  final senderDeliveriesProvider = SenderDeliveriesProvider();

  // Refresh the chat tab badge when an FCM chat push arrives, and pull the
  // body into any already-open matching conversation via REST resync.
  void refreshChatBadge() {
    if (!authProvider.isAuthenticated) return;
    notificationRealtimeProvider.refreshChatUnread(
      authRepository: authProvider.repository,
      demoMode: demoMode,
      threadType: notificationRealtimeProvider.activeRole?.chatInboxThreadType,
    );
  }

  PushNotificationService.onForegroundChatMessage = (conversationId) {
    final open = conversationId != null &&
        conversationId.isNotEmpty &&
        chatRealtimeProvider.isConversationOpen(conversationId);
    // Instant bottom-bar badge while REST catch-up runs (Home / any screen).
    if (!open) {
      notificationRealtimeProvider.bumpChatUnread();
    }
    refreshChatBadge();
    chatRealtimeProvider.requestResync(conversationId);
  };
  PushNotificationService.shouldSuppressChatBanner = (conversationId) {
    if (conversationId == null || conversationId.isEmpty) return false;
    return chatRealtimeProvider.isConversationOpen(conversationId);
  };
  PushNotificationService.onForegroundDeliveryRelated = (_) {
    if (!authProvider.isAuthenticated) return;
    notificationRealtimeProvider.notifyDeliveryUpdated();
    notificationRealtimeProvider.refreshUnread(
      role: notificationRealtimeProvider.activeRole ??
          WalletRole.receiver,
      authRepository: authProvider.repository,
      demoMode: demoMode,
    );
  };

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider<DemoModeProvider>.value(value: demoMode),
        ChangeNotifierProvider<AuthProvider>.value(value: authProvider),
        ChangeNotifierProvider<KycProvider>.value(value: kycProvider),
        ChangeNotifierProvider<WalletProvider>.value(value: walletProvider),
        ChangeNotifierProvider<NotificationRealtimeProvider>.value(
          value: notificationRealtimeProvider,
        ),
        ChangeNotifierProvider<ChatRealtimeProvider>.value(
          value: chatRealtimeProvider,
        ),
        ChangeNotifierProvider<SenderDeliveriesProvider>.value(
          value: senderDeliveriesProvider,
        ),
      ],
      child: const WwngoApp(),
    ),
  );
}
