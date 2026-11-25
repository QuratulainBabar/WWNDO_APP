import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../core/api/api_exception.dart';
import '../../core/auth/selected_role.dart';
import '../../core/config/demo_mode.dart';
import '../../core/currency/fx_rate_service.dart';
import '../../core/layout/responsive.dart';
import '../../core/navigation/app_navigation.dart';
import '../../core/payments/stripe_connect_return.dart';
import '../../core/platform/biometric_auth_service.dart';
import '../../core/platform/biometric_prefs.dart';
import '../../core/platform/keyboard_utils.dart';
import '../../core/platform/platform_ui.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_typography.dart';
import '../../core/utils/external_links.dart';
import '../../core/widgets/app_badge.dart';
import '../../core/widgets/app_button.dart';
import '../../core/widgets/app_card.dart';
import '../../core/widgets/app_labeled_field.dart';
import '../../core/widgets/app_svg_icon.dart';
import '../../core/widgets/app_toast.dart';
import '../../core/widgets/back_header.dart';
import '../../core/widgets/back_link.dart';
import '../../core/widgets/kyc_status_badge.dart';
import '../../core/widgets/role_switch_card.dart';
import '../../core/widgets/screen_body.dart';
import '../../core/widgets/stacked_route_endpoints.dart';
import '../../data/models/created_delivery.dart';
import '../../data/models/ledger_entry.dart';
import '../../data/models/profile_trust_metrics.dart';
import '../../data/models/shipment.dart';
import '../../data/models/wallet_role.dart';
import '../../data/services/delivery_repository.dart';
import '../../data/services/trust_metrics_repository.dart';
import '../../data/services/wallet_repository.dart';
import '../../data/static_data.dart';
import '../../data/wallet_service.dart';
import '../../l10n/app_localizations.dart';
import '../../providers/auth_provider.dart';
import '../../providers/currency_provider.dart';
import '../../providers/locale_provider.dart';
import '../../providers/theme_provider.dart';
import '../../providers/wallet_provider.dart';
import 'settings_flow_screens.dart';
import 'widgets/profile_header_card.dart';
import 'widgets/profile_trust_indicators.dart';
import 'widgets/recent_reviews_section.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  int? _activeCount;
  int? _completedCount;
  String? _lastMatchedLocation;
  ProfileTrustMetrics _trustMetrics = ProfileTrustMetrics.empty;
  bool _trustMetricsLoading = true;
  bool _openingRoute = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final location = GoRouterState.of(context).matchedLocation;
    if (location == '/profile' && _lastMatchedLocation != '/profile') {
      // Clear in case a prior push never completed (e.g. locale rebuild).
      _openingRoute = false;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          _loadShipmentCounts(silent: _activeCount != null);
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
      final list = await _deliveryRepository().listDeliveries(role: 'sender');
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

  Future<void> _loadTrustMetrics({bool silent = false}) async {
    if (!silent && mounted) {
      setState(() => _trustMetricsLoading = true);
    }
    try {
      final metrics = await _trustMetricsRepository().fetch(WalletRole.sender);
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
                Text(context.l10n.profile, style: typo.h1),
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
              subtitle: context.tr(switch (SelectedRoleStore.roleFromUser(
                authUser,
              )) {
                WalletRole.traveler => 'Traveler',
                WalletRole.receiver => 'Receiver',
                _ => 'Sender',
              }),
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
                    context.l10n.activeShipments,
                    onTap: () => _openRoute(
                      '/my-posted-parcels',
                      onReturn: () => _loadShipmentCounts(silent: true),
                    ),
                  ),
                  const SizedBox(width: 10),
                  _stat(
                    context,
                    completedLabel,
                    context.l10n.completedShipments,
                    onTap: () => _openRoute(
                      '/shipment-history?role=sender',
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
                    builder: (context, _, _) => _stat(
                      context,
                      WalletService.formatCents(
                        WalletService.availableCents(WalletRole.sender),
                      ),
                      context.l10n.wallet,
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
            Text(
              context.l10n.quickActions,
              style: typo.h3.copyWith(fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 12),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _quickAction(
                  context,
                  AppIcons.track,
                  context.l10n.myShipments,
                  () => context.go('/track'),
                ),
                const SizedBox(width: 10),
                _quickAction(
                  context,
                  AppIcons.history,
                  context.l10n.shipmentHistory,
                  () => _openRoute(
                    '/shipment-history?role=sender',
                    onReturn: () => _loadShipmentCounts(silent: true),
                  ),
                ),
                const SizedBox(width: 10),
                _quickAction(
                  context,
                  AppIcons.browse,
                  context.l10n.transactionHistory,
                  () => _openRoute('/transaction-history?role=sender'),
                ),
              ],
            ),
            const SizedBox(height: 16),
            const RecentReviewsSection(role: WalletRole.sender),
            const SizedBox(height: 8),
            AppButton(
              label: context.tr('Log out'),
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
            style: typo.h2.copyWith(color: AppColors.primary),
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

  Widget _quickAction(
    BuildContext context,
    String iconAsset,
    String label,
    VoidCallback onTap,
  ) {
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
  const ShipmentHistoryScreen({super.key, this.role = 'sender'});

  final String role;

  @override
  State<ShipmentHistoryScreen> createState() => _ShipmentHistoryScreenState();
}

class _ShipmentHistoryScreenState extends State<ShipmentHistoryScreen> {
  bool _loading = true;
  String? _error;
  List<CreatedDelivery>? _deliveries;

  List<CreatedDelivery> get _items => _deliveries ?? const <CreatedDelivery>[];

  String get _role {
    final fromWidget = widget.role.trim().toLowerCase();
    if (fromWidget == 'traveler' || fromWidget == 'receiver') return fromWidget;
    return 'sender';
  }

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
      final list = await _repository().listDeliveries(role: _role);
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

  Future<void> _openDelivery(CreatedDelivery d) async {
    final id = d.publicId.isNotEmpty ? d.publicId : d.id;
    if (_role == 'traveler') {
      await context.push('/shipment/$id?traveler=true');
    } else if (_role == 'receiver') {
      await context.push('/receiver-tracking?shipmentId=$id');
    } else {
      await context.push('/shipment/$id');
    }
    if (mounted) await _load(silent: true);
  }

  @override
  Widget build(BuildContext context) {
    final typo = context.typo;
    final fallback = switch (_role) {
      'traveler' => '/traveler-profile',
      'receiver' => '/receiver-home',
      _ => '/profile',
    };

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: BackHeader(
        title: context.l10n.shipmentHistory,
        fallbackRoute: fallback,
      ),
      body: SafeArea(
        child: RefreshIndicator(
          color: AppColors.primary,
          onRefresh: () => _load(silent: true),
          child: ListView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: context.pagePadding.copyWith(top: 16),
            children: [
              Text(context.l10n.completedCityToCity, style: typo.sm),
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
                      child: Text(context.tr('Retry')),
                    ),
                  ],
                )
              else if (_items.isEmpty)
                Text(
                  context.l10n.noCompletedShipments,
                  style: typo.sm.copyWith(color: AppColors.textSecondary),
                )
              else
                ..._items.map((s) {
                  final idLabel = s.publicId.isNotEmpty ? s.publicId : s.id;
                  final color = _statusColor(s.status);
                  return AppCard(
                    margin: const EdgeInsets.only(bottom: 14),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 18,
                      vertical: 16,
                    ),
                    onTap: () => _openDelivery(s),
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
                        StackedRouteEndpoints.split(s.route),
                        const SizedBox(height: 12),
                        Text(_formatTravelDate(s.travelDate), style: typo.sm),
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
      appBar: BackHeader(
        title: context.l10n.transactionHistory,
        fallbackRoute: fallback,
      ),
      body: Consumer<WalletProvider>(
        builder: (context, wallet, _) {
          return ValueListenableBuilder<int>(
            valueListenable: WalletService.walletVersion,
            builder: (context, _, _) {
              final entries = wallet.historyFor();

              if (wallet.loading && entries.isEmpty) {
                return const Center(child: CircularProgressIndicator());
              }

              return ScreenBody(
                padding: context.pagePadding.copyWith(top: 16, bottom: 0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(context.l10n.immutableLedger, style: typo.sm),
                    const SizedBox(height: 16),
                    if (entries.isEmpty)
                      Text(context.l10n.noTransactionsYet, style: typo.sm)
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
        ? '${context.l10n.escrow} ${escrowDelta > 0 ? '+' : '−'}${WalletService.formatCents(escrowDelta.abs())}'
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
                Text(
                  context.l10n.translateLedgerDescription(
                    entry.displayDescription,
                  ),
                  style: typo.sm,
                ),
                Text(
                  '${context.l10n.ledgerTypeLabel(entry.type.name)} · ${_walletRoleLabel(context, entry.role)}',
                  style: typo.sm.copyWith(color: AppColors.textSecondary),
                ),
              ],
            ),
          ),
          Text(
            DateFormat.MMMd(
              context.l10n.locale.toString(),
            ).format(entry.createdAt),
            style: typo.sm,
          ),
        ],
      ),
    );
  }
}

String _walletRoleLabel(BuildContext context, WalletRole role) =>
    switch (role) {
      WalletRole.sender => context.l10n.sender,
      WalletRole.traveler => context.l10n.traveler,
      WalletRole.receiver => context.l10n.receiver,
    };

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
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
      _loadConnectStatus();
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
        if (!linked) {
          _connectStatusLabel = 'not_linked';
        } else if (ready) {
          _connectStatusLabel = 'connected';
        } else {
          _connectStatusLabel = 'connected_finish';
        }
      });
    } catch (_) {
      if (!mounted) return;
      setState(() => _connectStatusLabel = null);
    }
  }

  Future<void> _linkStripeConnect() async {
    setState(() => _connectLoading = true);
    try {
      final roleParam = GoRouterState.of(context).uri.queryParameters['role'];
      final result = await _walletRepository().startConnectOnboarding(
        role: roleParam,
      );
      final url = result['onboardingUrl'] as String?;
      if (url == null || url.isEmpty) {
        throw Exception('No onboarding URL returned');
      }
      StripeConnectReturn.markOpened(role: roleParam);
      final opened = await ExternalLinks.openUrl(url);
      if (!mounted) return;
      if (!opened) {
        AppToast.error(context, context.l10n.couldNotOpenStripeConnect);
      } else {
        await _loadConnectStatus();
      }
    } on ApiException catch (e) {
      if (!mounted) return;
      AppToast.error(context, 'Stripe Connect: ${e.message}');
    } catch (e) {
      if (!mounted) return;
      AppToast.error(context, 'Stripe Connect: ${e.toString()}');
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
    final l10n = context.l10n;
    final bioLabel = PlatformUi.isIOS ? l10n.faceId : l10n.fingerprint;

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
      reason: l10n.biometricSetupReason(bioLabel),
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

    final message = switch (result.status) {
      BiometricAuthStatus.notEnrolled => l10n.biometricNotSetUp(bioLabel),
      BiometricAuthStatus.notAvailable => l10n.biometricNotAvailable(bioLabel),
      BiometricAuthStatus.failed => l10n.biometricNotRecognized(bioLabel),
      _ => l10n.couldNotEnableBiometric(bioLabel),
    };
    AppToast.error(context, message);
  }

  String _routeWithRole(String baseRoute, String? roleParam) {
    if (roleParam == null || roleParam.isEmpty) return baseRoute;
    return '$baseRoute?role=$roleParam';
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final roleParam = GoRouterState.of(context).uri.queryParameters['role'];
    final isReceiver = roleParam == 'receiver';
    final isTraveler = roleParam == 'traveler';
    final isSender = roleParam == 'sender' || roleParam == null;
    final editProfileRole = isReceiver
        ? EditProfileRole.receiver
        : isTraveler
        ? EditProfileRole.traveler
        : EditProfileRole.sender;
    // Demo app mode toggle commented out — live API only.
    // final demoMode = context.watch<DemoModeProvider>();
    final authUser = context.watch<AuthProvider>().user;
    final themeProvider = context.watch<ThemeProvider>();
    final localeProvider = context.watch<LocaleProvider>();
    final currencyProvider = context.watch<CurrencyProvider>();
    final settingsFallback = isReceiver
        ? '/receiver-profile'
        : isTraveler
        ? '/traveler-profile'
        : isSender
        ? '/profile'
        : null;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: BackHeader(title: l10n.settings, fallbackRoute: settingsFallback),
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
              _sectionLabel(l10n.accountVerification),
              AppCard(
                margin: const EdgeInsets.only(bottom: 16),
                child: ListTile(
                  contentPadding: EdgeInsets.zero,
                  title: Text(
                    l10n.verifyEmailPhone,
                    style: context.typo.bodyBold,
                  ),
                  subtitle: Text(
                    l10n.verifyEmailPhoneSubtitle,
                    style: context.typo.sm,
                  ),
                  trailing: const Icon(Icons.chevron_right_rounded),
                  onTap: () => context.push('/verify-account'),
                ),
              ),
            ],
            _sectionLabel(l10n.appearance),
            _settingsGroup([
              _tile(
                l10n.theme,
                subtitle: themeProvider.isDark ? l10n.darkMode : l10n.lightMode,
                onTap: () => themeProvider.setDarkMode(!themeProvider.isDark),
              ),
              _tile(
                l10n.currency,
                subtitle:
                    '${currencyProvider.currency.code} · ${currencyProvider.currency.symbol}',
                onTap: () => context.push(
                  _routeWithRole('/settings/currency', roleParam),
                ),
              ),
              _tile(
                l10n.language,
                subtitle:
                    '${localeProvider.language.nativeName} · ${localeProvider.language.name}',
                onTap: () => context.push(
                  _routeWithRole('/settings/language', roleParam),
                ),
              ),
            ]),
            _sectionLabel(l10n.profile),
            _settingsGroup([
              _tile(
                l10n.editProfile,
                onTap: () =>
                    context.push('/edit-profile', extra: editProfileRole),
              ),
            ]),
            _sectionLabel(l10n.walletAndPayments),
            _settingsGroup([
              SizedBox(
                width: double.infinity,
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: ValueListenableBuilder<int>(
                    valueListenable: WalletService.walletVersion,
                    builder: (context, _, _) {
                      return ValueListenableBuilder<int>(
                        valueListenable: FxRateService.version,
                        builder: (context, _, _) {
                          final role = WalletRole.fromQuery(roleParam);
                          return Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                l10n.availableBalance,
                                style: context.typo.sm,
                              ),
                              Text(
                                WalletService.formatCents(
                                  WalletService.availableCents(role),
                                ),
                                style: context.typo.priceLarge,
                              ),
                              const SizedBox(height: 8),
                              Text(l10n.escrowBalance, style: context.typo.sm),
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
                      );
                    },
                  ),
                ),
              ),
              _tile(
                l10n.topUpWallet,
                onTap: () {
                  FocusManager.instance.primaryFocus?.unfocus();
                  context.push(_routeWithRole('/wallet/top-up', roleParam));
                },
              ),
              _tile(
                _connectLoading
                    ? context.l10n.linkingStripeConnect
                    : context.l10n.linkStripeConnect,
                subtitle: () {
                  final label = _connectStatusLabel;
                  if (label == null) {
                    return context.l10n.requiredForWithdrawals;
                  }
                  if (label == 'connected') {
                    return context.l10n.accountLinkedReady;
                  }
                  if (label == 'connected_finish') {
                    return context.l10n.accountLinkedFinish;
                  }
                  return context.l10n.notLinked;
                }(),
                onTap: _connectLoading ? () {} : _linkStripeConnect,
                trailing:
                    _connectStatusLabel == 'connected' ||
                        _connectStatusLabel == 'connected_finish'
                    ? AppBadge.success(context.l10n.connected)
                    : null,
              ),
              _tile(
                l10n.withdraw,
                onTap: () => context.push(_routeWithRole('/wallet', roleParam)),
              ),
              _tile(
                l10n.transactionHistory,
                onTap: () => context.push(
                  _routeWithRole('/transaction-history', roleParam),
                ),
              ),
            ]),
            _sectionLabel(l10n.security),
            _settingsGroup([
              _tile(
                context.tr('Change password'),
                onTap: () =>
                    context.push(_routeWithRole('/change-password', roleParam)),
              ),
              _tile(
                l10n.kycVerification,
                onTap: () =>
                    context.push(_routeWithRole('/kyc-status', roleParam)),
                trailing: KycStatusBadge(user: authUser),
              ),
              _toggle(
                l10n.biometricLogin(
                  PlatformUi.isIOS ? l10n.faceId : l10n.fingerprint,
                ),
                _biometricEnabled,
                kIsWeb || _biometricBusy ? null : _onBiometricToggled,
                subtitle: kIsWeb
                    ? l10n.biometricLoginWebSubtitle
                    : l10n.biometricLoginSubtitle(
                        PlatformUi.isIOS ? l10n.faceId : l10n.fingerprint,
                      ),
              ),
            ]),
            _sectionLabel(l10n.legal),
            _settingsGroup([
              _tile(
                context.tr('Help & support'),
                subtitle: context.tr('FAQ, safety, contact'),
                onTap: () => context.push(_routeWithRole('/help', roleParam)),
              ),
              _tile(
                context.tr('Legal & policies'),
                subtitle: context.tr('Privacy, terms, cookies'),
                onTap: () => context.push(_routeWithRole('/legal', roleParam)),
              ),
            ]),
            _sectionLabel(context.tr('Account')),
            AppButton(
              label: l10n.logout,
              variant: AppButtonVariant.danger,
              onPressed: () => logoutToLoginScreen(context),
            ),
            const SizedBox(height: 12),
            AppButton(
              label: context.tr('Delete account'),
              variant: AppButtonVariant.danger,
              onPressed: () => context.go('/account-suspended'),
            ),
            const SizedBox(height: 24),
            Center(
              child: Text(
                'WWNGO v1.0.0',
                style: context.typo.caption.copyWith(
                  color: AppColors.textSecondary,
                ),
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
    const radius = 16.0;
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(radius),
        border: Border.all(color: AppColors.border),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(radius - 1),
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
      ),
    );
  }

  Widget _tile(
    String title, {
    required VoidCallback onTap,
    Widget? trailing,
    String? subtitle,
  }) {
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
                      style: context.typo.sm.copyWith(
                        color: AppColors.textSecondary,
                      ),
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
                    style: context.typo.sm.copyWith(
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ],
            ),
          ),
          Switch(value: value, onChanged: onChanged),
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
  final _amountController = TextEditingController();
  String? _error;
  bool _withdrawing = false;

  bool _connectChecking = true;
  bool _connectLinked = false;
  bool _connectReady = false;
  bool _connectMock = false;
  bool _connectLinking = false;

  /// Whether a payout destination is usable: linked and either onboarded
  /// (`ready`) or a dev/mock account. Mirrors the backend withdraw guard.
  bool get _payoutEnabled => _connectLinked && (_connectReady || _connectMock);

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
      _loadConnectStatus();
    });
  }

  @override
  void dispose() {
    _amountController.dispose();
    super.dispose();
  }

  WalletRepository _walletRepository() {
    final auth = context.read<AuthProvider>();
    return WalletRepository(apiClient: auth.repository.apiClient);
  }

  Future<void> _loadConnectStatus() async {
    if (mounted) setState(() => _connectChecking = true);
    try {
      final status = await _walletRepository().fetchConnectStatus();
      if (!mounted) return;
      setState(() {
        _connectLinked = status['linked'] == true;
        _connectReady = status['ready'] == true;
        _connectMock = status['mock'] == true;
        _connectChecking = false;
      });
    } catch (_) {
      if (!mounted) return;
      // Fail closed — treat an unknown status as "not ready" so we never let a
      // withdrawal through without a confirmed payout account.
      setState(() {
        _connectLinked = false;
        _connectReady = false;
        _connectMock = false;
        _connectChecking = false;
      });
    }
  }

  Future<void> _setUpPayouts() async {
    setState(() => _connectLinking = true);
    try {
      final roleParam = GoRouterState.of(context).uri.queryParameters['role'];
      final result = await _walletRepository().startConnectOnboarding(
        role: roleParam,
      );
      final url = result['onboardingUrl'] as String?;
      if (url == null || url.isEmpty) {
        throw Exception('No onboarding URL returned');
      }
      StripeConnectReturn.markOpened(role: roleParam);
      final opened = await ExternalLinks.openUrl(url);
      if (!mounted) return;
      if (!opened) {
        AppToast.error(context, context.l10n.couldNotOpenStripeConnect);
      }
    } on ApiException catch (e) {
      if (!mounted) return;
      AppToast.error(context, 'Stripe Connect: ${e.message}');
    } catch (_) {
      if (!mounted) return;
      AppToast.error(context, context.l10n.couldNotStartPayoutSetup);
    } finally {
      if (mounted) setState(() => _connectLinking = false);
      // Re-check status when the user returns from onboarding.
      await _loadConnectStatus();
    }
  }

  String _routeWithRole(String baseRoute, WalletRole role) =>
      '$baseRoute?role=${role.queryParam}';

  Future<void> _withdraw(WalletRole role, double parsedAmount) async {
    if (!_payoutEnabled) {
      setState(() => _error = context.l10n.linkPayoutBeforeWithdraw);
      return;
    }

    final currency = context.read<CurrencyProvider>();
    final wallet = context.read<WalletProvider>();
    setState(() {
      _withdrawing = true;
      _error = null;
    });
    try {
      // Wallet ledger is USD. Convert the entered display amount via Stripe FX.
      int usdCents;
      if (currency.code == 'USD') {
        usdCents = (parsedAmount * 100).round();
      } else {
        final displayMinor = currency.currency.toMinorUnits(parsedAmount);
        final quote = await currency.convert(
          fromCurrency: currency.code,
          toCurrency: 'USD',
          amountCents: displayMinor,
        );
        usdCents = quote.convertedAmountCents;
      }

      final validation = WalletService.validateWithdrawal(role, usdCents);
      if (validation != null) {
        if (mounted) setState(() => _error = validation);
        return;
      }

      // Debit USD from the ledger (backend treats amountCents as USD cents).
      await wallet.withdraw(role: role, amountCents: usdCents, currency: 'USD');
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
      setState(() => _error = context.l10n.withdrawalFailed);
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
    final currencyProvider = context.watch<CurrencyProvider>();

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: BackHeader(
        title: context.tr('Wallet'),
        fallbackRoute: walletFallback,
      ),
      body: Consumer<WalletProvider>(
        builder: (context, wallet, _) {
          return ValueListenableBuilder<int>(
            valueListenable: WalletService.walletVersion,
            builder: (context, _, _) {
              return ValueListenableBuilder<int>(
                valueListenable: FxRateService.version,
                builder: (context, _, _) {
                  final available = WalletService.availableCents(role);
                  final escrow = WalletService.escrowCents(role);
                  final entries = wallet.historyFor();
                  final parsedAmount =
                      double.tryParse(_amountController.text) ?? 0;
                  final displayAmount = parsedAmount;
                  final canWithdraw = true;
                  final amountEnabled = available > 0;
                  final minWithdraw =
                      wallet.summary?.minimumWithdrawalCents ??
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
                              colors: [
                                AppColors.primary,
                                AppColors.primaryDark,
                              ],
                            ),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Column(
                            children: [
                              Text(
                                context.l10n.availableBalance,
                                style: typo.captionOnDarkSoft,
                              ),
                              Text(
                                WalletService.formatCents(available),
                                style: typo.priceHeroDark,
                              ),
                              if (escrow > 0)
                                Padding(
                                  padding: const EdgeInsets.only(top: 8),
                                  child: Text(
                                    context.l10n.escrowWithAmount(
                                      WalletService.formatCents(escrow),
                                    ),
                                    style: typo.captionOnDarkSoft.copyWith(
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ),
                              if (canWithdraw) ...[
                                const SizedBox(height: 12),
                                Text(
                                  context.l10n.minimumWithdrawal(
                                    WalletService.formatCents(minWithdraw),
                                  ),
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
                                label: context.l10n.topUpStripe,
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
                                label: context.l10n.history,
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
                            context.l10n.withdrawViaStripeConnect,
                            style: typo.h3.copyWith(
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          const SizedBox(height: 8),
                          AppLabeledField(
                            label: context.l10n.amountLabelCurrency(
                              WalletService.currencyCode,
                            ),
                            labelStyle: typo.inputLabel.copyWith(
                              fontWeight: FontWeight.w600,
                            ),
                            padding: const EdgeInsets.only(
                              top: AppFieldSpacing.top,
                            ),
                            child: TextField(
                              controller: _amountController,
                              enabled: amountEnabled,
                              readOnly: !amountEnabled,
                              enableInteractiveSelection: amountEnabled,
                              onTap: amountEnabled
                                  ? ensureSoftKeyboardVisible
                                  : null,
                              onTapOutside: dismissKeyboardOnTapOutside,
                              keyboardType:
                                  const TextInputType.numberWithOptions(
                                    decimal: true,
                                  ),
                              style: typo.amountInput.copyWith(
                                fontWeight: FontWeight.w700,
                                color: amountEnabled
                                    ? AppColors.textPrimary
                                    : AppColors.textDisabled,
                              ),
                              decoration: InputDecoration(
                                filled: true,
                                fillColor: amountEnabled
                                    ? AppColors.surface
                                    : AppColors.background,
                                hintText: amountEnabled ? null : '0.00',
                                hintStyle: typo.amountInput.copyWith(
                                  fontWeight: FontWeight.w700,
                                  color: AppColors.textDisabled,
                                ),
                                disabledBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide: BorderSide(
                                    color: AppColors.border,
                                    width: 1.5,
                                  ),
                                ),
                              ),
                              onChanged: amountEnabled
                                  ? (_) {
                                      setState(() {
                                        if (_error != null) _error = null;
                                      });
                                    }
                                  : null,
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
                                  label: context.l10n.youWillReceive,
                                  value: currencyProvider.currency.formatMajor(
                                    displayAmount,
                                  ),
                                ),
                                _SummaryRow(
                                  label: context.l10n.payoutRail,
                                  value: 'Stripe Connect',
                                ),
                                _SummaryRow(
                                  label: context.l10n.arrivesIn,
                                  value: context.l10n.businessDays2to5,
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 20),
                          if (!_connectChecking && !_payoutEnabled) ...[
                            Container(
                              width: double.infinity,
                              padding: const EdgeInsets.all(14),
                              decoration: BoxDecoration(
                                color: AppColors.warning.withValues(
                                  alpha: 0.10,
                                ),
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color: AppColors.warning.withValues(
                                    alpha: 0.3,
                                  ),
                                ),
                              ),
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Icon(
                                    Icons.account_balance_outlined,
                                    size: 20,
                                    color: AppColors.warning,
                                  ),
                                  const SizedBox(width: 10),
                                  Expanded(
                                    child: Text(
                                      _connectLinked
                                          ? context.l10n.finishSettingUpPayout
                                          : context.l10n.linkPayoutToWithdraw,
                                      style: typo.sm.copyWith(
                                        color: AppColors.textPrimary,
                                        height: 1.4,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 12),
                            AppButton(
                              label: _connectLinking
                                  ? context.l10n.openingEllipsis
                                  : _connectLinked
                                  ? context.l10n.finishPayoutSetup
                                  : context.l10n.setUpPayoutAccount,
                              textStyle: typo.button.copyWith(
                                fontWeight: FontWeight.w700,
                              ),
                              onPressed: _connectLinking ? null : _setUpPayouts,
                            ),
                          ] else
                            AppButton(
                              label: _withdrawing
                                  ? context.l10n.withdrawing
                                  : context.l10n.withdrawToBank,
                              textStyle: typo.button.copyWith(
                                fontWeight: FontWeight.w700,
                              ),
                              onPressed:
                                  (_withdrawing ||
                                      _connectChecking ||
                                      !amountEnabled)
                                  ? null
                                  : () => _withdraw(role, parsedAmount),
                            ),
                          const SizedBox(height: 20),
                          Text(
                            context.l10n.recentTransactions,
                            style: typo.h3.copyWith(
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            context.l10n.immutableLedgerCents,
                            style: typo.sm.copyWith(
                              color: AppColors.textSecondary,
                            ),
                          ),
                          const SizedBox(height: 10),
                          if (entries.isEmpty)
                            Text(context.l10n.noTransactionsYet, style: typo.sm)
                          else
                            ...entries
                                .take(6)
                                .map((e) => _ledgerTile(context, e)),
                        ],
                      ],
                    ),
                  );
                },
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
                Text(
                  context.l10n.translateLedgerDescription(
                    entry.displayDescription,
                  ),
                  style: typo.sm,
                ),
              ],
            ),
          ),
          Text(
            DateFormat.MMMd(
              context.l10n.locale.toString(),
            ).format(entry.createdAt),
            style: typo.sm,
          ),
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
          Text(
            value,
            style: typo.bodyBold.copyWith(fontWeight: FontWeight.w700),
          ),
        ],
      ),
    );
  }
}
