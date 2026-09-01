import 'package:flutter/material.dart';
import '../layout/responsive.dart';
import '../platform/platform_ui.dart';
import '../theme/app_colors.dart';

/// Scrollable screen body with responsive padding and platform scroll physics.
///
/// When [keyboardDismiss] is true, dragging the scroll view dismisses the
/// keyboard. Do not wrap the body in a [GestureDetector] that unfocuses on tap —
/// that races with text field focus on MIUI / ColorOS devices
/// (flutter/flutter#185675). Keyboard inset is handled by Scaffold resize;
/// [pagePaddingWithKeyboard] only adds a small cushion, not a second full inset.
///
/// Pass [onRefresh] to enable pull-to-refresh from the top.
class ScreenBody extends StatelessWidget {
  const ScreenBody({
    super.key,
    required this.child,
    this.padding,
    this.safeArea = true,
    this.keyboardDismiss = true,
    this.onRefresh,
  });

  final Widget child;
  final EdgeInsets? padding;
  final bool safeArea;
  final bool keyboardDismiss;

  /// When set, wrapping [RefreshIndicator] lets the user pull down to reload.
  final Future<void> Function()? onRefresh;

  @override
  Widget build(BuildContext context) {
    final effectivePadding = context.pagePaddingWithKeyboard(padding);
    final canRefresh = onRefresh != null;

    Widget body = SingleChildScrollView(
      physics: canRefresh
          ? AlwaysScrollableScrollPhysics(parent: PlatformUi.scrollPhysics)
          : PlatformUi.scrollPhysics,
      padding: effectivePadding,
      keyboardDismissBehavior: keyboardDismiss
          ? ScrollViewKeyboardDismissBehavior.onDrag
          : ScrollViewKeyboardDismissBehavior.manual,
      child: child,
    );

    if (canRefresh) {
      body = RefreshIndicator(
        color: AppColors.primary,
        onRefresh: onRefresh!,
        child: body,
      );
    }

    if (safeArea) {
      body = SafeArea(child: body);
    }

    return body;
  }
}

/// Non-scrollable screen body with responsive padding.
class ScreenPadding extends StatelessWidget {
  const ScreenPadding({
    super.key,
    required this.child,
    this.padding,
    this.safeArea = true,
  });

  final Widget child;
  final EdgeInsets? padding;
  final bool safeArea;

  @override
  Widget build(BuildContext context) {
    Widget body = Padding(
      padding: padding ?? context.pagePadding,
      child: child,
    );

    if (safeArea) {
      body = SafeArea(child: body);
    }

    return body;
  }
}
