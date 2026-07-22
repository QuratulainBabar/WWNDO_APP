import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../data/models/auth_user.dart';
import '../../providers/auth_provider.dart';

/// Blocks marketplace activity until KYC is approved (Section 2.3).
abstract final class KycVerificationGuard {
  static bool canAccessMarketplace(AuthUser? user) {
    return user?.isKycApproved ?? false;
  }

  static bool ensureKycApproved(BuildContext context) {
    final user = context.read<AuthProvider>().user;
    if (canAccessMarketplace(user)) return true;
    _showKycRequired(context, user);
    return false;
  }

  static String routeForUser(AuthUser? user) {
    if (user == null) return '/kyc';
    return switch (user.kycStatus.toLowerCase()) {
      'submitted' => '/kyc-pending-review',
      'rejected' => '/kyc-rejected',
      _ => '/kyc',
    };
  }

  static void _showKycRequired(BuildContext context, AuthUser? user) {
    final status = user?.kycStatus.toLowerCase() ?? 'pending';
    final (title, message) = switch (status) {
      'submitted' => (
          'Verification in review',
          'Your identity documents are being reviewed. You can post parcels, create trips, and place bids once approved.',
        ),
      'rejected' => (
          'Verification failed',
          'Your KYC was rejected. Please retry identity verification before using marketplace features.',
        ),
      _ => (
          'Identity verification required',
          'Complete KYC verification before posting parcels, creating trips, or placing bids.',
        ),
    };

    showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Later'),
          ),
          FilledButton(
            onPressed: () {
              Navigator.of(context).pop();
              context.push(routeForUser(user));
            },
            child: Text(status == 'submitted' ? 'View status' : 'Verify now'),
          ),
        ],
      ),
    );
  }
}
