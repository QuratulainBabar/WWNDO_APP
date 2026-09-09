import 'package:flutter/material.dart';

import '../../data/route_display.dart';
import '../theme/app_colors.dart';
import '../theme/app_typography.dart';

/// From / To on separate rows so long map places stay readable on mobile.
///
/// Use for city-to-city and country-to-country lists and detail sections.
class StackedRouteEndpoints extends StatelessWidget {
  const StackedRouteEndpoints({
    super.key,
    this.from = '',
    this.to = '',
    this.fallbackRoute,
    this.sectionLabel,
    this.emphasized = false,
    this.bottomPadding = 0,
  });

  /// Split a single `"A → B"` route string into stacked endpoints.
  factory StackedRouteEndpoints.split(
    String route, {
    Key? key,
    String? sectionLabel,
    bool emphasized = false,
    double bottomPadding = 0,
  }) {
    final trimmed = route.trim();
    return StackedRouteEndpoints(
      key: key,
      from: routeLeft(trimmed),
      to: routeRight(trimmed),
      fallbackRoute: trimmed,
      sectionLabel: sectionLabel,
      emphasized: emphasized,
      bottomPadding: bottomPadding,
    );
  }

  final String from;
  final String to;
  final String? fallbackRoute;

  /// Optional heading above the endpoints (e.g. `"Route"` on detail screens).
  final String? sectionLabel;

  /// Slightly stronger place text for primary list cards.
  final bool emphasized;

  final double bottomPadding;

  @override
  Widget build(BuildContext context) {
    final typo = context.typo;
    final fromPlace = from.trim();
    final toPlace = to.trim();
    final fallback = (fallbackRoute ?? '').trim();

    if (fromPlace.isEmpty && toPlace.isEmpty) {
      return Padding(
        padding: EdgeInsets.only(bottom: bottomPadding),
        child: Text(
          fallback.isNotEmpty ? fallback : '—',
          style: _placeStyle(typo),
        ),
      );
    }

    final labelStyle = typo.sm.copyWith(
      fontSize: 11,
      fontWeight: FontWeight.w700,
      letterSpacing: 0.4,
    );

    return Padding(
      padding: EdgeInsets.only(bottom: bottomPadding),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (sectionLabel != null && sectionLabel!.trim().isNotEmpty) ...[
            Text(sectionLabel!.trim(), style: typo.sm),
            const SizedBox(height: 8),
          ],
          if (fromPlace.isNotEmpty) ...[
            Text(
              'FROM',
              style: labelStyle.copyWith(color: AppColors.primary),
            ),
            const SizedBox(height: 3),
            Text(fromPlace, style: _placeStyle(typo)),
          ],
          if (fromPlace.isNotEmpty && toPlace.isNotEmpty)
            const SizedBox(height: 10),
          if (toPlace.isNotEmpty) ...[
            Text(
              'TO',
              style: labelStyle.copyWith(color: AppColors.success),
            ),
            const SizedBox(height: 3),
            Text(toPlace, style: _placeStyle(typo)),
          ],
        ],
      ),
    );
  }

  TextStyle _placeStyle(AppTypography typo) {
    if (emphasized) {
      return typo.sm.copyWith(
        height: 1.4,
        fontWeight: FontWeight.w600,
        color: AppColors.textPrimary,
      );
    }
    return typo.sm.copyWith(
      height: 1.4,
      color: AppColors.textPrimary,
    );
  }
}
