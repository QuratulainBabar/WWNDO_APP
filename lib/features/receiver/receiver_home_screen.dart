import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_typography.dart';
import '../../core/widgets/app_badge.dart';
import '../../core/widgets/app_card.dart';
import '../../core/widgets/app_svg_icon.dart';
import '../../core/widgets/back_link.dart';
import '../../core/widgets/screen_body.dart';
import '../../data/models/wallet_role.dart';
import '../../data/models/shipment.dart';
import '../../data/static_data.dart';
import '../../core/widgets/wallet_card.dart';

class ReceiverHomeScreen extends StatelessWidget {
  const ReceiverHomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final typo = context.typo;
    final user = StaticData.receiverUser;

    return ValueListenableBuilder<int>(
      valueListenable: StaticData.nfcCheckpointVersion,
      builder: (context, _, __) {
        final shipment = StaticData.receiverActiveShipment;
        final status = StaticData.effectiveStatus(shipment);

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
                          Text('Receiver · Track incoming parcels', style: typo.sm),
                        ],
                      ),
                    ),
                    WalletCard(role: WalletRole.receiver),
                  ],
                ),
                const SizedBox(height: 24),
                Text(
                  status == ShipmentStatus.delivered ? 'Latest parcel' : 'Incoming parcel',
                  style: typo.h3.copyWith(fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 12),
                GestureDetector(
                  onTap: () => context.push(
                    '/receiver-tracking?shipmentId=${shipment.id}',
                  ),
                  child: AppCard(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(shipment.id, style: typo.h3.copyWith(fontWeight: FontWeight.w700)),
                            AppBadge.status(status, semiBold: true, wide: true),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Text(shipment.route, style: typo.sm),
                        const SizedBox(height: 8),
                        Text(
                          'Traveler: ${shipment.travelerName} · ${shipment.flightNumber}',
                          style: typo.sm,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Arriving ${DateFormat('MMM d, yyyy').format(shipment.travelDate)}',
                          style: typo.sm.copyWith(color: AppColors.primary, fontWeight: FontWeight.w600),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                Text('Quick actions', style: typo.h3.copyWith(fontWeight: FontWeight.w700)),
                const SizedBox(height: 12),
                Row(
                  children: [
                    _action(context, AppIcons.track, 'Track parcel', () => context.go('/receiver-shipments')),
                    const SizedBox(width: 10),
                    _action(context, AppIcons.chat, 'Chat traveler', () => context.go('/receiver-chats')),
                  ],
                ),
                const SizedBox(height: 24),
                Text('What to expect', style: typo.h3.copyWith(fontWeight: FontWeight.w700)),
                const SizedBox(height: 12),
                AppCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _tip(context, '1', 'Track your parcel in real time as the traveler carries it.'),
                      const SizedBox(height: 10),
                      _tip(context, '2', 'Chat with the traveler to coordinate handover details.'),
                      const SizedBox(height: 10),
                      _tip(context, '3', 'Confirm delivery via NFC when you meet the traveler.'),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _action(BuildContext context, String iconAsset, String label, VoidCallback onTap) {
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
              AppSvgIcon(asset: iconAsset, size: 28),
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

  Widget _tip(BuildContext context, String step, String text) {
    final typo = context.typo;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 24,
          height: 24,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: AppColors.primary.withValues(alpha: 0.1),
            shape: BoxShape.circle,
          ),
          child: Text(step, style: typo.sm.copyWith(color: AppColors.primary, fontWeight: FontWeight.w700)),
        ),
        const SizedBox(width: 10),
        Expanded(child: Text(text, style: typo.sm)),
      ],
    );
  }
}
