import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../../data/models/shipment.dart';

/// Demo route map visualization for shipment tracking (static layer).
class ShipmentRouteMap extends StatelessWidget {
  const ShipmentRouteMap({
    super.key,
    required this.shipment,
    required this.stepProgress,
  });

  final Shipment shipment;
  final int stepProgress;

  @override
  Widget build(BuildContext context) {
    final typo = context.typo;
    final progress = (stepProgress / 5).clamp(0.0, 1.0);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Route map', style: typo.h3.copyWith(fontWeight: FontWeight.w700)),
        const SizedBox(height: 12),
        ClipRRect(
          borderRadius: BorderRadius.circular(14),
          child: SizedBox(
            height: 168,
            width: double.infinity,
            child: CustomPaint(
              painter: _RouteMapPainter(progress: progress),
              child: Padding(
                padding: const EdgeInsets.all(14),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        _CityMarker(
                          code: shipment.fromCode,
                          city: shipment.fromCity,
                          alignEnd: false,
                        ),
                        _CityMarker(
                          code: shipment.toCode,
                          city: shipment.toCity,
                          alignEnd: true,
                        ),
                      ],
                    ),
                    const Spacer(),
                    Text(
                      shipment.route,
                      textAlign: TextAlign.center,
                      style: typo.sm.copyWith(
                        color: AppColors.primary,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    if (shipment.flightNumber != null) ...[
                      const SizedBox(height: 4),
                      Text(
                        'Flight ${shipment.flightNumber}',
                        textAlign: TextAlign.center,
                        style: typo.caption,
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _CityMarker extends StatelessWidget {
  const _CityMarker({
    required this.code,
    required this.city,
    required this.alignEnd,
  });

  final String code;
  final String city;
  final bool alignEnd;

  @override
  Widget build(BuildContext context) {
    final typo = context.typo;
    return Column(
      crossAxisAlignment:
          alignEnd ? CrossAxisAlignment.end : CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: AppColors.primary.withValues(alpha: 0.35)),
          ),
          child: Text(
            code,
            style: typo.caption.copyWith(
              fontWeight: FontWeight.w800,
              color: AppColors.primary,
            ),
          ),
        ),
        const SizedBox(height: 4),
        Text(
          city,
          style: typo.caption.copyWith(fontWeight: FontWeight.w600),
        ),
      ],
    );
  }
}

class _RouteMapPainter extends CustomPainter {
  _RouteMapPainter({required this.progress});

  final double progress;

  @override
  void paint(Canvas canvas, Size size) {
    final bg = Paint()..color = const Color(0xFFE8EEF9);
    canvas.drawRect(Offset.zero & size, bg);

    final gridPaint = Paint()
      ..color = AppColors.primary.withValues(alpha: 0.06)
      ..strokeWidth = 1;
    for (var x = 0.0; x < size.width; x += 24) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), gridPaint);
    }
    for (var y = 0.0; y < size.height; y += 24) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), gridPaint);
    }

    final start = Offset(size.width * 0.12, size.height * 0.72);
    final end = Offset(size.width * 0.88, size.height * 0.28);
    final control = Offset(size.width * 0.5, size.height * 0.05);

    final path = Path()
      ..moveTo(start.dx, start.dy)
      ..quadraticBezierTo(control.dx, control.dy, end.dx, end.dy);

    final routePaint = Paint()
      ..color = AppColors.primary.withValues(alpha: 0.35)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3
      ..strokeCap = StrokeCap.round;
    canvas.drawPath(path, routePaint);

    final dotPaint = Paint()..color = AppColors.primary;
    canvas.drawCircle(start, 6, dotPaint);
    canvas.drawCircle(end, 6, dotPaint..color = AppColors.success);

    final metric = path.computeMetrics().first;
    final planePos = metric.getTangentForOffset(metric.length * progress)?.position;
    if (planePos != null && progress > 0) {
      canvas.save();
      canvas.translate(planePos.dx, planePos.dy);
      canvas.rotate(-math.pi / 6);
      final plane = TextPainter(
        text: const TextSpan(text: '✈', style: TextStyle(fontSize: 18)),
        textDirection: TextDirection.ltr,
      )..layout();
      plane.paint(canvas, Offset(-plane.width / 2, -plane.height / 2));
      canvas.restore();
    }
  }

  @override
  bool shouldRepaint(covariant _RouteMapPainter oldDelegate) =>
      oldDelegate.progress != progress;
}
