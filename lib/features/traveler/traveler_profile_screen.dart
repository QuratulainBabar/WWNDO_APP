import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../core/api/api_exception.dart';
import '../../core/navigation/app_navigation.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_typography.dart';
import '../../core/widgets/app_button.dart';
import '../../core/widgets/app_card.dart';
import '../../core/widgets/app_svg_icon.dart';
import '../../core/widgets/back_link.dart';
import '../../core/widgets/role_switch_card.dart';
import '../../core/widgets/screen_body.dart';
import '../../core/widgets/star_rating_display.dart';
import '../../data/models/profile_trust_metrics.dart';
import '../../data/models/shipment.dart';
import '../../data/models/wallet_role.dart';
import '../../data/static_data.dart';
import '../../data/wallet_service.dart';
import '../../providers/auth_provider.dart';
import '../../providers/wallet_provider.dart';
import '../profile/widgets/profile_header_card.dart';
import '../profile/widgets/profile_trust_indicators.dart';

class TravelerProfileScreen extends StatefulWidget {
  const TravelerProfileScreen({super.key});

  @override
  State<TravelerProfileScreen> createState() => _TravelerProfileScreenState();
}

class _TravelerProfileScreenState extends State<TravelerProfileScreen> {
  bool _loading = true;
  String? _error;
  String? _lastMatchedLocation;

  /// Traveler marketplace stats are not on `/auth/me` yet — show empty values
  /// (not StaticData mocks) until a stats endpoint exists.
  static const _emptyTrustMetrics = ProfileTrustMetrics(
    completedDeliveries: 0,
    cancellationRate: 0,
    disputeRate: 0,
  );

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      _refreshProfile();
      context
          .read<WalletProvider>()
          .refresh(WalletRole.traveler, silent: true)
          .ignore();
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final location = GoRouterState.of(context).matchedLocation;
    if (location == '/traveler-profile' &&
        _lastMatchedLocation != '/traveler-profile') {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        _refreshProfile(silent: !_loading && context.read<AuthProvider>().user != null);
        context
            .read<WalletProvider>()
            .refresh(WalletRole.traveler, silent: true)
            .ignore();
      });
    }
    _lastMatchedLocation = location;
  }

  Future<void> _refreshProfile({bool silent = false}) async {
    if (!silent) {
      setState(() {
        _loading = true;
        _error = null;
      });
    }

    try {
      final user = await context.read<AuthProvider>().refreshUser();
      if (!mounted) return;
      setState(() {
        _loading = false;
        _error = user == null && context.read<AuthProvider>().user == null
            ? 'Unable to load profile. Pull to retry.'
            : null;
      });
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        if (context.read<AuthProvider>().user == null) {
          _error = e.message;
        }
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        if (context.read<AuthProvider>().user == null) {
          _error = 'Unable to load profile. Try again.';
        }
      });
    }
  }

  String _displayOrDash(String? value) {
    final trimmed = value?.trim() ?? '';
    return trimmed.isEmpty ? '—' : trimmed;
  }

  String _countryLabel(String? countryCode) {
    final code = countryCode?.trim() ?? '';
    if (code.isEmpty) return '—';
    final name = StaticData.countryName(code);
    return name.isEmpty ? code : name;
  }

  @override
  Widget build(BuildContext context) {
    final typo = context.typo;
    final authUser = context.watch<AuthProvider>().user;

    if (_loading && authUser == null) {
      return Scaffold(
        backgroundColor: AppColors.background,
        body: ScreenBody(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              BackLink(onTap: () => context.go('/traveler-home')),
              const SizedBox(height: 16),
              Text('Profile', style: typo.h1),
              const SizedBox(height: 48),
              const Center(
                child: CircularProgressIndicator(color: AppColors.primary),
              ),
            ],
          ),
        ),
      );
    }

    if (authUser == null) {
      return Scaffold(
        backgroundColor: AppColors.background,
        body: ScreenBody(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              BackLink(onTap: () => context.go('/traveler-home')),
              const SizedBox(height: 16),
              Text('Profile', style: typo.h1),
              const SizedBox(height: 24),
              Text(
                _error ?? 'Profile unavailable.',
                style: typo.sm.copyWith(color: AppColors.danger, height: 1.4),
              ),
              const SizedBox(height: 16),
              AppButton(
                label: 'Retry',
                onPressed: () => _refreshProfile(),
              ),
            ],
          ),
        ),
      );
    }

    final country = _countryLabel(authUser.countryCode);
    final rating = authUser.rating;
    // Trips / delivery counts require traveler APIs that are not implemented yet.
    const tripsCompleted = '0';
    const parcelsDelivered = '0';
    const totalDeliveries = '0';
    const activeTrips = '0';
    const successfulRate = '—';

    return Scaffold(
      backgroundColor: AppColors.background,
      body: ScreenBody(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            BackLink(onTap: () => context.go('/traveler-home')),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Profile', style: typo.h1),
                GestureDetector(
                  onTap: () async {
                    await context.push('/settings?role=traveler');
                    if (mounted) await _refreshProfile(silent: true);
                  },
                  child: AppSvgIcon(
                    asset: AppIcons.settings,
                    size: 24,
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
            if (_error != null) ...[
              const SizedBox(height: 8),
              Text(
                _error!,
                style: typo.sm.copyWith(color: AppColors.danger),
              ),
            ],
            const SizedBox(height: 16),
            ProfileHeaderCard(
              role: WalletRole.traveler,
              name: _displayOrDash(authUser.name),
              initial: authUser.initial,
              subtitle: 'Traveler',
              memberSince: _displayOrDash(authUser.memberSince),
              bio: authUser.bio.trim().isNotEmpty
                  ? authUser.bio
                  : 'No bio added yet.',
              rating: rating,
              authUser: authUser,
            ),
            const SizedBox(height: 16),
            const RoleSwitchCard(currentRole: ShipmentRole.traveler),
            const SizedBox(height: 16),
            AppCard(
              child: Column(
                children: [
                  _infoRow(context, 'Email', _displayOrDash(authUser.email)),
                  const Divider(height: 24),
                  _infoRow(
                    context,
                    'Phone number',
                    _displayOrDash(authUser.phone),
                  ),
                  const Divider(height: 24),
                  _infoRow(context, 'Country', country),
                  const Divider(height: 24),
                  _infoRow(
                    context,
                    'Rating',
                    '',
                    trailing: StarRatingDisplay(rating: rating),
                  ),
                  const Divider(height: 24),
                  _infoRow(context, 'Total trips completed', tripsCompleted),
                  const Divider(height: 24),
                  _infoRow(context, 'Parcels delivered', parcelsDelivered),
                ],
              ),
            ),
            const SizedBox(height: 16),
            ProfileTrustIndicators(
              metrics: _emptyTrustMetrics,
              authUser: authUser,
            ),
            const SizedBox(height: 16),
            Text(
              'Traveler statistics',
              style: typo.h3.copyWith(fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                _stat(context, totalDeliveries, 'Total deliveries'),
                const SizedBox(width: 10),
                _stat(context, activeTrips, 'Active trips'),
              ],
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                _stat(context, successfulRate, 'Successful delivery rate'),
                const SizedBox(width: 10),
                _stat(
                  context,
                  '',
                  'Average rating',
                  trailing: StarRatingDisplay(
                    rating: rating,
                    showValue: true,
                    size: 12,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(
                  child: ValueListenableBuilder<int>(
                    valueListenable: WalletService.walletVersion,
                    builder: (context, _, __) => _stat(
                      context,
                      WalletService.formatCents(
                        WalletService.availableCents(WalletRole.traveler),
                      ),
                      'Wallet',
                      onTap: () => context.push('/wallet?role=traveler'),
                      expand: false,
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                _stat(
                  context,
                  'History',
                  'Transactions',
                  onTap: () =>
                      context.push('/transaction-history?role=traveler'),
                ),
              ],
            ),
            const SizedBox(height: 16),
            AppButton(
              label: 'Log out',
              variant: AppButtonVariant.danger,
              onPressed: () => logoutToLoginScreen(context),
            ),
          ],
        ),
      ),
    );
  }

  Widget _infoRow(
    BuildContext context,
    String label,
    String value, {
    Widget? trailing,
  }) {
    final typo = context.typo;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(child: Text(label, style: typo.sm)),
        const SizedBox(width: 12),
        Flexible(
          child: trailing ??
              Text(
                value,
                textAlign: TextAlign.end,
                style: typo.bodyBold.copyWith(fontWeight: FontWeight.w700),
              ),
        ),
      ],
    );
  }

  Widget _stat(
    BuildContext context,
    String value,
    String label, {
    VoidCallback? onTap,
    Widget? trailing,
    bool expand = true,
  }) {
    final typo = context.typo;
    final labelStyle = typo.sm;
    final labelHeight =
        (labelStyle.fontSize ?? 15) * (labelStyle.height ?? 1.5) * 2;

    final content = GestureDetector(
      onTap: onTap,
      child: AppCard(
        margin: EdgeInsets.zero,
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 14),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            trailing ??
                Text(
                  value,
                  textAlign: TextAlign.center,
                  style: typo.h2.copyWith(color: AppColors.primary),
                ),
            const SizedBox(height: 4),
            SizedBox(
              height: labelHeight,
              child: Center(
                child: Text(
                  label,
                  textAlign: TextAlign.center,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: labelStyle,
                ),
              ),
            ),
          ],
        ),
      ),
    );
    return expand ? Expanded(child: content) : content;
  }
}
