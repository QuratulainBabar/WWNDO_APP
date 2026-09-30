import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:provider/provider.dart';
import 'core/navigation/app_navigation.dart';
import 'core/payments/stripe_connect_return.dart';
import 'core/theme/app_theme.dart';
import 'core/widgets/screen_container.dart';
import 'features/onboarding/inactivity_lock_gate.dart';
import 'l10n/app_localizations.dart';
import 'providers/auth_provider.dart';
import 'providers/locale_provider.dart';
import 'providers/session_inactivity_lock.dart';
import 'providers/theme_provider.dart';
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
    final auth = context.read<AuthProvider>();
    final lock = context.read<SessionInactivityLock>();

    if (state == AppLifecycleState.paused ||
        state == AppLifecycleState.detached) {
      lock.onAppPaused(isAuthenticated: auth.isAuthenticated);
    }

    if (state == AppLifecycleState.resumed) {
      lock.onAppResumed(isAuthenticated: auth.isAuthenticated);

      if (StripeConnectReturn.isReturnDue) {
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
    }
  }

  @override
  Widget build(BuildContext context) {
    final themeMode = context.watch<ThemeProvider>().themeMode;
    final localeProvider = context.watch<LocaleProvider>();
    final locale = localeProvider.locale;
    final inactivityLock = context.watch<SessionInactivityLock>();
    final isAuthenticated = context.watch<AuthProvider>().isAuthenticated;
    final showInactivityGate =
        isAuthenticated && inactivityLock.ready && inactivityLock.isLocked;

    return MaterialApp.router(
      title: 'WWNGO',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light,
      darkTheme: AppTheme.dark,
      themeMode: themeMode,
      locale: locale,
      supportedLocales: AppLocalizations.supportedLocales,
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      routerConfig: appRouter,
      builder: (context, child) {
        final mediaQuery = MediaQuery.of(context);
        // Update direction / media query on locale change without remounting
        // the navigator tree. A ValueKey remount left shell GlobalKey states
        // alive while hanging context.push futures (e.g. settings from profile).
        return Directionality(
          textDirection:
              localeProvider.isRtl ? TextDirection.rtl : TextDirection.ltr,
          child: MediaQuery(
            data: mediaQuery.copyWith(
              textScaler: mediaQuery.textScaler.clamp(
                minScaleFactor: 0.85,
                maxScaleFactor: 1.15,
              ),
            ),
            child: PopScope(
              canPop: !showInactivityGate && appRouter.canPop(),
              onPopInvokedWithResult: (didPop, _) {
                if (didPop || showInactivityGate) return;
                final fallback = backFallbackFor(appRouter.state.uri.path);
                if (fallback != null) {
                  appRouter.go(fallback);
                }
              },
              child: Stack(
                fit: StackFit.expand,
                children: [
                  ScreenContainer(child: child ?? const SizedBox.shrink()),
                  if (showInactivityGate) const InactivityLockGate(),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
