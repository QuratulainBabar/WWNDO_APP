import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../core/auth/auth_verification_guard.dart';
import '../../core/auth/kyc_verification_guard.dart';
import '../../core/config/demo_mode.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_typography.dart';
import '../../core/widgets/app_card.dart';
import '../../core/widgets/app_svg_icon.dart';
import '../../core/widgets/back_link.dart';
import '../../core/widgets/screen_body.dart';
import '../../core/widgets/wallet_card.dart';
import '../../data/models/traveler_trip.dart';
import '../../data/models/wallet_role.dart';
import '../../data/services/trip_repository.dart';
import '../../data/static_data.dart';
import '../../providers/auth_provider.dart';
import 'trip_posting_actions.dart';

class TravelerHomeScreen extends StatefulWidget {
  const TravelerHomeScreen({super.key});

  @override
  State<TravelerHomeScreen> createState() => _TravelerHomeScreenState();
}

class _TravelerHomeScreenState extends State<TravelerHomeScreen> {
  String? _lastMatchedLocation;
  final GlobalKey<_MyTripsSectionState> _tripsKey =
      GlobalKey<_MyTripsSectionState>();

  @override
  void initState() {
    super.initState();
    // Keep greeting in sync with `/auth/me` (name/rating from API).
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      context.read<AuthProvider>().refreshUser();
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
      });
    }
    _lastMatchedLocation = location;
  }

  void _onCreateTrip() {
    // Wallet balance gate first — must not be masked by auth/KYC dialogs.
    if (!TripPostingActions.ensureWalletAllowsTripCreation(context)) return;
    if (!AuthVerificationGuard.ensureVerifiedForTransaction(context)) return;
    if (!KycVerificationGuard.ensureKycApproved(context)) return;
    context.push('/trip-type');
  }

  @override
  Widget build(BuildContext context) {
    final typo = context.typo;
    final authUser = context.watch<AuthProvider>().user;
    final firstName = (authUser?.firstName.trim().isNotEmpty ?? false)
        ? authUser!.firstName
        : 'there';
    final rating = authUser?.rating ?? 0;
    final ratingLabel = rating > 0 ? rating.toStringAsFixed(1) : '—';

    return Scaffold(
      backgroundColor: AppColors.background,
      body: ScreenBody(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            BackLink(onTap: () => context.go('/role-selection')),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Flexible(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Hey, $firstName 👋',
                        style: typo.h1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      Text('★ $ratingLabel · Traveler', style: typo.sm),
                    ],
                  ),
                ),
                // Wallet is already wired to live balance — leave unchanged.
                WalletCard(role: WalletRole.traveler),
              ],
            ),
            const SizedBox(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Text('My Trips', style: typo.h3.copyWith(fontWeight: FontWeight.w700)),
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
                          'Create Trip',
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
            Text('Quick actions', style: typo.h3.copyWith(fontWeight: FontWeight.w700)),
            const SizedBox(height: 12),
            Row(
              children: [
                _quickAction(
                  context,
                  AppIcons.roleSender,
                  'Sender Requests',
                  () => context.push('/matching-requests'),
                ),
                const SizedBox(width: 10),
                _quickAction(
                  context,
                  AppIcons.track,
                  'My deliveries',
                  () => context.push('/traveler-deliveries'),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                _quickAction(
                  context,
                  AppIcons.history,
                  'Counter offers',
                  () => context.push('/traveler-bids'),
                ),
                const SizedBox(width: 10),
                const Expanded(child: SizedBox()),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _quickAction(
    BuildContext context,
    String iconAsset,
    String label,
    VoidCallback onTap,
  ) {
    final typo = context.typo;
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          constraints: const BoxConstraints(minHeight: 98),
          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 16),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: AppColors.border),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              AppSvgIcon(asset: iconAsset, size: 28, color: AppColors.primary),
              const SizedBox(height: 10),
              Text(
                label,
                textAlign: TextAlign.center,
                style: typo.actionLabel.copyWith(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textPrimary,
                  height: 1.2,
                ),
                maxLines: 2,
              ),
            ],
          ),
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
  List<TravelerTrip> _trips = const [];
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    StaticData.travelerPostedTripsVersion.addListener(_onTripsChanged);
    WidgetsBinding.instance.addPostFrameCallback((_) => reload());
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

  Future<void> reload({bool silent = false}) async {
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
          _error = 'Unable to load your trips. Tap to retry.';
        }
      });
    }
  }

  Future<void> _onMenuSelected(String value, TravelerTrip trip) async {
    final id = trip.displayId;
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
        onTap: _error != null ? () => reload() : null,
        child: AppCard(
          margin: EdgeInsets.zero,
          child: Text(
            _error ??
                'No trips yet. Tap + Create Trip to post your first route.',
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
          _TripCard(
            trip: _trips[i],
            onMenuSelected: (value) => _onMenuSelected(value, _trips[i]),
            menuItems: _menuItems,
          ),
        ],
      ],
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
                child: GestureDetector(
                  onTap: () => context.push('/traveler-trips'),
                  child: Text(
                    trip.route,
                    style: typo.h3.copyWith(fontWeight: FontWeight.w800),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
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
