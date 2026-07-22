import 'package:flutter/material.dart';

import '../../data/models/auth_user.dart';
import '../theme/app_colors.dart';
import 'app_badge.dart';

class KycStatusBadge extends StatelessWidget {
  const KycStatusBadge({super.key, required this.user});

  final AuthUser? user;

  @override
  Widget build(BuildContext context) {
    // TEMPORARILY DISABLED - SUMSUB KYC
    // Do not display or interpret persisted KYC decisions while paused.
    return const AppBadge(
      label: 'temporarily unavailable',
      color: AppColors.warning,
      backgroundColor: Color(0x1AF59E0B),
    );

    /*
    Preserved KYC status rendering:
    if (user == null) {
      return const AppBadge(
        label: 'required',
        color: AppColors.warning,
        backgroundColor: Color(0x1AF59E0B),
      );
    }

    return switch (user!.kycStatus.toLowerCase()) {
      'approved' => AppBadge.verified(label: 'approved'),
      'submitted' => const AppBadge(
          label: 'pending',
          color: AppColors.warning,
          backgroundColor: Color(0x1AF59E0B),
        ),
      'rejected' => const AppBadge(
          label: 'rejected',
          color: AppColors.danger,
          backgroundColor: Color(0x1AEF4444),
        ),
      _ => const AppBadge(
          label: 'required',
          color: AppColors.warning,
          backgroundColor: Color(0x1AF59E0B),
        ),
    };
    */
  }
}
