import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../platform/keyboard_utils.dart';
import '../phone/phone_countries.dart';
import '../theme/app_colors.dart';
import '../theme/app_typography.dart';
import 'app_labeled_field.dart';

/// International phone input: flag + dial code picker + national number field.
/// Matches [InputDecorationTheme] used by other form fields.
class InternationalPhoneField extends StatelessWidget {
  const InternationalPhoneField({
    super.key,
    required this.controller,
    required this.country,
    required this.onCountryChanged,
    this.label = 'Phone',
    this.labelStyle,
    this.inputStyle,
    this.hintText = '6 12 34 56 78',
    this.padding,
    this.textInputAction = TextInputAction.next,
  });

  final TextEditingController controller;
  final PhoneCountry country;
  final ValueChanged<PhoneCountry> onCountryChanged;
  final String label;
  final TextStyle? labelStyle;
  final TextStyle? inputStyle;
  final String? hintText;
  final EdgeInsetsGeometry? padding;
  final TextInputAction textInputAction;

  Future<void> _openPicker(BuildContext context) async {
    final selected = await showModalBottomSheet<PhoneCountry>(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => _CountryPickerSheet(selected: country),
    );
    if (selected != null) onCountryChanged(selected);
  }

  @override
  Widget build(BuildContext context) {
    final typo = context.typo;
    final fieldInputStyle = inputStyle ?? typo.input;

    return AppLabeledField(
      label: label,
      labelStyle: labelStyle,
      padding: padding ??
          const EdgeInsets.only(top: AppFieldSpacing.top, bottom: 12),
      child: TextFormField(
        controller: controller,
        onTapOutside: dismissKeyboardOnTapOutside,
        keyboardType: TextInputType.phone,
        textInputAction: textInputAction,
        style: fieldInputStyle,
        inputFormatters: [
          FilteringTextInputFormatter.allow(RegExp(r'[\d\s]')),
        ],
        decoration: InputDecoration(
          hintText: hintText,
          hintStyle: fieldInputStyle.copyWith(color: AppColors.textDisabled),
          prefixIcon: InkWell(
            onTap: () => _openPicker(context),
            borderRadius: BorderRadius.circular(12),
            child: Padding(
              padding: const EdgeInsets.only(left: 12, right: 8),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(country.flag, style: const TextStyle(fontSize: 22)),
                  const SizedBox(width: 6),
                  Text(
                    country.dialCode,
                    style: fieldInputStyle.copyWith(
                      fontWeight: FontWeight.w600,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(width: 2),
                  const Icon(
                    Icons.keyboard_arrow_down_rounded,
                    size: 20,
                    color: AppColors.textSecondary,
                  ),
                  Container(
                    width: 1,
                    height: 24,
                    margin: const EdgeInsets.only(left: 8),
                    color: AppColors.border,
                  ),
                ],
              ),
            ),
          ),
          prefixIconConstraints: const BoxConstraints(minWidth: 0, minHeight: 0),
        ),
      ),
    );
  }
}

class _CountryPickerSheet extends StatefulWidget {
  const _CountryPickerSheet({required this.selected});

  final PhoneCountry selected;

  @override
  State<_CountryPickerSheet> createState() => _CountryPickerSheetState();
}

class _CountryPickerSheetState extends State<_CountryPickerSheet> {
  final _searchController = TextEditingController();
  late List<PhoneCountry> _results;

  @override
  void initState() {
    super.initState();
    _results = PhoneCountries.ordered();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _onSearch(String value) {
    setState(() => _results = PhoneCountries.search(value));
  }

  @override
  Widget build(BuildContext context) {
    final typo = context.typo;
    final bottomInset = MediaQuery.viewInsetsOf(context).bottom;
    final height = MediaQuery.sizeOf(context).height * 0.72;

    return Padding(
      padding: EdgeInsets.only(bottom: bottomInset),
      child: SizedBox(
        height: height,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const SizedBox(height: 10),
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: AppColors.border,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
              child: Text('Select country', style: typo.h3),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: TextField(
                controller: _searchController,
                onChanged: _onSearch,
                onTapOutside: dismissKeyboardOnTapOutside,
                autofocus: true,
                style: typo.input,
                decoration: InputDecoration(
                  hintText: 'Search country or dial code',
                  hintStyle: typo.input.copyWith(color: AppColors.textDisabled),
                  prefixIcon: const Icon(
                    Icons.search_rounded,
                    color: AppColors.textSecondary,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 8),
            Expanded(
              child: _results.isEmpty
                  ? Center(
                      child: Text(
                        'No countries found',
                        style: typo.subheading,
                      ),
                    )
                  : ListView.separated(
                      itemCount: _results.length,
                      separatorBuilder: (_, _) => const Divider(
                        height: 1,
                        color: AppColors.border,
                      ),
                      itemBuilder: (context, index) {
                        final country = _results[index];
                        final selected = country.iso == widget.selected.iso;
                        return ListTile(
                          leading: Text(
                            country.flag,
                            style: const TextStyle(fontSize: 28),
                          ),
                          title: Text(
                            country.name,
                            style: typo.input.copyWith(
                              fontWeight:
                                  selected ? FontWeight.w700 : FontWeight.w500,
                            ),
                          ),
                          subtitle: Text(
                            country.iso,
                            style: typo.sm.copyWith(
                              color: AppColors.textSecondary,
                            ),
                          ),
                          trailing: Text(
                            country.dialCode,
                            style: typo.input.copyWith(
                              color: selected
                                  ? AppColors.primary
                                  : AppColors.textSecondary,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          selected: selected,
                          selectedTileColor: AppColors.kycBackground,
                          onTap: () => Navigator.of(context).pop(country),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }
}
