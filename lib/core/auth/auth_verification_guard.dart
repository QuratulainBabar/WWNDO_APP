import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../data/models/auth_user.dart';
import '../../providers/auth_provider.dart';

/// Blocks marketplace transactions until email + phone are cross-verified.
abstract final class AuthVerificationGuard {
  static bool canTransact(AuthUser? user) => user?.isFullyCrossVerified ?? false;

  static bool ensureVerifiedForTransaction(BuildContext context) {
    final user = context.read<AuthProvider>().user;
    if (canTransact(user)) return true;

    _showVerificationRequired(context, user);
    return false;
  }

  static void _showVerificationRequired(BuildContext context, AuthUser? user) {
    final missing = <String>[];
    if (user != null && !user.emailVerified) missing.add('email');
    if (user != null && !user.phoneVerified) missing.add('phone');

    showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Verification required'),
        content: Text(
          missing.isEmpty
              ? 'Verify your email and phone before starting transactions on WWNGO.'
              : 'Please verify your ${missing.join(' and ')} before starting transactions.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Later'),
          ),
          FilledButton(
            onPressed: () {
              Navigator.of(context).pop();
              context.push('/verify-account');
            },
            child: const Text('Verify now'),
          ),
        ],
      ),
    );
  }
}
