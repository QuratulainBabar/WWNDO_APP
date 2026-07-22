import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../core/auth/selected_role.dart';
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
