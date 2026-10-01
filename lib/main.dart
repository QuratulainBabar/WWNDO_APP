import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:provider/provider.dart';
import 'app.dart';
import 'core/config/api_config.dart';
import 'core/config/demo_mode.dart';
import 'core/l10n/app_language.dart';
import 'core/push/push_notification_service.dart';
import 'data/models/wallet_role.dart';
import 'providers/auth_provider.dart';
import 'providers/chat_realtime_provider.dart';
import 'providers/currency_provider.dart';
import 'providers/kyc_provider.dart';
import 'providers/locale_provider.dart';
import 'providers/notification_realtime_provider.dart';
import 'providers/sender_deliveries_provider.dart';
import 'providers/sender_offer_flow_lock.dart';
import 'providers/session_inactivity_lock.dart';
import 'providers/theme_provider.dart';
import 'providers/wallet_provider.dart';
import 'data/services/wallet_repository.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  debugPrint('API CONFIG → baseUrl=${ApiConfig.baseUrl}');
  debugPrint('API CONFIG → apiV1=${ApiConfig.apiV1}');
  SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);

  await Future.wait(
    AppLanguage.supported.map((lang) => initializeDateFormatting(lang.code)),
  );

  final demoMode = DemoModeProvider();
  final themeProvider = ThemeProvider();
  final currencyProvider = CurrencyProvider();
  final localeProvider = LocaleProvider();
  final inactivityLock = SessionInactivityLock();
  final authProvider = AuthProvider(
    demoMode: demoMode,
    inactivityLock: inactivityLock,
  );
  localeProvider.syncPreferredLanguage = (code) async {
    PushNotificationService.preferredLanguageCode = code;
    if (!authProvider.isAuthenticated) return;
    await authProvider.repository.updatePreferredLanguage(code);
  };
  await Future.wait([
    demoMode.init(),
    themeProvider.init(),
    currencyProvider.init(),
    localeProvider.init(),
    authProvider.init(),
    PushNotificationService.initialize(),
  ]);
  PushNotificationService.preferredLanguageCode = localeProvider.code;
  await inactivityLock.init(isAuthenticated: authProvider.isAuthenticated);

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
  currencyProvider.attachFxSource(
    walletRepository: WalletRepository(
      apiClient: authProvider.repository.apiClient,
      demoMode: demoMode,
    ),
    demoMode: demoMode,
  );
  if (authProvider.isAuthenticated) {
    await currencyProvider.refreshFxRate(force: true);
  }
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
    // Open thread body + Chats inbox previews (all roles) without pull-refresh.
    chatRealtimeProvider.requestResync(conversationId);
    chatRealtimeProvider.requestInboxRefresh();
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
        ChangeNotifierProvider<ThemeProvider>.value(value: themeProvider),
        ChangeNotifierProvider<CurrencyProvider>.value(value: currencyProvider),
        ChangeNotifierProvider<LocaleProvider>.value(value: localeProvider),
        ChangeNotifierProvider<SessionInactivityLock>.value(
          value: inactivityLock,
        ),
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
        ChangeNotifierProvider<SenderOfferFlowLock>.value(
          value: SenderOfferFlowLock.instance,
        ),
      ],
      child: const WwngoApp(),
    ),
  );
}
