import 'package:flutter/material.dart';
import '../layout/responsive.dart';
import '../navigation/app_navigation.dart';
import '../platform/platform_ui.dart';
import '../theme/app_typography.dart';

/// Shared ← Back label with a slightly larger arrow.
class BackLinkLabel extends StatelessWidget {
  const BackLinkLabel({super.key});

  @override
  Widget build(BuildContext context) {
    final style = context.typo.backLink;
    final arrowSize = (style.fontSize ?? 14) + 2;

    return Text.rich(
      TextSpan(
        children: [
          TextSpan(
            text: PlatformUi.backArrow,
            style: style.copyWith(fontSize: arrowSize, height: 1.1),
          ),
          TextSpan(text: ' Back', style: style),
        ],
      ),
    );
  }
}

/// Inline back control for forms and auth screens.
class BackLink extends StatelessWidget {
  const BackLink({super.key, this.onTap, this.fallbackRoute});

  final VoidCallback? onTap;
  final String? fallbackRoute;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap ?? () => appNavigateBackFromContext(context, fallback: fallbackRoute),
      child: const BackLinkLabel(),
    );
  }
}

/// Pins [BackLink] at the same top offset used on form screens (e.g. Create account).
class BackLinkScreen extends StatelessWidget {
  const BackLinkScreen({
    super.key,
    required this.child,
    this.padding,
    this.fallbackRoute,
  });

  final Widget child;
  final EdgeInsets? padding;
  final String? fallbackRoute;

  @override
  Widget build(BuildContext context) {
    final pagePadding = padding ?? context.pagePadding;

    return SafeArea(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: pagePadding.copyWith(bottom: 0),
            child: BackLink(fallbackRoute: fallbackRoute),
          ),
          Expanded(
            child: Padding(
              padding: pagePadding.copyWith(top: 0),
              child: child,
            ),
          ),
        ],
      ),
    );
  }
}
