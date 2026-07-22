import 'package:flutter/material.dart';
import 'core/navigation/app_navigation.dart';
import 'core/theme/app_theme.dart';
import 'core/widgets/screen_container.dart';
import 'router/app_router.dart';

class WwngoApp extends StatelessWidget {
  const WwngoApp({super.key});

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
