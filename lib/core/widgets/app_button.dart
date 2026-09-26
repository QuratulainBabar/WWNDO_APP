import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../theme/app_typography.dart';

enum AppButtonVariant { primary, outline, ghost, danger, outlineWhite }

class AppButton extends StatelessWidget {
  /// Vertical gap between stacked full-width buttons.
  static const double stackGap = 14;

  const AppButton({
    super.key,
    required this.label,
    this.onPressed,
    this.variant = AppButtonVariant.primary,
    this.small = false,
    this.icon,
    this.textStyle,
  });

  final String label;
  final VoidCallback? onPressed;
  final AppButtonVariant variant;
  final bool small;
  final Widget? icon;
  final TextStyle? textStyle;

  @override
  Widget build(BuildContext context) {
    final typo = context.typo;
    final radius = BorderRadius.circular(small ? 10 : 14);
    final padding = EdgeInsets.symmetric(
      vertical: small ? 10 : 14,
      horizontal: small ? 16 : 20,
    );
    final labelStyle = textStyle ?? (small ? typo.buttonSm : typo.button);

    switch (variant) {
      case AppButtonVariant.primary:
        return SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            onPressed: onPressed,
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
              disabledBackgroundColor: AppColors.textDisabled,
              disabledForegroundColor: Colors.white,
              elevation: 0,
              shadowColor: Colors.transparent,
              surfaceTintColor: Colors.transparent,
              padding: padding,
              shape: RoundedRectangleBorder(borderRadius: radius),
            ),
            child: _label(context, labelStyle),
          ),
        );
      case AppButtonVariant.outline:
        return SizedBox(
          width: double.infinity,
          child: OutlinedButton(
            onPressed: onPressed,
            style: OutlinedButton.styleFrom(
              padding: padding,
              side: BorderSide(color: AppColors.border, width: 1.5),
              foregroundColor: AppColors.textPrimary,
              shape: RoundedRectangleBorder(borderRadius: radius),
            ),
            child: _label(
              context,
              labelStyle.copyWith(color: textStyle?.color ?? AppColors.textPrimary),
            ),
          ),
        );
      case AppButtonVariant.outlineWhite:
        return SizedBox(
          width: double.infinity,
          child: OutlinedButton(
            onPressed: onPressed,
            style: OutlinedButton.styleFrom(
              padding: padding,
              side: BorderSide(color: Colors.white.withValues(alpha: 0.6), width: 2),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: radius),
            ),
            child: _label(context, labelStyle),
          ),
        );
      case AppButtonVariant.ghost:
        return SizedBox(
          width: double.infinity,
          child: OutlinedButton(
            onPressed: onPressed,
            style: OutlinedButton.styleFrom(
              padding: padding,
              backgroundColor: AppColors.primary.withValues(alpha: 0.1),
              disabledBackgroundColor: AppColors.border.withValues(alpha: 0.35),
              side: BorderSide(color: AppColors.primary.withValues(alpha: 0.3), width: 1.5),
              disabledForegroundColor: AppColors.textDisabled,
              foregroundColor: AppColors.primary,
              shape: RoundedRectangleBorder(borderRadius: radius),
            ),
            child: _label(context, labelStyle.copyWith(
              color: onPressed == null
                  ? AppColors.textDisabled
                  : AppColors.primary,
            )),
          ),
        );
      case AppButtonVariant.danger:
        return SizedBox(
          width: double.infinity,
          child: OutlinedButton(
            onPressed: onPressed,
            style: OutlinedButton.styleFrom(
              padding: padding,
              side: BorderSide(color: AppColors.danger.withValues(alpha: 0.4), width: 1.5),
              foregroundColor: AppColors.danger,
              shape: RoundedRectangleBorder(borderRadius: radius),
            ),
            child: _label(
              context,
              textStyle ?? (small ? typo.buttonSm.copyWith(color: AppColors.danger) : typo.buttonDanger),
            ),
          ),
        );
    }
  }

  Widget _label(BuildContext context, TextStyle style) {
    final text = Text(
      label,
      style: style,
      textAlign: TextAlign.center,
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
    );
    if (icon == null) return text;
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      mainAxisSize: MainAxisSize.min,
      children: [
        icon!,
        const SizedBox(width: 8),
        Flexible(child: text),
      ],
    );
  }
}
