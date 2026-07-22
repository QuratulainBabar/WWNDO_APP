import 'package:flutter/material.dart';

import '../../../core/geo/world_cities.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/widgets/app_labeled_field.dart';

/// Searchable city picker for From / To on Post Trip (city-to-city).
class RouteCityDropdown extends StatelessWidget {
  const RouteCityDropdown({
    super.key,
    required this.label,
    required this.value,
    required this.onChanged,
    this.countryIso,
    this.hintText = 'Select city',
  });

  final String label;
  final String? value;
  final String? countryIso;
  final ValueChanged<WorldCity> onChanged;
  final String hintText;

  Future<void> _openPicker(BuildContext context) async {
    final iso = countryIso?.trim().toUpperCase();
    if (iso == null || iso.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Select a country code first.'),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    final selected = await showModalBottomSheet<WorldCity>(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => _RouteCityPickerSheet(
        selectedName: value,
        countryIso: iso,
        title: label.isEmpty ? 'Select city' : 'Select $label',
      ),
    );
    if (selected != null) onChanged(selected);
  }

  @override
  Widget build(BuildContext context) {
    final typo = context.typo;
    final hasCountry = countryIso != null && countryIso!.trim().isNotEmpty;
    final display = (value != null && value!.trim().isNotEmpty) ? value : null;
    final effectiveHint = hasCountry ? hintText : 'Select code first';

    return AppLabeledField(
      label: label,
      labelStyle: typo.inputLabel.copyWith(fontWeight: FontWeight.w600),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => _openPicker(context),
          borderRadius: BorderRadius.circular(12),
          child: InputDecorator(
            isEmpty: display == null,
            decoration: InputDecoration(
              hintText: effectiveHint,
              isDense: true,
              contentPadding: const EdgeInsets.fromLTRB(16, 0, 4, 0),
              suffixIcon: const Icon(
                Icons.keyboard_arrow_down_rounded,
                color: AppColors.textSecondary,
              ),
              suffixIconConstraints: const BoxConstraints(
                minWidth: 32,
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
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
          ),
        ),
      ),
    );
  }
}

class _RouteCityPickerSheet extends StatefulWidget {
  const _RouteCityPickerSheet({
    required this.selectedName,
    required this.countryIso,
    required this.title,
  });

  final String? selectedName;
  final String countryIso;
  final String title;

  @override
  State<_RouteCityPickerSheet> createState() => _RouteCityPickerSheetState();
}

class _RouteCityPickerSheetState extends State<_RouteCityPickerSheet> {
  final _searchController = TextEditingController();
  late List<WorldCity> _results;

  @override
  void initState() {
    super.initState();
    _results = WorldCities.forCountry(widget.countryIso);
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _onSearch(String value) {
    setState(() {
      _results = WorldCities.search(
        query: value,
        countryIso: widget.countryIso,
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    final typo = context.typo;
    final bottomInset = MediaQuery.viewInsetsOf(context).bottom;
    final height = MediaQuery.sizeOf(context).height * 0.72;
    final selectedNeedle = widget.selectedName?.trim().toLowerCase();

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
                autofocus: true,
                style: typo.input,
                decoration: InputDecoration(
                  hintText: 'Search city',
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
                        'No cities found for this country',
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
                        final city = _results[index];
                        final selected =
                            city.name.toLowerCase() == selectedNeedle;
                        return ListTile(
                          title: Text(
                            city.name,
                            style: typo.input.copyWith(
                              fontWeight:
                                  selected ? FontWeight.w700 : FontWeight.w500,
                            ),
                          ),
                          subtitle: Text(
                            city.countryIso,
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
                          onTap: () => Navigator.of(context).pop(city),
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
