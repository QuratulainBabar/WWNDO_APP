import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_typography.dart';
import '../../core/widgets/app_svg_icon.dart';

class ReceiverShell extends StatelessWidget {
  const ReceiverShell({super.key, required this.navigationShell});

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
                _Tab(
                  navigationShell: navigationShell,
                  index: 0,
                  icon: _TabIcon.svg(AppIcons.home),
                  label: 'Home',
                ),
                _Tab(
                  navigationShell: navigationShell,
                  index: 1,
                  icon: _TabIcon.svg(AppIcons.parcel),
                  label: 'Shipments',
                ),
                _Tab(
                  navigationShell: navigationShell,
                  index: 2,
                  icon: _TabIcon.svg(AppIcons.chat),
                  label: 'Chat',
                ),
                _Tab(
                  navigationShell: navigationShell,
                  index: 3,
                  icon: const _TabIcon.material(Icons.notifications_outlined),
                  label: 'Alerts',
                ),
                _Tab(
                  navigationShell: navigationShell,
                  index: 4,
                  icon: _TabIcon.svg(AppIcons.profile),
                  label: 'Profile',
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _TabIcon {
  const _TabIcon.svg(this.asset) : icon = null;
  const _TabIcon.material(this.icon) : asset = null;

  final String? asset;
  final IconData? icon;
}

class _Tab extends StatelessWidget {
  const _Tab({
    required this.navigationShell,
    required this.index,
    required this.icon,
    required this.label,
  });

  final StatefulNavigationShell navigationShell;
  final int index;
  final _TabIcon icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    final typo = context.typo;
    final active = navigationShell.currentIndex == index;
    final color = active ? AppColors.primary : AppColors.textSecondary;

    return Expanded(
      child: InkWell(
        onTap: () => navigationShell.goBranch(index, initialLocation: true),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (icon.asset != null)
              AppSvgIcon(asset: icon.asset!, size: 22, color: color)
            else
              Icon(icon.icon, size: 22, color: color),
            const SizedBox(height: 3),
            Text(
              label,
              style: typo.tabLabelActive(color),
            ),
          ],
        ),
      ),
    );
  }
}
