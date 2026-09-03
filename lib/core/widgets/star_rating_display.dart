import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../theme/app_typography.dart';

class StarRatingDisplay extends StatelessWidget {
  const StarRatingDisplay({
    super.key,
    required this.rating,
    this.showValue = true,
    this.size = 14,
    this.valueFontWeight = FontWeight.w700,
  });

  final double rating;
  final bool showValue;
  final double size;
  final FontWeight valueFontWeight;

  @override
  Widget build(BuildContext context) {
    final typo = context.typo;
    final clamped = rating.clamp(0.0, 5.0);
    final full = clamped.floor();
    final hasHalf = clamped - full >= 0.5;
    final stars = StringBuffer();
    for (var i = 0; i < 5; i++) {
      if (i < full) {
        stars.write('★');
      } else if (i == full && hasHalf) {
        stars.write('★');
      } else {
        stars.write('☆');
      }
    }

    return FittedBox(
      fit: BoxFit.scaleDown,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            stars.toString(),
            style: typo.starRating.copyWith(fontSize: size, color: AppColors.warning),
          ),
          if (showValue) ...[
            const SizedBox(width: 4),
            Text(
              clamped.toStringAsFixed(1),
              style: typo.sm.copyWith(fontWeight: valueFontWeight),
            ),
          ],
        ],
      ),
    );
  }
}
