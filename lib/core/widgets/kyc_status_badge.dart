import 'package:flutter/material.dart';

import '../../data/models/auth_user.dart';
import '../../l10n/app_localizations.dart';
import '../theme/app_colors.dart';
import 'app_badge.dart';

class KycStatusBadge extends StatelessWidget {
  const KycStatusBadge({super.key, required this.user});

  final AuthUser? user;

  @override
  Widget build(BuildContext context) {
    if (user == null) {
      return AppBadge(
        label: context.l10n.kycBadgeRequired,
        color: AppColors.warning,
        backgroundColor: const Color(0x1AF59E0B),
      );
    }

    return switch (user!.kycStatus.toLowerCase()) {
      'approved' => AppBadge.verified(label: context.l10n.kycBadgeApproved),
      'submitted' => AppBadge(
          label: context.l10n.kycBadgePending,
          color: AppColors.warning,
          backgroundColor: const Color(0x1AF59E0B),
        ),
      'rejected' => AppBadge(
          label: context.l10n.kycBadgeRejected,
          color: AppColors.danger,
          backgroundColor: const Color(0x1AEF4444),
        ),
      _ => AppBadge(
          label: context.l10n.kycBadgeRequired,
          color: AppColors.warning,
          backgroundColor: const Color(0x1AF59E0B),
        ),
    };
  }
}
