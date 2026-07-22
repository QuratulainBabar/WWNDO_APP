import 'package:flutter/material.dart';
import '../layout/responsive.dart';
import '../platform/platform_ui.dart';

/// Scrollable screen body with responsive padding and platform scroll physics.
class ScreenBody extends StatelessWidget {
  const ScreenBody({
    super.key,
    required this.child,
    this.padding,
    this.safeArea = true,
    this.keyboardDismiss = true,
  });

  final Widget child;
  final EdgeInsets? padding;
  final bool safeArea;
  final bool keyboardDismiss;

  @override
  Widget build(BuildContext context) {
    final effectivePadding = context.pagePaddingWithKeyboard(padding);

    Widget body = SingleChildScrollView(
      physics: PlatformUi.scrollPhysics,
      padding: effectivePadding,
      child: child,
    );

    if (keyboardDismiss) {
      body = GestureDetector(
        onTap: () => FocusManager.instance.primaryFocus?.unfocus(),
        behavior: HitTestBehavior.translucent,
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
