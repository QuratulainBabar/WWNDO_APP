import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../core/platform/keyboard_utils.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/widgets/app_labeled_field.dart';

/// Editable parcel weight field for Post Delivery forms.
class WeightKgField extends StatefulWidget {
  const WeightKgField({
    super.key,
    this.initialValue,
    required this.onChanged,
    this.errorText,
  });

  final double? initialValue;
  final ValueChanged<double> onChanged;
  final String? errorText;

  @override
  State<WeightKgField> createState() => _WeightKgFieldState();
}

class _WeightKgFieldState extends State<WeightKgField> {
  late final TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    final initial = widget.initialValue;
    _controller = TextEditingController(
      text: initial == null || initial <= 0 ? '' : _formatWeight(initial),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  String _formatWeight(double value) {
    if (value == value.roundToDouble()) {
      return value.toStringAsFixed(0);
    }
    return value.toString();
  }

  void _handleChanged(String value) {
    final parsed = double.tryParse(value.trim());
    if (parsed != null) {
      widget.onChanged(parsed);
    } else if (value.trim().isEmpty) {
      widget.onChanged(0);
    }
  }

  @override
  Widget build(BuildContext context) {
    final typo = context.typo;

    return AppLabeledField(
      label: 'Weight (kg)',
      labelStyle: typo.inputLabel.copyWith(fontWeight: FontWeight.w600),
      child: TextField(
        controller: _controller,
        onTap: ensureSoftKeyboardVisible,
        onTapOutside: dismissKeyboardOnTapOutside,
        keyboardType: const TextInputType.numberWithOptions(decimal: true),
        inputFormatters: [
          FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d{0,2}')),
        ],
        style: typo.input,
        onChanged: _handleChanged,
        decoration: InputDecoration(
          hintText: 'Enter parcel weight',
          suffixText: 'kg',
          errorText: widget.errorText,
        ),
      ),
    );
  }
}
