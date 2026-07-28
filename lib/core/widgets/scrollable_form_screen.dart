import 'package:flutter/material.dart';
import '../layout/responsive.dart';
import '../platform/platform_ui.dart';
import 'app_button.dart';

/// Scrollable form content with action buttons.
///
/// By default actions are pinned below the scroll view. Set [pinActions] to
/// false to place them at the end of the form after scrolling all fields.
class ScrollableFormScreen extends StatelessWidget {
  const ScrollableFormScreen({
    super.key,
    required this.child,
    required this.actions,
    this.padding,
    this.pinActions = true,
  });

  final Widget child;
  final List<Widget> actions;
  final EdgeInsets? padding;

  /// When true (default), actions stay fixed below the scroll area.
  /// When false, actions scroll with the form as the last content.
  final bool pinActions;

  @override
  Widget build(BuildContext context) {
    final pagePadding = padding ?? context.pagePadding;
    final scrollPadding = context.pagePaddingWithKeyboard(pagePadding);
    final actionColumn = Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: _spacedActions(actions),
    );

    if (!pinActions) {
      return SafeArea(
        child: SingleChildScrollView(
          physics: PlatformUi.scrollPhysics,
          padding: scrollPadding,
          keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              child,
              SizedBox(height: context.actionGap),
              actionColumn,
            ],
          ),
        ),
      );
    }

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
            child: actionColumn,
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
