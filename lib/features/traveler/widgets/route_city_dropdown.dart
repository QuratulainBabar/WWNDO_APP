import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/widgets/app_labeled_field.dart';
import '../../../data/models/meetup_location.dart';

/// Opens the Google Maps location screen to pick From / To city.
class RouteCityDropdown extends StatelessWidget {
  const RouteCityDropdown({
    super.key,
    required this.label,
    required this.value,
    required this.onChanged,
    this.hintText = 'Select location on Google Maps',
    this.mapTitle,
    this.searchHint,
  });

  final String label;
  final MeetupLocation? value;
  final ValueChanged<MeetupLocation> onChanged;
  final String hintText;
  final String? mapTitle;
  final String? searchHint;

  Future<void> _openMapPicker(BuildContext context) async {
    final initial = value == null ? const <MeetupLocation>[] : [value!];
    final result = await context.push<List<MeetupLocation>>(
      '/add-meetup-locations',
      extra: <String, dynamic>{
        'locations': initial,
        'maxLocations': 1,
        'title': mapTitle ?? label,
        'searchHint': searchHint ?? 'Search $label',
      },
    );
    if (result != null && result.isNotEmpty) {
      onChanged(result.first);
    }
  }

  @override
  Widget build(BuildContext context) {
    final typo = context.typo;
    final hasValue = value != null;
    final display = hasValue ? value!.displayLabel : null;

    return AppLabeledField(
      label: label,
      labelStyle: typo.inputLabel.copyWith(fontWeight: FontWeight.w600),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => _openMapPicker(context),
          borderRadius: BorderRadius.circular(12),
          child: InputDecorator(
            isEmpty: !hasValue,
            decoration: InputDecoration(
              hintText: hintText,
              isDense: true,
              contentPadding: const EdgeInsets.fromLTRB(16, 0, 4, 0),
              prefixIcon: Icon(
                Icons.location_on_outlined,
                color: hasValue ? AppColors.primary : AppColors.textSecondary,
                size: 22,
              ),
              suffixIcon: Icon(
                Icons.my_location,
                color: AppColors.primary,
                size: 22,
              ),
              suffixIconConstraints: const BoxConstraints(
                minWidth: 40,
                minHeight: 48,
              ),
            ),
            child: display == null
                ? null
                : Text(
                    display,
                    maxLines: 1,
                    style: typo.input.copyWith(
                      color: AppColors.textPrimary,
                      height: 1.25,
                      fontWeight: FontWeight.w600,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
          ),
        ),
      ),
    );
  }
}
