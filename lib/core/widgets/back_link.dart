import 'package:flutter/material.dart';
import '../layout/responsive.dart';
import '../navigation/app_navigation.dart';
import '../platform/platform_ui.dart';
import '../theme/app_typography.dart';
import '../../l10n/app_localizations.dart';

/// Shared ← Back label with a slightly larger arrow.
///
/// Arrow and translated label stay on one line for all locales; text scales
/// down slightly when space is tight instead of wrapping under the arrow.
class BackLinkLabel extends StatelessWidget {
  const BackLinkLabel({super.key});

  @override
  Widget build(BuildContext context) {
    final style = context.typo.backLink;
    final arrowSize = (style.fontSize ?? 14) + 2;

    return FittedBox(
      fit: BoxFit.scaleDown,
      alignment: AlignmentDirectional.centerStart,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Text(
            PlatformUi.backArrow,
            style: style.copyWith(fontSize: arrowSize, height: 1),
            maxLines: 1,
            softWrap: false,
          ),
          const SizedBox(width: 4),
          Text(
            context.l10n.back,
            style: style.copyWith(height: 1),
            maxLines: 1,
            softWrap: false,
          ),
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
      onTap: onTap ??
          () => appNavigateBackFromContext(context, fallback: fallbackRoute),
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
