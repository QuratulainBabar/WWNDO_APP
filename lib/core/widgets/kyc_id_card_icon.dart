import 'package:flutter/material.dart';

/// Stylized ID card graphic for KYC verification screens.
class KycIdCardIcon extends StatelessWidget {
  const KycIdCardIcon({super.key, this.size = 44});

  final double size;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size * 0.72,
      child: CustomPaint(painter: const _KycIdCardIconPainter()),
    );
  }
}

class _KycIdCardIconPainter extends CustomPainter {
  const _KycIdCardIconPainter();

  static const _cardColor = Color(0xFF93BFF5);
  static const _darkColor = Color(0xFF1E3A5F);
  static const _lineColor = Color(0xFF4A8FD4);

  @override
  void paint(Canvas canvas, Size size) {
    final cardRect = RRect.fromRectAndRadius(
      Rect.fromLTWH(0, 0, size.width, size.height),
      Radius.circular(size.height * 0.12),
    );
    canvas.drawRRect(cardRect, Paint()..color = _cardColor);

    final headCenter = Offset(size.width * 0.24, size.height * 0.36);
    canvas.drawCircle(headCenter, size.height * 0.13, Paint()..color = _darkColor);

    final shoulders = Path()
      ..moveTo(size.width * 0.12, size.height * 0.86)
      ..quadraticBezierTo(
        size.width * 0.24,
        size.height * 0.56,
        size.width * 0.36,
        size.height * 0.86,
      )
      ..close();
    canvas.drawPath(shoulders, Paint()..color = _darkColor);

    final linePaint = Paint()
      ..color = _lineColor
      ..strokeWidth = size.height * 0.055
      ..strokeCap = StrokeCap.round;

    final lineStartX = size.width * 0.44;
    final lineEndX = size.width * 0.9;
    for (var i = 0; i < 4; i++) {
      final y = size.height * (0.26 + i * 0.14);
      canvas.drawLine(Offset(lineStartX, y), Offset(lineEndX, y), linePaint);
    }

    final chipRect = RRect.fromRectAndRadius(
      Rect.fromLTWH(
        size.width * 0.7,
        size.height * 0.7,
        size.width * 0.2,
        size.height * 0.18,
      ),
      Radius.circular(size.height * 0.04),
    );
    canvas.drawRRect(chipRect, Paint()..color = _darkColor);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
