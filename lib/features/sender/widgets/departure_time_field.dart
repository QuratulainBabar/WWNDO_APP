import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/widgets/app_labeled_field.dart';
import '../../../l10n/app_localizations.dart';

/// Time picker for Post Trip departure time.
class DepartureTimeField extends StatelessWidget {
  const DepartureTimeField({
    super.key,
    required this.value,
    required this.onChanged,
    this.errorText,
    this.label,
    this.hintText,
  });

  final TimeOfDay? value;
  final ValueChanged<TimeOfDay> onChanged;
  final String? errorText;
  final String? label;
  final String? hintText;

  Future<void> _pickTime(BuildContext context) async {
    final picked = await showModalBottomSheet<TimeOfDay>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _DepartureTimePickerSheet(
        initialTime: value ?? TimeOfDay.now(),
      ),
    );
    if (picked != null) {
      onChanged(picked);
    }
  }

  String _format(BuildContext context, TimeOfDay time) {
    return MaterialLocalizations.of(context).formatTimeOfDay(
      time,
      alwaysUse24HourFormat: false,
    );
  }

  @override
  Widget build(BuildContext context) {
    final typo = context.typo;
    final l10n = context.l10n;
    final fieldLabel = label ?? l10n.departureTime;
    final fieldHint = hintText ?? l10n.selectDepartureTime;
    final formatted = value == null ? '' : _format(context, value!);

    return AppLabeledField(
      label: fieldLabel,
      labelStyle: typo.inputLabel.copyWith(fontWeight: FontWeight.w600),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: () => _pickTime(context),
              borderRadius: BorderRadius.circular(12),
              child: InputDecorator(
                isEmpty: value == null,
                decoration: InputDecoration(
                  hintText: fieldHint,
                  errorText: errorText,
                  suffixIcon: Icon(
                    Icons.access_time_outlined,
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

class _DepartureTimePickerSheet extends StatefulWidget {
  const _DepartureTimePickerSheet({required this.initialTime});

  final TimeOfDay initialTime;

  @override
  State<_DepartureTimePickerSheet> createState() =>
      _DepartureTimePickerSheetState();
}

class _DepartureTimePickerSheetState extends State<_DepartureTimePickerSheet> {
  static const _itemExtent = 48.0;
  static const _visibleItems = 5;
  static const _minuteCount = 60;

  late int _hour12;
  late int _minute;
  late bool _isAm;
  late final FixedExtentScrollController _hourController;
  late final FixedExtentScrollController _minuteController;

  @override
  void initState() {
    super.initState();
    final initial = widget.initialTime;
    _hour12 = initial.hourOfPeriod;
    _minute = initial.minute.clamp(0, _minuteCount - 1);
    _isAm = initial.period == DayPeriod.am;
    _hourController = FixedExtentScrollController(initialItem: _hour12 - 1);
    _minuteController = FixedExtentScrollController(initialItem: _minute);
  }

  @override
  void dispose() {
    _hourController.dispose();
    _minuteController.dispose();
    super.dispose();
  }

  TimeOfDay get _selectedTime {
    final hour24 = _isAm
        ? (_hour12 == 12 ? 0 : _hour12)
        : (_hour12 == 12 ? 12 : _hour12 + 12);
    return TimeOfDay(hour: hour24, minute: _minute);
  }

  @override
  Widget build(BuildContext context) {
    final typo = context.typo;
    final l10n = context.l10n;
    final bottomInset = MediaQuery.paddingOf(context).bottom;

    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: EdgeInsets.fromLTRB(20, 10, 20, 16 + bottomInset),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
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
          const SizedBox(height: 18),
          Text(
            l10n.selectDepartureTimeTitle,
            style: typo.headerTitle.copyWith(fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 20),
          SizedBox(
            height: _itemExtent * _visibleItems,
            child: Row(
              children: [
                Expanded(
                  flex: 3,
                  child: _PickerColumn(
                    controller: _hourController,
                    itemCount: 12,
                    itemExtent: _itemExtent,
                    selectedIndex: _hour12 - 1,
                    labelOf: (i) => (i + 1).toString().padLeft(2, '0'),
                    onSelectedItemChanged: (i) {
                      setState(() => _hour12 = i + 1);
                    },
                  ),
                ),
                _VerticalDivider(height: _itemExtent * _visibleItems),
                Expanded(
                  flex: 3,
                  child: _PickerColumn(
                    controller: _minuteController,
                    itemCount: _minuteCount,
                    itemExtent: _itemExtent,
                    selectedIndex: _minute,
                    labelOf: (i) => i.toString().padLeft(2, '0'),
                    onSelectedItemChanged: (i) {
                      setState(() => _minute = i);
                    },
                  ),
                ),
                _VerticalDivider(height: _itemExtent * _visibleItems),
                Expanded(
                  flex: 2,
                  child: _AmPmColumn(
                    isAm: _isAm,
                    itemExtent: _itemExtent,
                    onChanged: (isAm) => setState(() => _isAm = isAm),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          Row(
            children: [
              Expanded(
                child: SizedBox(
                  height: 52,
                  child: Material(
                    color: AppColors.background,
                    borderRadius: BorderRadius.circular(28),
                    child: InkWell(
                      onTap: () => Navigator.of(context).pop(),
                      borderRadius: BorderRadius.circular(28),
                      child: Center(
                        child: Text(
                          l10n.cancel,
                          style: typo.buttonSm.copyWith(
                            color: AppColors.textPrimary,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                flex: 2,
                child: SizedBox(
                  height: 52,
                  child: Material(
                    color: AppColors.primary,
                    borderRadius: BorderRadius.circular(28),
                    child: InkWell(
                      onTap: () =>
                          Navigator.of(context).pop(_selectedTime),
                      borderRadius: BorderRadius.circular(28),
                      child: Center(
                        child: Text(
                          l10n.done,
                          style: typo.buttonSm.copyWith(
                            color: Colors.white,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _VerticalDivider extends StatelessWidget {
  const _VerticalDivider({required this.height});

  final double height;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 1,
      height: height * 0.72,
      margin: EdgeInsets.symmetric(vertical: height * 0.14),
      color: AppColors.border,
    );
  }
}

class _PickerColumn extends StatelessWidget {
  const _PickerColumn({
    required this.controller,
    required this.itemCount,
    required this.itemExtent,
    required this.labelOf,
    required this.selectedIndex,
    required this.onSelectedItemChanged,
  });

  final FixedExtentScrollController controller;
  final int itemCount;
  final double itemExtent;
  final String Function(int index) labelOf;
  final int selectedIndex;
  final ValueChanged<int> onSelectedItemChanged;

  @override
  Widget build(BuildContext context) {
    final typo = context.typo;

    return ListWheelScrollView.useDelegate(
      controller: controller,
      itemExtent: itemExtent,
      physics: const FixedExtentScrollPhysics(),
      perspective: 0.0001,
      diameterRatio: 100,
      offAxisFraction: 0,
      onSelectedItemChanged: onSelectedItemChanged,
      childDelegate: ListWheelChildBuilderDelegate(
        childCount: itemCount,
        builder: (context, index) {
          final selected = index == selectedIndex;
          return Center(
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 120),
              width: 72,
              height: itemExtent - 8,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: selected
                    ? AppColors.primary.withValues(alpha: 0.12)
                    : Colors.transparent,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                labelOf(index),
                style: typo.h3.copyWith(
                  fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                  color: selected
                      ? AppColors.primary
                      : AppColors.textSecondary.withValues(alpha: 0.55),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

class _AmPmColumn extends StatelessWidget {
  const _AmPmColumn({
    required this.isAm,
    required this.itemExtent,
    required this.onChanged,
  });

  final bool isAm;
  final double itemExtent;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return Center(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 8),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.border),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _AmPmOption(
              label: l10n.periodAm,
              selected: isAm,
              height: itemExtent - 8,
              onTap: () => onChanged(true),
            ),
            const SizedBox(height: 4),
            _AmPmOption(
              label: l10n.periodPm,
              selected: !isAm,
              height: itemExtent - 8,
              onTap: () => onChanged(false),
            ),
          ],
        ),
      ),
    );
  }
}

class _AmPmOption extends StatelessWidget {
  const _AmPmOption({
    required this.label,
    required this.selected,
    required this.height,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final double height;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final typo = context.typo;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 120),
          width: 64,
          height: height,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: selected
                ? AppColors.primary.withValues(alpha: 0.12)
                : Colors.transparent,
            borderRadius: BorderRadius.circular(20),
          ),
          child: Text(
            label,
            style: typo.body.copyWith(
              fontSize: 16,
              fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
              color: selected
                  ? AppColors.primary
                  : AppColors.textSecondary.withValues(alpha: 0.55),
            ),
          ),
        ),
      ),
    );
  }
}
