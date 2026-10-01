import 'dart:async';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../core/auth/selected_role.dart';
import '../../core/auth/auth_verification_guard.dart';
import '../../core/auth/kyc_verification_guard.dart';
import '../../core/config/demo_mode.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_typography.dart';
import '../../core/widgets/app_card.dart';
import '../../core/widgets/app_svg_icon.dart';
import '../../core/widgets/delivery_status_badge.dart';
import '../../core/widgets/screen_body.dart';
import '../../core/widgets/stacked_route_endpoints.dart';
import '../../core/widgets/wallet_card.dart';
import '../../data/models/created_delivery.dart';
import '../../data/models/traveler_trip.dart';
import '../../data/models/wallet_role.dart';
import '../../data/services/delivery_repository.dart';
import '../../data/services/trip_repository.dart';
import '../../data/static_data.dart';
import '../../l10n/app_localizations.dart';
import '../../providers/auth_provider.dart';
import '../../providers/notification_realtime_provider.dart';
import '../../providers/wallet_provider.dart';
import 'open_trip_delivery_detail.dart';

class TravelerHomeScreen extends StatefulWidget {
  const TravelerHomeScreen({super.key});

  @override
  State<TravelerHomeScreen> createState() => _TravelerHomeScreenState();
}

class _TravelerHomeScreenState extends State<TravelerHomeScreen> {
  String? _lastMatchedLocation;
  final GlobalKey<_MyTripsSectionState> _tripsKey =
      GlobalKey<_MyTripsSectionState>();
  final GlobalKey<_MyDeliveriesSectionState> _deliveriesKey =
      GlobalKey<_MyDeliveriesSectionState>();
  VoidCallback? _realtimeListener;
  NotificationRealtimeProvider? _realtimeProvider;
  int _lastDeliveryUpdateTick = 0;
  Timer? _fallbackPollTimer;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      context.read<AuthProvider>().refreshUser();
      _attachRealtimeListener();
      _refreshSenderRequestBadge();
    });
    _fallbackPollTimer = Timer.periodic(const Duration(seconds: 45), (_) {
      if (!mounted) return;
      if (!(_realtimeProvider?.isConnected ?? false)) {
        _refreshSenderRequestBadge();
      }
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final location = GoRouterState.of(context).matchedLocation;
    if (location == '/traveler-home' && _lastMatchedLocation != '/traveler-home') {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        context.read<AuthProvider>().refreshUser();
        _tripsKey.currentState?.reload(silent: true);
        _deliveriesKey.currentState?.reload(silent: true);
        _refreshSenderRequestBadge();
        context
            .read<WalletProvider>()
            .refresh(WalletRole.traveler, silent: true)
            .ignore();
      });
    }
    _lastMatchedLocation = location;
  }

  @override
  void dispose() {
    _fallbackPollTimer?.cancel();
    if (_realtimeListener != null) {
      _realtimeProvider?.removeListener(_realtimeListener!);
    }
    super.dispose();
  }

  void _attachRealtimeListener() {
    final realtime = context.read<NotificationRealtimeProvider>();
    _realtimeProvider = realtime;
    _lastDeliveryUpdateTick = realtime.deliveryUpdateTick;
    _realtimeListener ??= () {
      if (!mounted) return;
      final tick = realtime.deliveryUpdateTick;
      if (tick != _lastDeliveryUpdateTick) {
        _lastDeliveryUpdateTick = tick;
        _refreshSenderRequestBadge();
        _deliveriesKey.currentState?.reload(silent: true);
        // Keep Wallet + Escrow in sync when Pay Now / Delivered updates arrive.
        context
            .read<WalletProvider>()
            .refresh(WalletRole.traveler, silent: true)
            .ignore();
      }
    };
    realtime.addListener(_realtimeListener!);
  }

  TripRepository _tripRepo() {
    final auth = context.read<AuthProvider>();
    final demoMode = context.read<DemoModeProvider>();
    return TripRepository(
      apiClient: auth.repository.apiClient,
      demoMode: demoMode,
    );
  }

  Future<void> _refreshSenderRequestBadge() async {
    final demoMode = context.read<DemoModeProvider>();
    if (demoMode.enabled) return;

    try {
      final count = await _tripRepo().countSenderRequests();
      if (!mounted) return;
      context.read<NotificationRealtimeProvider>().setSenderRequestUnreadCount(
            count,
          );
    } catch (_) {
      // Keep last known badge count; home should stay usable offline.
    }
  }

  Future<void> _onPullRefresh() async {
    await Future.wait([
      context.read<AuthProvider>().refreshUser(),
      _tripsKey.currentState?.reload(silent: true) ?? Future<void>.value(),
      _deliveriesKey.currentState?.reload(silent: true) ?? Future<void>.value(),
      _refreshSenderRequestBadge(),
      context.read<WalletProvider>().refresh(WalletRole.traveler, silent: true),
    ]);
  }

  Future<void> _onCreateTrip() async {
    if (!AuthVerificationGuard.ensureVerifiedForTransaction(context)) return;
    if (!KycVerificationGuard.ensureKycApproved(context)) return;
    context.push('/trip-type');
  }

  @override
  Widget build(BuildContext context) {
    final typo = context.typo;
    final l10n = context.l10n;
    final authUser = context.watch<AuthProvider>().user;
    final senderRequestCount =
        context.watch<NotificationRealtimeProvider>().senderRequestUnreadCount;
    final greeting = (authUser?.firstName.trim().isNotEmpty ?? false)
        ? l10n.heyUser(authUser!.firstName)
        : l10n.heyThere;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: ScreenBody(
        onRefresh: _onPullRefresh,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Flexible(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        greeting,
                        style: typo.h1,
                      ),
                      Text(
                        context.tr(
                          SelectedRoleStore.homeRatingSubtitle(
                            authUser,
                            WalletRole.traveler,
                          ),
                        ),
                        style: typo.sm,
                      ),
                    ],
                  ),
                ),
                WalletCard(role: WalletRole.traveler),
              ],
            ),
            const SizedBox(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Text(l10n.travelerMyTrips, style: typo.h3.copyWith(fontWeight: FontWeight.w700)),
                GestureDetector(
                  onTap: _onCreateTrip,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    decoration: BoxDecoration(
                      color: AppColors.primary,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          '+',
                          style: typo.buttonSm.copyWith(
                            color: Colors.white,
                            fontWeight: FontWeight.w600,
                            fontSize: 18,
                          ),
                        ),
                        const SizedBox(width: 4),
                        Text(
                          l10n.travelerCreateTrip,
                          style: typo.buttonSm.copyWith(
                            color: Colors.white,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            _MyTripsSection(key: _tripsKey),
            const SizedBox(height: 24),
            Text(l10n.quickActions, style: typo.h3.copyWith(fontWeight: FontWeight.w700)),
            const SizedBox(height: 12),
            _quickActionsGrid(context, l10n, senderRequestCount),
            const SizedBox(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  l10n.activeDeliveries,
                  style: typo.h3.copyWith(fontWeight: FontWeight.w700),
                ),
                GestureDetector(
                  onTap: () => context.push('/traveler-deliveries'),
                  child: Text(
                    l10n.seeAll,
                    style: typo.sm.copyWith(
                      color: AppColors.primary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            _MyDeliveriesSection(key: _deliveriesKey),
          ],
        ),
      ),
    );
  }

  Widget _quickActionsGrid(
    BuildContext context,
    AppLocalizations l10n,
    int senderRequestCount,
  ) {
    final typo = context.typo;
    final labelStyle = typo.sm.copyWith(
      fontWeight: FontWeight.w600,
      height: 1.2,
    );
    const verticalPad = 32.0; // 16 top + 16 bottom
    const iconSize = 28.0;
    const iconGap = 10.0;
    const horizontalPad = 12.0; // 6 + 6
    const gridGap = 10.0;
    const borderWidth = 1.0; // Border.all on each tile

    final actions = <({String icon, String label, VoidCallback onTap, int badge})>[
      (
        icon: AppIcons.roleSender,
        label: l10n.senderRequests,
        onTap: () async {
          await context.push('/matching-requests');
          if (mounted) _refreshSenderRequestBadge();
        },
        badge: senderRequestCount,
      ),
      (
        icon: AppIcons.track,
        label: l10n.myDeliveries,
        onTap: () async {
          await context.push('/traveler-deliveries');
          if (mounted) {
            _deliveriesKey.currentState?.reload(silent: true);
          }
        },
        badge: 0,
      ),
      (
        icon: AppIcons.history,
        label: l10n.counterOffers,
        onTap: () => context.push('/traveler-bids'),
        badge: 0,
      ),
      (
        icon: AppIcons.match,
        label: l10n.acceptedOffers,
        onTap: () => context.push('/traveler-bids?filter=acceptance'),
        badge: 0,
      ),
    ];

    return LayoutBuilder(
      builder: (context, constraints) {
        final tileWidth = (constraints.maxWidth - gridGap) / 2;
        final labelMaxWidth = (tileWidth - horizontalPad).clamp(0.0, double.infinity);
        final textScaler = MediaQuery.textScalerOf(context);
        final textDirection = Directionality.of(context);

        var labelBlockHeight = 0.0;
        for (final action in actions) {
          final painter = TextPainter(
            text: TextSpan(text: action.label, style: labelStyle),
            textAlign: TextAlign.center,
            textDirection: textDirection,
            textScaler: textScaler,
            maxLines: 2,
            ellipsis: '…',
          )..layout(maxWidth: labelMaxWidth);
          if (painter.height > labelBlockHeight) {
            labelBlockHeight = painter.height;
          }
        }
        // Small buffer for glyph metrics / rounding across locales.
        labelBlockHeight += 4;

        // Border reduces the inner content area by 1px top + 1px bottom.
        final tileHeight = verticalPad +
            iconSize +
            iconGap +
            labelBlockHeight +
            (borderWidth * 2);

        return GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: actions.length,
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            mainAxisSpacing: gridGap,
            crossAxisSpacing: gridGap,
            mainAxisExtent: tileHeight,
          ),
          itemBuilder: (context, index) {
            final action = actions[index];
            return _quickAction(
              context,
              action.icon,
              action.label,
              action.onTap,
              badgeCount: action.badge,
              labelStyle: labelStyle,
              labelBlockHeight: labelBlockHeight,
            );
          },
        );
      },
    );
  }

  Widget _quickAction(
    BuildContext context,
    String iconAsset,
    String label,
    VoidCallback onTap, {
    int badgeCount = 0,
    TextStyle? labelStyle,
    required double labelBlockHeight,
  }) {
    final typo = context.typo;
    final style = labelStyle ??
        typo.sm.copyWith(fontWeight: FontWeight.w600, height: 1.2);
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        height: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 16),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppColors.border),
        ),
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  AppSvgIcon(
                    asset: iconAsset,
                    size: 28,
                    color: AppColors.primary,
                  ),
                  const SizedBox(height: 10),
                  SizedBox(
                    height: labelBlockHeight,
                    width: double.infinity,
                    child: Align(
                      alignment: Alignment.topCenter,
                      child: Text(
                        label,
                        textAlign: TextAlign.center,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: style,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            if (badgeCount > 0)
              Positioned(
                top: -4,
                right: 4,
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: AppColors.danger,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    badgeCount > 99 ? '99+' : '$badgeCount',
                    style: typo.caption.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _MyTripsSection extends StatefulWidget {
  const _MyTripsSection({super.key});

  @override
  State<_MyTripsSection> createState() => _MyTripsSectionState();
}

class _MyTripsSectionState extends State<_MyTripsSection> {
  late List<TravelerTrip> _trips;
  late bool _loading;
  bool _loadFailed = false;

  List<TravelerTrip> _homeTrips(List<TravelerTrip> trips) =>
      trips.where((t) => !t.status.isCompleted).toList();

  @override
  void initState() {
    super.initState();
    final cached = _homeTrips(StaticData.travelerPostedTrips);
    _trips = cached;
    _loading = cached.isEmpty;
    StaticData.travelerPostedTripsVersion.addListener(_onTripsChanged);
    WidgetsBinding.instance.addPostFrameCallback(
      (_) => reload(silent: cached.isNotEmpty),
    );
  }

  @override
  void dispose() {
    StaticData.travelerPostedTripsVersion.removeListener(_onTripsChanged);
    super.dispose();
  }

  void _onTripsChanged() {
    if (!mounted) return;
    final demoMode = context.read<DemoModeProvider>().enabled;
    setState(() {
      _trips = _homeTrips(
        StaticData.travelerTripsForDisplay(demoMode: demoMode),
      );
      _loading = false;
      _loadFailed = false;
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

  Future<void> reload({bool silent = false}) async {
    if (!mounted) return;
    final demoMode = context.read<DemoModeProvider>();

    if (demoMode.enabled) {
      setState(() {
        _trips = _homeTrips(
          StaticData.travelerTripsForDisplay(demoMode: true),
        );
        _loading = false;
        _loadFailed = false;
      });
      return;
    }

    if (!silent) {
      setState(() {
        _loading = true;
        _loadFailed = false;
      });
    }

    try {
      final trips = await _repository().listMyTrips();
      StaticData.replaceTravelerPostedTrips(trips);
      if (!mounted) return;
      setState(() {
        _trips = _homeTrips(trips);
        _loading = false;
        _loadFailed = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _trips = _homeTrips(
          StaticData.travelerTripsForDisplay(demoMode: false),
        );
        _loading = false;
        if (_trips.isEmpty) {
          _loadFailed = true;
        }
      });
    }
  }

  Future<void> _onMenuSelected(String value, TravelerTrip trip) async {
    final id = trip.displayId;
    if (value == 'view') {
      await openTravelerTripDeliveryDetail(context, trip);
      if (mounted) {
        await reload(silent: true);
      }
      return;
    }
    if (value == 'edit') {
      final updated = await context.push<bool>('/edit-trip/$id');
      if (updated == true && mounted) {
        await reload(silent: true);
      }
      return;
    }
    if (value == 'cancel') {
      await context.push('/cancel-trip/$id');
      if (mounted) {
        await reload(silent: true);
      }
    }
  }

  List<PopupMenuEntry<String>> _menuItems(
    BuildContext context, {
    required bool canEditOrCancel,
  }) {
    final typo = context.typo;
    final l10n = context.l10n;
    final itemStyle = typo.body.copyWith(fontWeight: FontWeight.w400);

    return [
      PopupMenuItem(
        value: 'view',
        height: 42,
        child: Text(l10n.view, style: itemStyle),
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
          child: Text(l10n.edit, style: itemStyle),
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
          child: Text(l10n.cancel, style: itemStyle),
        ),
      ],
    ];
  }

  @override
  Widget build(BuildContext context) {
    final typo = context.typo;

    if (_loading && _trips.isEmpty) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 16),
        child: Center(
          child: SizedBox(
            width: 22,
            height: 22,
            child: CircularProgressIndicator(
              strokeWidth: 2.5,
              color: AppColors.primary,
            ),
          ),
        ),
      );
    }

    if (_trips.isEmpty) {
      return GestureDetector(
        onTap: _loadFailed ? () => reload() : null,
        child: AppCard(
          margin: EdgeInsets.zero,
          child: Text(
            _loadFailed
                ? context.l10n.unableToLoadTrips
                : context.l10n.noTripsYet,
            style: typo.sm.copyWith(color: AppColors.textSecondary, height: 1.4),
          ),
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        for (var i = 0; i < _trips.length; i++) ...[
          if (i > 0) const SizedBox(height: 10),
          _tripCard(_trips[i]),
        ],
      ],
    );
  }

  Widget _tripCard(TravelerTrip trip) {
    return _TripCard(
      trip: trip,
      onMenuSelected: (value) => _onMenuSelected(value, trip),
      menuItems: (ctx) => _menuItems(
        ctx,
        canEditOrCancel: trip.status.canEditOrCancel,
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
    final l10n = context.l10n;
    final localeCode = Localizations.localeOf(context).languageCode;

    return AppCard(
      margin: EdgeInsets.zero,
      onTap: () => openTravelerTripDeliveryDetail(context, trip),
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
                tooltip: l10n.moreOptions,
                onSelected: onMenuSelected,
                itemBuilder: menuItems,
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            DateFormat('MMM d, yyyy', localeCode).format(trip.travelDate),
            style: typo.sm.copyWith(color: AppColors.textSecondary),
          ),
          const SizedBox(height: 4),
          Text(
            l10n.luggageAvailableKg(trip.luggageCapacityKg.toStringAsFixed(0)),
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

class _MyDeliveriesSection extends StatefulWidget {
  const _MyDeliveriesSection({super.key});

  @override
  State<_MyDeliveriesSection> createState() => _MyDeliveriesSectionState();
}

class _MyDeliveriesSectionState extends State<_MyDeliveriesSection> {
  List<CreatedDelivery> _deliveries = const [];
  bool _loading = true;
  bool _loadFailed = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => reload());
  }

  DeliveryRepository _repository() {
    final auth = context.read<AuthProvider>();
    final demoMode = context.read<DemoModeProvider>();
    return DeliveryRepository(
      apiClient: auth.repository.apiClient,
      demoMode: demoMode,
    );
  }

  List<CreatedDelivery> _activeOnly(List<CreatedDelivery> list) {
    return list.where((d) {
      final status = (d.status ?? '').toLowerCase();
      return status != 'delivered' && status != 'cancelled';
    }).toList();
  }

  Future<void> reload({bool silent = false}) async {
    if (!mounted) return;

    if (!silent) {
      setState(() {
        _loading = true;
        _loadFailed = false;
      });
    }

    try {
      final list = await _repository().listDeliveries(role: 'traveler');
      if (!mounted) return;
      setState(() {
        _deliveries = _activeOnly(list);
        _loading = false;
        _loadFailed = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        if (_deliveries.isEmpty) {
          _loadFailed = true;
        }
      });
    }
  }

  Future<void> _openDelivery(CreatedDelivery delivery) async {
    final id = delivery.publicId.isNotEmpty ? delivery.publicId : delivery.id;
    await context.push('/shipment/$id?traveler=true');
    if (mounted) await reload(silent: true);
  }

  String _formatTravelDate(String raw) {
    final parsed = DateTime.tryParse(raw);
    if (parsed == null) return raw.isEmpty ? '—' : raw;
    final localeCode = Localizations.localeOf(context).languageCode;
    return DateFormat('MMM d, yyyy', localeCode).format(parsed);
  }

  @override
  Widget build(BuildContext context) {
    final typo = context.typo;

    if (_loading && _deliveries.isEmpty) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 16),
        child: Center(
          child: SizedBox(
            width: 22,
            height: 22,
            child: CircularProgressIndicator(
              strokeWidth: 2.5,
              color: AppColors.primary,
            ),
          ),
        ),
      );
    }

    if (_deliveries.isEmpty) {
      return GestureDetector(
        onTap: _loadFailed ? () => reload() : null,
        child: AppCard(
          margin: EdgeInsets.zero,
          child: Text(
            _loadFailed
                ? context.l10n.unableToLoadDeliveries
                : context.l10n.noActiveDeliveriesYet,
            style: typo.sm.copyWith(color: AppColors.textSecondary, height: 1.4),
          ),
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        for (var i = 0; i < _deliveries.length; i++) ...[
          if (i > 0) const SizedBox(height: 10),
          _HomeDeliveryCard(
            delivery: _deliveries[i],
            formatTravelDate: _formatTravelDate,
            onTap: () => _openDelivery(_deliveries[i]),
          ),
        ],
      ],
    );
  }
}

class _HomeDeliveryCard extends StatelessWidget {
  const _HomeDeliveryCard({
    required this.delivery,
    required this.formatTravelDate,
    required this.onTap,
  });

  final CreatedDelivery delivery;
  final String Function(String raw) formatTravelDate;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final typo = context.typo;
    final id =
        delivery.publicId.isNotEmpty ? delivery.publicId : delivery.id;

    return AppCard(
      onTap: onTap,
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
      margin: EdgeInsets.zero,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  id,
                  style: typo.h3.copyWith(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              DeliveryStatusBadge(delivery.status, semiBold: true),
            ],
          ),
          const SizedBox(height: 10),
          StackedRouteEndpoints(
            from: delivery.exactDisplayFrom,
            to: delivery.exactDisplayTo,
            fallbackRoute: delivery.exactDisplayRoute,
          ),
          const SizedBox(height: 8),
          Text(
            '${context.l10n.travelDateLabel(formatTravelDate(delivery.travelDate))}'
            '${delivery.senderName != null && delivery.senderName!.isNotEmpty ? ' · ${delivery.senderName}' : ''}',
            style: typo.sm.copyWith(color: AppColors.textSecondary),
          ),
        ],
      ),
    );
  }
}

