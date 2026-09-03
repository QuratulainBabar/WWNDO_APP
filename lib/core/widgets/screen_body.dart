import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import '../layout/responsive.dart';
import '../platform/platform_ui.dart';
import '../theme/app_colors.dart';

/// Enables mouse / trackpad drag so pull-to-refresh works on web & desktop.
class _RefreshScrollBehavior extends MaterialScrollBehavior {
  const _RefreshScrollBehavior();

  @override
  Set<PointerDeviceKind> get dragDevices => {
        PointerDeviceKind.touch,
        PointerDeviceKind.stylus,
        PointerDeviceKind.invertedStylus,
        PointerDeviceKind.trackpad,
        PointerDeviceKind.mouse,
      };
}

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

    // Bouncing + always-scrollable so RefreshIndicator can overscroll on web /
    // Android / short pages (Clamping alone often blocks the pull gesture).
    final physics = canRefresh
        ? const AlwaysScrollableScrollPhysics(parent: BouncingScrollPhysics())
        : PlatformUi.scrollPhysics;

    Widget body = SingleChildScrollView(
      physics: physics,
      padding: effectivePadding,
      keyboardDismissBehavior: keyboardDismiss
          ? ScrollViewKeyboardDismissBehavior.onDrag
          : ScrollViewKeyboardDismissBehavior.manual,
      child: child,
    );

    if (canRefresh) {
      body = ScrollConfiguration(
        behavior: const _RefreshScrollBehavior(),
        child: RefreshIndicator(
          color: AppColors.primary,
          displacement: 48,
          onRefresh: onRefresh!,
          child: body,
        ),
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
