import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'app.dart';
import 'core/config/demo_mode.dart';
import 'providers/auth_provider.dart';
import 'providers/kyc_provider.dart';

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

  // TEMPORARILY DISABLED - SUMSUB KYC
  // Compatibility provider is retained so preserved widgets can compile; its
  // repository and SDK factory are inert.
  final kycProvider = KycProvider(
    authRepository: authProvider.repository,
    demoMode: demoMode,
  );

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider<DemoModeProvider>.value(value: demoMode),
        ChangeNotifierProvider<AuthProvider>.value(value: authProvider),
        ChangeNotifierProvider<KycProvider>.value(value: kycProvider),
      ],
      child: const WwngoApp(),
    ),
  );
}
