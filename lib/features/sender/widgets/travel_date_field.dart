import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../l10n/app_localizations.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/widgets/app_labeled_field.dart';
import '../../../data/trip_date_window.dart';

/// Calendar date picker for Post Delivery / Post Trip travel date.
class TravelDateField extends StatelessWidget {
  const TravelDateField({
    super.key,
    required this.value,
    required this.onChanged,
    this.errorText,
    /// When true, limits selection to the sender-visible trip window
    /// (previous 5 days + today + next 7 days). Used for traveler trip dates.
    this.constrainToActiveTripWindow = false,
  });

  final DateTime? value;
  final ValueChanged<DateTime> onChanged;
  final String? errorText;
  final bool constrainToActiveTripWindow;

  Future<void> _pickDate(BuildContext context) async {
    final today = TripDateWindow.today();
    final firstDate =
        constrainToActiveTripWindow ? TripDateWindow.earliest() : today;
    final lastDate = constrainToActiveTripWindow
        ? TripDateWindow.latest()
        : DateTime(today.year + 2, today.month, today.day);

    final current = value;
    DateTime initial;
    if (current == null) {
      initial = today;
    } else if (current.isBefore(firstDate)) {
      initial = firstDate;
    } else if (current.isAfter(lastDate)) {
      initial = lastDate;
    } else {
      initial = current;
    }

    final helpText = constrainToActiveTripWindow
        ? 'Select travel date (prev ${TripDateWindow.pastDays}d – next ${TripDateWindow.futureDays}d)'
        : context.l10n.selectTravelDate;

    // Compact custom dialog — Material date picker always reserves 6 week
    // rows, leaving a large empty gap above Cancel/OK.
    final picked = await showDialog<DateTime>(
      context: context,
      builder: (context) => _CompactTravelDateDialog(
        initialDate: initial,
        firstDate: firstDate,
        lastDate: lastDate,
        helpText: helpText,
      ),
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
      label: context.tr('Travel date'),
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
                  hintText: context.l10n.selectTravelDate,
                  errorText: errorText,
                  suffixIcon: Icon(
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

class _CompactTravelDateDialog extends StatefulWidget {
  const _CompactTravelDateDialog({
    required this.initialDate,
    required this.firstDate,
    required this.lastDate,
    required this.helpText,
  });

  final DateTime initialDate;
  final DateTime firstDate;
  final DateTime lastDate;
  final String helpText;

  @override
  State<_CompactTravelDateDialog> createState() =>
      _CompactTravelDateDialogState();
}

class _CompactTravelDateDialogState extends State<_CompactTravelDateDialog> {
  static const _cellSize = 40.0;

  late DateTime _displayedMonth;
  late DateTime _selected;

  @override
  void initState() {
    super.initState();
    _selected = DateTime(
      widget.initialDate.year,
      widget.initialDate.month,
      widget.initialDate.day,
    );
    _displayedMonth = DateTime(_selected.year, _selected.month);
  }

  DateTime get _monthStart => DateTime(_displayedMonth.year, _displayedMonth.month);

  DateTime get _monthEnd =>
      DateTime(_displayedMonth.year, _displayedMonth.month + 1, 0);

  bool get _canGoPrev {
    final prev = DateTime(_displayedMonth.year, _displayedMonth.month - 1);
    return !DateTime(prev.year, prev.month + 1, 0).isBefore(widget.firstDate);
  }

  bool get _canGoNext {
    final next = DateTime(_displayedMonth.year, _displayedMonth.month + 1);
    return !next.isAfter(
      DateTime(widget.lastDate.year, widget.lastDate.month),
    );
  }

  bool _isSelectable(DateTime day) {
    final d = DateTime(day.year, day.month, day.day);
    return !d.isBefore(widget.firstDate) && !d.isAfter(widget.lastDate);
  }

  bool _isSameDay(DateTime a, DateTime b) =>
      a.year == b.year && a.month == b.month && a.day == b.day;

  List<DateTime?> _daysInMonthGrid() {
    final firstWeekday = _monthStart.weekday % 7; // Sunday = 0
    final daysInMonth = _monthEnd.day;
    final cells = <DateTime?>[];
    for (var i = 0; i < firstWeekday; i++) {
      cells.add(null);
    }
    for (var day = 1; day <= daysInMonth; day++) {
      cells.add(DateTime(_displayedMonth.year, _displayedMonth.month, day));
    }
    while (cells.length % 7 != 0) {
      cells.add(null);
    }

    // Drop leading / trailing weeks with no selectable dates so Cancel/OK
    // sit directly under the active calendar rows.
    while (cells.length >= 7) {
      final week = cells.sublist(0, 7);
      final hasSelectable = week.any((d) => d != null && _isSelectable(d));
      if (hasSelectable) break;
      cells.removeRange(0, 7);
    }
    while (cells.length >= 7) {
      final week = cells.sublist(cells.length - 7);
      final hasSelectable = week.any((d) => d != null && _isSelectable(d));
      if (hasSelectable) break;
      cells.removeRange(cells.length - 7, cells.length);
    }
    return cells;
  }

  @override
  Widget build(BuildContext context) {
    final typo = context.typo;
    final cells = _daysInMonthGrid();
    final weekCount = cells.length ~/ 7;
    final monthLabel = DateFormat('MMMM yyyy').format(_displayedMonth);
    final selectedLabel = DateFormat('EEE, MMM d').format(_selected);
    const weekdays = ['S', 'M', 'T', 'W', 'T', 'F', 'S'];

    return Dialog(
      backgroundColor: AppColors.surface,
      surfaceTintColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 28, vertical: 24),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              widget.helpText,
              style: typo.sm.copyWith(color: AppColors.textSecondary),
            ),
            const SizedBox(height: 8),
            Text(
              selectedLabel,
              style: typo.h2.copyWith(
                color: AppColors.primary,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: Text(
                    monthLabel,
                    style: typo.body.copyWith(fontWeight: FontWeight.w700),
                  ),
                ),
                IconButton(
                  visualDensity: VisualDensity.compact,
                  onPressed: _canGoPrev
                      ? () => setState(() {
                            _displayedMonth = DateTime(
                              _displayedMonth.year,
                              _displayedMonth.month - 1,
                            );
                          })
                      : null,
                  icon: Icon(
                    Icons.chevron_left,
                    color: _canGoPrev
                        ? AppColors.textPrimary
                        : AppColors.textDisabled,
                  ),
                ),
                IconButton(
                  visualDensity: VisualDensity.compact,
                  onPressed: _canGoNext
                      ? () => setState(() {
                            _displayedMonth = DateTime(
                              _displayedMonth.year,
                              _displayedMonth.month + 1,
                            );
                          })
                      : null,
                  icon: Icon(
                    Icons.chevron_right,
                    color: _canGoNext
                        ? AppColors.textPrimary
                        : AppColors.textDisabled,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Row(
              children: [
                for (final label in weekdays)
                  Expanded(
                    child: Center(
                      child: Text(
                        label,
                        style: typo.badgeSm.copyWith(
                          color: AppColors.textSecondary,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 4),
            SizedBox(
              height: weekCount * _cellSize,
              child: GridView.builder(
                physics: const NeverScrollableScrollPhysics(),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 7,
                  mainAxisExtent: _cellSize,
                ),
                itemCount: cells.length,
                itemBuilder: (context, index) {
                  final day = cells[index];
                  if (day == null) return const SizedBox.shrink();

                  final selectable = _isSelectable(day);
                  final selected = _isSameDay(day, _selected);
                  final isToday = _isSameDay(day, TripDateWindow.today());

                  return Center(
                    child: Material(
                      color: Colors.transparent,
                      child: InkWell(
                        customBorder: const CircleBorder(),
                        onTap: selectable
                            ? () => setState(() => _selected = day)
                            : null,
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 120),
                          width: 36,
                          height: 36,
                          alignment: Alignment.center,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: selected
                                ? AppColors.primary
                                : Colors.transparent,
                            border: !selected && isToday
                                ? Border.all(color: AppColors.primary)
                                : null,
                          ),
                          child: Text(
                            '${day.day}',
                            style: typo.body.copyWith(
                              fontSize: 14,
                              fontWeight: selected || isToday
                                  ? FontWeight.w700
                                  : FontWeight.w500,
                              color: !selectable
                                  ? AppColors.textDisabled
                                  : selected
                                      ? Colors.white
                                      : AppColors.textPrimary,
                            ),
                          ),
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: Text(
                    'Cancel',
                    style: typo.buttonSm.copyWith(color: AppColors.primary),
                  ),
                ),
                TextButton(
                  onPressed: () => Navigator.of(context).pop(_selected),
                  child: Text(
                    'OK',
                    style: typo.buttonSm.copyWith(
                      color: AppColors.primary,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
