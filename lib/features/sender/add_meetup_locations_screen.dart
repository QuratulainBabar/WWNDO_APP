import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../core/api/api_exception.dart';
import '../../core/platform/keyboard_utils.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_typography.dart';
import '../../data/models/meetup_location.dart';
import '../../data/services/places_search_service.dart';
import '../../providers/auth_provider.dart';

/// Location picker (search + multi-stop) used for From/To city and meetup spots.
/// Plain background — no map. Selecting a place returns immediately to the caller.
class AddMeetupLocationsScreen extends StatefulWidget {
  const AddMeetupLocationsScreen({
    super.key,
    this.initialLocations = const [],
    this.maxLocations = 3,
    this.title = 'Meetup locations',
    this.searchHint = 'Search meetup location',
    this.citySearch = false,
    this.airportSearch = false,
  });

  final List<MeetupLocation> initialLocations;
  final int maxLocations;
  final String title;
  final String searchHint;

  /// When true, search cities only (From / To city fields).
  final bool citySearch;

  /// When true, search airports only (country-to-country route pickers).
  final bool airportSearch;

  @override
  State<AddMeetupLocationsScreen> createState() =>
      _AddMeetupLocationsScreenState();
}

enum _PickerMode { browse, search, multiStop }

class _AddMeetupLocationsScreenState extends State<AddMeetupLocationsScreen> {
  PlacesSearchService? _placesService;
  final TextEditingController _searchController = TextEditingController();
  final FocusNode _searchFocus = FocusNode();

  _PickerMode _mode = _PickerMode.browse;
  final List<MeetupLocation> _stops = [];
  int? _editingStopIndex;

  List<MeetupLocation> _suggestions = [];
  bool _searching = false;
  Timer? _debounce;
  String? _searchError;

  PlacesSearchService get _places {
    return _placesService ??= PlacesSearchService(
      apiClient: context.read<AuthProvider>().repository.apiClient,
    );
  }

  @override
  void initState() {
    super.initState();
    _stops.addAll(widget.initialLocations);
    if (widget.maxLocations == 1) {
      // Single-location From/To pickers: go straight to search and replace on select.
      _mode = _PickerMode.search;
      _editingStopIndex = _stops.isEmpty ? null : 0;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) requestSoftKeyboard(_searchFocus);
      });
    } else if (_stops.isNotEmpty) {
      _mode = _PickerMode.multiStop;
    } else {
      _mode = _PickerMode.search;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) requestSoftKeyboard(_searchFocus);
      });
    }
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _searchController.dispose();
    _searchFocus.dispose();
    super.dispose();
  }

  bool get _canAddStop => _stops.length < widget.maxLocations;

  void _openSearch({int? forStopIndex}) {
    setState(() {
      _mode = _PickerMode.search;
      _editingStopIndex = forStopIndex;
      _suggestions = [];
      _searchError = null;
      _searchController.clear();
    });
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) requestSoftKeyboard(_searchFocus);
    });
  }

  void _closeSearch() {
    FocusScope.of(context).unfocus();
    // Empty picker with nothing selected → leave screen.
    if (_stops.isEmpty) {
      if (context.canPop()) context.pop();
      return;
    }
    // Single-location pickers should return the current selection.
    if (widget.maxLocations == 1) {
      _finish();
      return;
    }
    setState(() {
      _mode = _PickerMode.multiStop;
      _editingStopIndex = null;
      _suggestions = [];
      _searchController.clear();
      _searchError = null;
    });
  }

  void _onSearchChanged(String value) {
    _debounce?.cancel();
    if (value.trim().length < 2) {
      setState(() {
        _suggestions = [];
        _searching = false;
        _searchError = null;
      });
      return;
    }

    setState(() {
      _searching = true;
      _searchError = null;
    });

    _debounce = Timer(const Duration(milliseconds: 350), () async {
      try {
        final results = widget.citySearch
            ? await _places.searchCities(value)
            : widget.airportSearch
            ? await _places.searchAirports(value)
            : await _places.search(value);
        if (!mounted) return;
        setState(() {
          _suggestions = results;
          _searching = false;
        });
      } catch (e) {
        if (!mounted) return;
        setState(() {
          _suggestions = [];
          _searching = false;
          _searchError = e is ApiException && e.message.trim().isNotEmpty
              ? e.message
              : 'Could not search locations. Try again.';
        });
      }
    });
  }

  Future<void> _selectPlace(MeetupLocation place) async {
    MeetupLocation resolved = place;
    if (place.placeId != null && place.placeId!.isNotEmpty) {
      setState(() => _searching = true);
      resolved = await _places.resolveDetails(place);
      if (!mounted) return;
    }

    if (widget.maxLocations == 1) {
      // From/To city: always take the latest selection and return immediately.
      _stops
        ..clear()
        ..add(resolved);
    } else if (_editingStopIndex != null &&
        _editingStopIndex! >= 0 &&
        _editingStopIndex! < _stops.length) {
      _stops[_editingStopIndex!] = resolved;
    } else if (_stops.length < widget.maxLocations) {
      _stops.add(resolved);
    }

    FocusScope.of(context).unfocus();
    // Apply immediately — no Finish button required.
    _finish();
  }

  void _removeStop(int index) {
    setState(() {
      _stops.removeAt(index);
      if (_stops.isEmpty) {
        _mode = _PickerMode.search;
        _editingStopIndex = null;
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) requestSoftKeyboard(_searchFocus);
        });
      }
    });
  }

  void _reorderStops(int oldIndex, int newIndex) {
    setState(() {
      if (newIndex > oldIndex) newIndex -= 1;
      final item = _stops.removeAt(oldIndex);
      _stops.insert(newIndex, item);
    });
  }

  void _finish() {
    if (_stops.isEmpty) return;
    context.pop(List<MeetupLocation>.from(_stops));
  }

  void _handleBack() {
    if (_mode == _PickerMode.search) {
      _closeSearch();
      return;
    }
    // Persist removals / reorders without a Finish tap.
    if (_stops.isNotEmpty) {
      _finish();
      return;
    }
    if (context.canPop()) {
      context.pop();
    }
  }

  String _letterFor(int index) => String.fromCharCode(65 + index); // A, B, C

  @override
  Widget build(BuildContext context) {
    final typo = context.typo;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: Stack(
        children: [
          if (_mode == _PickerMode.browse || _mode == _PickerMode.multiStop)
            _buildMultiStopPanel(typo),
          if (_mode == _PickerMode.search) _buildSearchOverlay(typo),
          if (_mode == _PickerMode.browse && _stops.isEmpty)
            _buildBrowseHeader(typo),
        ],
      ),
    );
  }

  Widget _buildBrowseHeader(AppTypography typo) {
    return Positioned(
      top: 0,
      left: 0,
      right: 0,
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(12, 8, 12, 0),
          child: Material(
            elevation: 3,
            shadowColor: Colors.black26,
            borderRadius: BorderRadius.circular(28),
            color: AppColors.surface,
            child: InkWell(
              onTap: () => _openSearch(),
              borderRadius: BorderRadius.circular(28),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                child: Row(
                  children: [
                    IconButton(
                      onPressed: _handleBack,
                      icon: Icon(
                        Icons.arrow_back,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const Icon(Icons.place, color: AppColors.primary, size: 22),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Search here',
                        style: typo.input.copyWith(
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildMultiStopPanel(AppTypography typo) {
    return Positioned(
      top: 0,
      left: 0,
      right: 0,
      child: SafeArea(
        bottom: false,
        child: Container(
          margin: const EdgeInsets.fromLTRB(12, 8, 12, 0),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(16),
            boxShadow: const [
              BoxShadow(
                color: Color(0x33000000),
                blurRadius: 12,
                offset: Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(4, 4, 8, 0),
                child: Row(
                  children: [
                    IconButton(
                      onPressed: _handleBack,
                      icon: Icon(
                        Icons.arrow_back,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    Expanded(
                      child: Text(
                        widget.title,
                        style: typo.headerTitle,
                        textAlign: TextAlign.center,
                      ),
                    ),
                    const SizedBox(width: 48),
                  ],
                ),
              ),
              ReorderableListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                buildDefaultDragHandles: false,
                itemCount: _stops.length,
                onReorder: _reorderStops,
                proxyDecorator: (child, index, animation) {
                  return Material(
                    elevation: 4,
                    color: AppColors.surface,
                    borderRadius: BorderRadius.circular(8),
                    child: child,
                  );
                },
                itemBuilder: (context, index) {
                  final stop = _stops[index];
                  return _StopTile(
                    key: ValueKey(
                      'stop-${stop.placeId ?? stop.displayLabel}-$index',
                    ),
                    letter: _letterFor(index),
                    label: stop.displayLabel,
                    isFirst: index == 0,
                    isLast: index == _stops.length - 1 && !_canAddStop,
                    index: index,
                    onTap: () => _openSearch(forStopIndex: index),
                    onRemove: () => _removeStop(index),
                  );
                },
              ),
              if (_canAddStop)
                _AddStopRow(
                  letter: _letterFor(_stops.length),
                  showConnector: _stops.isNotEmpty,
                  onTap: () => _openSearch(),
                ),
              Divider(height: 1, color: AppColors.border),
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 12,
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.schedule,
                      size: 18,
                      color: AppColors.textSecondary,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      '${_stops.length} of ${widget.maxLocations} locations',
                      style: typo.sm.copyWith(color: AppColors.textSecondary),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSearchOverlay(AppTypography typo) {
    return Positioned.fill(
      child: Material(
        color: AppColors.background,
        child: SafeArea(
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(8, 4, 12, 8),
                child: Row(
                  children: [
                    IconButton(
                      onPressed: _closeSearch,
                      icon: Icon(
                        Icons.arrow_back,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    Expanded(
                      child: Container(
                        decoration: BoxDecoration(
                          color: AppColors.surface,
                          borderRadius: BorderRadius.circular(28),
                          border: Border.all(color: AppColors.border),
                        ),
                        child: TextField(
                          controller: _searchController,
                          focusNode: _searchFocus,
                          onTap: ensureSoftKeyboardVisible,
                          onTapOutside: dismissKeyboardOnTapOutside,
                          style: typo.input,
                          onChanged: _onSearchChanged,
                          textInputAction: TextInputAction.search,
                          decoration: InputDecoration(
                            hintText:
                                _editingStopIndex == null && _stops.isEmpty
                                ? widget.searchHint
                                : 'Add stop',
                            hintStyle: typo.input.copyWith(
                              color: AppColors.textSecondary,
                            ),
                            border: InputBorder.none,
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 12,
                            ),
                            suffixIcon: _searchController.text.isNotEmpty
                                ? IconButton(
                                    icon: const Icon(Icons.close, size: 18),
                                    onPressed: () {
                                      _searchController.clear();
                                      _onSearchChanged('');
                                      setState(() {});
                                    },
                                  )
                                : null,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              Divider(height: 1, color: AppColors.border),
              Expanded(child: _buildSuggestions(typo)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSuggestions(AppTypography typo) {
    if (_searching) {
      return const Center(
        child: CircularProgressIndicator(color: AppColors.primary),
      );
    }
    if (_searchError != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Text(
            _searchError!,
            textAlign: TextAlign.center,
            style: typo.sm,
          ),
        ),
      );
    }
    if (_searchController.text.trim().length < 2) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Text(
            'Type at least 2 characters to search.',
            textAlign: TextAlign.center,
            style: typo.sm,
          ),
        ),
      );
    }
    if (_suggestions.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Text(
            'No places found. Try a different search.',
            textAlign: TextAlign.center,
            style: typo.sm,
          ),
        ),
      );
    }

    return ListView.separated(
      itemCount: _suggestions.length,
      separatorBuilder: (_, _) => Divider(height: 1, color: AppColors.border),
      itemBuilder: (context, index) {
        final place = _suggestions[index];
        return ListTile(
          leading: Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: AppColors.kycBackground,
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.place, color: AppColors.primary, size: 20),
          ),
          title: Text(
            place.name,
            style: typo.body.copyWith(fontWeight: FontWeight.w600),
          ),
          subtitle: place.address != place.name
              ? Text(
                  place.address,
                  style: typo.sm,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                )
              : null,
          trailing: Icon(
            Icons.north_west,
            size: 16,
            color: AppColors.textSecondary,
          ),
          onTap: () => _selectPlace(place),
        );
      },
    );
  }
}

class _StopTile extends StatelessWidget {
  const _StopTile({
    super.key,
    required this.letter,
    required this.label,
    required this.isFirst,
    required this.isLast,
    required this.index,
    required this.onTap,
    required this.onRemove,
  });

  final String letter;
  final String label;
  final bool isFirst;
  final bool isLast;
  final int index;
  final VoidCallback onTap;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) {
    final typo = context.typo;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(12, 0, 4, 0),
          child: Row(
            children: [
              SizedBox(
                width: 28,
                height: 48,
                child: CustomPaint(
                  painter: _ConnectorPainter(
                    isFirst: isFirst,
                    isLast: isLast,
                    color: AppColors.textSecondary.withValues(alpha: 0.45),
                  ),
                  child: Center(
                    child: Container(
                      width: 22,
                      height: 22,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: AppColors.primary,
                        border: Border.all(color: AppColors.primary, width: 2),
                      ),
                      alignment: Alignment.center,
                      child: Text(
                        letter,
                        style: typo.sm.copyWith(
                          color: Colors.white,
                          fontWeight: FontWeight.w700,
                          fontSize: 11,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: typo.input.copyWith(fontSize: 15),
                ),
              ),
              ReorderableDragStartListener(
                index: index,
                child: Padding(
                  padding: EdgeInsets.all(8),
                  child: Icon(
                    Icons.drag_handle,
                    color: AppColors.textSecondary,
                  ),
                ),
              ),
              IconButton(
                onPressed: onRemove,
                icon: Icon(
                  Icons.close,
                  size: 18,
                  color: AppColors.textSecondary,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _AddStopRow extends StatelessWidget {
  const _AddStopRow({
    required this.letter,
    required this.showConnector,
    required this.onTap,
  });

  final String letter;
  final bool showConnector;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final typo = context.typo;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(12, 0, 12, 8),
          child: Row(
            children: [
              SizedBox(
                width: 28,
                height: 44,
                child: CustomPaint(
                  painter: _ConnectorPainter(
                    isFirst: !showConnector,
                    isLast: true,
                    color: AppColors.textSecondary.withValues(alpha: 0.45),
                  ),
                  child: Center(
                    child: Container(
                      width: 22,
                      height: 22,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(color: AppColors.primary, width: 2),
                        color: AppColors.surface,
                      ),
                      alignment: Alignment.center,
                      child: Text(
                        letter,
                        style: typo.sm.copyWith(
                          color: AppColors.primary,
                          fontWeight: FontWeight.w700,
                          fontSize: 11,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  'Add stop',
                  style: typo.input.copyWith(color: AppColors.textSecondary),
                ),
              ),
              const Icon(
                Icons.add_circle_outline,
                color: AppColors.primary,
                size: 22,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ConnectorPainter extends CustomPainter {
  _ConnectorPainter({
    required this.isFirst,
    required this.isLast,
    required this.color,
  });

  final bool isFirst;
  final bool isLast;
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = 2
      ..style = PaintingStyle.stroke;

    final cx = size.width / 2;
    if (!isFirst) {
      _drawDashedLine(
        canvas,
        Offset(cx, 0),
        Offset(cx, size.height / 2 - 12),
        paint,
      );
    }
    if (!isLast) {
      _drawDashedLine(
        canvas,
        Offset(cx, size.height / 2 + 12),
        Offset(cx, size.height),
        paint,
      );
    }
  }

  void _drawDashedLine(Canvas canvas, Offset start, Offset end, Paint paint) {
    const dash = 3.0;
    const gap = 3.0;
    var y = start.dy;
    while (y < end.dy) {
      final y2 = math.min(y + dash, end.dy);
      canvas.drawLine(Offset(start.dx, y), Offset(start.dx, y2), paint);
      y = y2 + gap;
    }
  }

  @override
  bool shouldRepaint(covariant _ConnectorPainter oldDelegate) =>
      oldDelegate.isFirst != isFirst ||
      oldDelegate.isLast != isLast ||
      oldDelegate.color != color;
}
