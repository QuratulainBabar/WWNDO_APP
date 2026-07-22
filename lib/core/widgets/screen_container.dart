import 'package:flutter/material.dart';
import '../layout/responsive.dart';

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
