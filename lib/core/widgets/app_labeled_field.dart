import 'package:flutter/material.dart';
import '../theme/app_typography.dart';

abstract final class AppFieldSpacing {
  static const double top = 8;
  static const double labelGap = 8;
  static const double bottom = 4;
}

/// Label + input with consistent spacing used across form screens.
class AppLabeledField extends StatelessWidget {
  const AppLabeledField({
    super.key,
    required this.label,
    required this.child,
    this.labelStyle,
    this.padding,
  });

  final String label;
  final Widget child;
  final TextStyle? labelStyle;
  final EdgeInsetsGeometry? padding;

  @override
  Widget build(BuildContext context) {
    final typo = context.typo;
    return Padding(
      padding: padding ??
          const EdgeInsets.only(
            top: AppFieldSpacing.top,
            bottom: AppFieldSpacing.bottom,
          ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: labelStyle ?? typo.inputLabel),
          const SizedBox(height: AppFieldSpacing.labelGap),
          child,
        ],
      ),
    );
  }
}
