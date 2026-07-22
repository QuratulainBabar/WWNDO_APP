import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_typography.dart';
import '../../core/widgets/app_button.dart';
import '../../core/widgets/app_card.dart';
import '../../core/widgets/app_toast.dart';
import '../../core/widgets/back_header.dart';
import '../../core/widgets/cancel_request_confirmation_dialog.dart';
import '../../core/widgets/scrollable_form_screen.dart';
import '../../data/models/shipment.dart';
import '../../data/static_data.dart';

class CancelPostedDeliveryScreen extends StatelessWidget {
  const CancelPostedDeliveryScreen({super.key, required this.shipmentId});

  final String shipmentId;

  Shipment get _parcel =>
      StaticData.shipmentById(shipmentId) ??
      StaticData.senderShipments.firstWhere(
        (s) => s.id == shipmentId,
        orElse: () => StaticData.activeShipment,
      );

  Future<void> _confirmCancel(BuildContext context) async {
    final parcel = _parcel;
    if (!StaticData.canSenderCancelBeforeTravel(parcel.travelDate)) {
      AppToast.error(context, StaticData.senderCancelBlockedMessage);
      return;
    }

    final confirmed = await showCancelRequestConfirmation(context);
    if (!confirmed || !context.mounted) return;

    final cancelled = StaticData.cancelOpenBidDelivery(shipmentId);
    if (!cancelled) {
      AppToast.error(context, StaticData.senderCancelBlockedMessage);
      return;
    }

    AppToast.success(context, '${parcel.id} cancelled');
    context.go('/track');
  }

  @override
  Widget build(BuildContext context) {
    final typo = context.typo;
    final parcel = _parcel;
    final canCancel = StaticData.canSenderCancelBeforeTravel(parcel.travelDate);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: BackHeader(
        title: 'Cancel ${parcel.id}',
        fallbackRoute: '/track',
      ),
      body: ScrollableFormScreen(
        actions: [
          AppButton(
            label: 'Cancel delivery',
            variant: AppButtonVariant.danger,
            onPressed: () => _confirmCancel(context),
          ),
          AppButton(
            label: 'Keep delivery',
            variant: AppButtonVariant.ghost,
            onPressed: () => context.pop(),
          ),
        ],
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Are you sure you want to cancel this delivery?',
              style: typo.h3.copyWith(fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 8),
            Text(
              'This will remove your parcel request. Matching travelers will no longer see this delivery.',
              style: typo.sm.copyWith(color: AppColors.textSecondary),
            ),
            const SizedBox(height: 12),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: canCancel
                    ? AppColors.success.withValues(alpha: 0.1)
                    : AppColors.danger.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                canCancel
                    ? 'You can cancel this request because it is still more than '
                        '${StaticData.senderCancelMinHoursBeforeTravel} hours before the flight.'
                    : StaticData.senderCancelBlockedMessage,
                style: typo.sm.copyWith(
                  height: 1.45,
                  color: canCancel ? AppColors.success : AppColors.danger,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: AppCard(
                margin: EdgeInsets.zero,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      parcel.route,
                      style: typo.h3.copyWith(fontWeight: FontWeight.w800),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      DateFormat('MMM d, yyyy').format(parcel.travelDate),
                      style: typo.sm.copyWith(color: AppColors.textSecondary),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${parcel.parcelCategory} · ${parcel.parcelWeightKg} kg',
                      style: typo.sm.copyWith(
                        color: AppColors.primary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
