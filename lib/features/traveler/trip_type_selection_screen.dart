import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../core/auth/kyc_verification_guard.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_typography.dart';
import '../../core/widgets/app_button.dart';
import '../../core/widgets/app_card.dart';
import '../../core/widgets/app_svg_icon.dart';
import '../../core/widgets/back_link.dart';
import '../../core/widgets/screen_body.dart';
import '../../data/models/wallet_role.dart';
import '../../data/platform_fees.dart';
import '../../data/wallet_gate.dart';
import '../../data/wallet_service.dart';
import '../../l10n/app_localizations.dart';

enum _TripType { cityToCity, countryToCountry }

class TripTypeSelectionScreen extends StatefulWidget {
  const TripTypeSelectionScreen({super.key});

  @override
  State<TripTypeSelectionScreen> createState() => _TripTypeSelectionScreenState();
}

class _TripTypeSelectionScreenState extends State<TripTypeSelectionScreen> {
  _TripType? _selectedType;

  Future<void> _continue() async {
    if (_selectedType == null) return;
    if (!KycVerificationGuard.ensureKycApproved(context)) return;

    // Prefer cached balance so navigation is instant; only hit the network
    // when the local wallet is short of the $3 trip minimum.
    final cachedOk =
        WalletService.availableUsd(WalletRole.traveler) >=
        PlatformFees.minWalletTravelerUsd;
    if (!cachedOk) {
      if (!await WalletGate.ensureTravelerTripCreation(context)) return;
      if (!mounted) return;
    }

    switch (_selectedType) {
      case _TripType.cityToCity:
        context.push('/post-trip');
        break;
      case _TripType.countryToCountry:
        context.push('/post-trip/country-to-country');
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
            const BackLink(),
            const SizedBox(height: 16),
            Text('Choose trip type', style: typo.h1),
            const SizedBox(height: 8),
            Text(
              'Select the type of trip you want to post.',
              style: typo.subheading,
            ),
            const SizedBox(height: 24),
            _TripTypeCard(
              iconAsset: AppIcons.track,
              title: 'City to City',
              description: 'Share a domestic route between two cities.',
              selected: _selectedType == _TripType.cityToCity,
              onTap: () => setState(() => _selectedType = _TripType.cityToCity),
            ),
            _TripTypeCard(
              icon: Icons.public_rounded,
              title: 'Country to Country',
              description: 'Share an international route across borders.',
              selected: _selectedType == _TripType.countryToCountry,
              onTap: () => setState(() => _selectedType = _TripType.countryToCountry),
            ),
            const SizedBox(height: 8),
            AppButton(
              label: context.tr('Continue'),
              onPressed: _selectedType == null ? null : _continue,
            ),
          ],
        ),
      ),
    );
  }
}

class _TripTypeCard extends StatelessWidget {
  const _TripTypeCard({
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
