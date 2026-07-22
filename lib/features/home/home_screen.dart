import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../core/theme/app_typography.dart';
import '../../core/theme/app_colors.dart';
import '../../core/layout/responsive.dart';
import '../../core/widgets/app_badge.dart';
import '../../core/widgets/app_card.dart';
import '../../core/widgets/app_svg_icon.dart';
import '../../core/widgets/back_link.dart';
import '../../core/widgets/screen_body.dart';
import '../../core/widgets/wallet_card.dart';
import '../../data/models/wallet_role.dart';
import '../../data/notification_service.dart';
import '../../data/static_data.dart';
import '../../core/auth/auth_verification_guard.dart';
import '../../core/auth/kyc_verification_guard.dart';
import '../sender/delivery_posting_actions.dart';

class MainShell extends StatelessWidget {
  const MainShell({super.key, required this.navigationShell});

  final StatefulNavigationShell navigationShell;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: navigationShell,
      bottomNavigationBar: Container(
        decoration: const BoxDecoration(
          color: AppColors.surface,
          border: Border(top: BorderSide(color: AppColors.border)),
        ),
        child: SafeArea(
          top: false,
          child: SizedBox(
            height: 72,
            child: Row(
              children: [
                _Tab(navigationShell: navigationShell, index: 0, iconAsset: AppIcons.home, label: 'Home'),
                _Tab(navigationShell: navigationShell, index: 1, iconAsset: AppIcons.track, label: 'Track'),
                _Tab(navigationShell: navigationShell, index: 2, iconAsset: AppIcons.chat, label: 'Chat'),
                _Tab(navigationShell: navigationShell, index: 3, iconAsset: AppIcons.profile, label: 'Profile'),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _Tab extends StatelessWidget {
  const _Tab({
    required this.navigationShell,
    required this.index,
    required this.iconAsset,
    required this.label,
  });

  final StatefulNavigationShell navigationShell;
  final int index;
  final String iconAsset;
  final String label;

  @override
  Widget build(BuildContext context) {
    final typo = context.typo;
    final active = navigationShell.currentIndex == index;
    return Expanded(
      child: InkWell(
        onTap: () => navigationShell.goBranch(index, initialLocation: true),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            AppSvgIcon(
              asset: iconAsset,
              size: 22,
              color: active ? AppColors.primary : AppColors.textSecondary,
            ),
            const SizedBox(height: 3),
            Text(
              label,
              style: typo.tabLabelActive(active ? AppColors.primary : AppColors.textSecondary),
            ),
          ],
        ),
      ),
    );
  }
}

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final typo = context.typo;
    final user = StaticData.currentUser;
    final shipment = StaticData.activeShipment;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: ScreenBody(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
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
                      Text('Hey, ${user.firstName} 👋', style: typo.h1, overflow: TextOverflow.ellipsis),
                      Text('★ ${user.rating} · Sender', style: typo.sm),
                    ],
                  ),
                ),
                WalletCard(role: WalletRole.sender),
              ],
            ),
            const SizedBox(height: 24),
            GestureDetector(
              onTap: () {
                // Wallet balance gate first — must not be masked by auth/KYC dialogs.
                if (!DeliveryPostingActions.ensureWalletAllowsParcelCreation(context)) return;
                if (!AuthVerificationGuard.ensureVerifiedForTransaction(context)) return;
                if (!KycVerificationGuard.ensureKycApproved(context)) return;
                context.push('/delivery-type');
              },
              child: Container(
              padding: const EdgeInsets.fromLTRB(18, 16, 12, 16),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: AppColors.border, width: 1.5),
                boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 8, offset: const Offset(0, 2))],
              ),
              child: Row(
                children: [
                  Expanded(child: Text('Where does your parcel need to go?', style: typo.searchHint)),
                  Container(
                    width: 32,
                    height: 32,
                    decoration: BoxDecoration(
                      color: AppColors.primary,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    alignment: Alignment.center,
                    child: Text('→', style: typo.body.copyWith(color: Colors.white, fontWeight: FontWeight.w700)),
                  ),
                ],
              ),
            ),
            ),
            const SizedBox(height: 24),
            Text('Quick actions', style: typo.h3.copyWith(fontWeight: FontWeight.w700)),
            const SizedBox(height: 12),
            _menuLink(
              context,
              iconAsset: AppIcons.parcel,
              title: 'Create Delivery',
              subtitle: 'Post a new delivery request.',
              route: '/delivery-type',
              requireVerification: true,
              requireWalletBalance: true,
            ),
            _menuLink(
              context,
              iconAsset: AppIcons.postedParcels,
              title: 'My Posted Deliveries',
              subtitle: 'View all deliveries you have posted.',
              route: '/my-posted-parcels',
            ),
            _menuLink(
              context,
              iconAsset: AppIcons.notification,
              title: 'Notifications',
              subtitle: 'View delivery updates and important alerts.',
              route: '/sender-notifications',
              showUnreadBadge: true,
            ),
            SizedBox(height: context.blockGap),
            Text('Active deliveries', style: typo.h3.copyWith(fontWeight: FontWeight.w700)),
            const SizedBox(height: 12),
            GestureDetector(
              onTap: () => context.push(
                StaticData.senderParcelOpenRoute(shipment.id),
              ),
              child: AppCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(shipment.id, style: typo.h3.copyWith(fontWeight: FontWeight.w700)),
                        AppBadge.status(shipment.status, semiBold: true, wide: true),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(shipment.route, style: typo.sm),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _menuLink(
    BuildContext context, {
    String? iconAsset,
    IconData? icon,
    required String title,
    required String subtitle,
    required String route,
    bool showUnreadBadge = false,
    bool requireVerification = false,
    bool requireWalletBalance = false,
  }) {
    final typo = context.typo;
    if (!showUnreadBadge) {
      return _menuLinkBody(
        context,
        typo: typo,
        iconAsset: iconAsset,
        icon: icon,
        title: title,
        subtitle: subtitle,
        route: route,
        requireVerification: requireVerification,
        requireWalletBalance: requireWalletBalance,
      );
    }
    return ValueListenableBuilder<int>(
      valueListenable: NotificationService.version,
      builder: (context, _, __) {
        final badge = NotificationService.unreadCount(WalletRole.sender);
        return _menuLinkBody(
          context,
          typo: typo,
          iconAsset: iconAsset,
          icon: icon,
          title: title,
          subtitle: subtitle,
          route: route,
          badge: badge,
          requireVerification: requireVerification,
          requireWalletBalance: requireWalletBalance,
        );
      },
    );
  }

  Widget _menuLinkBody(
    BuildContext context, {
    required AppTypography typo,
    String? iconAsset,
    IconData? icon,
    required String title,
    required String subtitle,
    required String route,
    int badge = 0,
    bool requireVerification = false,
    bool requireWalletBalance = false,
  }) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 10),
      child: Material(
        color: AppColors.surface,
        clipBehavior: Clip.antiAlias,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(14),
          side: const BorderSide(color: AppColors.border),
        ),
        child: InkWell(
          onTap: () {
            if (requireWalletBalance &&
                !DeliveryPostingActions.ensureWalletAllowsParcelCreation(context)) {
              return;
            }
            if (requireVerification && !AuthVerificationGuard.ensureVerifiedForTransaction(context)) {
              return;
            }
            if (requireVerification && !KycVerificationGuard.ensureKycApproved(context)) {
              return;
            }
            context.push(route);
          },
          hoverColor: Colors.transparent,
          splashColor: Colors.transparent,
          highlightColor: Colors.transparent,
          splashFactory: NoSplash.splashFactory,
          overlayColor: const WidgetStatePropertyAll(Colors.transparent),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                if (iconAsset != null)
                  AppSvgIcon(asset: iconAsset, size: 28)
                else
                  Icon(icon, size: 28, color: AppColors.textPrimary),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(title, style: typo.bodyBold.copyWith(fontWeight: FontWeight.w700)),
                      const SizedBox(height: 2),
                      Text(subtitle, style: typo.sm),
                    ],
                  ),
                ),
                if (badge > 0) ...[
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: AppColors.primary,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(
                      '$badge',
                      style: typo.caption.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                ],
                const Icon(Icons.chevron_right_rounded, size: 22, color: AppColors.textSecondary),
              ],
            ),
          ),
        ),
      ),
    );
  }

}
