import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/platform/biometric_auth_service.dart';
import '../../core/platform/platform_ui.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_typography.dart';
import '../../core/widgets/app_button.dart';
import '../../l10n/app_localizations.dart';
import '../../providers/auth_provider.dart';
import '../../providers/session_inactivity_lock.dart';
import '../../router/app_router.dart';
import 'login_otp_verification_screen.dart';

/// Full-screen Face ID / biometric gate after 12 hours of inactivity.
///
/// Shown above the normal app tree for every role while the session is locked.
class InactivityLockGate extends StatefulWidget {
  const InactivityLockGate({super.key});

  @override
  State<InactivityLockGate> createState() => _InactivityLockGateState();
}

class _InactivityLockGateState extends State<InactivityLockGate>
    with SingleTickerProviderStateMixin {
  late final AnimationController _pulseController;
  bool _authenticating = false;
  bool _started = false;
  String? _statusMessage;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    )..repeat(reverse: true);
    WidgetsBinding.instance.addPostFrameCallback((_) => _authenticate());
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  Future<void> _authenticate() async {
    if (_authenticating) return;
    setState(() {
      _authenticating = true;
      _statusMessage = null;
      _started = true;
    });

    final result = await BiometricAuthService.authenticate(
      reason: PlatformUi.biometricInactivityReason,
      // Face ID / fingerprint preferred; device PIN allowed as fallback.
      biometricOnly: false,
    );

    if (!mounted) return;

    switch (result.status) {
      case BiometricAuthStatus.success:
        final auth = context.read<AuthProvider>();
        try {
          final status = await auth.getWeeklyLoginOtpStatus();
          if (!mounted) return;
          if (status.required) {
            final email = (status.email ?? auth.user?.email ?? '').trim();
            if (email.isEmpty) {
              setState(() {
                _authenticating = false;
                _statusMessage =
                    'Email verification required. Use password login.';
              });
              return;
            }
            // Keep inactivity lock until OTP succeeds; unlock after OTP via
            // PostAuthNavigation path which runs with an authenticated session.
            await context.read<SessionInactivityLock>().unlock();
            if (!mounted) return;
            appRouter.go(
              '/login/verify-otp',
              extra: PasswordLoginOtpFlowData.session(email: email),
            );
            return;
          }
        } catch (_) {
          if (!mounted) return;
          final email = (auth.user?.email ?? '').trim();
          if (email.isNotEmpty) {
            await context.read<SessionInactivityLock>().unlock();
            if (!mounted) return;
            appRouter.go(
              '/login/verify-otp',
              extra: PasswordLoginOtpFlowData.session(email: email),
            );
            return;
          }
        }
        await context.read<SessionInactivityLock>().unlock();
      case BiometricAuthStatus.cancelled:
        setState(() {
          _authenticating = false;
          _statusMessage = 'Authentication cancelled.';
        });
      case BiometricAuthStatus.notAvailable:
      case BiometricAuthStatus.notEnrolled:
      case BiometricAuthStatus.lockedOut:
      case BiometricAuthStatus.failed:
        setState(() {
          _authenticating = false;
          _statusMessage = result.message ??
              '${PlatformUi.biometricShortLabel} failed. Try again.';
        });
    }
  }

  Future<void> _usePasswordInstead() async {
    final auth = context.read<AuthProvider>();
    await auth.logoutFully();
    if (!mounted) return;
    appRouter.go('/login');
  }

  @override
  Widget build(BuildContext context) {
    final typo = context.typo;
    final l10n = context.l10n;
    final user = context.watch<AuthProvider>().user;
    final label = PlatformUi.biometricShortLabel;
    final scale = Tween<double>(begin: 0.96, end: 1.04).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );

    return Material(
      color: AppColors.surface,
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 28),
          child: Column(
            children: [
              const Spacer(),
              CircleAvatar(
                radius: 36,
                backgroundColor: AppColors.primary.withValues(alpha: 0.12),
                child: Icon(
                  PlatformUi.biometricIcon,
                  size: 36,
                  color: AppColors.primary,
                ),
              ),
              const SizedBox(height: 20),
              Text(
                l10n.verifyItsYou,
                style: typo.h2,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Text(
                user?.name.trim().isNotEmpty == true
                    ? '${l10n.welcomeBack}, ${user!.name.trim()}. ${l10n.awayForAWhile(label)}'
                    : l10n.awayForAWhile(label),
                style: typo.sm.copyWith(color: AppColors.textSecondary, height: 1.45),
                textAlign: TextAlign.center,
              ),
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
                    ? l10n.waitingForBiometric(label)
                    : _started
                        ? l10n.unlockWithBiometric(label)
                        : l10n.unlockWithBiometric(label),
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
              const Spacer(),
              AppButton(
                label: _authenticating
                    ? l10n.waitingForBiometric(label)
                    : l10n.unlockWithBiometric(label),
                onPressed: _authenticating ? null : _authenticate,
              ),
              const SizedBox(height: AppButton.stackGap),
              AppButton(
                label: l10n.loginWithPassword,
                variant: AppButtonVariant.outline,
                onPressed: _authenticating ? null : _usePasswordInstead,
              ),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }
}
