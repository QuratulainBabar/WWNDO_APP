import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../core/config/demo_mode.dart';
import '../../core/layout/responsive.dart';
import '../../core/payments/platform_fee_payment.dart';
import '../../core/platform/platform_ui.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_typography.dart';
import '../../core/widgets/app_badge.dart';
import '../../core/widgets/app_button.dart';
import '../../core/widgets/app_card.dart';
import '../../core/widgets/app_toast.dart';
import '../../core/widgets/back_header.dart';
import '../../core/widgets/stacked_route_endpoints.dart';
import '../../data/models/shipment.dart';
import '../../data/models/wallet_role.dart';
import '../../data/services/platform_repository.dart';
import '../../data/platform_fees.dart';
import '../../data/static_data.dart';
import '../../data/wallet_service.dart';
import '../../providers/auth_provider.dart';
import 'receiver_payment_success_screen.dart';

class ReceiverPaymentScreen extends StatefulWidget {
  const ReceiverPaymentScreen({super.key, this.shipment});

  final Shipment? shipment;

  @override
  State<ReceiverPaymentScreen> createState() => _ReceiverPaymentScreenState();
}

class _ReceiverPaymentScreenState extends State<ReceiverPaymentScreen> {
  bool _paying = false;

  Shipment? get _demoShipment {
    final pending = StaticData.receiverShipments.where(
      (s) => StaticData.effectiveStatus(s) == ShipmentStatus.bidAccepted,
    );
    return pending.isNotEmpty ? pending.first : StaticData.receiverActiveShipment;
  }

  Shipment? _shipmentFor(BuildContext context) {
    if (widget.shipment != null) return widget.shipment;
    if (context.read<DemoModeProvider>().enabled) return _demoShipment;
    return null;
  }

  PlatformRepository _platformRepo() {
    final auth = context.read<AuthProvider>();
    return PlatformRepository(apiClient: auth.repository.apiClient);
  }

  Future<void> _pay(BuildContext context, Shipment shipment, double receiverShare) async {
    if (_paying) return;
    final demoMode = context.read<DemoModeProvider>().enabled;
    setState(() => _paying = true);
    try {
      if (!demoMode) {
        final feeCents = (receiverShare * 100).round();
        await PlatformFeePayment.withStripeRetry(
          context: context,
          role: WalletRole.receiver,
          attempt: (paymentIntentId) => _platformRepo().submitReceiverPayment(
            deliveryId: shipment.id,
            feeCents: feeCents,
            paymentIntentId: paymentIntentId,
          ),
        );
      } else {
        final paid = StaticData.approveReceiverFeeShare(
          shipment: shipment,
          feeAmount: receiverShare,
        );
        if (!paid) {
          if (mounted) {
            AppToast.error(
              context,
              'Payment failed. Check wallet or card and try again.',
            );
          }
          return;
        }
      }
      if (!mounted) return;
      context.push(
        '/receiver-payment-confirmed',
        extra: ReceiverPaymentResult(
          shipmentId: shipment.id,
          feeAmount: receiverShare,
        ),
      );
    } catch (e) {
      if (mounted) {
        AppToast.error(context, 'Payment failed: $e');
      }
    } finally {
      if (mounted) setState(() => _paying = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final typo = context.typo;
    final s = _shipmentFor(context);
    if (s == null) {
      return Scaffold(
        backgroundColor: AppColors.background,
        appBar: const BackHeader(title: 'Payment'),
        body: Center(
          child: Padding(
            padding: context.pagePadding,
            child: Text(
              'No parcel selected for payment. Open this screen from an incoming parcel request.',
              textAlign: TextAlign.center,
              style: typo.sm.copyWith(color: AppColors.textSecondary, height: 1.5),
            ),
          ),
        ),
      );
    }

    final receiverShare = PlatformFees.receiverPlatformFeeUsd(
      category: s.parcelCategory,
      paysReceiverFee: false,
    );
    final senderShare = PlatformFees.senderPlatformFeeUsd(
      category: s.parcelCategory,
      paysReceiverFee: false,
    );
    final totalFee = receiverShare + senderShare;

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
                  StackedRouteEndpoints(
                    from: s.fromCity,
                    to: s.toCity,
                    fallbackRoute: s.route,
                    sectionLabel: 'Route',
                    bottomPadding: 8,
                  ),
                  const Divider(height: 24),
                  Text(
                    'Platform fee',
                    style: typo.h3.copyWith(fontWeight: FontWeight.w700),
                  ),
                  const SizedBox(height: 8),
                  _detailRow(
                    context,
                    'Total platform fee',
                    WalletService.formatMajor(totalFee),
                  ),
                  _detailRow(
                    context,
                    'Receiver pays 50%',
                    WalletService.formatMajor(receiverShare),
                  ),
                  _detailRow(
                    context,
                    'Sender pays 50%',
                    WalletService.formatMajor(senderShare),
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
                    WalletService.formatMajor(receiverShare),
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
              label: _paying ? 'Processing…' : 'Pay Now',
              onPressed: _paying ? null : () => _pay(context, s, receiverShare),
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
