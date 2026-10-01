import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../core/platform/keyboard_utils.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../../l10n/app_localizations.dart';

/// Numeric available luggage capacity for the post trip form.
class AvailableLuggageCapacityField extends StatefulWidget {
  const AvailableLuggageCapacityField({
    super.key,
    this.initialValue,
    this.onChanged,
  });

  final int? initialValue;
  final ValueChanged<int>? onChanged;

  @override
  State<AvailableLuggageCapacityField> createState() =>
      _AvailableLuggageCapacityFieldState();
}

class _AvailableLuggageCapacityFieldState
    extends State<AvailableLuggageCapacityField> {
  late final TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    final initial = widget.initialValue;
    _controller = TextEditingController(
      text: initial == null || initial <= 0 ? '' : '$initial',
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _handleChanged(String value) {
    final parsed = int.tryParse(value.trim());
    if (parsed != null) {
      widget.onChanged?.call(parsed);
    } else if (value.trim().isEmpty) {
      widget.onChanged?.call(0);
    }
  }

  @override
  Widget build(BuildContext context) {
    final typo = context.typo;
    final l10n = context.l10n;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        TextField(
          controller: _controller,
          onTap: ensureSoftKeyboardVisible,
          onTapOutside: dismissKeyboardOnTapOutside,
          keyboardType: TextInputType.number,
          inputFormatters: [
            FilteringTextInputFormatter.digitsOnly,
          ],
          style: typo.input,
          onChanged: _handleChanged,
          decoration: InputDecoration(
            hintText: l10n.enterAvailableCapacity,
            suffixText: l10n.kgUnit,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          l10n.capacityVisibleToSenders,
          style: typo.sm.copyWith(color: AppColors.textSecondary),
        ),
        const SizedBox(height: 12),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: AppColors.primary.withValues(alpha: 0.08),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Text(
            l10n.capacityMultipleRequestsNote,
            style: typo.sm.copyWith(height: 1.45),
          ),
        ),
      ],
    );
  }
}
