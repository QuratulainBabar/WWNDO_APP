import 'package:flutter/material.dart';

import '../../../core/platform/keyboard_utils.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/widgets/app_labeled_field.dart';

/// Editable parcel description for post delivery forms.
class DescriptionField extends StatelessWidget {
  const DescriptionField({
    super.key,
    required this.controller,
    this.errorText,
    this.hintText = 'Describe your parcel',
  });

  final TextEditingController controller;
  final String? errorText;
  final String hintText;

  @override
  Widget build(BuildContext context) {
    final typo = context.typo;

    return AppLabeledField(
      label: 'Description',
      labelStyle: typo.inputLabel.copyWith(fontWeight: FontWeight.w600),
      child: TextField(
        controller: controller,
        onTap: ensureSoftKeyboardVisible,
        onTapOutside: dismissKeyboardOnTapOutside,
        maxLines: 3,
        minLines: 3,
        textInputAction: TextInputAction.newline,
        style: typo.input,
        decoration: InputDecoration(
          hintText: hintText,
          hintStyle: typo.input.copyWith(color: AppColors.textDisabled),
          errorText: errorText,
        ),
      ),
    );
  }
}
