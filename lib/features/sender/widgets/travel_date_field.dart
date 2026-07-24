import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/widgets/app_labeled_field.dart';

/// Calendar date picker for Post Delivery / Post Trip travel date.
class TravelDateField extends StatelessWidget {
  const TravelDateField({
    super.key,
    required this.value,
    required this.onChanged,
    this.errorText,
  });

  final DateTime? value;
  final ValueChanged<DateTime> onChanged;
  final String? errorText;

  Future<void> _pickDate(BuildContext context) async {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final current = value;
    final initial =
        current == null || current.isBefore(today) ? today : current;

    final picked = await showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: today,
      lastDate: DateTime(today.year + 2, today.month, today.day),
      helpText: 'Select travel date',
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: Theme.of(context).colorScheme.copyWith(
                  primary: AppColors.primary,
                ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      onChanged(DateTime(picked.year, picked.month, picked.day));
    }
  }

  @override
  Widget build(BuildContext context) {
    final typo = context.typo;
    final formatted =
        value == null ? '' : DateFormat('yyyy-MM-dd').format(value!);

    return AppLabeledField(
      label: 'Travel date',
      labelStyle: typo.inputLabel.copyWith(fontWeight: FontWeight.w600),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: () => _pickDate(context),
              borderRadius: BorderRadius.circular(12),
              child: InputDecorator(
                isEmpty: value == null,
                decoration: InputDecoration(
                  hintText: 'Select travel date',
                  errorText: errorText,
                  suffixIcon: const Icon(
                    Icons.calendar_month_outlined,
                    color: AppColors.textSecondary,
                  ),
                ),
                child: Text(
                  formatted,
                  style: typo.input,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
