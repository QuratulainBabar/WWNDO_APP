import 'package:flutter/material.dart';
import 'core/navigation/app_navigation.dart';
import 'core/payments/stripe_connect_return.dart';
import 'core/theme/app_theme.dart';
import 'core/widgets/screen_container.dart';
import 'router/app_router.dart';

class WwngoApp extends StatefulWidget {
  const WwngoApp({super.key});

  @override
  State<WwngoApp> createState() => _WwngoAppState();
}

class _WwngoAppState extends State<WwngoApp> with WidgetsBindingObserver {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state != AppLifecycleState.resumed) return;
    if (!StripeConnectReturn.isReturnDue) return;
    final path = appRouter.state.uri.path;
    if (path == '/wallet/connect-success' || path == '/connect-success') {
      StripeConnectReturn.consume();
      return;
    }
    final role = StripeConnectReturn.role;
    StripeConnectReturn.consume();
    final q = (role == null || role.isEmpty) ? '' : '&role=$role';
    appRouter.go('/wallet/connect-success?status=done$q');
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: 'WWNGO',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light,
      routerConfig: appRouter,
      builder: (context, child) {
        final mediaQuery = MediaQuery.of(context);
        return MediaQuery(
          data: mediaQuery.copyWith(
            textScaler: mediaQuery.textScaler.clamp(
              minScaleFactor: 0.85,
              maxScaleFactor: 1.15,
            ),
          ),
          child: PopScope(
            canPop: appRouter.canPop(),
            onPopInvokedWithResult: (didPop, _) {
              if (didPop) return;
              final fallback = backFallbackFor(appRouter.state.uri.path);
              if (fallback != null) {
                appRouter.go(fallback);
              }
            },
            child: ScreenContainer(child: child ?? const SizedBox.shrink()),
          ),
        );
      },
    );
  }
}
