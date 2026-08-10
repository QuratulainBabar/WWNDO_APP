import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../core/api/api_exception.dart';
import '../../core/config/demo_mode.dart';
import '../../core/layout/responsive.dart';
import '../../core/platform/platform_ui.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_typography.dart';
import '../../core/widgets/app_badge.dart';
import '../../core/widgets/app_button.dart';
import '../../core/widgets/app_card.dart';
import '../../core/widgets/app_toast.dart';
import '../../core/widgets/back_header.dart';
import '../../data/models/bid.dart';
import '../../data/services/trip_repository.dart';
import '../../data/static_data.dart';
import '../../providers/auth_provider.dart';

class BidAcceptanceContext {
  const BidAcceptanceContext({
    required this.bid,
    required this.shipmentId,
    this.offerId,
    this.parcelCategory = 'documents',
    this.paysReceiverFee = false,
  });

  final Bid bid;
  final String shipmentId;
  final String? offerId;
  final String parcelCategory;
  final bool paysReceiverFee;
}

class BidAcceptancePaymentScreen extends StatefulWidget {
  const BidAcceptancePaymentScreen({super.key, required this.acceptance});

  final BidAcceptanceContext acceptance;

  @override
  State<BidAcceptancePaymentScreen> createState() =>
      _BidAcceptancePaymentScreenState();
}

class _BidAcceptancePaymentScreenState extends State<BidAcceptancePaymentScreen> {
  bool _paying = false;

  TripRepository _tripRepo() {
    final auth = context.read<AuthProvider>();
    final demo = context.read<DemoModeProvider>();
    return TripRepository(
      apiClient: auth.repository.apiClient,
      demoMode: demo,
    );
  }

  Future<void> _payNow() async {
    if (_paying) return;
    final acceptance = widget.acceptance;
    final demo = context.read<DemoModeProvider>().enabled;

    setState(() => _paying = true);
    try {
      if (demo) {
        final ok = StaticData.acceptBid(
          shipmentId: acceptance.shipmentId,
          bid: acceptance.bid,
        );
        if (!ok) {
          if (!mounted) return;
          AppToast.error(
            context,
            'Payment failed. Booking was not created. Check wallet or card and try again.',
          );
          return;
        }
      } else {
        final offerId = acceptance.offerId;
        if (offerId == null || offerId.isEmpty) {
          AppToast.error(context, 'Counter offer reference is missing.');
          return;
        }
        await _tripRepo().acceptSenderCounterOffer(offerId);
      }

      if (!mounted) return;
      context.push('/bid-payment-success', extra: acceptance);
    } on ApiException catch (e) {
      if (!mounted) return;
      AppToast.error(context, e.message);
    } catch (_) {
      if (!mounted) return;
      AppToast.error(
        context,
        'Payment failed. Booking was not created. Check wallet or card and try again.',
      );
    } finally {
      if (mounted) setState(() => _paying = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final acceptance = widget.acceptance;
    final bid = acceptance.bid;
    final shipment = StaticData.shipmentById(acceptance.shipmentId);
    final category =
        shipment?.parcelCategory ?? acceptance.parcelCategory;
    final paysReceiver = shipment != null
        ? StaticData.paysReceiverFeeFor(acceptance.shipmentId)
        : acceptance.paysReceiverFee;
    final platformFee = StaticData.senderPlatformFeeUsd(
      category: category,
      paysReceiverFee: paysReceiver,
    );
    final total = bid.price + platformFee;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: const BackHeader(title: 'Payment Summary'),
      body: SingleChildScrollView(
        physics: PlatformUi.scrollPhysics,
        padding: context.pagePadding,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            AppCard(
              margin: EdgeInsets.zero,
              child: Column(
                children: [
                  _detailRow(context, 'Accepted traveler', bid.travelerName),
                  _detailRow(context, 'Parcel ID', acceptance.shipmentId),
                  _detailRow(
                    context,
                    'Accepted bid amount',
                    '\$${bid.price.toStringAsFixed(2)}',
                  ),
                  const Divider(height: 24),
                  _detailRow(
                    context,
                    'Your platform fee',
                    '\$${platformFee.toStringAsFixed(2)}',
                  ),
                  if (paysReceiver)
                    _detailRow(
                      context,
                      'Includes receiver fee',
                      'Yes',
                    ),
                  _detailRow(
                    context,
                    'Total amount to pay',
                    '\$${total.toStringAsFixed(2)}',
                    bold: true,
                    primary: true,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            const Wrap(
              spacing: 6,
              runSpacing: 6,
              children: [
                AppBadge.success('✓ Escrow protected'),
                AppBadge.success('✓ Secure payment'),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              'If your wallet balance is insufficient, the shortfall is charged to your card. '
              'Sender, traveler, and receiver platform fees are collected instantly. '
              'The booking is not created if any payment fails.',
              style: context.typo.sm.copyWith(
                color: AppColors.textSecondary,
                height: 1.4,
              ),
            ),
            const SizedBox(height: 24),
            AppButton(
              label: _paying ? 'Processing…' : 'Pay Now',
              onPressed: _paying ? null : _payNow,
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
