import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../core/auth/kyc_verification_guard.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_typography.dart';
import '../../core/widgets/app_button.dart';
import '../../core/widgets/app_card.dart';
import '../../core/widgets/app_svg_icon.dart';
import '../../core/widgets/back_link.dart';
import '../../core/widgets/screen_body.dart';
import 'delivery_posting_actions.dart';

enum _DeliveryType { cityToCity, countryToCountry }

class DeliveryTypeSelectionScreen extends StatefulWidget {
  const DeliveryTypeSelectionScreen({super.key});

  @override
  State<DeliveryTypeSelectionScreen> createState() =>
      _DeliveryTypeSelectionScreenState();
}

class _DeliveryTypeSelectionScreenState
    extends State<DeliveryTypeSelectionScreen> {
  _DeliveryType? _selectedType;

  Future<void> _selectType(_DeliveryType type) async {
    setState(() => _selectedType = type);
    await DeliveryPostingActions.ensureWalletAllowsParcelCreation(context);
  }

  Future<void> _continue() async {
    if (!await DeliveryPostingActions.ensureWalletAllowsParcelCreation(context)) return;
    if (!KycVerificationGuard.ensureKycApproved(context)) return;
    switch (_selectedType) {
      case _DeliveryType.cityToCity:
        context.push('/post-delivery');
        break;
      case _DeliveryType.countryToCountry:
        context.push('/post-delivery/country-to-country');
        break;
      case null:
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    final typo = context.typo;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: ScreenBody(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const BackLink(fallbackRoute: '/home'),
            const SizedBox(height: 16),
            Text('Choose delivery type', style: typo.h1),
            const SizedBox(height: 8),
            Text(
              'Select how you want to send your parcel.',
              style: typo.subheading,
            ),
            const SizedBox(height: 24),
            _DeliveryTypeCard(
              iconAsset: AppIcons.track,
              title: 'City to City',
              description: 'Send parcels between cities on a domestic route.',
              selected: _selectedType == _DeliveryType.cityToCity,
              onTap: () => _selectType(_DeliveryType.cityToCity),
            ),
            _DeliveryTypeCard(
              icon: Icons.public_rounded,
              title: 'Country to Country',
              description: 'Send parcels across international borders.',
              selected: _selectedType == _DeliveryType.countryToCountry,
              onTap: () => _selectType(_DeliveryType.countryToCountry),
            ),
            const SizedBox(height: 8),
            AppButton(
              label: 'Continue',
              onPressed: _selectedType == null ? null : _continue,
            ),
          ],
        ),
      ),
    );
  }
}

class _DeliveryTypeCard extends StatelessWidget {
  const _DeliveryTypeCard({
    this.iconAsset,
    this.icon,
    required this.title,
    required this.description,
    required this.selected,
    required this.onTap,
  }) : assert(iconAsset != null || icon != null);

  final String? iconAsset;
  final IconData? icon;
  final String title;
  final String description;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final typo = context.typo;

    return AppCard(
      highlighted: selected,
      margin: const EdgeInsets.only(bottom: 12),
      padding: EdgeInsets.zero,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(16),
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
                  child: iconAsset != null
                      ? AppSvgIcon(
                          asset: iconAsset!,
                          size: 22,
                          color: AppColors.primary,
                        )
                      : Icon(icon, size: 22, color: AppColors.primary),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: typo.bodyBold.copyWith(fontWeight: FontWeight.w700),
                      ),
                      const SizedBox(height: 2),
                      Text(description, style: typo.sm),
                    ],
                  ),
                ),
                Icon(
                  selected
                      ? Icons.check_circle_rounded
                      : Icons.radio_button_unchecked_rounded,
                  color: selected ? AppColors.primary : AppColors.textSecondary,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
