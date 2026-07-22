import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/widgets/app_card.dart';

class ParcelAcknowledgementSection extends StatefulWidget {
  const ParcelAcknowledgementSection({super.key, this.onChanged});

  final ValueChanged<bool>? onChanged;

  @override
  State<ParcelAcknowledgementSection> createState() => _ParcelAcknowledgementSectionState();
}

class _ParcelAcknowledgementSectionState extends State<ParcelAcknowledgementSection> {
  bool _acknowledged = false;

  static const _terms = [
    'The traveler may inspect/open the parcel before accepting it.',
    'The traveler will carry the parcel in their own luggage.',
    'Do not hand over your entire luggage; only the parcel.',
    'Liquids and prohibited items are not allowed.',
    'By continuing, you confirm that the information provided is accurate.',
  ];

  void _toggleAcknowledged() {
    setState(() => _acknowledged = !_acknowledged);
    widget.onChanged?.call(_acknowledged);
  }

  @override
  Widget build(BuildContext context) {
    final typo = context.typo;

    return AppCard(
      margin: EdgeInsets.zero,
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Parcel Acknowledgement',
            style: typo.bodyBold.copyWith(fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 8),
          Text(
            'Before posting your parcel, please read and acknowledge the following:',
            style: typo.sm.copyWith(color: AppColors.textPrimary),
          ),
          const SizedBox(height: 12),
          for (final term in _terms) ...[
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('• ', style: typo.sm.copyWith(color: AppColors.textPrimary)),
                  Expanded(
                    child: Text(
                      term,
                      style: typo.sm.copyWith(color: AppColors.textPrimary),
                    ),
                  ),
                ],
              ),
            ),
          ],
          const SizedBox(height: 4),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              GestureDetector(
                onTap: _toggleAcknowledged,
                child: Container(
                  width: 24,
                  height: 24,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: _acknowledged ? AppColors.primary : Colors.transparent,
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(color: AppColors.primary, width: 1.5),
                  ),
                  child: _acknowledged
                      ? const Icon(Icons.check_rounded, size: 16, color: Colors.white)
                      : null,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: GestureDetector(
                  onTap: _toggleAcknowledged,
                  child: Text(
                    'I have read and agree to the above terms and acknowledge that the traveler may inspect my parcel before accepting it.',
                    style: typo.sm.copyWith(color: AppColors.textPrimary),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
