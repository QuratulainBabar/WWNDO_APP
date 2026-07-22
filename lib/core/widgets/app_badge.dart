import 'package:flutter/material.dart';
import '../../data/models/shipment.dart';
import '../theme/app_colors.dart';
import '../theme/app_typography.dart';

class AppBadge extends StatelessWidget {
  const AppBadge({
    super.key,
    required this.label,
    this.color,
    this.backgroundColor,
    this.small = false,
    this.semiBold = false,
    this.wide = false,
  });

  factory AppBadge.status(ShipmentStatus status, {bool semiBold = false, bool wide = false}) {
    return AppBadge(
      label: status.label,
      color: status.color,
      backgroundColor: status.backgroundColor,
      semiBold: semiBold,
      wide: wide,
    );
  }

  factory AppBadge.verified({String label = '✓ ID'}) {
    return AppBadge(
      label: label,
      color: AppColors.primary,
      backgroundColor: AppColors.primary.withValues(alpha: 0.12),
    );
  }

  factory AppBadge.success(String label) {
    return AppBadge(
      label: label,
      color: AppColors.success,
      backgroundColor: AppColors.success.withValues(alpha: 0.1),
      small: true,
    );
  }

  final String label;
  final Color? color;
  final Color? backgroundColor;
  final bool small;
  final bool semiBold;
  final bool wide;

  @override
  Widget build(BuildContext context) {
    final typo = context.typo;
    final fg = color ?? AppColors.primary;
    final bg = backgroundColor ?? fg.withValues(alpha: 0.12);
    final baseStyle = small ? typo.badgeSm : typo.badge;
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: wide ? 14 : (small ? 8 : 10),
        vertical: small ? 3 : 4,
      ),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        label,
        style: baseStyle.copyWith(
          color: fg,
          fontWeight: semiBold ? FontWeight.w700 : baseStyle.fontWeight,
        ),
      ),
    );
  }
}
