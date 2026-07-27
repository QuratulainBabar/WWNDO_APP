import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'app.dart';
import 'core/config/demo_mode.dart';
import 'providers/auth_provider.dart';
import 'providers/kyc_provider.dart';
import 'providers/notification_realtime_provider.dart';
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
  ]);

  final kycProvider = KycProvider(
    authRepository: authProvider.repository,
    demoMode: demoMode,
  );
  final walletProvider = WalletProvider(
    authRepository: authProvider.repository,
    demoMode: demoMode,
  );
  final notificationRealtimeProvider = NotificationRealtimeProvider();

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
      ],
      child: const WwngoApp(),
    ),
  );
}
