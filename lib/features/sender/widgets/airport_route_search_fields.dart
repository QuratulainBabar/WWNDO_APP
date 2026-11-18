import 'dart:async';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/api/api_exception.dart';
import '../../../core/platform/keyboard_utils.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/widgets/app_chip.dart';
import '../../../data/models/meetup_location.dart';
import '../../../data/services/places_search_service.dart';
import '../../../providers/auth_provider.dart';

/// From / To airport or city search for country-to-country posting.
class AirportRouteSearchFields extends StatefulWidget {
  const AirportRouteSearchFields({
    super.key,
    this.fromAirport,
    this.toAirport,
    this.fromErrorText,
    this.toErrorText,
    this.fromFieldKey,
    this.toFieldKey,
    this.fromSearchAirports = true,
    this.toSearchAirports = true,
    this.onFromSearchModeChanged,
    this.onToSearchModeChanged,
    required this.onFromChanged,
    required this.onToChanged,
  });

  final MeetupLocation? fromAirport;
  final MeetupLocation? toAirport;
  final String? fromErrorText;
  final String? toErrorText;
  final Key? fromFieldKey;
  final Key? toFieldKey;
  /// When false, From searches cities instead of airports.
  final bool fromSearchAirports;
  /// When false, To searches cities instead of airports.
  final bool toSearchAirports;
  final ValueChanged<bool>? onFromSearchModeChanged;
  final ValueChanged<bool>? onToSearchModeChanged;
  final ValueChanged<MeetupLocation?> onFromChanged;
  final ValueChanged<MeetupLocation?> onToChanged;

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

  PlacesSearchService? _placesService;
  Timer? _debounce;

  _ActiveField _active = _ActiveField.none;
  List<MeetupLocation> _suggestions = const [];
  int _totalMatches = 0;
  bool _showAll = false;
  bool _searching = false;
  String? _searchError;
  String _query = '';
  bool _applyingSelection = false;

  PlacesSearchService get _places {
    return _placesService ??= PlacesSearchService(
      apiClient: context.read<AuthProvider>().repository.apiClient,
    );
  }

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
        oldWidget.fromAirport?.placeId != widget.fromAirport?.placeId) {
      _fromController.text = widget.fromAirport?.displayLabel ?? '';
    }
    if (!_toFocus.hasFocus &&
        !_applyingSelection &&
        oldWidget.toAirport?.placeId != widget.toAirport?.placeId) {
      _toController.text = widget.toAirport?.displayLabel ?? '';
    }
    if (oldWidget.fromSearchAirports != widget.fromSearchAirports ||
        oldWidget.toSearchAirports != widget.toSearchAirports) {
      setState(() {
        _suggestions = const [];
        _totalMatches = 0;
        _query = '';
        _searchError = null;
        _showAll = false;
      });
    }
  }

  void _syncControllersFromProps() {
    _fromController.text = widget.fromAirport?.displayLabel ?? '';
    _toController.text = widget.toAirport?.displayLabel ?? '';
  }

  @override
  void dispose() {
    _debounce?.cancel();
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

  void _handleBlur({required bool isFrom}) {
    Future<void>.delayed(const Duration(milliseconds: 120), () {
      if (!mounted || _applyingSelection) return;
      if (_fromFocus.hasFocus || _toFocus.hasFocus) return;
      if (isFrom && _active != _ActiveField.from) return;
      if (!isFrom && _active != _ActiveField.to) return;

      final selected = isFrom ? widget.fromAirport : widget.toAirport;
      final controller = isFrom ? _fromController : _toController;
      if (selected != null) {
        controller.text = selected.displayLabel;
      } else if (controller.text.trim().length < 2) {
        controller.clear();
      }

      setState(() {
        _active = _ActiveField.none;
        _suggestions = const [];
        _totalMatches = 0;
        _query = '';
        _showAll = false;
        _searchError = null;
      });
    });
  }

  void _runSearch(String value) {
    final q = value.trim();
    _debounce?.cancel();

    if (q.length < 2) {
      setState(() {
        _query = q;
        _suggestions = const [];
        _totalMatches = 0;
        _searching = false;
        _searchError = null;
      });
      return;
    }

    setState(() {
      _query = q;
      _searching = true;
      _searchError = null;
    });

    _debounce = Timer(const Duration(milliseconds: 350), () async {
      try {
        final searchAirports = _active == _ActiveField.from
            ? widget.fromSearchAirports
            : widget.toSearchAirports;
        final results = searchAirports
            ? await _places.searchAirports(q)
            : await _places.searchCities(q);
        if (!mounted) return;
        setState(() {
          _totalMatches = results.length;
          _suggestions = _showAll
              ? results
              : results.take(_previewLimit).toList();
          _searching = false;
        });
      } catch (e) {
        if (!mounted) return;
        final searchAirports = _active == _ActiveField.from
            ? widget.fromSearchAirports
            : widget.toSearchAirports;
        setState(() {
          _suggestions = const [];
          _totalMatches = 0;
          _searching = false;
          _searchError = e is ApiException && e.message.trim().isNotEmpty
              ? e.message
              : (searchAirports
                  ? 'Could not search airports. Try again.'
                  : 'Could not search locations. Try again.');
        });
      }
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

  Future<void> _selectAirport(MeetupLocation place, {required bool isFrom}) async {
    _applyingSelection = true;
    setState(() => _searching = true);

    MeetupLocation resolved = place;
    if (place.placeId != null && place.placeId!.isNotEmpty) {
      resolved = await _places.resolveDetails(place);
    }

    if (!mounted) return;

    final title = resolved.displayLabel;
    final controller = isFrom ? _fromController : _toController;
    controller.value = TextEditingValue(
      text: title,
      selection: TextSelection.collapsed(offset: title.length),
    );

    if (isFrom) {
      widget.onFromChanged(resolved);
    } else {
      widget.onToChanged(resolved);
    }

    setState(() {
      _active = _ActiveField.none;
      _suggestions = const [];
      _totalMatches = 0;
      _query = '';
      _showAll = false;
      _searching = false;
    });

    FocusManager.instance.primaryFocus?.unfocus();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      _applyingSelection = false;
    });
  }

  void _clearField({required bool isFrom}) {
    if (isFrom) {
      _fromController.clear();
      widget.onFromChanged(null);
      requestSoftKeyboard(_fromFocus);
    } else {
      _toController.clear();
      widget.onToChanged(null);
      requestSoftKeyboard(_toFocus);
    }
    setState(() {
      _showAll = false;
      _suggestions = const [];
      _totalMatches = 0;
      _query = '';
      _searchError = null;
    });
  }

  void _viewMoreResults() async {
    setState(() => _showAll = true);
    if (_query.trim().length >= 2) {
      try {
        final searchAirports = _active == _ActiveField.from
            ? widget.fromSearchAirports
            : widget.toSearchAirports;
        final results = searchAirports
            ? await _places.searchAirports(_query)
            : await _places.searchCities(_query);
        if (!mounted) return;
        setState(() {
          _totalMatches = results.length;
          _suggestions = results;
        });
      } catch (_) {
        // Keep current preview list.
      }
    }
  }

  String get _helperText {
    final fromAirport = widget.fromSearchAirports;
    final toAirport = widget.toSearchAirports;
    if (fromAirport && toAirport) {
      return 'Start typing an airport name';
    }
    if (!fromAirport && !toAirport) {
      return 'Start typing a city name';
    }
    return 'Start typing an airport or city name';
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
        if (widget.onFromSearchModeChanged != null) ...[
          const SizedBox(height: 8),
          AppChipRow(
            options: const ['Airport', 'City'],
            selected: widget.fromSearchAirports ? 'Airport' : 'City',
            onSelected: (value) =>
                widget.onFromSearchModeChanged!(value == 'Airport'),
          ),
        ],
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
                    KeyedSubtree(
                      key: widget.fromFieldKey,
                      child: _AirportSearchField(
                        controller: _fromController,
                        focusNode: _fromFocus,
                        hasValue: widget.fromAirport != null,
                        errorText: widget.fromErrorText,
                        hintText: widget.fromSearchAirports
                            ? 'Search Airport'
                            : 'Search Location',
                        onChanged: (v) => _onQueryChanged(v, isFrom: true),
                        onClear: () => _clearField(isFrom: true),
                      ),
                    ),
                    if (showSuggestions && _active == _ActiveField.from)
                      _SuggestionPanel(
                        query: _query,
                        suggestions: _suggestions,
                        totalMatches: _totalMatches,
                        showAll: _showAll,
                        searching: _searching,
                        searchError: _searchError,
                        onSelect: (airport) =>
                            _selectAirport(airport, isFrom: true),
                        onViewMore: _viewMoreResults,
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
                    if (widget.onToSearchModeChanged != null) ...[
                      const SizedBox(height: 8),
                      Align(
                        alignment: Alignment.centerLeft,
                        child: AppChipRow(
                          options: const ['Airport', 'City'],
                          selected:
                              widget.toSearchAirports ? 'Airport' : 'City',
                          onSelected: (value) =>
                              widget.onToSearchModeChanged!(value == 'Airport'),
                        ),
                      ),
                    ],
                    const SizedBox(height: 8),
                    KeyedSubtree(
                      key: widget.toFieldKey,
                      child: _AirportSearchField(
                        controller: _toController,
                        focusNode: _toFocus,
                        hasValue: widget.toAirport != null,
                        errorText: widget.toErrorText,
                        hintText: widget.toSearchAirports
                            ? 'Search Airport'
                            : 'Search Location',
                        onChanged: (v) => _onQueryChanged(v, isFrom: false),
                        onClear: () => _clearField(isFrom: false),
                      ),
                    ),
                    if (showSuggestions && _active == _ActiveField.to)
                      _SuggestionPanel(
                        query: _query,
                        suggestions: _suggestions,
                        totalMatches: _totalMatches,
                        showAll: _showAll,
                        searching: _searching,
                        searchError: _searchError,
                        onSelect: (airport) =>
                            _selectAirport(airport, isFrom: false),
                        onViewMore: _viewMoreResults,
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
            _helperText,
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
    this.hintText = 'Search Airport',
  });

  final TextEditingController controller;
  final FocusNode focusNode;
  final bool hasValue;
  final ValueChanged<String> onChanged;
  final VoidCallback onClear;
  final String? errorText;
  final String hintText;

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
          onTap: ensureSoftKeyboardVisible,
          onTapOutside: dismissKeyboardOnTapOutside,
          style: typo.input.copyWith(
            fontWeight: hasValue ? FontWeight.w600 : FontWeight.w400,
          ),
          onChanged: onChanged,
          textInputAction: TextInputAction.search,
          decoration: InputDecoration(
            hintText: hintText,
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
                  icon: Icon(
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
    required this.searching,
    required this.searchError,
    required this.onSelect,
    required this.onViewMore,
  });

  final String query;
  final List<MeetupLocation> suggestions;
  final int totalMatches;
  final bool showAll;
  final bool searching;
  final String? searchError;
  final ValueChanged<MeetupLocation> onSelect;
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
          if (searching && suggestions.isEmpty)
            Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
                  const SizedBox(width: 10),
                  Text(
                    'Searching airports…',
                    style: typo.sm.copyWith(color: AppColors.textSecondary),
                  ),
                ],
              ),
            )
          else if (searchError != null)
            Padding(
              padding: const EdgeInsets.all(16),
              child: Text(
                searchError!,
                style: typo.sm.copyWith(color: AppColors.danger),
              ),
            )
          else if (suggestions.isEmpty)
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
                                airport.name.isNotEmpty
                                    ? airport.name
                                    : airport.displayLabel,
                                style: typo.input.copyWith(
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              if (airport.address.isNotEmpty &&
                                  airport.address != airport.name) ...[
                                const SizedBox(height: 2),
                                Text(
                                  airport.address,
                                  style: typo.sm.copyWith(
                                    color: AppColors.textSecondary,
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          if (!searching && !showAll && remaining > 0)
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
