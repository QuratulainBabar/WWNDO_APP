import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../l10n/app_localizations.dart';

import '../../core/config/demo_mode.dart';
import '../../core/layout/responsive.dart';
import '../../core/platform/platform_ui.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_typography.dart';
import '../../core/widgets/app_card.dart';
import '../../core/widgets/back_link.dart';
import '../../core/widgets/stacked_route_endpoints.dart';
import '../../data/models/traveler_trip.dart';
import '../../data/services/trip_repository.dart';
import '../../data/static_data.dart';
import '../../providers/auth_provider.dart';
import 'open_trip_delivery_detail.dart';

/// My Trips tab — lists trips from GET /api/v1/trips.
enum _MyTripsTab { active, completed, cancelled }

class TravelerMyTripsScreen extends StatefulWidget {
  const TravelerMyTripsScreen({super.key});

  @override
  State<TravelerMyTripsScreen> createState() => _TravelerMyTripsScreenState();
}

class _TravelerMyTripsScreenState extends State<TravelerMyTripsScreen>
    with WidgetsBindingObserver {
  late List<TravelerTrip> _trips;
  _MyTripsTab _tabFilter = _MyTripsTab.active;
  late bool _loading;
  String? _error;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    // Paint cached trips immediately so Home → Trip / trip cards feel instant.
    final cached = StaticData.travelerPostedTrips;
    _trips = List<TravelerTrip>.from(cached);
    _loading = cached.isEmpty;
    StaticData.travelerPostedTripsVersion.addListener(_onTripsChanged);
    WidgetsBinding.instance.addPostFrameCallback((_) => _load(silent: cached.isNotEmpty));
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
      return switch (_tabFilter) {
        _MyTripsTab.active =>
          t.status != TripStatus.delivered && t.status != TripStatus.cancelled,
        _MyTripsTab.completed => t.status == TripStatus.delivered,
        _MyTripsTab.cancelled => t.status == TripStatus.cancelled,
      };
    }).toList();
  }

  Future<void> _onMenuSelected(String value, TravelerTrip trip) async {
    final id = trip.displayId;
    if (value == 'view') {
      await openTravelerTripDeliveryDetail(context, trip);
      if (mounted) {
        await _load(silent: true);
      }
      return;
    }
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

  List<PopupMenuEntry<String>> _menuItems(
    BuildContext context, {
    required bool canEditOrCancel,
  }) {
    final typo = context.typo;
    final itemStyle = typo.body.copyWith(fontWeight: FontWeight.w400);

    return [
      PopupMenuItem(
        value: 'view',
        height: 42,
        child: Text('View', style: itemStyle),
      ),
      if (canEditOrCancel) ...[
        PopupMenuItem<String>(
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
          value: 'edit',
          height: 42,
          child: Text('Edit', style: itemStyle),
        ),
        PopupMenuItem<String>(
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
      ],
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
              decoration: BoxDecoration(
                border: Border(
                  bottom: BorderSide(color: AppColors.border, width: 1),
                ),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: _tab(
                      context,
                      'Active',
                      _tabFilter == _MyTripsTab.active,
                      () => setState(() => _tabFilter = _MyTripsTab.active),
                    ),
                  ),
                  Expanded(
                    child: _tab(
                      context,
                      'Completed',
                      _tabFilter == _MyTripsTab.completed,
                      () => setState(() => _tabFilter = _MyTripsTab.completed),
                    ),
                  ),
                  Expanded(
                    child: _tab(
                      context,
                      'Cancelled',
                      _tabFilter == _MyTripsTab.cancelled,
                      () => setState(() => _tabFilter = _MyTripsTab.cancelled),
                    ),
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
              TextButton(onPressed: _load, child: Text(context.tr('Retry'))),
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
            _tabFilter == _MyTripsTab.active
                ? 'No active trips yet.'
                : _tabFilter == _MyTripsTab.completed
                    ? 'No completed trips yet.'
                    : 'No cancelled trips yet.',
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
          final trip = trips[i];
          return Padding(
            padding: EdgeInsets.only(bottom: i == trips.length - 1 ? 0 : 10),
            child: _TripCard(
              trip: trip,
              onTap: () => openTravelerTripDeliveryDetail(context, trip),
              onMenuSelected: (value) => _onMenuSelected(value, trip),
              menuItems: (ctx) => _menuItems(
                ctx,
                canEditOrCancel: trip.status.canEditOrCancel,
              ),
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
      behavior: HitTestBehavior.opaque,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.only(top: 4, bottom: 12),
        alignment: Alignment.center,
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
          textAlign: TextAlign.center,
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
    required this.onTap,
    required this.onMenuSelected,
    required this.menuItems,
  });

  final TravelerTrip trip;
  final VoidCallback onTap;
  final ValueChanged<String> onMenuSelected;
  final List<PopupMenuEntry<String>> Function(BuildContext context) menuItems;

  @override
  Widget build(BuildContext context) {
    final typo = context.typo;

    return AppCard(
      margin: EdgeInsets.zero,
      onTap: onTap,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: StackedRouteEndpoints(
                  from: trip.displayOrigin,
                  to: trip.displayDestination,
                  fallbackRoute: trip.route,
                  emphasized: true,
                ),
              ),
              PopupMenuButton<String>(
                icon: Icon(
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
          if (trip.status.isCompleted) ...[
            const SizedBox(height: 8),
            Text(
              trip.status.label,
              style: typo.sm.copyWith(
                color: trip.status.color,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ],
      ),
    );
  }
}
