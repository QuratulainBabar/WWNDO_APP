import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../../data/static_data.dart';

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
  static const _placeholder = 'Enter available capacity';
  static const _helperText =
      'This capacity will be visible when matching with sender requests.';
  static const _infoNote =
      'You may accept multiple parcel requests as long as your available luggage capacity allows.';

  late final TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    final initial = widget.initialValue ??
        StaticData.travelerAvailableLuggageCapacityKg.round();
    _controller = TextEditingController(text: '$initial');
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

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        TextField(
          controller: _controller,
          keyboardType: TextInputType.number,
          inputFormatters: [
            FilteringTextInputFormatter.digitsOnly,
          ],
          style: typo.input,
          onChanged: _handleChanged,
          decoration: const InputDecoration(
            hintText: _placeholder,
            suffixText: 'kg',
          ),
        ),
        const SizedBox(height: 8),
        Text(
          _helperText,
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
            _infoNote,
            style: typo.sm.copyWith(height: 1.45),
          ),
        ),
      ],
    );
  }
}
