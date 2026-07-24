import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/widgets/app_badge.dart';
import '../../../core/widgets/app_card.dart';
import '../../../core/widgets/kyc_status_badge.dart';
import '../../../data/models/auth_user.dart';
import '../../../data/models/profile_trust_metrics.dart';
import '../../../providers/auth_provider.dart';

class ProfileTrustIndicators extends StatelessWidget {
  const ProfileTrustIndicators({
    super.key,
    required this.metrics,
    this.authUser,
    this.loading = false,
  });

  final ProfileTrustMetrics metrics;
  final AuthUser? authUser;
  final bool loading;

  @override
  Widget build(BuildContext context) {
    final typo = context.typo;
    final user = authUser ?? context.watch<AuthProvider>().user;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Trust indicators', style: typo.h3.copyWith(fontWeight: FontWeight.w700)),
        const SizedBox(height: 10),
        AppCard(
          child: Column(
            children: [
              _row(
                context,
                label: 'KYC status',
                trailing: KycStatusBadge(user: user),
              ),
              const Divider(height: 24),
              _row(
                context,
                label: 'Completed deliveries',
                trailing: loading
                    ? _loadingValue(context)
                    : Text(
                        '${metrics.completedDeliveries}',
                        style: typo.bodyBold.copyWith(color: AppColors.primary),
                      ),
              ),
              const Divider(height: 24),
              _row(
                context,
                label: 'Cancellation rate',
                trailing: loading
                    ? _loadingValue(context)
                    : AppBadge(
                        label: '${metrics.cancellationRate.toStringAsFixed(1)}%',
                        color: AppColors.warning,
                        backgroundColor: AppColors.warning.withValues(alpha: 0.12),
                        small: true,
                      ),
              ),
              const Divider(height: 24),
              _row(
                context,
                label: 'Dispute rate',
                trailing: loading
                    ? _loadingValue(context)
                    : AppBadge(
                        label: '${metrics.disputeRate.toStringAsFixed(1)}%',
                        color: metrics.disputeRate > 2
                            ? AppColors.danger
                            : AppColors.success,
                        backgroundColor: (metrics.disputeRate > 2
                                ? AppColors.danger
                                : AppColors.success)
                            .withValues(alpha: 0.12),
                        small: true,
                      ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _loadingValue(BuildContext context) {
    return SizedBox(
      width: 16,
      height: 16,
      child: CircularProgressIndicator(
        strokeWidth: 2,
        color: context.typo.sm.color ?? AppColors.textSecondary,
      ),
    );
  }

  Widget _row(
    BuildContext context, {
    required String label,
    required Widget trailing,
  }) {
    final typo = context.typo;
    return Row(
      children: [
        Expanded(child: Text(label, style: typo.sm)),
        trailing,
      ],
    );
  }
}
