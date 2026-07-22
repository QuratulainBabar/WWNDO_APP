import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../data/models/auth_user.dart';

/// Blocks marketplace activity until KYC is approved (Section 2.3).
abstract final class KycVerificationGuard {
  /// TEMPORARILY DISABLED - SUMSUB KYC
  /// Temporarily skip Sumsub Identity Verification.
  /// TODO: restore `user?.isKycApproved ?? false`
  static bool canAccessMarketplace(AuthUser? user) {
    // return user?.isKycApproved ?? false;
    return user != null;
  }

  /// Temporarily always allows Create Delivery / marketplace actions.
  /// Restores to: check approval → show dialog → push `/kyc`.
  static bool ensureKycApproved(BuildContext context) {
    // final user = context.read<AuthProvider>().user;
    // if (canAccessMarketplace(user)) return true;
    // _showKycRequired(context, user);
    // return false;
    return true;
  }

  static String routeForUser(AuthUser? user) {
    // TEMPORARILY DISABLED - SUMSUB KYC
    // All former status destinations now display the disabled placeholder.
    return '/kyc';

    /*
    Preserved status routing:
    if (user == null) return '/kyc';
    return switch (user.kycStatus.toLowerCase()) {
      'submitted' => '/kyc-pending-review',
      'rejected' => '/kyc-rejected',
      _ => '/kyc',
    };
    */
  }

  // TEMPORARILY DISABLED - SUMSUB KYC
  // Kept for easy restore when KYC is re-enabled; no active guard calls it.
  // ignore: unused_element
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
