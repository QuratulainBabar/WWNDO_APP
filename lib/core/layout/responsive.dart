import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'app_breakpoints.dart';

extension ResponsiveContext on BuildContext {
  Size get screenSize => MediaQuery.sizeOf(this);

  double get screenWidth => screenSize.width;

  double get screenHeight => screenSize.height;

  bool get isLandscape => screenWidth > screenHeight;

  bool get isTablet => screenWidth >= AppBreakpoints.tablet;

  bool get isLargeScreen => screenWidth >= AppBreakpoints.desktop;

  bool get isCompactPhone => screenWidth < AppBreakpoints.compactPhone;

  bool get isShortScreen => screenHeight < AppBreakpoints.shortScreen;

  /// Width-based spacing scale for narrow vs wide phones.
  double get _widthScale {
    if (screenWidth < AppBreakpoints.compactPhone) return 0.85;
    if (screenWidth < AppBreakpoints.mediumPhone) return 0.92;
    if (isTablet) return 1.1;
    return 1.0;
  }

  /// Height-based spacing scale for short vs tall phones.
  double get _heightScale {
    if (isShortScreen) return 0.85;
    if (screenHeight < 740) return 0.92;
    return 1.0;
  }

  /// Scales a base spacing value for the current viewport.
  double scaledSpacing(double base) => base * _widthScale * _heightScale;

  /// Horizontal page padding — tighter on narrow phones, wider on tablets.
  double get horizontalPadding {
    if (screenWidth < AppBreakpoints.compactPhone) return 16;
    if (screenWidth < AppBreakpoints.mediumPhone) return 20;
    if (isTablet) return 32;
    return 24;
  }

  /// Vertical page padding — reduced on short screens.
  double get verticalPadding {
    if (isShortScreen) return 16;
    if (isTablet) return 28;
    return 24;
  }

  EdgeInsets get pagePadding => EdgeInsets.fromLTRB(
        horizontalPadding,
        verticalPadding,
        horizontalPadding,
        verticalPadding,
      );

  /// Adds keyboard inset to bottom padding so scrollable content stays visible.
  EdgeInsets pagePaddingWithKeyboard([EdgeInsets? base]) {
    final resolved = base ?? pagePadding;
    final keyboard = MediaQuery.viewInsetsOf(this).bottom;
    if (keyboard <= 0) return resolved;
    return resolved.copyWith(bottom: math.max(resolved.bottom, keyboard + 8));
  }

  /// Vertical gap between major screen sections.
  double get sectionGap => scaledSpacing(28);

  /// Gap between grouped blocks (cards, form groups).
  double get blockGap => scaledSpacing(20);

  /// Gap between form fields.
  double get fieldGap => scaledSpacing(18);

  /// Gap above pinned form actions.
  double get actionGap => scaledSpacing(16);

  /// Max width for centered phone-style content on wide screens.
  double get contentMaxWidth => math.min(screenWidth, AppBreakpoints.maxContentWidth);

  /// Scale a base font size for very small or large screens.
  double scaledFont(double base) {
    if (isTablet) return base * 1.05;
    if (isCompactPhone) return base * 0.95;
    return base;
  }
}
