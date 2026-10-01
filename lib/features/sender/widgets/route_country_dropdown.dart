import 'package:flutter/material.dart';

import '../../../core/platform/keyboard_utils.dart';
import '../../../core/geo/world_countries.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/widgets/app_labeled_field.dart';
import '../../../l10n/app_localizations.dart';

/// Searchable full-country picker for From / To on Post Delivery.
class RouteCountryDropdown extends StatelessWidget {
  const RouteCountryDropdown({
    super.key,
    required this.label,
    required this.value,
    required this.onChanged,
    this.hintText = 'Select country',
    this.allowedIsos,
    this.compact = false,
    this.labelStyle,
  });

  final String label;
  final String? value;
  final ValueChanged<String> onChanged;
  final String hintText;
  /// When set, only these ISO codes appear in the picker.
  final Set<String>? allowedIsos;
  /// When true, shows only the ISO code (e.g. for Code columns).
  final bool compact;
  final TextStyle? labelStyle;

  Future<void> _openPicker(BuildContext context) async {
    final selected = await showModalBottomSheet<WorldCountry>(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => _RouteCountryPickerSheet(
        selectedIso: value?.toUpperCase(),
        title: label.isEmpty
            ? context.tr('Select country')
            : context.l10n.selectLabel(context.tr(label)),
        allowedIsos: allowedIsos,
      ),
    );
    if (selected != null) onChanged(selected.iso);
  }

  @override
  Widget build(BuildContext context) {
    final typo = context.typo;
    final hasValue = value != null &&
        value!.isNotEmpty &&
        WorldCountries.containsIso(value!);
    final country = hasValue ? WorldCountries.byIso(value!) : null;
    final display = country == null
        ? null
        : (compact
            ? country.iso
            : '${country.flag}  ${country.name} (${country.iso})');

    return AppLabeledField(
      label: context.tr(label),
      labelStyle: labelStyle ??
          typo.inputLabel.copyWith(fontWeight: FontWeight.w700),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => _openPicker(context),
          borderRadius: BorderRadius.circular(12),
          child: InputDecorator(
            isEmpty: display == null,
            decoration: InputDecoration(
              hintText: context.tr(hintText),
              isDense: compact,
              contentPadding: compact
                  ? const EdgeInsets.fromLTRB(12, 0, 4, 0)
                  : null,
              suffixIcon: Icon(
                Icons.keyboard_arrow_down_rounded,
                size: compact ? 22 : 24,
                color: AppColors.textSecondary,
              ),
              suffixIconConstraints: compact
                  ? const BoxConstraints(minWidth: 32, minHeight: 48)
                  : null,
            ),
            child: display == null
                ? null
                : Text(
                    display,
                    maxLines: 1,
                    style: typo.input.copyWith(
                      color: AppColors.textPrimary,
                      height: 1.25,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
          ),
        ),
      ),
    );
  }
}

class _RouteCountryPickerSheet extends StatefulWidget {
  const _RouteCountryPickerSheet({
    required this.selectedIso,
    required this.title,
    this.allowedIsos,
  });

  final String? selectedIso;
  final String title;
  final Set<String>? allowedIsos;

  @override
  State<_RouteCountryPickerSheet> createState() =>
      _RouteCountryPickerSheetState();
}

class _RouteCountryPickerSheetState extends State<_RouteCountryPickerSheet> {
  final _searchController = TextEditingController();
  late List<WorldCountry> _results;

  List<WorldCountry> _filter(List<WorldCountry> source) {
    final allowed = widget.allowedIsos;
    if (allowed == null || allowed.isEmpty) return source;
    final normalized = {for (final iso in allowed) iso.toUpperCase()};
    return source.where((c) => normalized.contains(c.iso)).toList();
  }

  @override
  void initState() {
    super.initState();
    _results = _filter(WorldCountries.ordered());
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _onSearch(String value) {
    setState(() => _results = _filter(WorldCountries.search(value)));
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
              child: Text(widget.title, style: typo.h3),
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
                  hintText: context.tr('Search country name or code'),
                  hintStyle: typo.input.copyWith(color: AppColors.textDisabled),
                  prefixIcon: Icon(
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
                        context.tr('No countries found'),
                        style: typo.subheading,
                      ),
                    )
                  : ListView.separated(
                      itemCount: _results.length,
                      separatorBuilder: (_, _) => Divider(
                        height: 1,
                        color: AppColors.border,
                      ),
                      itemBuilder: (context, index) {
                        final country = _results[index];
                        final selected =
                            country.iso == widget.selectedIso?.toUpperCase();
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
                          trailing: selected
                              ? const Icon(
                                  Icons.check_rounded,
                                  color: AppColors.primary,
                                )
                              : null,
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
