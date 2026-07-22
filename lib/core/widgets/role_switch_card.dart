import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../data/models/shipment.dart';
import '../theme/app_colors.dart';
import '../theme/app_typography.dart';
import 'app_badge.dart';
import 'app_card.dart';
import 'app_svg_icon.dart';

class RoleSwitchCard extends StatelessWidget {
  const RoleSwitchCard({
    super.key,
    required this.currentRole,
  });

  final ShipmentRole currentRole;

  void _switchRole(BuildContext context, ShipmentRole role) {
    if (role == currentRole) return;

    final route = switch (role) {
      ShipmentRole.sender => '/profile',
      ShipmentRole.traveler => '/traveler-profile',
      ShipmentRole.receiver => '/receiver-profile',
    };
    context.go(route);
  }

  static const _roles = [
    (
      role: ShipmentRole.sender,
      iconAsset: AppIcons.roleSender,
      title: 'Sender',
      description: 'Post deliveries and choose trusted travelers',
    ),
    (
      role: ShipmentRole.traveler,
      iconAsset: AppIcons.roleTraveler,
      title: 'Traveler',
      description: 'Share your route and carry parcels on your trip',
    ),
    (
      role: ShipmentRole.receiver,
      iconAsset: AppIcons.roleReceiver,
      title: 'Receiver',
      description: 'Track parcel progress and confirm delivery',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    final typo = context.typo;

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
                  onTap: () => _switchRole(context, _roles[i].role),
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
  });

  final String iconAsset;
  final String title;
  final String description;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final typo = context.typo;

    return Material(
      color: selected ? AppColors.primary.withValues(alpha: 0.04) : Colors.transparent,
      child: InkWell(
        onTap: onTap,
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
                        color: selected ? AppColors.primary : AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(description, style: typo.sm),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              if (selected)
                AppBadge(
                  label: 'Active',
                  color: AppColors.primary,
                  backgroundColor: AppColors.primary.withValues(alpha: 0.1),
                )
              else
                Icon(
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
