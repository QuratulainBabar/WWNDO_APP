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
import '../../data/models/created_delivery.dart';
import '../../data/models/wallet_role.dart';
import '../../data/platform_fees.dart';
import '../../data/services/delivery_repository.dart';
import '../../data/services/trip_repository.dart';
import '../../data/wallet_gate.dart';
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
  bool _loading = true;
  CreatedDelivery? _delivery;
  String? _error;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _loadDelivery());
  }

  DeliveryRepository _deliveryRepo() {
    final auth = context.read<AuthProvider>();
    return DeliveryRepository(
      apiClient: auth.repository.apiClient,
      demoMode: context.read<DemoModeProvider>(),
    );
  }

  TripRepository _tripRepo() {
    final auth = context.read<AuthProvider>();
    final demo = context.read<DemoModeProvider>();
    return TripRepository(
      apiClient: auth.repository.apiClient,
      demoMode: demo,
    );
  }

  Future<void> _loadDelivery() async {
    if (context.read<DemoModeProvider>().enabled) {
      setState(() {
        _loading = false;
        _error = 'Turn off Demo mode to complete live escrow payment.';
      });
      return;
    }
    try {
      final delivery = await _deliveryRepo().getDelivery(
        widget.acceptance.shipmentId,
        role: 'sender',
      );
      if (!mounted) return;
      setState(() {
        _delivery = delivery;
        _loading = false;
      });
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _error = e.message;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _error = 'Unable to load delivery details.';
      });
    }
  }

  Future<void> _payNow() async {
    if (_paying) return;
    final acceptance = widget.acceptance;

    setState(() => _paying = true);
    try {
      final offerId = acceptance.offerId;
      if (offerId == null || offerId.isEmpty) {
        AppToast.error(context, 'Counter offer reference is missing.');
        return;
      }
      await _tripRepo().acceptSenderCounterOffer(offerId);
      if (!mounted) return;
      await WalletGate.refreshRoles(
        context,
        [WalletRole.sender, WalletRole.traveler, WalletRole.receiver],
      );

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
    if (_loading) {
      return Scaffold(
        backgroundColor: AppColors.background,
        appBar: const BackHeader(title: 'Payment Summary'),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    if (_error != null) {
      return Scaffold(
        backgroundColor: AppColors.background,
        appBar: const BackHeader(title: 'Payment Summary'),
        body: Center(
          child: Padding(
            padding: context.pagePadding,
            child: Text(_error!, textAlign: TextAlign.center),
          ),
        ),
      );
    }

    final acceptance = widget.acceptance;
    final bid = acceptance.bid;
    final delivery = _delivery;
    final category = delivery?.parcelCategory ?? acceptance.parcelCategory;
    final paysReceiver = delivery != null
        ? PlatformFees.senderPaysReceiverFee(delivery)
        : acceptance.paysReceiverFee;
    final platformFee = PlatformFees.senderPlatformFeeUsd(
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
                  const Divider(height: 24),
                  _detailRow(
                    context,
                    'Total due now',
                    '\$${total.toStringAsFixed(2)}',
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
    bool primary = false,
  }) {
    final typo = context.typo;
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: typo.sm),
          Text(
            value,
            style: primary
                ? typo.h3.copyWith(
                    fontWeight: FontWeight.w700,
                    color: AppColors.primary,
                  )
                : typo.bodyBold.copyWith(fontWeight: FontWeight.w700),
          ),
        ],
      ),
    );
  }
}
