import 'package:flutter/material.dart';

/// Yellow warning triangle with exclamation mark for dispute status screens.
class DisputeWarningIcon extends StatelessWidget {
  const DisputeWarningIcon({super.key, this.size = 36});

  final double size;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: CustomPaint(painter: const _DisputeWarningIconPainter()),
    );
  }
}

class _DisputeWarningIconPainter extends CustomPainter {
  const _DisputeWarningIconPainter();

  static const _yellow = Color(0xFFFFCC00);
  static const _black = Color(0xFF1A1A1A);

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;
    final padding = w * 0.04;

    final triangle = Path()
      ..moveTo(w / 2, padding)
      ..lineTo(w - padding, h - padding)
      ..lineTo(padding, h - padding)
      ..close();

    canvas.drawPath(triangle, Paint()..color = _yellow);

    final cx = w / 2;
    final stemTop = h * 0.32;
    final stemBottom = h * 0.62;
    final stemWidth = w * 0.09;

    final stem = RRect.fromRectAndRadius(
      Rect.fromCenter(
        center: Offset(cx, (stemTop + stemBottom) / 2),
        width: stemWidth,
        height: stemBottom - stemTop,
      ),
      Radius.circular(stemWidth / 2),
    );
    canvas.drawRRect(stem, Paint()..color = _black);

    canvas.drawCircle(
      Offset(cx, h * 0.76),
      w * 0.055,
      Paint()..color = _black,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
