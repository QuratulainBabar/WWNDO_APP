import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../layout/responsive.dart';
import '../../providers/locale_provider.dart';

/// Centers content and constrains width on tablets / wide screens.
class ScreenContainer extends StatelessWidget {
  const ScreenContainer({
    super.key,
    required this.child,
    this.constrainWidth = true,
  });

  final Widget child;
  final bool constrainWidth;

  @override
  Widget build(BuildContext context) {
    // Rebuild shared chrome when theme or language changes.
    Theme.of(context);
    context.watch<LocaleProvider>();
    if (!constrainWidth || !context.isTablet) {
      return child;
    }

    return Align(
      alignment: Alignment.topCenter,
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: context.contentMaxWidth),
        child: child,
      ),
    );
  }
}
