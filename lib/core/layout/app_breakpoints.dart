/// Layout breakpoints for phone / tablet responsive UI.
abstract final class AppBreakpoints {
  /// Narrow phones (e.g. iPhone SE, small Android).
  static const double compactPhone = 360;

  /// Standard small-to-medium phones.
  static const double mediumPhone = 400;

  /// Tablet and large foldable inner displays.
  static const double tablet = 600;

  static const double desktop = 900;

  /// Short viewports where vertical space should be conserved.
  static const double shortScreen = 680;

  static const double maxContentWidth = 480;
}
