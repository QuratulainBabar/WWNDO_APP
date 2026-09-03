import 'package:flutter/material.dart';

import '../../../core/platform/keyboard_utils.dart';
import '../../../core/geo/world_airports.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/widgets/app_labeled_field.dart';
import '../../../core/widgets/app_toast.dart';

/// Searchable airport picker scoped to a selected country.
class RouteAirportDropdown extends StatelessWidget {
  const RouteAirportDropdown({
    super.key,
    required this.label,
    required this.countryIso,
    required this.value,
    required this.onChanged,
    this.hintText = 'Select airport',
  });

  final String label;
  final String? countryIso;
  final String? value;
  final ValueChanged<String> onChanged;
  final String hintText;

  Future<void> _openPicker(BuildContext context) async {
    final iso = countryIso?.trim().toUpperCase();
    if (iso == null || iso.isEmpty) {
      AppToast.error(context, 'Select a country first.');
      return;
    }

    final selected = await showModalBottomSheet<WorldAirport>(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => _RouteAirportPickerSheet(
        countryIso: iso,
        selectedCode: value,
        title: label.isEmpty ? 'Select airport' : 'Select $label',
      ),
    );
    if (selected != null) onChanged(selected.label);
  }

  @override
  Widget build(BuildContext context) {
    final typo = context.typo;
    final hasCountry = countryIso != null && countryIso!.trim().isNotEmpty;
    final display = (value != null && value!.isNotEmpty) ? value : null;

    return AppLabeledField(
      label: label,
      labelStyle: typo.inputLabel.copyWith(fontWeight: FontWeight.w600),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => _openPicker(context),
          borderRadius: BorderRadius.circular(12),
          child: InputDecorator(
            decoration: InputDecoration(
              hintText: hasCountry ? hintText : 'Select country first',
              suffixIcon: const Icon(
                Icons.keyboard_arrow_down_rounded,
                color: AppColors.textSecondary,
              ),
            ),
            child: Text(
              display ?? (hasCountry ? hintText : 'Select country first'),
              style: typo.input.copyWith(
                color: display == null
                    ? AppColors.textSecondary
                    : AppColors.textPrimary,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _RouteAirportPickerSheet extends StatefulWidget {
  const _RouteAirportPickerSheet({
    required this.countryIso,
    required this.selectedCode,
    required this.title,
  });

  final String countryIso;
  final String? selectedCode;
  final String title;

  @override
  State<_RouteAirportPickerSheet> createState() =>
      _RouteAirportPickerSheetState();
}

class _RouteAirportPickerSheetState extends State<_RouteAirportPickerSheet> {
  final _searchController = TextEditingController();
  late List<WorldAirport> _results;

  @override
  void initState() {
    super.initState();
    _results = WorldAirports.forCountry(widget.countryIso);
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _onSearch(String value) {
    setState(() {
      _results = WorldAirports.searchInCountry(widget.countryIso, value);
    });
  }

  String? get _selectedAirportCode {
    final raw = widget.selectedCode?.trim() ?? '';
    if (raw.isEmpty) return null;
    final byLabel = WorldAirports.byLabel(raw);
    if (byLabel != null) return byLabel.code;
    return raw.toUpperCase();
  }

  @override
  Widget build(BuildContext context) {
    final typo = context.typo;
    final bottomInset = MediaQuery.viewInsetsOf(context).bottom;
    final height = MediaQuery.sizeOf(context).height * 0.72;
    final selectedCode = _selectedAirportCode;

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
                  hintText: 'Search airport name or code',
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
                        'No airports found for this country',
                        style: typo.subheading,
                        textAlign: TextAlign.center,
                      ),
                    )
                  : ListView.separated(
                      itemCount: _results.length,
                      separatorBuilder: (_, _) => const Divider(
                        height: 1,
                        color: AppColors.border,
                      ),
                      itemBuilder: (context, index) {
                        final airport = _results[index];
                        final selected = airport.code == selectedCode;
                        return ListTile(
                          title: Text(
                            airport.name,
                            style: typo.input.copyWith(
                              fontWeight:
                                  selected ? FontWeight.w700 : FontWeight.w500,
                            ),
                          ),
                          subtitle: Text(
                            airport.code,
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
                          onTap: () => Navigator.of(context).pop(airport),
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
