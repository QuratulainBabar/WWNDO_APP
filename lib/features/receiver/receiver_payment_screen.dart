import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../core/layout/responsive.dart';
import '../../core/platform/platform_ui.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_typography.dart';
import '../../core/widgets/app_badge.dart';
import '../../core/widgets/app_button.dart';
import '../../core/widgets/app_card.dart';
import '../../core/widgets/app_toast.dart';
import '../../core/widgets/back_header.dart';
import '../../data/models/shipment.dart';
import '../../data/static_data.dart';
import 'receiver_payment_success_screen.dart';

class ReceiverPaymentScreen extends StatelessWidget {
  const ReceiverPaymentScreen({super.key, this.shipment});

  final Shipment? shipment;

  Shipment get _shipment {
    if (shipment != null) return shipment!;
    final pending = StaticData.receiverShipments.where(
      (s) => StaticData.effectiveStatus(s) == ShipmentStatus.bidAccepted,
    );
    return pending.isNotEmpty ? pending.first : StaticData.receiverActiveShipment;
  }

  @override
  Widget build(BuildContext context) {
    final typo = context.typo;
    final s = _shipment;
    final totalFee = StaticData.platformFeeInternational;
    final receiverShare = StaticData.platformFeeShare;
    final senderShare = totalFee - receiverShare;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: const BackHeader(title: 'Payment'),
      body: SingleChildScrollView(
        physics: PlatformUi.scrollPhysics,
        padding: context.pagePadding,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            AppBadge.status(ShipmentStatus.bidAccepted, semiBold: true, wide: true),
            const SizedBox(height: 16),
            AppCard(
              margin: EdgeInsets.zero,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _detailRow(context, 'Parcel ID', s.id),
                  _detailRow(context, 'Route', s.route),
                  const Divider(height: 24),
                  Text(
                    'Platform fee',
                    style: typo.h3.copyWith(fontWeight: FontWeight.w700),
                  ),
                  const SizedBox(height: 8),
                  _detailRow(
                    context,
                    'Total platform fee',
                    '\$${totalFee.toStringAsFixed(2)}',
                  ),
                  _detailRow(
                    context,
                    'Receiver pays 50%',
                    '\$${receiverShare.toStringAsFixed(2)}',
                  ),
                  _detailRow(
                    context,
                    'Sender pays 50%',
                    '\$${senderShare.toStringAsFixed(2)}',
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Remaining 50% is paid by Sender',
                    style: typo.sm.copyWith(color: AppColors.textSecondary),
                  ),
                  const Divider(height: 24),
                  _detailRow(
                    context,
                    'Amount to Pay',
                    '\$${receiverShare.toStringAsFixed(2)}',
                    bold: true,
                    primary: true,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: [
                AppBadge.success('✓ Secure payment'),
                AppBadge.success('✓ 50% fee share'),
              ],
            ),
            const SizedBox(height: 24),
            AppButton(
              label: 'Pay Now',
              onPressed: () {
                final paid = StaticData.approveReceiverFeeShare(
                  shipment: s,
                  feeAmount: receiverShare,
                );
                if (!paid) {
                  AppToast.error(
                    context,
                    'Payment failed. Check wallet or card and try again.',
                  );
                  return;
                }
                context.push(
                  '/receiver-payment-confirmed',
                  extra: ReceiverPaymentResult(
                    shipmentId: s.id,
                    feeAmount: receiverShare,
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _detailRow(
    BuildContext context,
    String label,
    String value, {
    bool bold = false,
    bool primary = false,
  }) {
    final typo = context.typo;
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: typo.sm),
          const SizedBox(width: 16),
          Flexible(
            child: Text(
              value,
              textAlign: TextAlign.right,
              style: (bold ? typo.bodyBold : typo.body).copyWith(
                fontWeight: bold ? FontWeight.w700 : FontWeight.w600,
                color: primary ? AppColors.primary : AppColors.textPrimary,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
