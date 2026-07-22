import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/widgets/app_labeled_field.dart';
import '../../../data/static_data.dart';

/// Maximum budget input for the post delivery form.
class MaximumBudgetField extends StatefulWidget {
  const MaximumBudgetField({
    super.key,
    this.initialValue,
    this.onChanged,
    this.errorText,
  });

  final double? initialValue;
  final ValueChanged<double>? onChanged;
  final String? errorText;

  @override
  State<MaximumBudgetField> createState() => _MaximumBudgetFieldState();
}

class _MaximumBudgetFieldState extends State<MaximumBudgetField> {
  static const _placeholder = 'Enter the maximum amount you are willing to pay';
  static const _helperText =
      'Travelers will see this budget when submitting their bids.';

  late final TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    final initial =
        widget.initialValue ?? StaticData.postDeliveryMaximumBudget;
    _controller = TextEditingController(text: initial.toStringAsFixed(2));
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _handleChanged(String value) {
    final parsed = double.tryParse(value.trim());
    if (parsed != null) {
      widget.onChanged?.call(parsed);
    }
  }

  @override
  Widget build(BuildContext context) {
    final typo = context.typo;

    return AppLabeledField(
      label: 'Maximum Budget',
      labelStyle: typo.inputLabel.copyWith(fontWeight: FontWeight.w600),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          TextField(
            controller: _controller,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            inputFormatters: [
              FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d{0,2}')),
            ],
            style: typo.input,
            onChanged: _handleChanged,
            decoration: InputDecoration(
              prefixText: '\$ ',
              hintText: _placeholder,
              errorText: widget.errorText,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            _helperText,
            style: typo.sm.copyWith(color: AppColors.textSecondary),
          ),
        ],
      ),
    );
  }
}
