import 'package:flutter/material.dart';

import '../theme/app_typography.dart';

/// Single-line bottom navigation label that scales down when needed.
class BottomNavLabel extends StatelessWidget {
  const BottomNavLabel({
    super.key,
    required this.label,
    required this.color,
    this.active = false,
  });

  final String label;
  final Color color;
  final bool active;

  @override
  Widget build(BuildContext context) {
    final languageCode = Localizations.localeOf(context).languageCode;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 2),
      child: FittedBox(
        fit: BoxFit.scaleDown,
        child: Text(
          label,
          maxLines: 1,
          softWrap: false,
          textAlign: TextAlign.center,
          style: context.typo.bottomNavLabel(
            color,
            languageCode: languageCode,
            active: active,
          ),
        ),
      ),
    );
  }
}
