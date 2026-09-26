import 'package:flutter/material.dart';

/// Surface / text palette that switches with Light / Dark mode.
@immutable
class AppColorPalette {
  const AppColorPalette({
    required this.background,
    required this.surface,
    required this.border,
    required this.textPrimary,
    required this.textSecondary,
    required this.textDisabled,
    required this.kycBackground,
  });

  final Color background;
  final Color surface;
  final Color border;
  final Color textPrimary;
  final Color textSecondary;
  final Color textDisabled;
  final Color kycBackground;

  static const light = AppColorPalette(
    background: Color(0xFFF9FAFB),
    surface: Color(0xFFFFFFFF),
    border: Color(0xFFE5E7EB),
    textPrimary: Color(0xFF111827),
    textSecondary: Color(0xFF6B7280),
    textDisabled: Color(0xFFD1D5DB),
    kycBackground: Color(0xFFF0F4FF),
  );

  /// Professional dark surfaces with clear text contrast.
  static const dark = AppColorPalette(
    background: Color(0xFF0B1220),
    surface: Color(0xFF151C2C),
    border: Color(0xFF2A3548),
    textPrimary: Color(0xFFF3F4F6),
    textSecondary: Color(0xFF9CA3AF),
    textDisabled: Color(0xFF4B5563),
    kycBackground: Color(0xFF1A2438),
  );
}

/// App-wide colors. Brand/status colors are shared; surfaces follow [palette].
abstract final class AppColors {
  static AppColorPalette _palette = AppColorPalette.light;

  static AppColorPalette get palette => _palette;

  /// Called by [ThemeProvider] when Light / Dark mode changes.
  static void bind(AppColorPalette palette) {
    _palette = palette;
  }

  static const primary = Color(0xFF1A56DB);
  static const primaryDark = Color(0xFF1244B4);
  static const secondary = Color(0xFFF59E0B);
  static const success = Color(0xFF10B981);
  static const danger = Color(0xFFEF4444);
  static const warning = Color(0xFFF59E0B);

  static Color get background => _palette.background;
  static Color get surface => _palette.surface;
  static Color get border => _palette.border;

  /// Hover/press overlay (transparent — no grey flash on tap/hover).
  static const hover = Colors.transparent;

  static Color get textPrimary => _palette.textPrimary;
  static Color get textSecondary => _palette.textSecondary;
  static Color get textDisabled => _palette.textDisabled;
  static const transit = Color(0xFF8B5CF6);
  static Color get kycBackground => _palette.kycBackground;
  static const darkNavy = Color(0xFF1A1A2E);
  static const darkNavy2 = Color(0xFF16213E);
  static const nfcGradientStart = Color(0xFF0F172A);
  static const chatReadReceipt = Color(0xFF53BDEB);
}
