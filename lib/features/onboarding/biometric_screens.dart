import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../core/api/api_exception.dart';
import '../../core/auth/post_auth_navigation.dart';
import '../../core/navigation/app_navigation.dart';
import '../../core/platform/biometric_auth_service.dart';
import '../../core/platform/biometric_prefs.dart';
import '../../core/platform/keyboard_utils.dart';
import '../../core/platform/platform_ui.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_typography.dart';
import '../../core/widgets/app_button.dart';
import '../../core/widgets/app_labeled_field.dart';
import '../../core/widgets/app_toast.dart';
import '../../core/widgets/back_link.dart';
import '../../core/widgets/screen_body.dart';
import '../../l10n/app_localizations.dart';
import '../../providers/auth_provider.dart';
import 'login_otp_verification_screen.dart';

class BiometricSetupScreen extends StatefulWidget {
  const BiometricSetupScreen({super.key});

  @override
  State<BiometricSetupScreen> createState() => _BiometricSetupScreenState();
}

class _BiometricSetupScreenState extends State<BiometricSetupScreen> {
  final _passwordController = TextEditingController();
  bool _obscurePassword = true;
  bool _loading = false;

  @override
  void dispose() {
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _enableBiometricLogin() async {
    final password = _passwordController.text;
    if (password.isEmpty) {
      AppToast.error(context, 'Enter your password');
      return;
    }

    final auth = context.read<AuthProvider>();

    setState(() => _loading = true);

    try {
      await auth.verifyPassword(password);
    } on ApiException catch (e) {
      if (mounted) {
        setState(() => _loading = false);
        AppToast.error(context, e.message);
      }
      return;
    }

    final result = await BiometricAuthService.authenticate(
      reason: PlatformUi.biometricSetupReason,
    );

    if (!mounted) return;

    switch (result.status) {
      case BiometricAuthStatus.success:
        await BiometricPrefs.setLoginEnabled(true);
        if (!mounted) return;
        context.pushReplacement('/biometric/success', extra: true);
      case BiometricAuthStatus.notAvailable:
      case BiometricAuthStatus.notEnrolled:
      case BiometricAuthStatus.lockedOut:
        context.pushReplacement(
          '/biometric/unavailable',
          extra: result.message,
        );
      case BiometricAuthStatus.cancelled:
        setState(() => _loading = false);
        AppToast.error(
          context,
          'Verification cancelled. Try again when you are ready.',
        );
      case BiometricAuthStatus.failed:
        setState(() => _loading = false);
        AppToast.error(
          context,
          result.message ?? 'Verification failed. Please try again.',
        );
    }
  }

  @override
  Widget build(BuildContext context) {
    final typo = context.typo;
    final label = PlatformUi.biometricShortLabel;

    return Scaffold(
      backgroundColor: AppColors.surface,
      resizeToAvoidBottomInset: true,
      body: ScreenBody(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const BackLink(fallbackRoute: '/login'),
            const SizedBox(height: 12),
            Text('Enable $label login', style: typo.h1),
            const SizedBox(height: 8),
            Text(
              'Sign in faster next time with ${label.toLowerCase()}. Confirm your password to turn this on.',
              style: typo.sm.copyWith(height: 1.5),
            ),
            const SizedBox(height: 28),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.kycBackground,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: AppColors.border),
              ),
              child: Row(
                children: [
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: AppColors.primary.withValues(alpha: 0.12),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      PlatformUi.biometricIcon,
                      color: AppColors.primary,
                      size: 28,
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Quick sign-in',
                          style: typo.body.copyWith(
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          'Use $label instead of typing your password each time.',
                          style: typo.sm,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            AppLabeledField(
              label: context.tr('Password'),
              padding: const EdgeInsets.only(top: AppFieldSpacing.top),
              child: TextField(
                controller: _passwordController,
                onTap: () => ensureSoftKeyboardVisible(retry: true),
                onTapOutside: dismissKeyboardOnTapOutside,
                obscureText: _obscurePassword,
                textInputAction: TextInputAction.done,
                onSubmitted: (_) => _enableBiometricLogin(),
                style: typo.input,
                decoration: InputDecoration(
                  hintText: 'Enter your password',
                  hintStyle: typo.input.copyWith(color: AppColors.textDisabled),
                  suffixIcon: IconButton(
                    icon: Icon(
                      _obscurePassword
                          ? Icons.visibility_off_outlined
                          : Icons.visibility_outlined,
                      color: AppColors.textSecondary,
                    ),
                    onPressed: () =>
                        setState(() => _obscurePassword = !_obscurePassword),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 24),
            AppButton(
              label: _loading ? 'Verifying…' : 'Enable $label',
              onPressed: _loading ? null : _enableBiometricLogin,
            ),
            const SizedBox(height: AppButton.stackGap),
            AppButton(
              label: 'Skip for now',
              variant: AppButtonVariant.ghost,
              onPressed: _loading
                  ? null
                  : () => PostAuthNavigation.continueAfterAuth(
                      context,
                      offerBiometricSetup: false,
                    ),
            ),
          ],
        ),
      ),
    );
  }
}

class BiometricLoginScreen extends StatefulWidget {
  const BiometricLoginScreen({super.key});

  @override
  State<BiometricLoginScreen> createState() => _BiometricLoginScreenState();
}

class _BiometricLoginScreenState extends State<BiometricLoginScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _pulseController;
  bool _authenticating = false;
  String? _statusMessage;
  bool _hasStarted = false;
  String _displayName = 'WWNGO';
  String _displayInitials = 'W';

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    )..repeat(reverse: true);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadCachedUser();
      _prepareAndAuthenticate();
    });
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  Future<void> _loadCachedUser() async {
    final auth = context.read<AuthProvider>();
    final cached = await auth.repository.tokenStorage.getUser();
    if (!mounted || cached == null) return;
    final parts = cached.name.trim().split(RegExp(r'\s+'));
    setState(() {
      _displayName = cached.name;
      _displayInitials = parts
          .take(2)
          .map((p) => p.isNotEmpty ? p[0] : '')
          .join()
          .toUpperCase();
      if (_displayInitials.isEmpty) _displayInitials = 'W';
    });
  }

  Future<void> _prepareAndAuthenticate() async {
    final auth = context.read<AuthProvider>();
    final canUnlock = await auth.canUnlockWithBiometric();
    if (!mounted) return;

    if (!canUnlock) {
      AppToast.info(
        context,
        'Log in with password first, then enable ${PlatformUi.biometricShortLabel}.',
      );
      context.go('/login');
      return;
    }

    await _authenticate();
  }

  Future<void> _authenticate() async {
    if (_authenticating) return;

    setState(() {
      _authenticating = true;
      _statusMessage = null;
      _hasStarted = true;
    });

    final result = await BiometricAuthService.authenticate(
      reason: PlatformUi.biometricPromptReason,
    );

    if (!mounted) return;

    switch (result.status) {
      case BiometricAuthStatus.success:
        final auth = context.read<AuthProvider>();
        if (!auth.isAuthenticated) {
          final restored = await auth.tryRestoreSession();
          if (!mounted) return;
          if (!restored) {
            await BiometricPrefs.setLoginEnabled(false);
            AppToast.error(
              context,
              'Session expired. Please log in with your password again.',
            );
            context.go('/login');
            return;
          }
        }
        if (!mounted) return;
        await _continueAfterBiometricUnlock(auth);
      case BiometricAuthStatus.notAvailable:
      case BiometricAuthStatus.notEnrolled:
      case BiometricAuthStatus.lockedOut:
        context.pushReplacement(
          '/biometric/unavailable',
          extra: result.message,
        );
      case BiometricAuthStatus.cancelled:
        setState(() {
          _authenticating = false;
          _statusMessage = 'Authentication cancelled.';
        });
      case BiometricAuthStatus.failed:
        setState(() {
          _authenticating = false;
          _statusMessage = result.message ?? 'Authentication failed.';
        });
    }
  }

  /// After Face ID / fingerprint succeeds, enforce the same 7-day email OTP gate.
  Future<void> _continueAfterBiometricUnlock(AuthProvider auth) async {
    try {
      final status = await auth.getWeeklyLoginOtpStatus();
      if (!mounted) return;

      if (status.required) {
        final email = (status.email ?? auth.user?.email ?? '').trim();
        if (email.isEmpty) {
          AppToast.error(
            context,
            'Email verification is required, but no email is linked. Log in with password.',
          );
          context.go('/login');
          return;
        }
        context.pushReplacement(
          '/login/verify-otp',
          extra: PasswordLoginOtpFlowData.session(email: email),
        );
        return;
      }

      context.pushReplacement('/biometric/success', extra: false);
    } catch (_) {
      if (!mounted) return;
      // Fail closed: require OTP rather than letting biometric bypass the gate.
      final email = (auth.user?.email ?? '').trim();
      if (email.isEmpty) {
        AppToast.error(
          context,
          'Could not verify login status. Please log in with password.',
        );
        context.go('/login');
        return;
      }
      context.pushReplacement(
        '/login/verify-otp',
        extra: PasswordLoginOtpFlowData.session(email: email),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final typo = context.typo;
    final authUser = context.watch<AuthProvider>().user;
    final name = authUser?.name ?? _displayName;
    final initials = authUser != null
        ? authUser.name
              .trim()
              .split(RegExp(r'\s+'))
              .take(2)
              .map((p) => p.isNotEmpty ? p[0] : '')
              .join()
              .toUpperCase()
        : _displayInitials;
    final label = PlatformUi.biometricShortLabel;
    final scale = Tween<double>(begin: 0.96, end: 1.04).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );

    return Scaffold(
      backgroundColor: AppColors.surface,
      body: BackLinkScreen(
        fallbackRoute: '/login',
        child: Column(
          children: [
            Expanded(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircleAvatar(
                    radius: 36,
                    backgroundColor: AppColors.primary.withValues(alpha: 0.12),
                    child: Text(
                      initials.isNotEmpty ? initials : 'W',
                      style: typo.h2.copyWith(color: AppColors.primary),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Welcome back',
                    style: typo.h2,
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 4),
                  Text(name, style: typo.sm, textAlign: TextAlign.center),
                  const SizedBox(height: 32),
                  ScaleTransition(
                    scale: _authenticating
                        ? scale
                        : const AlwaysStoppedAnimation(1),
                    child: Container(
                      width: 96,
                      height: 96,
                      decoration: BoxDecoration(
                        color: AppColors.primary.withValues(alpha: 0.1),
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: AppColors.primary.withValues(alpha: 0.25),
                          width: 2,
                        ),
                      ),
                      child: Icon(
                        PlatformUi.biometricIcon,
                        size: 48,
                        color: AppColors.primary,
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  Text(
                    _authenticating
                        ? 'Waiting for $label…'
                        : _hasStarted
                        ? 'Try again with $label'
                        : 'Use $label to continue',
                    style: typo.body.copyWith(fontWeight: FontWeight.w600),
                    textAlign: TextAlign.center,
                  ),
                  if (_statusMessage != null) ...[
                    const SizedBox(height: 8),
                    Text(
                      _statusMessage!,
                      style: typo.sm.copyWith(color: AppColors.danger),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ],
              ),
            ),
            if (!_authenticating)
              AppButton(
                label: context.tr('Try again'),
                onPressed: _authenticate,
              ),
            const SizedBox(height: AppButton.stackGap),
            AppButton(
              label: 'Use password instead',
              variant: AppButtonVariant.outline,
              onPressed: () =>
                  appNavigateBackFromContext(context, fallback: '/login'),
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }
}

class BiometricSuccessScreen extends StatefulWidget {
  const BiometricSuccessScreen({super.key, required this.fromSetup});

  final bool fromSetup;

  @override
  State<BiometricSuccessScreen> createState() => _BiometricSuccessScreenState();
}

class _BiometricSuccessScreenState extends State<BiometricSuccessScreen> {
  @override
  void initState() {
    super.initState();
    Future.delayed(const Duration(seconds: 2), () {
      if (mounted)
        PostAuthNavigation.continueAfterAuth(
          context,
          offerBiometricSetup: false,
        );
    });
  }

  @override
  Widget build(BuildContext context) {
    final typo = context.typo;
    final label = PlatformUi.biometricShortLabel;

    return Scaffold(
      backgroundColor: AppColors.surface,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  color: AppColors.success.withValues(alpha: 0.12),
                  shape: BoxShape.circle,
                ),
                alignment: Alignment.center,
                child: Icon(
                  PlatformUi.biometricIcon,
                  size: 40,
                  color: AppColors.success,
                ),
              ),
              const SizedBox(height: 20),
              Text(
                widget.fromSetup ? '$label enabled!' : 'Authenticated!',
                style: typo.h1,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Text(
                widget.fromSetup
                    ? 'You can now sign in quickly with ${label.toLowerCase()}.'
                    : 'Welcome back to WWNGO.',
                textAlign: TextAlign.center,
                style: typo.sm.copyWith(height: 1.5),
              ),
              const SizedBox(height: 32),
              AppButton(
                label: context.tr('Continue'),
                onPressed: () => context.go('/role-selection'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class BiometricUnavailableScreen extends StatelessWidget {
  const BiometricUnavailableScreen({super.key, this.message});

  final String? message;

  @override
  Widget build(BuildContext context) {
    final typo = context.typo;
    final label = PlatformUi.biometricShortLabel;

    return Scaffold(
      backgroundColor: AppColors.surface,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  color: AppColors.warning.withValues(alpha: 0.12),
                  shape: BoxShape.circle,
                ),
                alignment: Alignment.center,
                child: const Icon(
                  Icons.phonelink_lock_rounded,
                  size: 40,
                  color: AppColors.warning,
                ),
              ),
              const SizedBox(height: 20),
              Text(
                '$label unavailable',
                style: typo.h1,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Text(
                message ??
                    '$label is not set up on this device. Add it in your device security settings, then try again.',
                textAlign: TextAlign.center,
                style: typo.sm.copyWith(height: 1.5),
              ),
              const SizedBox(height: 32),
              AppButton(
                label: context.tr('Log in with password'),
                onPressed: () => context.go('/login'),
              ),
              const SizedBox(height: AppButton.stackGap),
              AppButton(
                label: context.tr('Try again'),
                variant: AppButtonVariant.outline,
                onPressed: () => context.go('/biometric/login'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
