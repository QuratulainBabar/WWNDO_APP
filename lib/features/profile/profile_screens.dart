import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../core/config/demo_mode.dart';
import '../../core/layout/responsive.dart';
import '../../core/widgets/kyc_status_badge.dart';
import '../../providers/auth_provider.dart';
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
import '../../data/models/shipment.dart';
import '../../data/models/ledger_entry.dart';
import '../../data/models/wallet_role.dart';
import '../../data/static_data.dart';
import '../../data/wallet_service.dart';
import 'settings_flow_screens.dart';
import 'widgets/profile_header_card.dart';
import 'widgets/profile_trust_indicators.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final typo = context.typo;
    final authUser = context.watch<AuthProvider>().user;
    final user = authUser?.toUserProfile() ?? StaticData.currentUser;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: ScreenBody(
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
                    onTap: () => context.push('/settings?role=sender'),
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
                subtitle: 'Sender',
                memberSince: user.memberSince,
                bio: user.bio,
                rating: user.rating,
                authUser: authUser,
              ),
              IntrinsicHeight(
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _stat(context, '${StaticData.senderActiveShipmentCount}', 'Active Shipments'),
                    const SizedBox(width: 10),
                    _stat(context, '${StaticData.senderCompletedShipmentCount}', 'Completed Shipments'),
                  ],
                ),
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  ValueListenableBuilder<int>(
                    valueListenable: WalletService.walletVersion,
                    builder: (context, _, __) => _stat(
                      context,
                      WalletService.formatCents(
                        WalletService.availableCents(WalletRole.sender),
                      ),
                      'Wallet',
                      onTap: () => context.push('/wallet?role=sender'),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              ProfileTrustIndicators(
                metrics: StaticData.senderTrustMetrics,
                authUser: authUser,
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
                  _quickAction(context, AppIcons.history, 'Shipment History', () => context.push('/shipment-history')),
                  const SizedBox(width: 10),
                  _quickAction(context, AppIcons.browse, 'Transaction History', () => context.push('/transaction-history?role=sender')),
                ],
              ),
              const SizedBox(height: 16),
              Text('Recent reviews', style: typo.h3.copyWith(fontWeight: FontWeight.w700)),
              const SizedBox(height: 10),
              ...StaticData.reviews.map((r) => AppCard(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            AppAvatar(initial: r.initial, size: AvatarSize.small),
                            const SizedBox(width: 8),
                            Expanded(child: Text(r.reviewerName, style: typo.sm.copyWith(fontWeight: FontWeight.w700))),
                            Text('${'★' * r.rating}${'☆' * (5 - r.rating)}', style: typo.starRating),
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

  Widget _stat(BuildContext context, String value, String label, {bool primary = false, VoidCallback? onTap}) {
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

    if (onTap == null) return Expanded(child: card);

    return Expanded(
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(16),
          child: card,
        ),
      ),
    );
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
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          constraints: const BoxConstraints(minHeight: 98),
          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 14),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: AppColors.border),
          ),
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
    );
  }
}

class ShipmentHistoryScreen extends StatelessWidget {
  const ShipmentHistoryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final typo = context.typo;
    final shipments = StaticData.senderCompletedShipments;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: const BackHeader(title: 'Shipment History'),
      body: ScreenBody(
        padding: context.pagePadding.copyWith(top: 16, bottom: 0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Completed city-to-city and country-to-country deliveries.',
              style: typo.sm,
            ),
            const SizedBox(height: 16),
            ...shipments.map((s) => GestureDetector(
                  onTap: () => context.push('/shipment/${s.id}'),
                  child: AppCard(
                    margin: const EdgeInsets.only(bottom: 14),
                    padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              s.id,
                              style: typo.h3.copyWith(fontSize: 16, fontWeight: FontWeight.w700),
                            ),
                            AppBadge.status(s.status, semiBold: true, wide: true),
                          ],
                        ),
                        const SizedBox(height: 10),
                        Text(s.route, style: typo.sm.copyWith(color: AppColors.textPrimary)),
                        if (s.travelerName != null) ...[
                          const SizedBox(height: 6),
                          Text('Traveler: ${s.travelerName}', style: typo.sm),
                        ],
                        const SizedBox(height: 12),
                        Text(
                          DateFormat('MMM d, yyyy').format(s.travelDate),
                          style: typo.sm,
                        ),
                      ],
                    ),
                  ),
                )),
          ],
        ),
      ),
    );
  }
}

class TransactionHistoryScreen extends StatelessWidget {
  const TransactionHistoryScreen({super.key});

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
      body: ValueListenableBuilder<int>(
        valueListenable: WalletService.walletVersion,
        builder: (context, _, __) {
          final entries = WalletService.historyFor(role);

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
                  Text('No transactions yet.', style: typo.sm)
                else
                  ...entries.map((e) => _ledgerTile(context, e)),
              ],
            ),
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

  @override
  void initState() {
    super.initState();
    _loadBiometricPreference();
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
    final demoMode = context.watch<DemoModeProvider>();
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
            _sectionLabel('Developer'),
            _settingsGroup([
              _toggle(
                'Demo app mode',
                demoMode.enabled,
                demoMode.setEnabled,
                subtitle: demoMode.enabled
                    ? 'Offline static data — no backend'
                    : 'Live API — backend required',
              ),
            ]),
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
                onTap: () => context.push(
                  _routeWithRole('/wallet/top-up', roleParam),
                ),
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
            _sectionLabel('Account'),
            AppButton(
              label: 'Delete account',
              variant: AppButtonVariant.danger,
              onPressed: () => context.go('/account-suspended'),
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
      child: Column(
        children: [
          for (var i = 0; i < children.length; i++) ...[
            children[i],
            if (i < children.length - 1) const Divider(height: 1),
          ],
        ],
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

  @override
  void dispose() {
    _amountController.dispose();
    super.dispose();
  }

  String _routeWithRole(String baseRoute, WalletRole role) =>
      '$baseRoute?role=${role.queryParam}';

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
      body: ValueListenableBuilder<int>(
        valueListenable: WalletService.walletVersion,
        builder: (context, _, __) {
          final available = WalletService.availableCents(role);
          final escrow = WalletService.escrowCents(role);
          final entries = WalletService.historyFor(role);
          final parsedAmount = double.tryParse(_amountController.text) ?? 0;
          final displayAmount = parsedAmount > 0 ? parsedAmount : 50.0;
          final canWithdraw = role != WalletRole.sender;

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
                          'Minimum withdrawal: ${WalletService.formatCents(WalletService.minimumWithdrawalCents)}',
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
                        onPressed: () => context.push(_routeWithRole('/wallet/top-up', role)),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: AppButton(
                        label: 'History',
                        variant: AppButtonVariant.outline,
                        small: true,
                        onPressed: () =>
                            context.push(_routeWithRole('/transaction-history', role)),
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
                    labelStyle: typo.inputLabel.copyWith(fontWeight: FontWeight.w600),
                    padding: const EdgeInsets.only(top: AppFieldSpacing.top),
                    child: TextField(
                      controller: _amountController,
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      style: typo.amountInput.copyWith(fontWeight: FontWeight.w700),
                      onChanged: (_) {
                        setState(() {
                          if (_error != null) _error = null;
                        });
                      },
                    ),
                  ),
                  if (_error != null) ...[
                    const SizedBox(height: 8),
                    Text(_error!, style: typo.sm.copyWith(color: AppColors.danger)),
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
                        const _SummaryRow(label: 'Arrives in', value: '2–5 business days'),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),
                  AppButton(
                    label: 'Withdraw to bank',
                    textStyle: typo.button.copyWith(fontWeight: FontWeight.w700),
                    onPressed: () {
                      final cents = (parsedAmount * 100).round();
                      final validation = WalletService.validateWithdrawal(role, cents);
                      if (validation != null) {
                        setState(() => _error = validation);
                        return;
                      }
                      final ok = WalletService.withdrawViaStripeConnect(
                        role: role,
                        amountCents: cents,
                      );
                      if (!ok) return;
                      context.push(
                        _routeWithRole('/wallet/withdrawal-success', role),
                        extra: parsedAmount,
                      );
                    },
                  ),
                  const SizedBox(height: 20),
                  Text('Recent transactions', style: typo.h3.copyWith(fontWeight: FontWeight.w700)),
                  const SizedBox(height: 4),
                  Text(
                    'Immutable ledger (cents precision)',
                    style: typo.sm.copyWith(color: AppColors.textSecondary),
                  ),
                  const SizedBox(height: 10),
                  ...entries.take(6).map((e) => _ledgerTile(context, e)),
                ],
              ],
            ),
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
