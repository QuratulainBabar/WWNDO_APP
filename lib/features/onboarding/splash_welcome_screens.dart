import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../core/auth/post_auth_navigation.dart';
import '../../core/platform/biometric_prefs.dart';
import '../../core/theme/app_typography.dart';
import '../../core/widgets/app_button.dart';
import '../../core/widgets/gradient_background.dart';
import '../../providers/auth_provider.dart';
import '../../l10n/app_localizations.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    Future.delayed(const Duration(milliseconds: 1200), _routeAfterSplash);
  }

  Future<void> _routeAfterSplash() async {
    if (!mounted) return;
    final auth = context.read<AuthProvider>();

    if (auth.isAuthenticated) {
      await PostAuthNavigation.continueAfterAuth(
        context,
        offerBiometricSetup: false,
        requireVerification: false,
      );
      return;
    }

    // User explicitly logged out with biometric unlock enabled.
    final softLocked = await BiometricPrefs.isSessionSoftLocked();
    final biometricOn = await BiometricPrefs.isLoginEnabled();
    if (!mounted) return;
    if (softLocked && biometricOn) {
      context.go('/biometric/login');
      return;
    }

    context.go('/welcome');
  }

  @override
  Widget build(BuildContext context) {
    final typo = context.typo;
    return Scaffold(
      body: PrimaryGradientBackground(
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text('WWNGO', style: typo.brandSplash),
              const SizedBox(height: 16),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 48),
                child: Text(
                  'Ship it with someone already going',
                  textAlign: TextAlign.center,
                  style: typo.splashTagline,
                ),
              ),
              const SizedBox(height: 56),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  _dot(0.8),
                  const SizedBox(width: 6),
                  _dot(0.4),
                  const SizedBox(width: 6),
                  _dot(0.4),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _dot(double opacity) => Container(
        width: 8,
        height: 8,
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: opacity),
          shape: BoxShape.circle,
        ),
      );
}

class WelcomeScreen extends StatelessWidget {
  const WelcomeScreen({super.key});

  // Demo app mode entry point — kept for easy re-enable later.
  // Future<void> _exploreDemoApp(BuildContext context) async {
  //   final auth = context.read<AuthProvider>();
  //   await auth.signInAsDemo();
  //   if (!context.mounted) return;
  //   await PostAuthNavigation.continueAfterAuth(context, offerBiometricSetup: false);
  // }

  @override
  Widget build(BuildContext context) {
    final typo = context.typo;
    // final demoMode = context.watch<DemoModeProvider>();

    return Scaffold(
      body: PrimaryGradientBackground(
        child: SafeArea(
          child: MediaQuery(
            data: MediaQuery.of(context).copyWith(
              textScaler: TextScaler.noScaling,
            ),
            child: LayoutBuilder(
              builder: (context, constraints) {
                return SingleChildScrollView(
                  child: ConstrainedBox(
                    constraints: BoxConstraints(minHeight: constraints.maxHeight),
                    child: IntrinsicHeight(
                      child: Column(
                        children: [
                          // Demo app mode toggle — commented out (live API only).
                          // Padding(
                          //   padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
                          //   child: _DemoModeToggle(
                          //     enabled: demoMode.enabled,
                          //     onChanged: demoMode.setEnabled,
                          //   ),
                          // ),
                          Expanded(
                            child: Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 32),
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Text('WWNGO', style: typo.brandWelcome),
                                  const SizedBox(height: 32),
                                  Text(
                                    'Ship it with\nsomeone\nalready going.',
                                    textAlign: TextAlign.center,
                                    style: typo.welcomeHeadline.copyWith(
                                      fontSize: 40,
                                      fontWeight: FontWeight.w900,
                                      letterSpacing: -0.5,
                                    ),
                                  ),
                                  const SizedBox(height: 24),
                                  Text(
                                    'Peer-to-peer delivery by real travelers.\nFaster. Cheaper. Verified.',
                                    textAlign: TextAlign.center,
                                    style: typo.welcomeSubtext,
                                  ),
                                  // if (demoMode.enabled) ...[
                                  //   const SizedBox(height: 20),
                                  //   Text(
                                  //     'Demo mode is on — no server needed.',
                                  //     textAlign: TextAlign.center,
                                  //     style: typo.sm.copyWith(
                                  //       color: Colors.white.withValues(alpha: 0.9),
                                  //       height: 1.4,
                                  //     ),
                                  //   ),
                                  // ],
                                ],
                              ),
                            ),
                          ),
                          Padding(
                            padding: const EdgeInsets.fromLTRB(24, 0, 24, 56),
                            child: Column(
                              children: [
                                // if (demoMode.enabled) ...[
                                //   AppButton(
                                //     label: 'Explore demo app →',
                                //     textStyle: typo.welcomeButton,
                                //     onPressed: () => _exploreDemoApp(context),
                                //   ),
                                //   const SizedBox(height: AppButton.stackGap),
                                // ],
                                AppButton(
                                  label: context.tr('Sign up'),
                                  variant: AppButtonVariant.primary,
                                  // variant: demoMode.enabled
                                  //     ? AppButtonVariant.outlineWhite
                                  //     : AppButtonVariant.primary,
                                  textStyle: typo.welcomeButton,
                                  onPressed: () => context.push('/register'),
                                ),
                                const SizedBox(height: AppButton.stackGap),
                                AppButton(
                                  label: context.tr('Log in'),
                                  variant: AppButtonVariant.outlineWhite,
                                  textStyle: typo.welcomeButton,
                                  onPressed: () => context.push('/login'),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ),
      ),
    );
  }
}

// Demo app mode toggle widget — commented out with welcome UI.
// class _DemoModeToggle extends StatelessWidget {
//   const _DemoModeToggle({
//     required this.enabled,
//     required this.onChanged,
//   });
//
//   final bool enabled;
//   final ValueChanged<bool> onChanged;
//
//   @override
//   Widget build(BuildContext context) {
//     return Container(
//       padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
//       decoration: BoxDecoration(
//         color: Colors.white.withValues(alpha: 0.14),
//         borderRadius: BorderRadius.circular(14),
//         border: Border.all(color: Colors.white.withValues(alpha: 0.25)),
//       ),
//       child: Row(
//         children: [
//           Expanded(
//             child: Column(
//               crossAxisAlignment: CrossAxisAlignment.start,
//               children: [
//                 Text(
//                   'Demo app mode',
//                   style: context.typo.sm.copyWith(
//                     color: Colors.white,
//                     fontWeight: FontWeight.w700,
//                   ),
//                 ),
//                 const SizedBox(height: 2),
//                 Text(
//                   enabled ? 'Offline — static data, no backend' : 'Live — needs backend server',
//                   style: context.typo.sm.copyWith(
//                     color: Colors.white.withValues(alpha: 0.85),
//                     fontSize: 12,
//                   ),
//                 ),
//               ],
//             ),
//           ),
//           Switch.adaptive(
//             value: enabled,
//             activeTrackColor: AppColors.primary,
//             onChanged: onChanged,
//           ),
//         ],
//       ),
//     );
//   }
// }
