import 'package:flutter/material.dart';

abstract final class SplashWelcomeGradientColors {
  static const start = Color(0xFF2563EB);
  static const end = Color(0xFF1E3A8A);
}

class PrimaryGradientBackground extends StatelessWidget {
  const PrimaryGradientBackground({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [SplashWelcomeGradientColors.start, SplashWelcomeGradientColors.end],
        ),
      ),
      child: child,
    );
  }
}
