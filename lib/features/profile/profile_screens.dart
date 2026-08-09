import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../core/platform/keyboard_utils.dart';
import '../../core/api/api_exception.dart';
import '../../core/auth/selected_role.dart';
import '../../core/config/demo_mode.dart';
import '../../core/layout/responsive.dart';
import '../../core/widgets/kyc_status_badge.dart';
import '../../providers/auth_provider.dart';
import '../../providers/wallet_provider.dart';
import '../../core/navigation/app_navigation.dart';
import '../../core/platform/biometric_auth_service.dart';
import '../../core/platform/biometric_prefs.dart';
import '../../core/platform/platform_ui.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_typography.dart';
import '../../core/widgets/app_avatar.dart';
import '../../core/widgets/app_badge.dart';
import '../../core/widgets/app_button.dart';
import '../../core/widgets/app_card.dart';
import '../../core/widgets/app_labeled_field.dart';
import '../../core/widgets/app_svg_icon.dart';
import '../../core/widgets/back_header.dart';
import '../../core/widgets/back_link.dart';
import '../../core/widgets/role_switch_card.dart';
import '../../core/widgets/screen_body.dart';
import '../../data/models/created_delivery.dart';
import '../../data/models/shipment.dart';
import '../../data/models/ledger_entry.dart';
import '../../data/models/profile_trust_metrics.dart';
import '../../data/models/review.dart';
import '../../data/models/wallet_role.dart';
import '../../data/services/delivery_repository.dart';
import '../../data/services/review_repository.dart';
import '../../data/services/trust_metrics_repository.dart';
import '../../core/utils/external_links.dart';
import '../../data/services/wallet_repository.dart';
import '../../data/static_data.dart';
import '../../data/wallet_service.dart';
import 'legal_screens.dart';
import 'settings_flow_screens.dart';
import 'widgets/profile_header_card.dart';
import 'widgets/profile_trust_indicators.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  int? _activeCount;
  int? _completedCount;
  String? _lastMatchedLocation;
  List<Review> _reviews = const [];
  bool _reviewsLoading = true;
  ProfileTrustMetrics _trustMetrics = ProfileTrustMetrics.empty;
  bool _trustMetricsLoading = true;
  bool _openingRoute = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final location = GoRouterState.of(context).matchedLocation;
    if (location == '/profile' && _lastMatchedLocation != '/profile') {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          _loadShipmentCounts(silent: _activeCount != null);
          _loadReviews(silent: !_reviewsLoading && _reviews.isNotEmpty);
          _loadTrustMetrics(silent: !_trustMetricsLoading);
          context.read<WalletProvider>().refresh(
                WalletRole.sender,
                silent: true,
              );
        }
      });
    }
    _lastMatchedLocation = location;
  }

  DeliveryRepository _deliveryRepository() {
    final auth = context.read<AuthProvider>();
    final demoMode = context.read<DemoModeProvider>();
    return DeliveryRepository(
      apiClient: auth.repository.apiClient,
      demoMode: demoMode,
    );
  }

  ReviewRepository _reviewRepository() {
    final auth = context.read<AuthProvider>();
    final demoMode = context.read<DemoModeProvider>();
    return ReviewRepository(
      apiClient: auth.repository.apiClient,
      demoMode: demoMode,
    );
  }

  TrustMetricsRepository _trustMetricsRepository() {
    final auth = context.read<AuthProvider>();
    final demoMode = context.read<DemoModeProvider>();
    return TrustMetricsRepository(
      apiClient: auth.repository.apiClient,
      demoMode: demoMode,
    );
  }

  Future<void> _loadShipmentCounts({bool silent = false}) async {
    try {
      final list = await _deliveryRepository().listDeliveries();
      if (!mounted) return;
      var active = 0;
      var completed = 0;
      for (final d in list) {
        if (_isCompletedDeliveryStatus(d.status)) {
          completed++;
        } else if (_isActiveDeliveryStatus(d.status)) {
          active++;
        }
      }
      setState(() {
        _activeCount = active;
        _completedCount = completed;
      });
    } on ApiException {
      if (!mounted || silent) return;
      setState(() {
        _activeCount ??= 0;
        _completedCount ??= 0;
      });
    } catch (_) {
      if (!mounted || silent) return;
      setState(() {
        _activeCount ??= 0;
        _completedCount ??= 0;
      });
    }
  }

  Future<void> _loadReviews({bool silent = false}) async {
    if (!silent && mounted) {
      setState(() => _reviewsLoading = true);
    }
    try {
      final reviews = await _reviewRepository().listMyReviews(
        WalletRole.sender,
        limit: 10,
      );
      if (!mounted) return;
      setState(() {
        _reviews = reviews;
        _reviewsLoading = false;
      });
    } on ApiException {
      if (!mounted) return;
      setState(() {
        if (!silent) _reviews = const [];
        _reviewsLoading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        if (!silent) _reviews = const [];
        _reviewsLoading = false;
      });
    }
  }

  Future<void> _loadTrustMetrics({bool silent = false}) async {
    if (!silent && mounted) {
      setState(() => _trustMetricsLoading = true);
    }
    try {
      final metrics =
          await _trustMetricsRepository().fetch(WalletRole.sender);
      if (!mounted) return;
      setState(() {
        _trustMetrics = metrics;
        _trustMetricsLoading = false;
      });
    } on ApiException {
      if (!mounted) return;
      setState(() {
        if (!silent) _trustMetrics = ProfileTrustMetrics.empty;
        _trustMetricsLoading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        if (!silent) _trustMetrics = ProfileTrustMetrics.empty;
        _trustMetricsLoading = false;
      });
    }
  }

  Future<void> _openRoute(String location, {VoidCallback? onReturn}) async {
    if (_openingRoute) return;
    _openingRoute = true;
    try {
      await context.push(location);
      if (mounted) onReturn?.call();
    } finally {
      _openingRoute = false;
    }
  }

  @override
  Widget build(BuildContext context) {
    final typo = context.typo;
    final authUser = context.watch<AuthProvider>().user;
    final user = authUser?.toUserProfile() ?? StaticData.currentUser;
    final activeLabel = _activeCount?.toString() ?? '—';
    final completedLabel = _completedCount?.toString() ?? '—';

    return Scaffold(
      backgroundColor: AppColors.background,
      body: ScreenBody(
        keyboardDismiss: false,
        child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              BackLink(onTap: () => context.go('/home')),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('Profile', style: typo.h1),
                  GestureDetector(
                    behavior: HitTestBehavior.opaque,
                    onTap: () => _openRoute('/settings?role=sender'),
                    child: AppSvgIcon(
                      asset: AppIcons.settings,
                      size: 24,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              ProfileHeaderCard(
                role: WalletRole.sender,
                name: user.name,
                initial: user.initial,
                subtitle: switch (SelectedRoleStore.roleFromUser(authUser)) {
                  WalletRole.traveler => 'Traveler',
                  WalletRole.receiver => 'Receiver',
                  _ => 'Sender',
                },
                memberSince: user.memberSince,
                bio: user.bio,
                rating: user.rating,
                authUser: authUser,
              ),
              IntrinsicHeight(
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _stat(
                      context,
                      activeLabel,
                      'Active Shipments',
                      onTap: () => _openRoute(
                        '/my-posted-parcels',
                        onReturn: () => _loadShipmentCounts(silent: true),
                      ),
                    ),
                    const SizedBox(width: 10),
                    _stat(
                      context,
                      completedLabel,
                      'Completed Shipments',
                      onTap: () => _openRoute(
                        '/shipment-history',
                        onReturn: () => _loadShipmentCounts(silent: true),
                      ),
                    ),
                  ],
                ),
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
                          WalletService.availableCents(WalletRole.sender),
                        ),
                        'Wallet',
                        onTap: () => _openRoute('/wallet?role=sender'),
                        expand: false,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              ProfileTrustIndicators(
                metrics: _trustMetrics,
                authUser: authUser,
                loading: _trustMetricsLoading,
              ),
              const SizedBox(height: 16),
              const RoleSwitchCard(currentRole: ShipmentRole.sender),
              const SizedBox(height: 16),
              Text('Quick actions', style: typo.h3.copyWith(fontWeight: FontWeight.w700)),
              const SizedBox(height: 12),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _quickAction(context, AppIcons.track, 'My Shipments', () => context.go('/track')),
                  const SizedBox(width: 10),
                  _quickAction(
                    context,
                    AppIcons.history,
                    'Shipment History',
                    () => _openRoute(
                      '/shipment-history',
                      onReturn: () => _loadShipmentCounts(silent: true),
                    ),
                  ),
                  const SizedBox(width: 10),
                  _quickAction(
                    context,
                    AppIcons.browse,
                    'Transaction History',
                    () => _openRoute('/transaction-history?role=sender'),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Text('Recent reviews', style: typo.h3.copyWith(fontWeight: FontWeight.w700)),
              const SizedBox(height: 10),
              if (_reviewsLoading && _reviews.isEmpty)
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 12),
                  child: Center(
                    child: SizedBox(
                      width: 24,
                      height: 24,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    ),
                  ),
                )
              else if (_reviews.isEmpty)
                AppCard(
                  child: Text(
                    'No reviews yet.',
                    style: typo.sm.copyWith(color: AppColors.textSecondary),
                  ),
                )
              else
                ..._reviews.map((r) => AppCard(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              AppAvatar(initial: r.initial, size: AvatarSize.small),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  r.reviewerName,
                                  style: typo.sm.copyWith(fontWeight: FontWeight.w700),
                                ),
                              ),
                              Text(
                                '${'★' * r.rating}${'☆' * (5 - r.rating)}',
                                style: typo.starRating,
                              ),
                            ],
                          ),
                          const SizedBox(height: 6),
                          Text('"${r.text}"', style: typo.reviewText),
                          const SizedBox(height: 4),
                          Text(r.date, style: typo.sm),
                        ],
                      ),
                    )),
              const SizedBox(height: 8),
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

  Widget _stat(
    BuildContext context,
    String value,
    String label, {
    VoidCallback? onTap,
    bool expand = true,
  }) {
    final typo = context.typo;
    final card = AppCard(
      margin: EdgeInsets.zero,
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 14),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Text(
            value,
            textAlign: TextAlign.center,
            style: typo.h2.copyWith(
              color: AppColors.primary,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            textAlign: TextAlign.center,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: typo.sm,
          ),
        ],
      ),
    );

    final Widget content = onTap == null
        ? card
        : Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: onTap,
              borderRadius: BorderRadius.circular(16),
              child: card,
            ),
          );

    return expand ? Expanded(child: content) : content;
  }

  Widget _quickAction(BuildContext context, String iconAsset, String label, VoidCallback onTap) {
    final typo = context.typo;
    final labelStyle = typo.actionLabel.copyWith(
      fontSize: 13,
      fontWeight: FontWeight.w600,
      color: AppColors.textPrimary,
      height: 1.25,
    );
    return Expanded(
      child: Material(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(14),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(14),
          child: Ink(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: AppColors.border),
            ),
            child: Container(
              constraints: const BoxConstraints(minHeight: 98),
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 14),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  AppSvgIcon(asset: iconAsset, size: 28),
                  const SizedBox(height: 8),
                  Text(
                    label,
                    textAlign: TextAlign.center,
                    style: labelStyle,
                    maxLines: 2,
                    softWrap: true,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

bool _isActiveDeliveryStatus(String? status) {
  switch (status?.trim().toLowerCase()) {
    case 'posted':
    case 'matched':
    case 'in_transit':
      return true;
    default:
      return false;
  }
}

bool _isCompletedDeliveryStatus(String? status) {
  switch (status?.trim().toLowerCase()) {
    case 'delivered':
    case 'cancelled':
    case 'canceled':
    case 'completed':
      return true;
    default:
      return false;
  }
}

class ShipmentHistoryScreen extends StatefulWidget {
  const ShipmentHistoryScreen({super.key});

  @override
  State<ShipmentHistoryScreen> createState() => _ShipmentHistoryScreenState();
}

class _ShipmentHistoryScreenState extends State<ShipmentHistoryScreen> {
  bool _loading = true;
  String? _error;
  List<CreatedDelivery>? _deliveries;

  List<CreatedDelivery> get _items => _deliveries ?? const <CreatedDelivery>[];

  @override
  void initState() {
    super.initState();
    _deliveries = const [];
    WidgetsBinding.instance.addPostFrameCallback((_) => _load());
  }

  DeliveryRepository _repository() {
    final auth = context.read<AuthProvider>();
    final demoMode = context.read<DemoModeProvider>();
    return DeliveryRepository(
      apiClient: auth.repository.apiClient,
      demoMode: demoMode,
    );
  }

  Future<void> _load({bool silent = false}) async {
    if (!silent) {
      setState(() {
        _loading = true;
        _error = null;
      });
    }
    try {
      final list = await _repository().listDeliveries();
      if (!mounted) return;
      setState(() {
        _deliveries = list
            .where((d) => _isCompletedDeliveryStatus(d.status))
            .toList();
        _loading = false;
        _error = null;
      });
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _error = e.message;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _error = 'Unable to load shipment history.';
      });
    }
  }

  String _formatTravelDate(String raw) {
    final parsed = DateTime.tryParse(raw);
    if (parsed == null) return raw.isEmpty ? '—' : raw;
    return DateFormat('MMM d, yyyy').format(parsed);
  }

  String _statusLabel(String? status) {
    switch (status?.trim().toLowerCase()) {
      case 'delivered':
      case 'completed':
        return 'Delivered';
      case 'cancelled':
      case 'canceled':
        return 'Cancelled';
      default:
        return 'Completed';
    }
  }

  Color _statusColor(String? status) {
    switch (status?.trim().toLowerCase()) {
      case 'cancelled':
      case 'canceled':
        return AppColors.danger;
      default:
        return AppColors.success;
    }
  }

  @override
  Widget build(BuildContext context) {
    final typo = context.typo;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: const BackHeader(
        title: 'Shipment History',
        fallbackRoute: '/profile',
      ),
      body: SafeArea(
        child: RefreshIndicator(
          color: AppColors.primary,
          onRefresh: () => _load(silent: true),
          child: ListView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: context.pagePadding.copyWith(top: 16),
            children: [
              Text(
                'Completed city-to-city and country-to-country deliveries.',
                style: typo.sm,
              ),
              const SizedBox(height: 16),
              if (_loading && _items.isEmpty)
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 40),
                  child: Center(
                    child: CircularProgressIndicator(color: AppColors.primary),
                  ),
                )
              else if (_error != null && _items.isEmpty)
                Column(
                  children: [
                    Text(
                      _error!,
                      style: typo.sm.copyWith(color: AppColors.textSecondary),
                    ),
                    TextButton(
                      onPressed: () => _load(),
                      child: const Text('Retry'),
                    ),
                  ],
                )
              else if (_items.isEmpty)
                Text(
                  'No completed shipments yet.',
                  style: typo.sm.copyWith(color: AppColors.textSecondary),
                )
              else
                ..._items.map((s) {
                  final idLabel =
                      s.publicId.isNotEmpty ? s.publicId : s.id;
                  final color = _statusColor(s.status);
                  return AppCard(
                    margin: const EdgeInsets.only(bottom: 14),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 18,
                      vertical: 16,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Flexible(
                              child: Text(
                                idLabel,
                                style: typo.h3.copyWith(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w700,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            const SizedBox(width: 8),
                            AppBadge(
                              label: _statusLabel(s.status),
                              color: color,
                              backgroundColor: color.withValues(alpha: 0.12),
                              semiBold: true,
                              wide: true,
                            ),
                          ],
                        ),
                        const SizedBox(height: 10),
                        Text(
                          s.route.isNotEmpty ? s.route : '—',
                          style: typo.sm.copyWith(color: AppColors.textPrimary),
                        ),
                        const SizedBox(height: 12),
                        Text(
                          _formatTravelDate(s.travelDate),
                          style: typo.sm,
                        ),
                      ],
                    ),
                  );
                }),
            ],
          ),
        ),
      ),
    );
  }
}

class TransactionHistoryScreen extends StatefulWidget {
  const TransactionHistoryScreen({super.key});

  @override
  State<TransactionHistoryScreen> createState() =>
      _TransactionHistoryScreenState();
}

class _TransactionHistoryScreenState extends State<TransactionHistoryScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final role = WalletRole.fromQuery(
        GoRouterState.of(context).uri.queryParameters['role'],
      );
      context
          .read<WalletProvider>()
          .refresh(role, includeFullHistory: true)
          .ignore();
    });
  }

  @override
  Widget build(BuildContext context) {
    final typo = context.typo;
    final role = WalletRole.fromQuery(
      GoRouterState.of(context).uri.queryParameters['role'],
    );
    final fallback = switch (role) {
      WalletRole.receiver => '/settings?role=receiver',
      WalletRole.traveler => '/settings?role=traveler',
      WalletRole.sender => '/profile',
    };

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: BackHeader(title: 'Transaction History', fallbackRoute: fallback),
      body: Consumer<WalletProvider>(
        builder: (context, wallet, _) {
          return ValueListenableBuilder<int>(
            valueListenable: WalletService.walletVersion,
            builder: (context, _, __) {
              final entries = wallet.historyFor(role);

              if (wallet.loading && entries.isEmpty) {
                return const Center(child: CircularProgressIndicator());
              }

              return ScreenBody(
                padding: context.pagePadding.copyWith(top: 16, bottom: 0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Immutable ledger · cents-precision transaction log for ${role.name}.',
                      style: typo.sm,
                    ),
                    const SizedBox(height: 16),
                    if (entries.isEmpty)
                      Text(
                        'No transactions yet.',
                        style: typo.sm,
                      )
                    else
                      ...entries.map((e) => _ledgerTile(context, e)),
                  ],
                ),
              );
            },
          );
        },
      ),
    );
  }

  Widget _ledgerTile(BuildContext context, LedgerEntry entry) {
    final typo = context.typo;
    final availableDelta = entry.availableDeltaCents;
    final escrowDelta = entry.escrowDeltaCents;
    final isCredit = availableDelta > 0 || escrowDelta > 0;
    final amountLabel = availableDelta != 0
        ? '${availableDelta > 0 ? '+' : '−'}${WalletService.formatCents(availableDelta.abs())}'
        : escrowDelta != 0
            ? 'Escrow ${escrowDelta > 0 ? '+' : '−'}${WalletService.formatCents(escrowDelta.abs())}'
            : WalletService.formatCents(entry.amountCents);

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  amountLabel,
                  style: typo.bodyBold.copyWith(
                    fontWeight: FontWeight.w700,
                    color: isCredit ? AppColors.success : AppColors.danger,
                  ),
                ),
                Text(entry.description, style: typo.sm),
                Text(
                  entry.type.name,
                  style: typo.sm.copyWith(color: AppColors.textSecondary),
                ),
              ],
            ),
          ),
          Text(
            DateFormat('MMM d').format(entry.createdAt),
            style: typo.sm,
          ),
        ],
      ),
    );
  }
}

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  bool _pushNotifications = true;
  bool _emailNotifications = true;
  bool _biometricEnabled = false;
  bool _biometricBusy = false;
  bool _connectLoading = false;
  String? _connectStatusLabel;

  @override
  void initState() {
    super.initState();
    _loadBiometricPreference();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final roleParam = GoRouterState.of(context).uri.queryParameters['role'];
      final role = WalletRole.fromQuery(roleParam);
      context.read<WalletProvider>().refresh(role, silent: true).ignore();
      if (role != WalletRole.sender) {
        _loadConnectStatus();
      }
    });
  }

  WalletRepository _walletRepository() {
    final auth = context.read<AuthProvider>();
    return WalletRepository(apiClient: auth.repository.apiClient);
  }

  Future<void> _loadConnectStatus() async {
    try {
      final status = await _walletRepository().fetchConnectStatus();
      if (!mounted) return;
      final linked = status['linked'] == true;
      final ready = status['ready'] == true;
      setState(() {
        _connectStatusLabel = !linked
            ? 'Not linked'
            : ready
                ? 'Ready for payouts'
                : 'Complete onboarding';
      });
    } catch (_) {
      if (!mounted) return;
      setState(() => _connectStatusLabel = null);
    }
  }

  Future<void> _linkStripeConnect() async {
    setState(() => _connectLoading = true);
    try {
      final result = await _walletRepository().startConnectOnboarding();
      final url = result['onboardingUrl'] as String?;
      if (url == null || url.isEmpty) {
        throw Exception('No onboarding URL returned');
      }
      final opened = await ExternalLinks.openUrl(url);
      if (!mounted) return;
      if (!opened) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Could not open Stripe Connect onboarding.')),
        );
      } else {
        await _loadConnectStatus();
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Stripe Connect: ${e.toString()}')),
      );
    } finally {
      if (mounted) setState(() => _connectLoading = false);
    }
  }

  Future<void> _loadBiometricPreference() async {
    final enabled = await BiometricPrefs.isLoginEnabled();
    if (!mounted) return;
    setState(() => _biometricEnabled = enabled);
  }

  Future<void> _onBiometricToggled(bool enabled) async {
    if (_biometricBusy) return;

    if (!enabled) {
      setState(() {
        _biometricBusy = true;
        _biometricEnabled = false;
      });
      await BiometricPrefs.setLoginEnabled(false);
      if (!mounted) return;
      setState(() => _biometricBusy = false);
      return;
    }

    setState(() => _biometricBusy = true);

    final result = await BiometricAuthService.authenticate(
      reason: PlatformUi.biometricSetupReason,
    );

    if (!mounted) return;

    if (result.isSuccess) {
      await BiometricPrefs.setLoginEnabled(true);
      if (!mounted) return;
      setState(() {
        _biometricEnabled = true;
        _biometricBusy = false;
      });
      return;
    }

    setState(() {
      _biometricEnabled = false;
      _biometricBusy = false;
    });

    if (result.status == BiometricAuthStatus.cancelled) return;

    final message = result.message ??
        'Could not enable ${PlatformUi.biometricShortLabel}. Please try again.';
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
  }

  String _routeWithRole(String baseRoute, String? roleParam) {
    if (roleParam == null || roleParam.isEmpty) return baseRoute;
    return '$baseRoute?role=$roleParam';
  }

  @override
  Widget build(BuildContext context) {
    final roleParam = GoRouterState.of(context).uri.queryParameters['role'];
    final isReceiver = roleParam == 'receiver';
    final isTraveler = roleParam == 'traveler';
    final isSender = roleParam == 'sender' || roleParam == null;
    final user = isReceiver
        ? StaticData.receiverUser
        : isTraveler
            ? StaticData.travelerUser
            : StaticData.currentUser;
    final editProfileRole = isReceiver
        ? EditProfileRole.receiver
        : isTraveler
            ? EditProfileRole.traveler
            : EditProfileRole.sender;
    // Demo app mode toggle commented out — live API only.
    // final demoMode = context.watch<DemoModeProvider>();
    final authUser = context.watch<AuthProvider>().user;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: BackHeader(
        title: 'Settings',
        fallbackRoute: isReceiver
            ? '/receiver-profile'
            : isTraveler
                ? '/traveler-profile'
                : isSender
                    ? '/profile'
                    : null,
      ),
      body: ScreenBody(
        padding: context.pagePadding.copyWith(top: 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Demo app mode option — commented out.
            // _sectionLabel('Developer'),
            // _settingsGroup([
            //   _toggle(
            //     'Demo app mode',
            //     demoMode.enabled,
            //     demoMode.setEnabled,
            //     subtitle: demoMode.enabled
            //         ? 'Offline static data — no backend'
            //         : 'Live API — backend required',
            //   ),
            // ]),
            if (authUser != null && !authUser.isFullyCrossVerified) ...[
              _sectionLabel('Account verification'),
              AppCard(
                margin: const EdgeInsets.only(bottom: 16),
                child: ListTile(
                  contentPadding: EdgeInsets.zero,
                  title: Text('Verify email & phone', style: context.typo.bodyBold),
                  subtitle: Text(
                    'Required before posting, bidding, or paying on WWNGO.',
                    style: context.typo.sm,
                  ),
                  trailing: const Icon(Icons.chevron_right_rounded),
                  onTap: () => context.push('/verify-account'),
                ),
              ),
            ],
            _sectionLabel('Profile'),
            _settingsGroup([
              _tile(
                'Edit profile',
                onTap: () => context.push('/edit-profile', extra: editProfileRole),
              ),
            ]),
            _sectionLabel('Wallet & Payments'),
            _settingsGroup([
              SizedBox(
                width: double.infinity,
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: ValueListenableBuilder<int>(
                    valueListenable: WalletService.walletVersion,
                    builder: (context, _, __) {
                      final role = WalletRole.fromQuery(roleParam);
                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Available balance', style: context.typo.sm),
                          Text(
                            WalletService.formatCents(
                              WalletService.availableCents(role),
                            ),
                            style: context.typo.priceLarge,
                          ),
                          const SizedBox(height: 8),
                          Text('Escrow balance', style: context.typo.sm),
                          Text(
                            WalletService.formatCents(
                              WalletService.escrowCents(role),
                            ),
                            style: context.typo.bodyBold.copyWith(
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ],
                      );
                    },
                  ),
                ),
              ),
              _tile(
                'Top up via Stripe',
                onTap: () {
                  FocusManager.instance.primaryFocus?.unfocus();
                  context.push(
                    _routeWithRole('/wallet/top-up', roleParam),
                  );
                },
              ),
              if (WalletRole.fromQuery(roleParam) != WalletRole.sender)
                _tile(
                  _connectLoading ? 'Linking Stripe Connect…' : 'Link Stripe Connect',
                  subtitle: _connectStatusLabel ?? 'Required for bank withdrawals',
                  onTap: _connectLoading ? () {} : _linkStripeConnect,
                ),
              if (WalletRole.fromQuery(roleParam) != WalletRole.sender)
                _tile(
                  'Withdraw via Stripe Connect',
                  onTap: () => context.push(_routeWithRole('/wallet', roleParam)),
                ),
              _tile(
                'Transaction history',
                onTap: () => context.push(
                  _routeWithRole('/transaction-history', roleParam),
                ),
              ),
            ]),
            _sectionLabel('Security'),
            _settingsGroup([
              _tile(
                'Change password',
                onTap: () => context.push(_routeWithRole('/change-password', roleParam)),
              ),
              _tile(
                'Identity verification',
                onTap: () => context.push(_routeWithRole('/kyc-status', roleParam)),
                trailing: KycStatusBadge(user: authUser),
              ),
              _tile(
                'Email & phone',
                subtitle: authUser == null
                    ? 'Link your contacts'
                    : authUser.isFullyCrossVerified
                        ? '${authUser.email} · ${authUser.phone}'
                        : 'Finish linking email and phone',
                onTap: () => context.push('/verify-account'),
              ),
              _tile(
                'Security logs',
                onTap: () => context.push(_routeWithRole('/security-logs', roleParam)),
              ),
              _toggle(
                '${PlatformUi.biometricShortLabel} login',
                _biometricEnabled,
                kIsWeb || _biometricBusy ? null : _onBiometricToggled,
                subtitle: kIsWeb
                    ? 'Not available in the browser'
                    : 'Sign in faster with ${PlatformUi.biometricShortLabel}',
              ),
            ]),
            _sectionLabel('Notifications'),
            _settingsGroup([
              _toggle('Push notifications', _pushNotifications, (v) => setState(() => _pushNotifications = v)),
              _toggle('Email notifications', _emailNotifications, (v) => setState(() => _emailNotifications = v)),
            ]),
            _sectionLabel('Help & legal'),
            _settingsGroup([
              _tile(
                'Help & support',
                subtitle: 'FAQ, safety, contact',
                onTap: () => context.push(_routeWithRole('/help', roleParam)),
              ),
              _tile(
                'Legal & policies',
                subtitle: 'Privacy, terms, cookies',
                onTap: () => context.push(_routeWithRole('/legal', roleParam)),
              ),
            ]),
            _sectionLabel('Account'),
            AppButton(
              label: 'Sign out',
              variant: AppButtonVariant.outline,
              onPressed: () async {
                await context.read<AuthProvider>().logout();
                if (context.mounted) context.go('/welcome');
              },
            ),
            const SizedBox(height: 12),
            AppButton(
              label: 'Delete account',
              variant: AppButtonVariant.danger,
              onPressed: () => context.go('/account-suspended'),
            ),
            const SizedBox(height: 24),
            Center(
              child: Text(
                'WWNGO v1.0.0',
                style: context.typo.caption.copyWith(color: AppColors.textSecondary),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _sectionLabel(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(
        text.toUpperCase(),
        style: context.typo.sm.copyWith(
          fontSize: 12,
          fontWeight: FontWeight.w600,
          letterSpacing: 0.5,
        ),
      ),
    );
  }

  Widget _settingsGroup(List<Widget> children) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      clipBehavior: Clip.antiAlias,
      child: Material(
        color: AppColors.surface,
        child: Column(
          children: [
            for (var i = 0; i < children.length; i++) ...[
              children[i],
              if (i < children.length - 1) const Divider(height: 1),
            ],
          ],
        ),
      ),
    );
  }

  Widget _tile(String title, {required VoidCallback onTap, Widget? trailing, String? subtitle}) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title),
                  if (subtitle != null) ...[
                    const SizedBox(height: 4),
                    Text(
                      subtitle,
                      style: context.typo.sm.copyWith(color: AppColors.textSecondary),
                    ),
                  ],
                ],
              ),
            ),
            trailing ??
                Icon(
                  Icons.chevron_right_rounded,
                  size: 22,
                  color: AppColors.textSecondary,
                ),
          ],
        ),
      ),
    );
  }

  Widget _toggle(
    String title,
    bool value,
    ValueChanged<bool>? onChanged, {
    String? subtitle,
  }) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title),
                if (subtitle != null) ...[
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: context.typo.sm.copyWith(color: AppColors.textSecondary),
                  ),
                ],
              ],
            ),
          ),
          Switch(
            value: value,
            onChanged: onChanged,
          ),
        ],
      ),
    );
  }
}

class WalletScreen extends StatefulWidget {
  const WalletScreen({super.key});

  @override
  State<WalletScreen> createState() => _WalletScreenState();
}

class _WalletScreenState extends State<WalletScreen> {
  final _amountController = TextEditingController(text: '50.00');
  String? _error;
  bool _withdrawing = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final role = WalletRole.fromQuery(
        GoRouterState.of(context).uri.queryParameters['role'],
      );
      context
          .read<WalletProvider>()
          .refresh(role, includeFullHistory: true)
          .ignore();
    });
  }

  @override
  void dispose() {
    _amountController.dispose();
    super.dispose();
  }

  String _routeWithRole(String baseRoute, WalletRole role) =>
      '$baseRoute?role=${role.queryParam}';

  Future<void> _withdraw(WalletRole role, double parsedAmount) async {
    final cents = (parsedAmount * 100).round();
    final validation = WalletService.validateWithdrawal(role, cents);
    if (validation != null) {
      setState(() => _error = validation);
      return;
    }

    setState(() {
      _withdrawing = true;
      _error = null;
    });
    try {
      await context.read<WalletProvider>().withdraw(
            role: role,
            amountCents: cents,
          );
      if (!mounted) return;
      context.push(
        _routeWithRole('/wallet/withdrawal-success', role),
        extra: parsedAmount,
      );
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() => _error = e.message);
    } catch (_) {
      if (!mounted) return;
      setState(() => _error = 'Withdrawal failed. Please try again.');
    } finally {
      if (mounted) setState(() => _withdrawing = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final role = WalletRole.fromQuery(
      GoRouterState.of(context).uri.queryParameters['role'],
    );
    final walletFallback = switch (role) {
      WalletRole.receiver => '/settings?role=receiver',
      WalletRole.traveler => '/settings?role=traveler',
      WalletRole.sender => '/settings?role=sender',
    };
    final typo = context.typo;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: BackHeader(
        title: 'Wallet',
        fallbackRoute: walletFallback,
      ),
      body: Consumer<WalletProvider>(
        builder: (context, wallet, _) {
          return ValueListenableBuilder<int>(
            valueListenable: WalletService.walletVersion,
            builder: (context, _, __) {
              final available = WalletService.availableCents(role);
              final escrow = WalletService.escrowCents(role);
              final entries = wallet.historyFor(role);
              final parsedAmount = double.tryParse(_amountController.text) ?? 0;
              final displayAmount = parsedAmount > 0 ? parsedAmount : 50.0;
              final canWithdraw = role != WalletRole.sender;
              final minWithdraw = wallet.summary?.minimumWithdrawalCents ??
                  WalletService.minimumWithdrawalCents;

              if (wallet.loading && wallet.summary == null) {
                return const Center(child: CircularProgressIndicator());
              }

              return ScreenBody(
                padding: EdgeInsets.all(context.horizontalPadding + 4),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(28),
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [AppColors.primary, AppColors.primaryDark],
                        ),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Column(
                        children: [
                          Text('Available balance', style: typo.captionOnDarkSoft),
                          Text(
                            WalletService.formatCents(available),
                            style: typo.priceHeroDark,
                          ),
                          const SizedBox(height: 12),
                          Text('Escrow balance', style: typo.captionOnDarkSoft),
                          Text(
                            WalletService.formatCents(escrow),
                            style: typo.h2.copyWith(color: Colors.white),
                          ),
                          if (canWithdraw) ...[
                            const SizedBox(height: 8),
                            Text(
                              'Minimum withdrawal: ${WalletService.formatCents(minWithdraw)}',
                              style: typo.captionOnDark,
                            ),
                          ],
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          child: AppButton(
                            label: 'Top up (Stripe)',
                            small: true,
                            onPressed: () {
                              // Unfocus first so MIUI phantom insets don't
                              // block the next screen's layout / Pay CTA.
                              FocusManager.instance.primaryFocus?.unfocus();
                              context.push(
                                _routeWithRole('/wallet/top-up', role),
                              );
                            },
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: AppButton(
                            label: 'History',
                            variant: AppButtonVariant.outline,
                            small: true,
                            onPressed: () => context.push(
                              _routeWithRole('/transaction-history', role),
                            ),
                          ),
                        ),
                      ],
                    ),
                    if (canWithdraw) ...[
                      const SizedBox(height: 24),
                      Text(
                        'Withdraw via Stripe Connect',
                        style: typo.h3.copyWith(fontWeight: FontWeight.w700),
                      ),
                      const SizedBox(height: 8),
                      AppLabeledField(
                        label: 'Amount (USD)',
                        labelStyle:
                            typo.inputLabel.copyWith(fontWeight: FontWeight.w600),
                        padding: const EdgeInsets.only(top: AppFieldSpacing.top),
                        child: TextField(
                          controller: _amountController,
                          onTap: ensureSoftKeyboardVisible,
                          onTapOutside: dismissKeyboardOnTapOutside,
                          keyboardType: const TextInputType.numberWithOptions(
                            decimal: true,
                          ),
                          style: typo.amountInput
                              .copyWith(fontWeight: FontWeight.w700),
                          onChanged: (_) {
                            setState(() {
                              if (_error != null) _error = null;
                            });
                          },
                        ),
                      ),
                      if (_error != null) ...[
                        const SizedBox(height: 8),
                        Text(
                          _error!,
                          style: typo.sm.copyWith(color: AppColors.danger),
                        ),
                      ],
                      const SizedBox(height: 12),
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: AppColors.primary.withValues(alpha: 0.06),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Column(
                          children: [
                            _SummaryRow(
                              label: "You'll receive",
                              value: '\$${displayAmount.toStringAsFixed(2)}',
                            ),
                            const _SummaryRow(
                              label: 'Payout rail',
                              value: 'Stripe Connect',
                            ),
                            const _SummaryRow(
                              label: 'Arrives in',
                              value: '2–5 business days',
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 20),
                      AppButton(
                        label: _withdrawing ? 'Withdrawing…' : 'Withdraw to bank',
                        textStyle:
                            typo.button.copyWith(fontWeight: FontWeight.w700),
                        onPressed: _withdrawing
                            ? null
                            : () => _withdraw(role, parsedAmount),
                      ),
                      const SizedBox(height: 20),
                      Text(
                        'Recent transactions',
                        style: typo.h3.copyWith(fontWeight: FontWeight.w700),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Immutable ledger (cents precision)',
                        style: typo.sm.copyWith(color: AppColors.textSecondary),
                      ),
                      const SizedBox(height: 10),
                      if (entries.isEmpty)
                        Text('No transactions yet.', style: typo.sm)
                      else
                        ...entries.take(6).map((e) => _ledgerTile(context, e)),
                    ],
                  ],
                ),
              );
            },
          );
        },
      ),
    );
  }

  Widget _ledgerTile(BuildContext context, LedgerEntry entry) {
    final typo = context.typo;
    final delta = entry.availableDeltaCents != 0
        ? entry.availableDeltaCents
        : entry.escrowDeltaCents;
    final isCredit = delta > 0;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${isCredit ? '+' : '−'}${WalletService.formatCents(delta.abs())}',
                  style: typo.bodyBold.copyWith(
                    fontWeight: FontWeight.w700,
                    color: isCredit ? AppColors.success : AppColors.danger,
                  ),
                ),
                Text(entry.description, style: typo.sm),
              ],
            ),
          ),
          Text(DateFormat('MMM d').format(entry.createdAt), style: typo.sm),
        ],
      ),
    );
  }
}

class _SummaryRow extends StatelessWidget {
  const _SummaryRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final typo = context.typo;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: typo.sm),
          Text(value, style: typo.bodyBold.copyWith(fontWeight: FontWeight.w700)),
        ],
      ),
    );
  }
}
