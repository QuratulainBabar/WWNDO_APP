import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_typography.dart';
import '../../core/widgets/app_card.dart';
import '../../core/widgets/app_svg_icon.dart';
import '../../core/widgets/back_link.dart';
import '../../core/widgets/screen_body.dart';
import '../../core/widgets/wallet_card.dart';
import '../../data/models/traveler_trip.dart';
import '../../data/models/wallet_role.dart';
import '../../core/auth/kyc_verification_guard.dart';
import '../../core/auth/auth_verification_guard.dart';
import '../../data/static_data.dart';
import 'trip_posting_actions.dart';

class TravelerHomeScreen extends StatelessWidget {
  const TravelerHomeScreen({super.key});

  void _onCreateTrip(BuildContext context) {
    // Wallet balance gate first — must not be masked by auth/KYC dialogs.
    if (!TripPostingActions.ensureWalletAllowsTripCreation(context)) return;
    if (!AuthVerificationGuard.ensureVerifiedForTransaction(context)) return;
    if (!KycVerificationGuard.ensureKycApproved(context)) return;
    context.push('/trip-type');
  }

  @override
  Widget build(BuildContext context) {
    final typo = context.typo;
    final user = StaticData.travelerUser;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: ScreenBody(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
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
                      Text('★ ${user.rating} · Traveler', style: typo.sm),
                    ],
                  ),
                ),
                WalletCard(role: WalletRole.traveler),
              ],
            ),
            const SizedBox(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Text('My Trips', style: typo.h3.copyWith(fontWeight: FontWeight.w700)),
                GestureDetector(
                  onTap: () => _onCreateTrip(context),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    decoration: BoxDecoration(
                      color: AppColors.primary,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          '+',
                          style: typo.buttonSm.copyWith(
                            color: Colors.white,
                            fontWeight: FontWeight.w600,
                            fontSize: 18,
                          ),
                        ),
                        const SizedBox(width: 4),
                        Text(
                          'Create Trip',
                          style: typo.buttonSm.copyWith(
                            color: Colors.white,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            _myTripsSection(context),
            const SizedBox(height: 24),
            Text('Quick actions', style: typo.h3.copyWith(fontWeight: FontWeight.w700)),
            const SizedBox(height: 12),
            Row(
              children: [
                _quickAction(context, AppIcons.roleSender, 'Sender Requests', () => context.push('/matching-requests')),
                const SizedBox(width: 10),
                _quickAction(context, AppIcons.track, 'My deliveries', () => context.push('/traveler-deliveries')),
              ],
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                _quickAction(context, AppIcons.history, 'Counter offers', () => context.push('/traveler-bids')),
                const SizedBox(width: 10),
                const Expanded(child: SizedBox()),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _myTripsSection(BuildContext context) {
    StaticData.purgeFranceSenegalOpenTripOnce();
    return ValueListenableBuilder<int>(
      valueListenable: StaticData.travelerPostedTripsVersion,
      builder: (context, _, _) {
        final trips = StaticData.travelerPostedTrips;
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            for (var i = 0; i < trips.length; i++) ...[
              if (i > 0) const SizedBox(height: 10),
              _tripCard(context, trips[i]),
            ],
          ],
        );
      },
    );
  }

  Widget _tripCard(BuildContext context, TravelerTrip trip) {
    final typo = context.typo;
    return AppCard(
      margin: EdgeInsets.zero,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(trip.route, style: typo.h3.copyWith(fontWeight: FontWeight.w800), maxLines: 2, overflow: TextOverflow.ellipsis),
          const SizedBox(height: 6),
          Text(
            DateFormat('MMM d, yyyy').format(trip.travelDate),
            style: typo.sm.copyWith(color: AppColors.textSecondary),
          ),
          const SizedBox(height: 4),
          Text(
            '${trip.luggageCapacityKg.toStringAsFixed(0)} kg luggage available',
            style: typo.sm.copyWith(color: AppColors.primary, fontWeight: FontWeight.w600),
          ),
        ],
      ),
    );
  }

  Widget _quickAction(BuildContext context, String iconAsset, String label, VoidCallback onTap) {
    final typo = context.typo;
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          constraints: const BoxConstraints(minHeight: 98),
          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 16),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: AppColors.border),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              AppSvgIcon(asset: iconAsset, size: 28, color: AppColors.primary),
              const SizedBox(height: 10),
              Text(
                label,
                textAlign: TextAlign.center,
                style: typo.actionLabel.copyWith(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textPrimary,
                  height: 1.2,
                ),
                maxLines: 2,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
