import 'package:flutter/material.dart';

import '../../l10n/app_localizations.dart';
import '../theme/app_colors.dart';
import 'app_badge.dart';

/// Context-aware badge from backend delivery status string.
class DeliveryStatusBadge extends StatelessWidget {
  const DeliveryStatusBadge(this.status, {super.key, this.semiBold = false});

  final String? status;
  final bool semiBold;

  @override
  Widget build(BuildContext context) {
    final s = (status ?? 'posted').toLowerCase();
    final (label, color, bg) = switch (s) {
      'bid_accepted' || 'matched' => ('Bid accepted', AppColors.success, AppColors.success.withValues(alpha: 0.12)),
      'waiting_receiver' => ('Awaiting receiver', AppColors.warning, AppColors.warning.withValues(alpha: 0.12)),
      'collected' => ('Collected', AppColors.primary, AppColors.primary.withValues(alpha: 0.12)),
      'in_transit' => ('In transit', AppColors.primary, AppColors.primary.withValues(alpha: 0.12)),
      'delivered' => ('Delivered', AppColors.success, AppColors.success.withValues(alpha: 0.12)),
      'disputed' => ('Disputed', AppColors.danger, AppColors.danger.withValues(alpha: 0.12)),
      'cancelled' => ('Cancelled', AppColors.textSecondary, AppColors.border),
      'ready_for_handoff' => ('Ready for handoff', AppColors.warning, AppColors.warning.withValues(alpha: 0.12)),
      _ => ('Posted', AppColors.textSecondary, AppColors.border),
    };
    return AppBadge(
      label: context.tr(label),
      color: color,
      backgroundColor: bg,
      semiBold: semiBold,
    );
  }
}
