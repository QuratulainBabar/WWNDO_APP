import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../core/config/demo_mode.dart';
import '../../core/layout/responsive.dart';
import '../../core/platform/platform_ui.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_typography.dart';
import '../../core/widgets/app_card.dart';
import '../../core/widgets/back_link.dart';
import '../../data/models/traveler_trip.dart';
import '../../data/services/trip_repository.dart';
import '../../data/static_data.dart';
import '../../providers/auth_provider.dart';

/// My Trips tab — lists trips from GET /api/v1/trips.
class TravelerMyTripsScreen extends StatefulWidget {
  const TravelerMyTripsScreen({super.key});

  @override
  State<TravelerMyTripsScreen> createState() => _TravelerMyTripsScreenState();
}

class _TravelerMyTripsScreenState extends State<TravelerMyTripsScreen>
    with WidgetsBindingObserver {
  List<TravelerTrip> _trips = const [];
  bool _showActive = true;
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    StaticData.travelerPostedTripsVersion.addListener(_onTripsChanged);
    WidgetsBinding.instance.addPostFrameCallback((_) => _load());
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    StaticData.travelerPostedTripsVersion.removeListener(_onTripsChanged);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _load(silent: true);
    }
  }

  void _onTripsChanged() {
    if (!mounted) return;
    final demoMode = context.read<DemoModeProvider>().enabled;
    setState(() {
      _trips = StaticData.travelerTripsForDisplay(demoMode: demoMode);
      _loading = false;
      _error = null;
    });
  }

  TripRepository _repository() {
    final auth = context.read<AuthProvider>();
    final demoMode = context.read<DemoModeProvider>();
    return TripRepository(
      apiClient: auth.repository.apiClient,
      demoMode: demoMode,
    );
  }

  Future<void> _load({bool silent = false}) async {
    if (!mounted) return;
    final demoMode = context.read<DemoModeProvider>();

    if (demoMode.enabled) {
      setState(() {
        _trips = StaticData.travelerTripsForDisplay(demoMode: true);
        _loading = false;
        _error = null;
      });
      return;
    }

    if (!silent) {
      setState(() {
        _loading = true;
        _error = null;
      });
    }

    try {
      final trips = await _repository().listMyTrips();
      StaticData.replaceTravelerPostedTrips(trips);
      if (!mounted) return;
      setState(() {
        _trips = List<TravelerTrip>.from(trips);
        _loading = false;
        _error = null;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _trips = StaticData.travelerTripsForDisplay(demoMode: false);
        _loading = false;
        if (_trips.isEmpty) {
          _error = 'Unable to load your trips. Tap Retry.';
        }
      });
    }
  }

  List<TravelerTrip> get _visible {
    return _trips.where((t) {
      return _showActive ? !t.status.isCompleted : t.status.isCompleted;
    }).toList();
  }

  Future<void> _onMenuSelected(String value, TravelerTrip trip) async {
    final id = trip.displayId;
    if (value == 'edit') {
      final updated = await context.push<bool>('/edit-trip/$id');
      if (updated == true && mounted) {
        await _load(silent: true);
      }
      return;
    }
    if (value == 'cancel') {
      await context.push('/cancel-trip/$id');
      if (mounted) {
        await _load(silent: true);
      }
    }
  }

  List<PopupMenuEntry<String>> _menuItems(BuildContext context) {
    final typo = context.typo;
    final itemStyle = typo.body.copyWith(fontWeight: FontWeight.w400);

    return [
      PopupMenuItem(
        value: 'edit',
        height: 42,
        child: Text('Edit', style: itemStyle),
      ),
      const PopupMenuItem<String>(
        enabled: false,
        height: 1,
        padding: EdgeInsets.zero,
        child: Divider(
          height: 1,
          thickness: 1,
          color: AppColors.border,
        ),
      ),
      PopupMenuItem(
        value: 'cancel',
        height: 42,
        child: Text('Cancel', style: itemStyle),
      ),
    ];
  }

  @override
  Widget build(BuildContext context) {
    final horizontal = context.horizontalPadding;
    final typo = context.typo;
    final trips = _visible;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: EdgeInsets.fromLTRB(horizontal, 20, horizontal, 0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  BackLink(onTap: () => context.go('/traveler-home')),
                  const SizedBox(height: 16),
                  Text('My Trips', style: typo.h1),
                ],
              ),
            ),
            const SizedBox(height: 12),
            Container(
              width: double.infinity,
              padding: EdgeInsets.symmetric(horizontal: horizontal),
              decoration: const BoxDecoration(
                border: Border(
                  bottom: BorderSide(color: AppColors.border, width: 1),
                ),
              ),
              child: Row(
                children: [
                  _tab(
                    context,
                    'Active',
                    _showActive,
                    () => setState(() => _showActive = true),
                  ),
                  const SizedBox(width: 28),
                  _tab(
                    context,
                    'Completed',
                    !_showActive,
                    () => setState(() => _showActive = false),
                  ),
                ],
              ),
            ),
            Expanded(child: _body(context, typo, horizontal, trips)),
          ],
        ),
      ),
    );
  }

  Widget _body(
    BuildContext context,
    AppTypography typo,
    double horizontal,
    List<TravelerTrip> trips,
  ) {
    if (_loading && _trips.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_error != null && _trips.isEmpty) {
      return Center(
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: horizontal),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                _error!,
                textAlign: TextAlign.center,
                style: typo.sm.copyWith(color: AppColors.textSecondary),
              ),
              TextButton(onPressed: _load, child: const Text('Retry')),
            ],
          ),
        ),
      );
    }

    if (trips.isEmpty) {
      return Center(
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: horizontal),
          child: Text(
            _showActive ? 'No active trips yet.' : 'No completed trips yet.',
            style: typo.sm.copyWith(color: AppColors.textSecondary),
            textAlign: TextAlign.center,
          ),
        ),
      );
    }

    return RefreshIndicator(
      color: AppColors.primary,
      onRefresh: () => _load(silent: true),
      child: ListView.builder(
        physics: AlwaysScrollableScrollPhysics(parent: PlatformUi.scrollPhysics),
        padding: EdgeInsets.fromLTRB(horizontal, 20, horizontal, 24),
        itemCount: trips.length,
        itemBuilder: (context, i) {
          return Padding(
            padding: EdgeInsets.only(bottom: i == trips.length - 1 ? 0 : 10),
            child: _TripCard(
              trip: trips[i],
              onMenuSelected: (value) => _onMenuSelected(value, trips[i]),
              menuItems: _menuItems,
            ),
          );
        },
      ),
    );
  }

  Widget _tab(
    BuildContext context,
    String label,
    bool active,
    VoidCallback onTap,
  ) {
    final typo = context.typo;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.only(top: 4, bottom: 12),
        decoration: BoxDecoration(
          border: Border(
            bottom: BorderSide(
              color: active ? AppColors.primary : Colors.transparent,
              width: 2,
            ),
          ),
        ),
        child: Text(
          label,
          style: typo.body.copyWith(
            fontSize: 14,
            fontWeight: FontWeight.w700,
            color: active ? AppColors.primary : AppColors.textSecondary,
          ),
        ),
      ),
    );
  }
}

class _TripCard extends StatelessWidget {
  const _TripCard({
    required this.trip,
    required this.onMenuSelected,
    required this.menuItems,
  });

  final TravelerTrip trip;
  final ValueChanged<String> onMenuSelected;
  final List<PopupMenuEntry<String>> Function(BuildContext context) menuItems;

  @override
  Widget build(BuildContext context) {
    final typo = context.typo;
    final showMenu = trip.status.canEditOrCancel;

    return AppCard(
      margin: EdgeInsets.zero,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Text(
                  trip.route,
                  style: typo.h3.copyWith(fontWeight: FontWeight.w800),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              if (showMenu)
                PopupMenuButton<String>(
                  icon: const Icon(
                    Icons.more_vert,
                    color: AppColors.textSecondary,
                    size: 22,
                  ),
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(
                    minWidth: 36,
                    minHeight: 36,
                  ),
                  tooltip: 'More options',
                  onSelected: onMenuSelected,
                  itemBuilder: menuItems,
                ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            DateFormat('MMM d, yyyy').format(trip.travelDate),
            style: typo.sm.copyWith(color: AppColors.textSecondary),
          ),
          const SizedBox(height: 4),
          Text(
            '${trip.luggageCapacityKg.toStringAsFixed(0)} kg luggage available',
            style: typo.sm.copyWith(
              color: AppColors.primary,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}
