import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/widgets/app_card.dart';
import '../../../l10n/app_localizations.dart';

class ParcelAcknowledgementSection extends StatefulWidget {
  const ParcelAcknowledgementSection({
    super.key,
    this.onChanged,
    this.errorText,
  });

  final ValueChanged<bool>? onChanged;
  final String? errorText;

  @override
  State<ParcelAcknowledgementSection> createState() =>
      _ParcelAcknowledgementSectionState();
}

class _ParcelAcknowledgementSectionState
    extends State<ParcelAcknowledgementSection> {
  bool _acknowledged = false;

  void _toggleAcknowledged() {
    setState(() => _acknowledged = !_acknowledged);
    widget.onChanged?.call(_acknowledged);
  }

  @override
  Widget build(BuildContext context) {
    final typo = context.typo;
    final l10n = context.l10n;
    final terms = [
      l10n.parcelAckTerm1,
      l10n.parcelAckTerm2,
      l10n.parcelAckTerm3,
      l10n.parcelAckTerm4,
      l10n.parcelAckTerm5,
    ];

    return AppCard(
      margin: EdgeInsets.zero,
      padding: const EdgeInsets.all(16),
      child: DecoratedBox(
        decoration: widget.errorText != null
            ? BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: AppColors.danger.withValues(alpha: 0.45),
                  width: 1.5,
                ),
              )
            : const BoxDecoration(),
        child: Padding(
          padding: widget.errorText != null
              ? const EdgeInsets.all(12)
              : EdgeInsets.zero,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                l10n.parcelAcknowledgement,
                style: typo.bodyBold.copyWith(fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 8),
              Text(
                l10n.parcelAckIntro,
                style: typo.sm.copyWith(color: AppColors.textPrimary),
              ),
              const SizedBox(height: 12),
              for (final term in terms) ...[
                Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '• ',
                        style: typo.sm.copyWith(color: AppColors.textPrimary),
                      ),
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
                        color:
                            _acknowledged ? AppColors.primary : Colors.transparent,
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(color: AppColors.primary, width: 1.5),
                      ),
                      child: _acknowledged
                          ? const Icon(
                              Icons.check_rounded,
                              size: 16,
                              color: Colors.white,
                            )
                          : null,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: GestureDetector(
                      onTap: _toggleAcknowledged,
                      child: Text(
                        l10n.parcelAckCheckbox,
                        style: typo.sm.copyWith(color: AppColors.textPrimary),
                      ),
                    ),
                  ),
                ],
              ),
              if (widget.errorText != null) ...[
                const SizedBox(height: 10),
                Text(
                  widget.errorText!,
                  style: typo.sm.copyWith(color: AppColors.danger),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
