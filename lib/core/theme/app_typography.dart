import 'package:flutter/material.dart';
import 'app_colors.dart';

/// Typography aligned with the original WWNGO design file.
/// Segoe UI is bundled in assets/fonts so it renders on every platform.
@immutable
class AppTypography extends ThemeExtension<AppTypography> {
  const AppTypography({this.colors = AppColorPalette.light});

  final AppColorPalette colors;

  static const String fontFamilyName = 'Segoe UI';

  static AppTypography light() => const AppTypography(colors: AppColorPalette.light);

  static AppTypography dark() => const AppTypography(colors: AppColorPalette.dark);

  TextStyle _style({
    required double fontSize,
    FontWeight? fontWeight,
    Color? color,
    double? height,
    double? letterSpacing,
    FontStyle? fontStyle,
  }) {
    return TextStyle(
      fontFamily: fontFamilyName,
      fontSize: fontSize,
      fontWeight: fontWeight,
      color: color,
      height: height,
      letterSpacing: letterSpacing,
      fontStyle: fontStyle,
    );
  }

  // ── Core scale (mobile-readable minimums: body 15, sm 15, labels 12+) ──
  TextStyle get h1 => _style(fontSize: 26, fontWeight: FontWeight.w900, color: colors.textPrimary, height: 1.25);
  TextStyle get h2 => _style(fontSize: 22, fontWeight: FontWeight.w900, color: colors.textPrimary, height: 1.3);
  TextStyle get h3 => _style(fontSize: 19, fontWeight: FontWeight.w900, color: colors.textPrimary, height: 1.35);
  TextStyle get subheading => _style(fontSize: 16, fontWeight: FontWeight.w400, color: colors.textSecondary, height: 1.5);
  TextStyle get body => _style(fontSize: 15, fontWeight: FontWeight.w400, color: colors.textPrimary, height: 1.5);
  TextStyle get bodyBold => _style(fontSize: 17, fontWeight: FontWeight.w900, color: colors.textPrimary, height: 1.5);
  TextStyle get sm => _style(fontSize: 15, fontWeight: FontWeight.w400, color: colors.textSecondary, height: 1.5);
  TextStyle get smPrimary => _style(fontSize: 15, fontWeight: FontWeight.w400, color: colors.textPrimary, height: 1.5);
  TextStyle get label => _style(
        fontSize: 15,
        fontWeight: FontWeight.w900,
        color: colors.textSecondary,
        letterSpacing: 0.5,
        height: 1.4,
      );

  // ── UI components ──
  TextStyle get input => _style(fontSize: 16, fontWeight: FontWeight.w400, color: colors.textPrimary);
  TextStyle get inputLabel => _style(fontSize: 14, fontWeight: FontWeight.w900, color: colors.textPrimary, height: 1.4);
  TextStyle get button => _style(fontSize: 16, fontWeight: FontWeight.w700, color: Colors.white, height: 1.3);
  TextStyle get buttonSm => _style(fontSize: 14, fontWeight: FontWeight.w700);
  TextStyle get buttonDanger => _style(fontSize: 14, fontWeight: FontWeight.w700, color: AppColors.danger);
  TextStyle get badge => _style(fontSize: 13, fontWeight: FontWeight.w600);
  TextStyle get badgeSm => _style(fontSize: 12, fontWeight: FontWeight.w600);
  TextStyle get chip => _style(fontSize: 15, fontWeight: FontWeight.w400, color: colors.textSecondary);
  TextStyle get backLink => _style(fontSize: 15, fontWeight: FontWeight.w400, color: AppColors.primary);
  TextStyle get link => _style(fontSize: 14, fontWeight: FontWeight.w400, color: AppColors.primary);
  TextStyle get linkBold => _style(fontSize: 14, fontWeight: FontWeight.w900, color: AppColors.primary);
  TextStyle get headerTitle => _style(fontSize: 19, fontWeight: FontWeight.w700, color: colors.textPrimary, height: 1.25);
  TextStyle get tabLabel => _style(fontSize: 14, fontWeight: FontWeight.w400, color: colors.textSecondary);
  TextStyle get tabIcon => _style(fontSize: 20);

  // ── Gradient / brand headers ──
  TextStyle get gradHeaderTitle => _style(fontSize: 26, fontWeight: FontWeight.w900, color: Colors.white, height: 1.25);
  TextStyle get gradHeaderSubtitle => _style(
        fontSize: 14,
        fontWeight: FontWeight.w400,
        color: Colors.white.withValues(alpha: 0.8),
        height: 1.5,
      );
  TextStyle get brandSplash => _style(
        fontSize: 56,
        fontWeight: FontWeight.w900,
        color: Colors.white,
        height: 1.1,
        letterSpacing: 6,
      );
  TextStyle get brandWelcome => _style(
        fontSize: 56,
        fontWeight: FontWeight.w900,
        color: Colors.white,
        height: 1.1,
        letterSpacing: 5,
      );
  TextStyle get welcomeHeadline => _style(
        fontSize: 36,
        fontWeight: FontWeight.w900,
        color: Colors.white,
        height: 1.25,
        letterSpacing: -0.3,
      );
  TextStyle get welcomeSubtext => _style(
        fontSize: 18,
        fontWeight: FontWeight.w400,
        color: Colors.white.withValues(alpha: 0.75),
        height: 1.5,
      );
  TextStyle get welcomeButton => _style(
        fontSize: 16,
        fontWeight: FontWeight.w700,
        color: Colors.white,
        height: 1.3,
      );
  TextStyle get splashTagline => _style(
        fontSize: 18,
        fontWeight: FontWeight.w400,
        color: Colors.white.withValues(alpha: 0.8),
        height: 1.5,
      );

  // ── Home / wallet ──
  TextStyle get walletLabel => _style(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.primary);
  TextStyle get walletAmount => _style(fontSize: 19, fontWeight: FontWeight.w900, color: AppColors.primary);
  TextStyle get searchHint => _style(fontSize: 16, fontWeight: FontWeight.w400, color: colors.textSecondary);
  TextStyle get actionLabel => _style(fontSize: 14, fontWeight: FontWeight.w500, color: colors.textPrimary, height: 1.25);
  TextStyle get actionIcon => _style(fontSize: 22);
  TextStyle get routeArrow => _style(fontSize: 14, fontWeight: FontWeight.w400, color: AppColors.primary);

  // ── Prices ──
  TextStyle get priceHero => _style(fontSize: 42, fontWeight: FontWeight.w900, color: Colors.white);
  TextStyle get priceHeroDark => _style(fontSize: 46, fontWeight: FontWeight.w900, color: Colors.white);
  TextStyle get priceLarge => _style(fontSize: 22, fontWeight: FontWeight.w900, color: AppColors.primary);
  TextStyle get priceMedium => _style(fontSize: 20, fontWeight: FontWeight.w900, color: AppColors.primary);
  TextStyle get priceSmall => _style(fontSize: 18, fontWeight: FontWeight.w900, color: AppColors.primary);
  TextStyle get amountInput => _style(fontSize: 18, fontWeight: FontWeight.w400, color: colors.textPrimary);
  TextStyle get trackingId => _style(fontSize: 20, fontWeight: FontWeight.w700, color: AppColors.primary);

  // ── Chat / steps ──
  TextStyle get stepText => _style(fontSize: 15, fontWeight: FontWeight.w400, color: colors.textSecondary, height: 1.5);
  TextStyle get stepTextCurrent => _style(fontSize: 15, fontWeight: FontWeight.w900, color: AppColors.primary, height: 1.5);
  TextStyle get bubbleText => _style(fontSize: 14, fontWeight: FontWeight.w400, height: 1.5);
  TextStyle get bubbleTextMine => _style(fontSize: 14, fontWeight: FontWeight.w400, color: Colors.white, height: 1.5);
  TextStyle get bubbleTime => _style(fontSize: 14, fontWeight: FontWeight.w400, color: colors.textSecondary);
  TextStyle get chatInput => _style(fontSize: 15, fontWeight: FontWeight.w400, color: colors.textSecondary);
  TextStyle get datePill => _style(fontSize: 14, fontWeight: FontWeight.w400, color: colors.textSecondary);

  // ── Misc screen text ──
  TextStyle get caption => _style(fontSize: 15, fontWeight: FontWeight.w400, color: colors.textSecondary, height: 1.5);
  TextStyle get captionOnDark => _style(fontSize: 14, fontWeight: FontWeight.w400, color: Colors.white.withValues(alpha: 0.7), height: 1.5);
  TextStyle get captionOnDarkSoft => _style(fontSize: 14, fontWeight: FontWeight.w400, color: Colors.white.withValues(alpha: 0.8), height: 1.5);
  TextStyle get italicQuote => _style(fontSize: 14, fontWeight: FontWeight.w400, fontStyle: FontStyle.italic, color: colors.textPrimary, height: 1.5);
  TextStyle get bodyOnDark => _style(fontSize: 14, fontWeight: FontWeight.w400, color: Colors.white.withValues(alpha: 0.65), height: 1.5);
  TextStyle get screenTitleDark => _style(fontSize: 26, fontWeight: FontWeight.w900, color: Colors.white, height: 1.25);
  TextStyle get nfcTitle => _style(fontSize: 28, fontWeight: FontWeight.w900, color: Colors.white, height: 1.25);
  TextStyle get nfcBody => _style(fontSize: 15, fontWeight: FontWeight.w400, color: Colors.white.withValues(alpha: 0.7), height: 1.5);
  TextStyle get starRating => _style(fontSize: 14, fontWeight: FontWeight.w400, color: AppColors.warning);
  TextStyle get reviewText => _style(fontSize: 14, fontWeight: FontWeight.w400, height: 1.5);
  TextStyle get policyTitle => _style(fontSize: 14, fontWeight: FontWeight.w900, color: AppColors.danger);
  TextStyle get emojiLg => _style(fontSize: 36);
  TextStyle get emojiXl => _style(fontSize: 48);
  TextStyle get emojiHero => _style(fontSize: 60);
  TextStyle get avatarMd => _style(fontSize: 16, fontWeight: FontWeight.w900, color: AppColors.primary);
  TextStyle get avatarSm => _style(fontSize: 14, fontWeight: FontWeight.w900, color: AppColors.primary);
  TextStyle get avatarLg => _style(fontSize: 24, fontWeight: FontWeight.w900, color: AppColors.primary);

  TextStyle tabLabelActive(Color color) => tabLabel.copyWith(
        color: color,
        fontWeight: color == AppColors.primary ? FontWeight.w900 : FontWeight.w400,
      );

  /// Bottom-nav label style. Arabic uses a smaller size so longer labels
  /// (e.g. الملف الشخصي) stay on one line like English.
  TextStyle bottomNavLabel(
    Color color, {
    required String languageCode,
    bool active = false,
  }) {
    final isArabic = languageCode == 'ar';
    return tabLabel.copyWith(
      color: color,
      fontWeight: active ? FontWeight.w900 : FontWeight.w400,
      fontSize: isArabic ? 11 : 14,
      height: 1.1,
    );
  }

  /// Base text theme for Material [ThemeData].
  TextTheme get materialTextTheme => (colors == AppColorPalette.dark
          ? ThemeData.dark()
          : ThemeData.light())
      .textTheme
      .apply(fontFamily: fontFamilyName);

  static AppTypography of(BuildContext context) {
    return Theme.of(context).extension<AppTypography>() ?? light();
  }

  @override
  AppTypography copyWith({AppColorPalette? colors}) =>
      AppTypography(colors: colors ?? this.colors);

  @override
  AppTypography lerp(ThemeExtension<AppTypography>? other, double t) {
    if (other is! AppTypography) return this;
    return t < 0.5 ? this : other;
  }
}

extension AppTypographyContext on BuildContext {
  AppTypography get typo => AppTypography.of(this);
}
