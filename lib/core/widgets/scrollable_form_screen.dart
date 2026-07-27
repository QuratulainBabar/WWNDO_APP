import 'package:flutter/material.dart';
import '../layout/responsive.dart';
import '../platform/platform_ui.dart';
import 'app_button.dart';

/// Scrollable content with pinned action buttons — avoids [Spacer] inside scroll views.
class ScrollableFormScreen extends StatelessWidget {
  const ScrollableFormScreen({
    super.key,
    required this.child,
    required this.actions,
    this.padding,
  });

  final Widget child;
  final List<Widget> actions;
  final EdgeInsets? padding;

  @override
  Widget build(BuildContext context) {
    final pagePadding = padding ?? context.pagePadding;
    final scrollPadding = context.pagePaddingWithKeyboard(pagePadding);

    return SafeArea(
      child: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              physics: PlatformUi.scrollPhysics,
              padding: scrollPadding,
              keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
              child: child,
            ),
          ),
          Padding(
            padding: pagePadding.copyWith(top: context.actionGap),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: _spacedActions(actions),
            ),
          ),
        ],
      ),
    );
  }

  static List<Widget> _spacedActions(List<Widget> actions) {
    final widgets = actions.where((widget) => widget is! SizedBox).toList();
    if (widgets.length <= 1) return widgets;

    return [
      for (var i = 0; i < widgets.length; i++) ...[
        if (i > 0) const SizedBox(height: AppButton.stackGap),
        widgets[i],
      ],
    ];
  }
}
