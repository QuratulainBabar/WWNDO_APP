import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../../data/models/shipment.dart';
import 'tracking_step_state.dart';

/// Vertical status timeline (Open → Delivered).
class ShipmentStatusTimeline extends StatelessWidget {
  const ShipmentStatusTimeline({
    super.key,
    required this.stepProgress,
  });

  final int stepProgress;

  @override
  Widget build(BuildContext context) {
    final typo = context.typo;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Status timeline', style: typo.h3.copyWith(fontWeight: FontWeight.w700)),
        const SizedBox(height: 12),
        ...List.generate(Shipment.trackingSteps.length, (i) {
          return _TimelineStep(
            label: Shipment.trackingSteps[i],
            isDone: trackingStepIsDone(stepProgress, i),
            isCurrent: trackingStepIsCurrent(stepProgress, i),
            isLast: i == Shipment.trackingSteps.length - 1,
          );
        }),
      ],
    );
  }
}

class _TimelineStep extends StatelessWidget {
  const _TimelineStep({
    required this.label,
    required this.isDone,
    required this.isCurrent,
    required this.isLast,
  });

  final String label;
  final bool isDone;
  final bool isCurrent;
  final bool isLast;

  @override
  Widget build(BuildContext context) {
    final typo = context.typo;
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 20,
            child: Column(
              children: [
                Container(
                  width: 20,
                  height: 20,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: isDone ? AppColors.success : null,
                    border: Border.all(
                      color: isDone
                          ? AppColors.success
                          : isCurrent
                              ? AppColors.primary
                              : AppColors.border,
                      width: 2,
                    ),
                  ),
                  child: isDone
                      ? const Icon(Icons.check, size: 12, color: Colors.white)
                      : isCurrent
                          ? Center(
                              child: Container(
                                width: 8,
                                height: 8,
                                decoration: const BoxDecoration(
                                  color: AppColors.primary,
                                  shape: BoxShape.circle,
                                ),
                              ),
                            )
                          : null,
                ),
                if (!isLast)
                  Expanded(
                    child: Container(
                      width: 2,
                      color: isDone ? AppColors.success : AppColors.border,
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Padding(
              padding: EdgeInsets.only(bottom: isLast ? 0 : 20),
              child: Text(
                label,
                style: isCurrent ? typo.stepTextCurrent : typo.stepText,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
