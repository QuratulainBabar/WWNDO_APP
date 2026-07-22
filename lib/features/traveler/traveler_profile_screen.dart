import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../core/navigation/app_navigation.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_typography.dart';
import '../../core/widgets/app_avatar.dart';
import '../../core/widgets/app_badge.dart';
import '../../core/widgets/app_button.dart';
import '../../core/widgets/app_card.dart';
import '../../core/widgets/app_svg_icon.dart';
import '../../core/widgets/back_link.dart';
import '../../core/widgets/role_switch_card.dart';
import '../../core/widgets/screen_body.dart';
import 'package:provider/provider.dart';
import '../../core/widgets/star_rating_display.dart';
import '../../data/models/shipment.dart';
import '../../data/models/wallet_role.dart';
import '../../providers/auth_provider.dart';
import '../profile/widgets/profile_header_card.dart';
import '../profile/widgets/profile_trust_indicators.dart';
import '../../data/static_data.dart';
import '../../data/wallet_service.dart';

class TravelerProfileScreen extends StatelessWidget {
  const TravelerProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final typo = context.typo;
    final user = StaticData.travelerUser;
    final authUser = context.watch<AuthProvider>().user;
    final country = StaticData.countryName(user.countryCode);

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
                  onTap: () => context.push('/settings?role=traveler'),
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
              role: WalletRole.traveler,
              name: user.name,
              initial: user.initial,
              subtitle: 'Traveler',
              memberSince: user.memberSince,
              bio: user.bio,
              rating: user.rating,
              authUser: authUser,
            ),
            const SizedBox(height: 16),
            const RoleSwitchCard(currentRole: ShipmentRole.traveler),
            const SizedBox(height: 16),
            AppCard(
              child: Column(
                children: [
                  _infoRow(context, 'Email', user.email),
                  const Divider(height: 24),
                  _infoRow(context, 'Phone number', user.phone),
                  const Divider(height: 24),
                  _infoRow(context, 'Country', country),
                  const Divider(height: 24),
                  _infoRow(
                    context,
                    'Rating',
                    '',
                    trailing: StarRatingDisplay(rating: user.rating),
                  ),
                  const Divider(height: 24),
                  _infoRow(
                    context,
                    'Total trips completed',
                    '${StaticData.travelerTotalTripsCompleted}',
                  ),
                  const Divider(height: 24),
                  _infoRow(
                    context,
                    'Parcels delivered',
                    '${StaticData.travelerParcelsDelivered}',
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            ProfileTrustIndicators(
              metrics: StaticData.travelerTrustMetrics,
              authUser: authUser,
            ),
            const SizedBox(height: 16),
            Text('Traveler statistics', style: typo.h3.copyWith(fontWeight: FontWeight.w700)),
            const SizedBox(height: 10),
            Row(
              children: [
                _stat(context, '${StaticData.travelerTotalDeliveries}', 'Total deliveries'),
                const SizedBox(width: 10),
                _stat(context, '${StaticData.travelerActiveTrips}', 'Active trips'),
              ],
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                _stat(
                  context,
                  '${StaticData.travelerSuccessfulDeliveryRate}%',
                  'Successful delivery rate',
                ),
                const SizedBox(width: 10),
                _stat(
                  context,
                  '',
                  'Average rating',
                  trailing: StarRatingDisplay(
                    rating: StaticData.travelerAverageRating,
                    showValue: true,
                    size: 12,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                ValueListenableBuilder<int>(
                  valueListenable: WalletService.walletVersion,
                  builder: (context, _, __) => _stat(
                    context,
                    WalletService.formatCents(
                      WalletService.availableCents(WalletRole.traveler),
                    ),
                    'Wallet',
                    onTap: () => context.push('/wallet?role=traveler'),
                  ),
                ),
                const SizedBox(width: 10),
                _stat(
                  context,
                  'History',
                  'Transactions',
                  onTap: () => context.push('/transaction-history?role=traveler'),
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

  Widget _infoRow(BuildContext context, String label, String value, {Widget? trailing}) {
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
    bool primary = false,
    VoidCallback? onTap,
    Widget? trailing,
  }) {
    final typo = context.typo;
    final labelStyle = typo.sm;
    final labelHeight = (labelStyle.fontSize ?? 15) * (labelStyle.height ?? 1.5) * 2;

    return Expanded(
      child: GestureDetector(
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
      ),
    );
  }
}
