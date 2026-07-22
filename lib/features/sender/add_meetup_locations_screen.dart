import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_typography.dart';
import '../../data/models/meetup_location.dart';
import '../../data/services/places_search_service.dart';
import '../../providers/auth_provider.dart';

/// Maps-style meetup location picker (search + multi-stop), themed for WWNGO.
class AddMeetupLocationsScreen extends StatefulWidget {
  const AddMeetupLocationsScreen({
    super.key,
    this.initialLocations = const [],
    this.maxLocations = 3,
    this.title = 'Meetup locations',
    this.searchHint = 'Search meetup location',
    this.citySearch = false,
  });

  final List<MeetupLocation> initialLocations;
  final int maxLocations;
  final String title;
  final String searchHint;
  /// When true, search cities only (From / To route fields).
  final bool citySearch;

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
    if (_stops.isNotEmpty) {
      _mode = _PickerMode.multiStop;
    }
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _searchController.dispose();
    _searchFocus.dispose();
    super.dispose();
  }

  bool get _canFinish => _stops.isNotEmpty;
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
      if (mounted) _searchFocus.requestFocus();
    });
  }

  void _closeSearch() {
    FocusScope.of(context).unfocus();
    setState(() {
      _mode = _stops.isEmpty ? _PickerMode.browse : _PickerMode.multiStop;
      _editingStopIndex = null;
      _suggestions = [];
      _searchController.clear();
      _searchError = null;
    });
  }

  void _enterMultiStop() {
    setState(() => _mode = _PickerMode.multiStop);
    if (_stops.isEmpty) {
      _openSearch(forStopIndex: null);
    }
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
            : await _places.search(value);
        if (!mounted) return;
        setState(() {
          _suggestions = results;
          _searching = false;
        });
      } catch (_) {
        if (!mounted) return;
        setState(() {
          _suggestions = [];
          _searching = false;
          _searchError = 'Could not search locations. Try again.';
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

    setState(() {
      if (_editingStopIndex != null &&
          _editingStopIndex! >= 0 &&
          _editingStopIndex! < _stops.length) {
        _stops[_editingStopIndex!] = resolved;
      } else {
        if (_stops.length < widget.maxLocations) {
          _stops.add(resolved);
        }
      }
      _mode = _PickerMode.multiStop;
      _editingStopIndex = null;
      _suggestions = [];
      _searchController.clear();
      _searchError = null;
      _searching = false;
    });
    FocusScope.of(context).unfocus();
  }

  void _removeStop(int index) {
    setState(() {
      _stops.removeAt(index);
      if (_stops.isEmpty) {
        _mode = _PickerMode.browse;
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

  void _showAddStopMenu() {
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) {
        final typo = context.typo;
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(height: 8),
              Container(
                width: 36,
                height: 4,
                decoration: BoxDecoration(
                  color: AppColors.border,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              ListTile(
                leading: Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(color: AppColors.primary, width: 1.5),
                  ),
                  child: const Icon(Icons.add, color: AppColors.primary, size: 20),
                ),
                title: Text(
                  'Add stop',
                  style: typo.body.copyWith(fontWeight: FontWeight.w600),
                ),
                enabled: _canAddStop,
                onTap: _canAddStop
                    ? () {
                        Navigator.pop(context);
                        _openSearch();
                      }
                    : null,
              ),
              ListTile(
                leading: const Icon(Icons.close, color: AppColors.textSecondary),
                title: Text('Cancel', style: typo.body),
                onTap: () => Navigator.pop(context),
              ),
              const SizedBox(height: 8),
            ],
          ),
        );
      },
    );
  }

  void _finish() {
    if (!_canFinish) return;
    context.pop(List<MeetupLocation>.from(_stops));
  }

  void _handleBack() {
    if (_mode == _PickerMode.search) {
      _closeSearch();
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
      backgroundColor: const Color(0xFFE8F0E3),
      body: Stack(
        children: [
          const Positioned.fill(child: _MapBackdrop()),
          if (_stops.isNotEmpty) Positioned.fill(child: _RouteMarkers(stops: _stops)),

          // Top overlays
          if (_mode == _PickerMode.browse) _buildBrowseHeader(typo),
          if (_mode == _PickerMode.multiStop) _buildMultiStopPanel(typo),
          if (_mode == _PickerMode.search) _buildSearchOverlay(typo),

          // Directions FAB (browse mode) — like Maps "Go" button
          if (_mode == _PickerMode.browse)
            Positioned(
              right: 16,
              bottom: 28 + MediaQuery.paddingOf(context).bottom,
              child: _DirectionsFab(onTap: _enterMultiStop),
            ),

          // More / layers controls on map when multi-stop
          if (_mode == _PickerMode.multiStop)
            Positioned(
              right: 12,
              bottom: 28 + MediaQuery.paddingOf(context).bottom,
              child: Column(
                children: [
                  if (_canAddStop)
                    _MapIconButton(
                      icon: Icons.more_vert,
                      onTap: _showAddStopMenu,
                    ),
                ],
              ),
            ),
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
                      icon: const Icon(Icons.arrow_back, color: AppColors.textPrimary),
                    ),
                    const Icon(Icons.place, color: AppColors.primary, size: 22),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Search here',
                        style: typo.input.copyWith(color: AppColors.textSecondary),
                      ),
                    ),
                    const Icon(Icons.mic_none, color: AppColors.textSecondary),
                    const SizedBox(width: 8),
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
                      icon: const Icon(Icons.arrow_back, color: AppColors.textPrimary),
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
                    key: ValueKey('stop-${stop.placeId ?? stop.displayLabel}-$index'),
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
              const Divider(height: 1, color: AppColors.border),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
                child: Row(
                  children: [
                    const Icon(Icons.schedule, size: 18, color: AppColors.textSecondary),
                    const SizedBox(width: 8),
                    Text(
                      '${_stops.length} of ${widget.maxLocations} locations',
                      style: typo.sm.copyWith(color: AppColors.textSecondary),
                    ),
                    const Spacer(),
                    TextButton(
                      onPressed: _canFinish ? _finish : null,
                      child: Text(
                        'FINISHED',
                        style: typo.sm.copyWith(
                          color: _canFinish ? AppColors.primary : AppColors.textDisabled,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 0.6,
                        ),
                      ),
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
        color: AppColors.surface,
        child: SafeArea(
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(8, 4, 12, 8),
                child: Row(
                  children: [
                    IconButton(
                      onPressed: _closeSearch,
                      icon: const Icon(Icons.arrow_back, color: AppColors.textPrimary),
                    ),
                    Expanded(
                      child: Container(
                        decoration: BoxDecoration(
                          color: AppColors.background,
                          borderRadius: BorderRadius.circular(28),
                          border: Border.all(color: AppColors.border),
                        ),
                        child: TextField(
                          controller: _searchController,
                          focusNode: _searchFocus,
                          style: typo.input,
                          onChanged: _onSearchChanged,
                          textInputAction: TextInputAction.search,
                          decoration: InputDecoration(
                            hintText: _editingStopIndex == null && _stops.isEmpty
                                ? widget.searchHint
                                : 'Add stop',
                            hintStyle: typo.input.copyWith(color: AppColors.textSecondary),
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
              const Divider(height: 1, color: AppColors.border),
              Expanded(child: _buildSuggestions(typo)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSuggestions(AppTypography typo) {
    if (_searching) {
      return const Center(child: CircularProgressIndicator(color: AppColors.primary));
    }
    if (_searchError != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Text(_searchError!, textAlign: TextAlign.center, style: typo.sm),
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
      separatorBuilder: (_, _) => const Divider(height: 1, color: AppColors.border),
      itemBuilder: (context, index) {
        final place = _suggestions[index];
        return ListTile(
          leading: Container(
            width: 40,
            height: 40,
            decoration: const BoxDecoration(
              color: AppColors.kycBackground,
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.place, color: AppColors.primary, size: 20),
          ),
          title: Text(place.name, style: typo.body.copyWith(fontWeight: FontWeight.w600)),
          subtitle: place.address != place.name
              ? Text(place.address, style: typo.sm, maxLines: 2, overflow: TextOverflow.ellipsis)
              : null,
          trailing: const Icon(Icons.north_west, size: 16, color: AppColors.textSecondary),
          onTap: () => _selectPlace(place),
        );
      },
    );
  }
}

class _DirectionsFab extends StatelessWidget {
  const _DirectionsFab({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      elevation: 4,
      shadowColor: Colors.black38,
      shape: const CircleBorder(),
      color: AppColors.primary,
      child: InkWell(
        customBorder: const CircleBorder(),
        onTap: onTap,
        child: const SizedBox(
          width: 56,
          height: 56,
          child: Icon(Icons.directions, color: Colors.white, size: 28),
        ),
      ),
    );
  }
}

class _MapIconButton extends StatelessWidget {
  const _MapIconButton({required this.icon, required this.onTap});

  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      elevation: 3,
      shadowColor: Colors.black26,
      shape: const CircleBorder(),
      color: AppColors.surface,
      child: InkWell(
        customBorder: const CircleBorder(),
        onTap: onTap,
        child: SizedBox(
          width: 44,
          height: 44,
          child: Icon(icon, color: AppColors.textPrimary, size: 22),
        ),
      ),
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
                child: const Padding(
                  padding: EdgeInsets.all(8),
                  child: Icon(Icons.drag_handle, color: AppColors.textSecondary),
                ),
              ),
              IconButton(
                onPressed: onRemove,
                icon: const Icon(Icons.close, size: 18, color: AppColors.textSecondary),
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
              const Icon(Icons.add_circle_outline, color: AppColors.primary, size: 22),
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
      _drawDashedLine(canvas, Offset(cx, 0), Offset(cx, size.height / 2 - 12), paint);
    }
    if (!isLast) {
      _drawDashedLine(canvas, Offset(cx, size.height / 2 + 12), Offset(cx, size.height), paint);
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

/// Soft map-like backdrop (no Google Maps SDK / bottom nav).
class _MapBackdrop extends StatelessWidget {
  const _MapBackdrop();

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      painter: _MapBackdropPainter(),
      child: const SizedBox.expand(),
    );
  }
}

class _MapBackdropPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final bg = Paint()..color = const Color(0xFFE8F0E3);
    canvas.drawRect(Offset.zero & size, bg);

    // Parks / land patches
    final park = Paint()..color = const Color(0xFFD4E8C8);
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(size.width * 0.1, size.height * 0.25, size.width * 0.35, size.height * 0.18),
        const Radius.circular(40),
      ),
      park,
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(size.width * 0.55, size.height * 0.55, size.width * 0.4, size.height * 0.22),
        const Radius.circular(50),
      ),
      park,
    );

    // Water
    final water = Paint()..color = const Color(0xFFB8D4E8);
    canvas.drawOval(
      Rect.fromLTWH(size.width * 0.6, size.height * 0.15, size.width * 0.5, size.height * 0.2),
      water,
    );

    // Roads
    final road = Paint()
      ..color = Colors.white
      ..strokeWidth = 10
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;
    final roadEdge = Paint()
      ..color = const Color(0xFFC5CBD3)
      ..strokeWidth = 12
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    final paths = <Path>[
      Path()
        ..moveTo(0, size.height * 0.4)
        ..quadraticBezierTo(size.width * 0.4, size.height * 0.35, size.width, size.height * 0.48),
      Path()
        ..moveTo(size.width * 0.25, 0)
        ..quadraticBezierTo(size.width * 0.3, size.height * 0.5, size.width * 0.2, size.height),
      Path()
        ..moveTo(0, size.height * 0.7)
        ..quadraticBezierTo(size.width * 0.5, size.height * 0.65, size.width, size.height * 0.75),
    ];

    for (final path in paths) {
      canvas.drawPath(path, roadEdge);
      canvas.drawPath(path, road);
    }

    // Subtle grid
    final grid = Paint()
      ..color = const Color(0x14000000)
      ..strokeWidth = 1;
    for (var x = 0.0; x < size.width; x += 48) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), grid);
    }
    for (var y = 0.0; y < size.height; y += 48) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), grid);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _RouteMarkers extends StatelessWidget {
  const _RouteMarkers({required this.stops});

  final List<MeetupLocation> stops;

  @override
  Widget build(BuildContext context) {
    if (stops.isEmpty) return const SizedBox.shrink();

    return LayoutBuilder(
      builder: (context, constraints) {
        final points = <Offset>[];
        for (var i = 0; i < stops.length; i++) {
          final t = (i + 1) / (stops.length + 1);
          points.add(
            Offset(
              constraints.maxWidth * (0.25 + t * 0.5),
              constraints.maxHeight * (0.42 + (i.isEven ? -0.05 : 0.08) * t),
            ),
          );
        }

        return CustomPaint(
          size: Size(constraints.maxWidth, constraints.maxHeight),
          painter: _RouteLinePainter(points: points),
          child: Stack(
            children: [
              for (var i = 0; i < points.length; i++)
                Positioned(
                  left: points[i].dx - 16,
                  top: points[i].dy - 16,
                  child: Container(
                    width: 32,
                    height: 32,
                    decoration: BoxDecoration(
                      color: AppColors.primary,
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white, width: 2),
                      boxShadow: const [
                        BoxShadow(color: Colors.black26, blurRadius: 4, offset: Offset(0, 2)),
                      ],
                    ),
                    alignment: Alignment.center,
                    child: Text(
                      String.fromCharCode(65 + i),
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w700,
                        fontSize: 13,
                        fontFamily: AppTypography.fontFamilyName,
                      ),
                    ),
                  ),
                ),
            ],
          ),
        );
      },
    );
  }
}

class _RouteLinePainter extends CustomPainter {
  _RouteLinePainter({required this.points});

  final List<Offset> points;

  @override
  void paint(Canvas canvas, Size size) {
    if (points.length < 2) return;
    final paint = Paint()
      ..color = AppColors.primary.withValues(alpha: 0.85)
      ..strokeWidth = 4
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    final path = Path()..moveTo(points.first.dx, points.first.dy);
    for (var i = 1; i < points.length; i++) {
      path.lineTo(points[i].dx, points[i].dy);
    }
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant _RouteLinePainter oldDelegate) =>
      oldDelegate.points != points;
}
