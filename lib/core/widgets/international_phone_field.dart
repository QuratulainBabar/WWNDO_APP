import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../platform/keyboard_utils.dart';
import '../phone/phone_countries.dart';
import '../theme/app_colors.dart';
import '../theme/app_typography.dart';
import 'app_labeled_field.dart';

/// International phone input: flag + dial code picker + national number field.
/// Uses a [Row] layout instead of [InputDecoration.prefixIcon] so dial-code
/// updates reliably on Flutter web when the country changes from another field.
class InternationalPhoneField extends StatelessWidget {
  const InternationalPhoneField({
    super.key,
    required this.controller,
    required this.country,
    required this.onCountryChanged,
    this.label = 'Phone',
    this.labelStyle,
    this.inputStyle,
    this.hintText,
    this.padding,
    this.textInputAction = TextInputAction.next,
  });

  final TextEditingController controller;
  final PhoneCountry country;
  final ValueChanged<PhoneCountry> onCountryChanged;
  final String label;
  final TextStyle? labelStyle;
  final TextStyle? inputStyle;
  /// When null, uses [PhoneCountries.examplePlaceholder] for [country]
  /// (dial code + local number format).
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
      child: _PhoneInputRow(
        key: ValueKey(country.iso),
        controller: controller,
        country: country,
        fieldInputStyle: fieldInputStyle,
        hintText: hintText ?? PhoneCountries.examplePlaceholder(country),
        textInputAction: textInputAction,
        onOpenPicker: () => _openPicker(context),
      ),
    );
  }
}

class _PhoneInputRow extends StatefulWidget {
  const _PhoneInputRow({
    super.key,
    required this.controller,
    required this.country,
    required this.fieldInputStyle,
    required this.hintText,
    required this.textInputAction,
    required this.onOpenPicker,
  });

  final TextEditingController controller;
  final PhoneCountry country;
  final TextStyle fieldInputStyle;
  final String? hintText;
  final TextInputAction textInputAction;
  final VoidCallback onOpenPicker;

  @override
  State<_PhoneInputRow> createState() => _PhoneInputRowState();
}

class _PhoneInputRowState extends State<_PhoneInputRow> {
  final _focusNode = FocusNode();

  @override
  void initState() {
    super.initState();
    _focusNode.addListener(_onFocusChange);
  }

  @override
  void dispose() {
    _focusNode.removeListener(_onFocusChange);
    _focusNode.dispose();
    super.dispose();
  }

  void _onFocusChange() => setState(() {});

  @override
  Widget build(BuildContext context) {
    final focused = _focusNode.hasFocus;
    final borderColor = focused ? AppColors.primary : AppColors.border;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 150),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: borderColor, width: 1.5),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: widget.onOpenPicker,
              borderRadius: const BorderRadius.horizontal(
                left: Radius.circular(11),
              ),
              child: Padding(
                padding: const EdgeInsets.fromLTRB(12, 14, 8, 14),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      widget.country.flag,
                      style: const TextStyle(fontSize: 22),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      widget.country.dialCode,
                      style: widget.fieldInputStyle.copyWith(
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
                  ],
                ),
              ),
            ),
          ),
          Container(
            width: 1,
            height: 24,
            color: AppColors.border,
          ),
          Expanded(
            child: TextFormField(
              controller: widget.controller,
              focusNode: _focusNode,
              onTap: ensureSoftKeyboardVisible,
              onTapOutside: dismissKeyboardOnTapOutside,
              keyboardType: TextInputType.phone,
              textInputAction: widget.textInputAction,
              style: widget.fieldInputStyle,
              inputFormatters: [
                FilteringTextInputFormatter.allow(RegExp(r'[\d\s]')),
              ],
              decoration: InputDecoration(
                hintText: widget.hintText,
                hintStyle: widget.fieldInputStyle.copyWith(
                  color: AppColors.textDisabled,
                ),
                filled: false,
                border: InputBorder.none,
                enabledBorder: InputBorder.none,
                focusedBorder: InputBorder.none,
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 14,
                ),
              ),
            ),
          ),
        ],
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
                onTap: ensureSoftKeyboardVisible,
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
