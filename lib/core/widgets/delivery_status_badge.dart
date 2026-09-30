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
    final l10n = context.l10n;
    final s = (status ?? 'posted').toLowerCase();
    final (label, color, bg) = switch (s) {
      'bid_accepted' || 'matched' => (l10n.statusBidAccepted, AppColors.success, AppColors.success.withValues(alpha: 0.12)),
      'waiting_receiver' => (l10n.statusAwaitingReceiver, AppColors.warning, AppColors.warning.withValues(alpha: 0.12)),
      'collected' => (l10n.statusCollected, AppColors.primary, AppColors.primary.withValues(alpha: 0.12)),
      'in_transit' => (l10n.statusInTransit, AppColors.primary, AppColors.primary.withValues(alpha: 0.12)),
      'delivered' => (l10n.statusDelivered, AppColors.success, AppColors.success.withValues(alpha: 0.12)),
      'disputed' => (l10n.statusDisputed, AppColors.danger, AppColors.danger.withValues(alpha: 0.12)),
      'cancelled' => (l10n.statusCancelled, AppColors.textSecondary, AppColors.border),
      'ready_for_handoff' => (l10n.statusReadyForHandoff, AppColors.warning, AppColors.warning.withValues(alpha: 0.12)),
      _ => (l10n.statusPosted, AppColors.textSecondary, AppColors.border),
    };
    return AppBadge(
      label: context.tr(label),
      color: color,
      backgroundColor: bg,
      semiBold: semiBold,
    );
  }
}
