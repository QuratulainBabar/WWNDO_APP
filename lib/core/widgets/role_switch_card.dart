import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../core/api/api_exception.dart';
import '../../core/auth/selected_role.dart';
import '../../data/models/auth_user.dart';
import '../../data/models/shipment.dart';
import '../../data/models/wallet_role.dart';
import '../../providers/auth_provider.dart';
import '../theme/app_colors.dart';
import '../theme/app_typography.dart';
import 'app_badge.dart';
import 'app_card.dart';
import 'app_svg_icon.dart';
import 'app_toast.dart';

class RoleSwitchCard extends StatefulWidget {
  const RoleSwitchCard({
    super.key,
    this.currentRole,
  });

  /// Optional fallback when the auth user has no role yet.
  final ShipmentRole? currentRole;

  @override
  State<RoleSwitchCard> createState() => _RoleSwitchCardState();
}

class _RoleSwitchCardState extends State<RoleSwitchCard> {
  ShipmentRole? _pendingRole;

  static const _roles = [
    (
      role: ShipmentRole.sender,
      walletRole: WalletRole.sender,
      iconAsset: AppIcons.roleSender,
      title: 'Sender',
      description: 'Post deliveries and choose trusted travelers',
      profileRoute: '/profile',
    ),
    (
      role: ShipmentRole.traveler,
      walletRole: WalletRole.traveler,
      iconAsset: AppIcons.roleTraveler,
      title: 'Traveler',
      description: 'Share your route and carry parcels on your trip',
      profileRoute: '/traveler-profile',
    ),
    (
      role: ShipmentRole.receiver,
      walletRole: WalletRole.receiver,
      iconAsset: AppIcons.roleReceiver,
      title: 'Receiver',
      description: 'Track parcel progress and confirm delivery',
      profileRoute: '/receiver-profile',
    ),
  ];

  ShipmentRole _effectiveRole(AuthUser? user) {
    final fromAuth = SelectedRoleStore.roleFromUser(user);
    if (fromAuth != null) {
      return switch (fromAuth) {
        WalletRole.sender => ShipmentRole.sender,
        WalletRole.traveler => ShipmentRole.traveler,
        WalletRole.receiver => ShipmentRole.receiver,
      };
    }
    return widget.currentRole ?? ShipmentRole.sender;
  }

  Future<void> _switchRole(ShipmentRole role) async {
    if (_pendingRole != null) return;

    final auth = context.read<AuthProvider>();
    final current = _effectiveRole(auth.user);
    if (role == current) return;

    final entry = _roles.firstWhere((r) => r.role == role);
    setState(() => _pendingRole = role);

    try {
      final updated =
          await auth.setRole(SelectedRoleStore.apiValue(entry.walletRole));
      await SelectedRoleStore.saveForUser(
        userId: updated.id,
        email: updated.email,
        role: entry.walletRole,
      );
      if (!mounted) return;
      context.go(entry.profileRoute);
    } on ApiException catch (e) {
      if (!mounted) return;
      AppToast.error(context, e.message);
      setState(() => _pendingRole = null);
    } catch (_) {
      if (!mounted) return;
      AppToast.error(context, 'Could not switch role. Please try again.');
      setState(() => _pendingRole = null);
    }
  }

  @override
  Widget build(BuildContext context) {
    final typo = context.typo;
    final authUser = context.watch<AuthProvider>().user;
    final currentRole = _effectiveRole(authUser);
    final switching = _pendingRole != null;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Switch role', style: typo.h3.copyWith(fontWeight: FontWeight.w700)),
        const SizedBox(height: 4),
        Text('Use WWNGO as a sender, traveler, or receiver', style: typo.sm),
        const SizedBox(height: 10),
        AppCard(
          margin: EdgeInsets.zero,
          padding: EdgeInsets.zero,
          child: Column(
            children: [
              for (var i = 0; i < _roles.length; i++) ...[
                if (i > 0) const Divider(height: 1),
                _RoleRow(
                  iconAsset: _roles[i].iconAsset,
                  title: _roles[i].title,
                  description: _roles[i].description,
                  selected: currentRole == _roles[i].role,
                  enabled: !switching,
                  loading: _pendingRole == _roles[i].role,
                  onTap: () => _switchRole(_roles[i].role),
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }
}

class _RoleRow extends StatelessWidget {
  const _RoleRow({
    required this.iconAsset,
    required this.title,
    required this.description,
    required this.selected,
    required this.onTap,
    this.enabled = true,
    this.loading = false,
  });

  final String iconAsset;
  final String title;
  final String description;
  final bool selected;
  final VoidCallback onTap;
  final bool enabled;
  final bool loading;

  @override
  Widget build(BuildContext context) {
    final typo = context.typo;

    return Material(
      color: selected
          ? AppColors.primary.withValues(alpha: 0.04)
          : Colors.transparent,
      child: InkWell(
        onTap: enabled && !selected ? onTap : null,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          child: Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                alignment: Alignment.center,
                child: AppSvgIcon(
                  asset: iconAsset,
                  size: 22,
                  color: AppColors.primary,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: typo.bodyBold.copyWith(
                        fontWeight: FontWeight.w700,
                        color: selected
                            ? AppColors.primary
                            : AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(description, style: typo.sm),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              if (loading)
                const SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: AppColors.primary,
                  ),
                )
              else if (selected)
                AppBadge(
                  label: 'Active',
                  color: AppColors.primary,
                  backgroundColor: AppColors.primary.withValues(alpha: 0.1),
                )
              else
                const Icon(
                  Icons.arrow_forward_ios_rounded,
                  size: 14,
                  color: AppColors.textSecondary,
                ),
            ],
          ),
        ),
      ),
    );
  }
}
