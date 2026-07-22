import 'package:flutter/material.dart';

import '../../../core/geo/world_airports.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';

/// From / To airport search fields for country-to-country posting.
class AirportRouteSearchFields extends StatefulWidget {
  const AirportRouteSearchFields({
    super.key,
    this.fromAirport,
    this.toAirport,
    this.fromErrorText,
    this.toErrorText,
    required this.onFromChanged,
    required this.onToChanged,
  });

  final WorldAirport? fromAirport;
  final WorldAirport? toAirport;
  final String? fromErrorText;
  final String? toErrorText;
  final ValueChanged<WorldAirport?> onFromChanged;
  final ValueChanged<WorldAirport?> onToChanged;

  @override
  State<AirportRouteSearchFields> createState() =>
      _AirportRouteSearchFieldsState();
}

enum _ActiveField { none, from, to }

class _AirportRouteSearchFieldsState extends State<AirportRouteSearchFields> {
  static const _previewLimit = 5;

  final _fromController = TextEditingController();
  final _toController = TextEditingController();
  final _fromFocus = FocusNode();
  final _toFocus = FocusNode();

  _ActiveField _active = _ActiveField.none;
  List<WorldAirport> _suggestions = const [];
  int _totalMatches = 0;
  bool _showAll = false;
  String _query = '';
  bool _applyingSelection = false;

  @override
  void initState() {
    super.initState();
    _syncControllersFromProps();
    _fromFocus.addListener(_onFromFocus);
    _toFocus.addListener(_onToFocus);
  }

  @override
  void didUpdateWidget(covariant AirportRouteSearchFields oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!_fromFocus.hasFocus &&
        !_applyingSelection &&
        oldWidget.fromAirport?.code != widget.fromAirport?.code) {
      _fromController.text = widget.fromAirport?.resultTitle ?? '';
    }
    if (!_toFocus.hasFocus &&
        !_applyingSelection &&
        oldWidget.toAirport?.code != widget.toAirport?.code) {
      _toController.text = widget.toAirport?.resultTitle ?? '';
    }
  }

  void _syncControllersFromProps() {
    _fromController.text = widget.fromAirport?.resultTitle ?? '';
    _toController.text = widget.toAirport?.resultTitle ?? '';
  }

  @override
  void dispose() {
    _fromFocus.removeListener(_onFromFocus);
    _toFocus.removeListener(_onToFocus);
    _fromController.dispose();
    _toController.dispose();
    _fromFocus.dispose();
    _toFocus.dispose();
    super.dispose();
  }

  void _onFromFocus() {
    if (_fromFocus.hasFocus) {
      setState(() {
        _active = _ActiveField.from;
        _showAll = false;
      });
      _runSearch(_fromController.text);
      return;
    }
    _handleBlur(isFrom: true);
  }

  void _onToFocus() {
    if (_toFocus.hasFocus) {
      setState(() {
        _active = _ActiveField.to;
        _showAll = false;
      });
      _runSearch(_toController.text);
      return;
    }
    _handleBlur(isFrom: false);
  }

  /// Delay blur cleanup so a suggestion tap can apply before the panel closes.
  void _handleBlur({required bool isFrom}) {
    Future<void>.delayed(const Duration(milliseconds: 120), () {
      if (!mounted || _applyingSelection) return;
      if (_fromFocus.hasFocus || _toFocus.hasFocus) return;
      if (isFrom && _active != _ActiveField.from) return;
      if (!isFrom && _active != _ActiveField.to) return;

      final selected = isFrom ? widget.fromAirport : widget.toAirport;
      final controller = isFrom ? _fromController : _toController;
      if (selected != null) {
        controller.text = selected.resultTitle;
        controller.selection = TextSelection.collapsed(
          offset: controller.text.length,
        );
      }

      setState(() {
        _active = _ActiveField.none;
        _suggestions = const [];
        _totalMatches = 0;
        _query = '';
        _showAll = false;
      });
    });
  }

  void _runSearch(String value) {
    final q = value.trim();
    setState(() {
      _query = q;
      _totalMatches = WorldAirports.searchCount(q);
      _suggestions = WorldAirports.search(
        q,
        limit: _showAll ? 0 : _previewLimit,
      );
    });
  }

  void _onQueryChanged(String value, {required bool isFrom}) {
    if (isFrom && widget.fromAirport != null) {
      widget.onFromChanged(null);
    }
    if (!isFrom && widget.toAirport != null) {
      widget.onToChanged(null);
    }
    setState(() => _showAll = false);
    _runSearch(value);
  }

  void _selectAirport(WorldAirport airport, {required bool isFrom}) {
    _applyingSelection = true;
    final title = airport.resultTitle;
    final controller = isFrom ? _fromController : _toController;
    controller.value = TextEditingValue(
      text: title,
      selection: TextSelection.collapsed(offset: title.length),
    );

    if (isFrom) {
      widget.onFromChanged(airport);
    } else {
      widget.onToChanged(airport);
    }

    setState(() {
      _active = _ActiveField.none;
      _suggestions = const [];
      _totalMatches = 0;
      _query = '';
      _showAll = false;
    });

    FocusManager.instance.primaryFocus?.unfocus();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      _applyingSelection = false;
      // Ensure parent rebuild didn't wipe the selected label.
      if (isFrom) {
        _fromController.value = TextEditingValue(
          text: title,
          selection: TextSelection.collapsed(offset: title.length),
        );
      } else {
        _toController.value = TextEditingValue(
          text: title,
          selection: TextSelection.collapsed(offset: title.length),
        );
      }
    });
  }

  void _clearField({required bool isFrom}) {
    if (isFrom) {
      _fromController.clear();
      widget.onFromChanged(null);
      _fromFocus.requestFocus();
    } else {
      _toController.clear();
      widget.onToChanged(null);
      _toFocus.requestFocus();
    }
    setState(() {
      _showAll = false;
      _suggestions = const [];
      _totalMatches = 0;
      _query = '';
    });
  }

  @override
  Widget build(BuildContext context) {
    final typo = context.typo;
    final showSuggestions =
        _active != _ActiveField.none && _query.trim().length >= 2;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'From',
          style: typo.inputLabel.copyWith(fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 8),
        IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              SizedBox(
                width: 22,
                child: Column(
                  children: [
                    const SizedBox(height: 14),
                    Container(
                      width: 10,
                      height: 10,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(color: AppColors.primary, width: 2),
                      ),
                    ),
                    Expanded(
                      child: CustomPaint(
                        painter: _DashedLinePainter(color: AppColors.border),
                        child: const SizedBox(width: 2),
                      ),
                    ),
                    Container(
                      width: 10,
                      height: 10,
                      decoration: const BoxDecoration(
                        shape: BoxShape.circle,
                        color: AppColors.primary,
                      ),
                    ),
                    const SizedBox(height: 14),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  children: [
                    _AirportSearchField(
                      controller: _fromController,
                      focusNode: _fromFocus,
                      hasValue: widget.fromAirport != null,
                      errorText: widget.fromErrorText,
                      onChanged: (v) => _onQueryChanged(v, isFrom: true),
                      onClear: () => _clearField(isFrom: true),
                    ),
                    if (showSuggestions && _active == _ActiveField.from)
                      _SuggestionPanel(
                        query: _query,
                        suggestions: _suggestions,
                        totalMatches: _totalMatches,
                        showAll: _showAll,
                        onSelect: (airport) =>
                            _selectAirport(airport, isFrom: true),
                        onViewMore: () {
                          setState(() {
                            _showAll = true;
                            _suggestions =
                                WorldAirports.search(_query, limit: 0);
                          });
                        },
                      ),
                    const SizedBox(height: 12),
                    Align(
                      alignment: Alignment.centerLeft,
                      child: Text(
                        'To',
                        style: typo.inputLabel
                            .copyWith(fontWeight: FontWeight.w600),
                      ),
                    ),
                    const SizedBox(height: 8),
                    _AirportSearchField(
                      controller: _toController,
                      focusNode: _toFocus,
                      hasValue: widget.toAirport != null,
                      errorText: widget.toErrorText,
                      onChanged: (v) => _onQueryChanged(v, isFrom: false),
                      onClear: () => _clearField(isFrom: false),
                    ),
                    if (showSuggestions && _active == _ActiveField.to)
                      _SuggestionPanel(
                        query: _query,
                        suggestions: _suggestions,
                        totalMatches: _totalMatches,
                        showAll: _showAll,
                        onSelect: (airport) =>
                            _selectAirport(airport, isFrom: false),
                        onViewMore: () {
                          setState(() {
                            _showAll = true;
                            _suggestions =
                                WorldAirports.search(_query, limit: 0);
                          });
                        },
                      ),
                  ],
                ),
              ),
            ],
          ),
        ),
        if (!showSuggestions) ...[
          const SizedBox(height: 6),
          Text(
            'Start typing an airport name',
            style: typo.sm.copyWith(color: AppColors.textSecondary),
          ),
        ],
      ],
    );
  }
}

class _AirportSearchField extends StatelessWidget {
  const _AirportSearchField({
    required this.controller,
    required this.focusNode,
    required this.hasValue,
    required this.onChanged,
    required this.onClear,
    this.errorText,
  });

  final TextEditingController controller;
  final FocusNode focusNode;
  final bool hasValue;
  final ValueChanged<String> onChanged;
  final VoidCallback onClear;
  final String? errorText;

  @override
  Widget build(BuildContext context) {
    final typo = context.typo;
    final hasError = errorText != null && errorText!.isNotEmpty;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        TextField(
          controller: controller,
          focusNode: focusNode,
          style: typo.input.copyWith(
            fontWeight: hasValue ? FontWeight.w600 : FontWeight.w400,
          ),
          onChanged: onChanged,
          textInputAction: TextInputAction.search,
          decoration: InputDecoration(
            hintText: 'Search airport',
            hintStyle: typo.input.copyWith(color: AppColors.textDisabled),
            prefixIcon: const Icon(
              Icons.location_on,
              color: AppColors.primary,
              size: 22,
            ),
            suffixIcon: ListenableBuilder(
              listenable: controller,
              builder: (context, _) {
                if (controller.text.isEmpty) return const SizedBox.shrink();
                return IconButton(
                  onPressed: onClear,
                  icon: const Icon(
                    Icons.close_rounded,
                    size: 18,
                    color: AppColors.textSecondary,
                  ),
                );
              },
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(
                color: hasError ? AppColors.danger : AppColors.border,
              ),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(
                color: hasError ? AppColors.danger : AppColors.primary,
                width: 1.5,
              ),
            ),
          ),
        ),
        if (hasError) ...[
          const SizedBox(height: 6),
          Text(
            errorText!,
            style: typo.sm.copyWith(color: AppColors.danger),
          ),
        ],
      ],
    );
  }
}

class _SuggestionPanel extends StatelessWidget {
  const _SuggestionPanel({
    required this.query,
    required this.suggestions,
    required this.totalMatches,
    required this.showAll,
    required this.onSelect,
    required this.onViewMore,
  });

  final String query;
  final List<WorldAirport> suggestions;
  final int totalMatches;
  final bool showAll;
  final ValueChanged<WorldAirport> onSelect;
  final VoidCallback onViewMore;

  @override
  Widget build(BuildContext context) {
    final typo = context.typo;
    final remaining = totalMatches - suggestions.length;

    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(top: 8),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
        boxShadow: const [
          BoxShadow(
            color: Color(0x14000000),
            blurRadius: 10,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (suggestions.isEmpty)
            Padding(
              padding: const EdgeInsets.all(16),
              child: Text(
                'No airports found for "$query"',
                style: typo.sm.copyWith(color: AppColors.textSecondary),
              ),
            )
          else
            ...suggestions.map(
              (airport) => Material(
                color: Colors.transparent,
                child: InkWell(
                  // onTapDown fires before TextField blur, so full label is applied.
                  onTapDown: (_) => onSelect(airport),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 10,
                    ),
                    child: Row(
                      children: [
                        const Icon(
                          Icons.flight_takeoff_rounded,
                          color: AppColors.primary,
                          size: 20,
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                airport.resultTitle,
                                style: typo.input.copyWith(
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                airport.locationSubtitle,
                                style: typo.sm.copyWith(
                                  color: AppColors.textSecondary,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          if (!showAll && remaining > 0)
            InkWell(
              onTap: onViewMore,
              child: Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                child: Text(
                  "View more results for '$query'",
                  style: typo.sm.copyWith(
                    color: AppColors.primary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _DashedLinePainter extends CustomPainter {
  const _DashedLinePainter({required this.color});

  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = 2
      ..style = PaintingStyle.stroke;

    const dashHeight = 4.0;
    const dashSpace = 3.0;
    var startY = 0.0;
    final x = size.width / 2;
    while (startY < size.height) {
      canvas.drawLine(
        Offset(x, startY),
        Offset(x, (startY + dashHeight).clamp(0, size.height)),
        paint,
      );
      startY += dashHeight + dashSpace;
    }
  }

  @override
  bool shouldRepaint(covariant _DashedLinePainter oldDelegate) =>
      oldDelegate.color != color;
}
