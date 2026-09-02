import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../../data/platform_fees.dart';

/// Optional platform fee choice shown below Parcel Acknowledgement on post delivery.
class PlatformFeeSection extends StatefulWidget {
  const PlatformFeeSection({
    super.key,
    required this.parcelCategory,
    this.onChanged,
  });

  final String parcelCategory;
  final ValueChanged<bool>? onChanged;

  @override
  State<PlatformFeeSection> createState() => _PlatformFeeSectionState();
}

class _PlatformFeeSectionState extends State<PlatformFeeSection> {
  bool _payFullFee = false;

  @override
  void didUpdateWidget(covariant PlatformFeeSection oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.parcelCategory != widget.parcelCategory) {
      setState(() {});
    }
  }

  @override
  Widget build(BuildContext context) {
    final typo = context.typo;
    final senderOnlyFee = PlatformFees.senderPlatformFeeUsd(
      category: widget.parcelCategory,
      paysReceiverFee: false,
    );
    final senderPaysAllFee = PlatformFees.senderPlatformFeeUsd(
      category: widget.parcelCategory,
      paysReceiverFee: true,
    );
    final selectedFee = _payFullFee ? senderPaysAllFee : senderOnlyFee;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.primary.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.primary.withValues(alpha: 0.45)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          InkWell(
            onTap: () {
              setState(() => _payFullFee = !_payFullFee);
              widget.onChanged?.call(_payFullFee);
            },
            borderRadius: BorderRadius.circular(8),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SizedBox(
                  width: 24,
                  height: 24,
                  child: Checkbox(
                    value: _payFullFee,
                    activeColor: AppColors.primary,
                    side: const BorderSide(color: AppColors.primary, width: 1.5),
                    onChanged: (value) {
                      final next = value ?? false;
                      setState(() => _payFullFee = next);
                      widget.onChanged?.call(next);
                    },
                    materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    visualDensity: VisualDensity.compact,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'Would you like to pay 100% platform fee?',
                    style: typo.bodyBold.copyWith(
                      fontWeight: FontWeight.w700,
                      color: AppColors.primary,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 10),
          Text(
            _payFullFee
                ? 'Your sender fee at Pay Now: '
                    '\$${senderPaysAllFee.toStringAsFixed(2)} '
                    '(includes the receiver\'s share).'
                : 'Your sender fee at Pay Now: '
                    '\$${senderOnlyFee.toStringAsFixed(2)}. '
                    'The receiver pays their share separately when they accept.',
            style: typo.sm.copyWith(
              color: AppColors.textSecondary,
              height: 1.45,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'Selected: \$${selectedFee.toStringAsFixed(2)}',
            style: typo.sm.copyWith(
              fontWeight: FontWeight.w700,
              color: AppColors.primary,
            ),
          ),
        ],
      ),
    );
  }
}
