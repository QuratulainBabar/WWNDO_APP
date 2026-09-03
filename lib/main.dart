import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'app.dart';
import 'core/config/demo_mode.dart';
import 'core/push/push_notification_service.dart';
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

  // Refresh the chat tab badge the moment a chat push arrives in the foreground,
  // instead of waiting for the periodic poll.
  void refreshChatBadge() {
    if (!authProvider.isAuthenticated) return;
    notificationRealtimeProvider.refreshChatUnread(
      authRepository: authProvider.repository,
      demoMode: demoMode,
      threadType: notificationRealtimeProvider.activeRole?.chatInboxThreadType,
    );
  }

  PushNotificationService.onForegroundChatMessage = refreshChatBadge;
  chatRealtimeProvider.onIncomingPeerMessage = refreshChatBadge;

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
