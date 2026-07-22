import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../core/auth/selected_role.dart';
import '../../core/auth/kyc_verification_guard.dart';
import '../../core/platform/biometric_auth_service.dart';
import '../../core/platform/biometric_prefs.dart';
import '../../data/models/wallet_role.dart';
import '../../providers/auth_provider.dart';

/// Routes user after login/register toward the correct home or onboarding step.
abstract final class PostAuthNavigation {
  static Future<void> continueAfterAuth(
    BuildContext context, {
    bool offerBiometricSetup = true,
    bool requireVerification = true,
  }) async {
    if (!context.mounted) return;

    final auth = context.read<AuthProvider>();
    final user = auth.user;
    if (user == null) {
      context.go('/login');
      return;
    }

    if (user.accountStatus == 'suspended') {
      context.go('/account-suspended');
      return;
    }

    // Resolve role from API user, then local cache (survives demo re-login).
    var role = SelectedRoleStore.roleFromUser(user);
    role ??= await SelectedRoleStore.loadForUser(
      userId: user.id,
      email: user.email,
    );

    if (!context.mounted) return;

    if (requireVerification && !user.isFullyCrossVerified) {
      if (role == null) {
        context.go('/role-selection');
        return;
      }
      // Keep server/demo user in sync if role only existed locally.
      if (!user.hasRole) {
        await _syncRole(auth, role);
      }
      if (!context.mounted) return;
      context.go('/verify-account');
      return;
    }

    // Identity verification (Sumsub) before marketplace access.
    // Pending / rejected: keep user in KYC screens.
    // Submitted: allow browsing; posting/bidding still blocked by KycVerificationGuard.
    if (user.isKycPending || user.isKycRejected) {
      if (!context.mounted) return;
      context.go(KycVerificationGuard.routeForUser(user));
      return;
    }

    // Offer device biometric unlock once KYC/verification are clear.
    if (offerBiometricSetup && !kIsWeb) {
      final alreadyEnabled = await BiometricPrefs.isLoginEnabled();
      if (!alreadyEnabled) {
        final supported = await BiometricAuthService.isDeviceSupported();
        final canCheck = await BiometricAuthService.canCheckBiometrics();
        final enrolled = await BiometricAuthService.getAvailableBiometrics();
        if (supported && canCheck && enrolled.isNotEmpty) {
          if (!context.mounted) return;
          context.go('/biometric/setup');
          return;
        }
      }
    }

    if (role != null) {
      if (!user.hasRole) {
        await _syncRole(auth, role);
      }
      if (!context.mounted) return;
      context.go(SelectedRoleStore.homeRouteFor(role));
      return;
    }

    context.go('/role-selection');
  }

  static Future<void> _syncRole(AuthProvider auth, WalletRole role) async {
    try {
      await auth.setRole(SelectedRoleStore.apiValue(role));
    } catch (_) {
      // Local routing can still proceed; role will retry on next save.
    }
  }
}
