import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
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
import '../../core/widgets/back_header.dart';
import '../../core/widgets/cancel_request_confirmation_dialog.dart';
import '../../core/payments/platform_fee_payment.dart';
import '../../data/models/created_delivery.dart';
import '../../data/models/wallet_role.dart';
import '../../data/models/incoming_parcel_request.dart';
import '../../data/models/receiver_delivery_status.dart';
import '../../data/services/delivery_repository.dart';
import '../../data/platform_fees.dart';
import '../../data/wallet_gate.dart';
import '../../data/wallet_service.dart';
import '../../providers/auth_provider.dart';
import '../../providers/wallet_provider.dart';

class IncomingParcelRequestScreen extends StatefulWidget {
  const IncomingParcelRequestScreen({super.key, required this.requestId});

  final String requestId;

  @override
  State<IncomingParcelRequestScreen> createState() =>
      _IncomingParcelRequestScreenState();
}

class _IncomingParcelRequestScreenState
    extends State<IncomingParcelRequestScreen> {
  bool _loading = true;
  bool _acting = false;
  String? _error;
  CreatedDelivery? _delivery;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      context.read<WalletProvider>().refresh(WalletRole.receiver, silent: true);
      _load();
    });
  }

  DeliveryRepository _repo() {
    final auth = context.read<AuthProvider>();
    final demoMode = context.read<DemoModeProvider>();
    return DeliveryRepository(
      apiClient: auth.repository.apiClient,
      demoMode: demoMode,
    );
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final delivery = await _repo().getDelivery(
        widget.requestId,
        role: 'receiver',
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
        _error = 'Unable to load parcel request.';
      });
    }
  }

  IncomingParcelRequest? get _request =>
      _delivery?.toIncomingParcelRequest();

  Future<void> _accept() async {
    final delivery = _delivery;
    if (delivery == null || _acting) return;

    final paysReceiver = PlatformFees.senderPaysReceiverFee(delivery);
    final platformFee = PlatformFees.receiverPlatformFeeUsd(
      category: delivery.parcelCategory,
      paysReceiverFee: paysReceiver,
    );

    if (!await WalletGate.ensureReceiverAccept(
      context,
      category: delivery.parcelCategory,
      paysReceiverFee: paysReceiver,
      platformFeeUsd: platformFee,
    )) {
      return;
    }

    setState(() => _acting = true);
    try {
      CreatedDelivery updated;
      if (platformFee > 0) {
        updated = await PlatformFeePayment.withStripeRetry(
          context: context,
          role: WalletRole.receiver,
          attempt: (paymentIntentId) => _repo().acceptAsReceiver(
            delivery.displayId,
            paymentIntentId: paymentIntentId,
          ),
        );
      } else {
        updated = await _repo().acceptAsReceiver(delivery.displayId);
      }

      if (!mounted) return;
      setState(() {
        _delivery = updated;
        _acting = false;
      });
      await context.read<WalletProvider>().refresh(WalletRole.receiver, silent: true);
      if (!mounted) return;
      await _showAcceptedDialog(updated.displayId);
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() => _acting = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.message)),
      );
    } catch (_) {
      if (!mounted) return;
      setState(() => _acting = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Unable to accept this request.')),
      );
    }
  }

  Future<void> _reject() async {
    final delivery = _delivery;
    if (delivery == null || _acting) return;
    final confirmed = await showCancelRequestConfirmation(context);
    if (!confirmed || !mounted) return;

    setState(() => _acting = true);
    try {
      final updated = await _repo().declineAsReceiver(delivery.displayId);
      if (!mounted) return;
      setState(() {
        _delivery = updated;
        _acting = false;
      });
      context.pop();
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() => _acting = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.message)),
      );
    } catch (_) {
      if (!mounted) return;
      setState(() => _acting = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Unable to decline this request.')),
      );
    }
  }

  Future<void> _showAcceptedDialog(String id) async {
    await showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) {
        final typo = dialogContext.typo;
        return Dialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(24, 28, 24, 20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 64,
                  height: 64,
                  decoration: BoxDecoration(
                    color: AppColors.success.withValues(alpha: 0.12),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.check_rounded,
                    color: AppColors.success,
                    size: 36,
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  'Request Accepted!',
                  style: typo.h2.copyWith(fontWeight: FontWeight.w700),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),
                Text(
                  'Your parcel request has been accepted. We will match a traveler '
                      'and notify you once the sender completes payment.',
                  textAlign: TextAlign.center,
                  style: typo.sm.copyWith(
                    height: 1.5,
                    color: AppColors.textSecondary,
                  ),
                ),
                const SizedBox(height: 24),
                AppButton(
                  label: 'OK',
                  onPressed: () {
                    Navigator.of(dialogContext).pop();
                    context.go('/receiver-tracking?shipmentId=$id');
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final typo = context.typo;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: const BackHeader(title: 'Parcel Request'),
      body: _loading
          ? const Center(
              child: SizedBox(
                width: 22,
                height: 22,
                child: CircularProgressIndicator(
                  strokeWidth: 2.5,
                  color: AppColors.primary,
                ),
              ),
            )
          : _error != null || _request == null
              ? Center(
                  child: Padding(
                    padding: context.pagePadding,
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          _error ?? 'Parcel request not found.',
                          textAlign: TextAlign.center,
                          style: typo.sm.copyWith(color: AppColors.textSecondary),
                        ),
                        const SizedBox(height: 12),
                        TextButton(onPressed: _load, child: const Text('Retry')),
                      ],
                    ),
                  ),
                )
              : ValueListenableBuilder<int>(
                  valueListenable: WalletService.walletVersion,
                  builder: (context, _, __) {
                    final current = _request!;
                    final status = ReceiverDeliveryStatus.fromDelivery(_delivery!);
                    final walletBalance =
                        WalletService.availableUsd(WalletRole.receiver);
                    final paysReceiver =
                        PlatformFees.senderPaysReceiverFee(_delivery!);
                    final platformFee = PlatformFees.receiverPlatformFeeUsd(
                      category: _delivery!.parcelCategory,
                      paysReceiverFee: paysReceiver,
                    );
                    final requiredBalance = platformFee > 0
                        ? platformFee
                        : PlatformFees.minWalletReceiverUsd;
                    final canAccept = !_acting;
                    final isPending = status.isPendingRequest &&
                        current.status == IncomingParcelRequestStatus.pending;

                    return SingleChildScrollView(
                      physics: PlatformUi.scrollPhysics,
                      padding: context.pagePadding,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          AppBadge(
                            label: status.label,
                            color: status.color,
                            backgroundColor: status.backgroundColor,
                            semiBold: true,
                          ),
                          const SizedBox(height: 12),
                          Text(
                            '${current.senderName} wants to send you a parcel.',
                            style: typo.body.copyWith(
                              color: AppColors.textSecondary,
                            ),
                          ),
                          const SizedBox(height: 16),
                          AppCard(
                            margin: EdgeInsets.zero,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Parcel details',
                                  style: typo.h3
                                      .copyWith(fontWeight: FontWeight.w700),
                                ),
                                const SizedBox(height: 12),
                                _detailRow(context, 'Parcel type', current.parcelType),
                                _detailRow(
                                  context,
                                  'Weight',
                                  '${current.weightKg} kg',
                                ),
                                _detailRow(
                                  context,
                                  'Pickup location',
                                  current.pickupLocation,
                                ),
                                _detailRow(
                                  context,
                                  'Receiver location',
                                  current.receiverLocation,
                                ),
                                _detailRow(
                                  context,
                                  'Travel date',
                                  DateFormat('MMM d, yyyy')
                                      .format(current.travelDate),
                                ),
                                _detailRow(
                                  context,
                                  'Traveler (to be matched)',
                                  current.travelerLabel,
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 12),
                          AppCard(
                            margin: EdgeInsets.zero,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Payment details',
                                  style: typo.h3
                                      .copyWith(fontWeight: FontWeight.w700),
                                ),
                                const SizedBox(height: 12),
                                _detailRow(
                                  context,
                                  'Platform fee',
                                  platformFee > 0
                                      ? '\$${platformFee.toStringAsFixed(2)}'
                                      : '\$0.00 (covered by sender)',
                                  bold: true,
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  platformFee > 0
                                      ? 'Deducted from your wallet when you tap Accept '
                                          '(\$${platformFee.toStringAsFixed(2)}).'
                                      : 'The sender chose to pay 100% of the platform fee. '
                                          'No charge when you accept.',
                                  style: typo.sm.copyWith(
                                    color: AppColors.textSecondary,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 12),
                          AppCard(
                            margin: EdgeInsets.zero,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Wallet',
                                  style: typo.h3
                                      .copyWith(fontWeight: FontWeight.w700),
                                ),
                                const SizedBox(height: 12),
                                _detailRow(
                                  context,
                                  'Wallet balance',
                                  '\$${walletBalance.toStringAsFixed(2)}',
                                  bold: true,
                                  valueColor: AppColors.success,
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 16),
                          if (isPending) ...[
                            if (walletBalance < requiredBalance) ...[
                              const SizedBox(height: 10),
                              Text(
                                'Insufficient wallet balance. Top up your wallet to accept this request.',
                                style: typo.sm.copyWith(
                                  color: AppColors.danger,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              const SizedBox(height: 12),
                              AppButton(
                                label: 'Top up wallet',
                                variant: AppButtonVariant.outline,
                                onPressed: _acting
                                    ? null
                                    : () => context.push(
                                          '/wallet/top-up?role=receiver',
                                        ),
                              ),
                            ],
                            const SizedBox(height: 24),
                            Row(
                              children: [
                                Expanded(
                                  child: AppButton(
                                    label: 'Reject',
                                    variant: AppButtonVariant.danger,
                                    onPressed: _acting ? null : _reject,
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: AppButton(
                                    label: _acting ? 'Please wait…' : 'Accept',
                                    onPressed: canAccept ? _accept : null,
                                  ),
                                ),
                              ],
                            ),
                          ] else ...[
                            const SizedBox(height: 8),
                            Text(
                              current.status ==
                                      IncomingParcelRequestStatus.accepted
                                  ? 'You accepted this parcel request.'
                                  : 'You declined this parcel request.',
                              style: typo.sm.copyWith(
                                color: AppColors.textSecondary,
                              ),
                            ),
                          ],
                        ],
                      ),
                    );
                  },
                ),
    );
  }

  Widget _detailRow(
    BuildContext context,
    String label,
    String value, {
    bool bold = false,
    Color? valueColor,
  }) {
    final typo = context.typo;
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(child: Text(label, style: typo.sm)),
          const SizedBox(width: 12),
          Flexible(
            child: Text(
              value,
              textAlign: TextAlign.right,
              style: (bold ? typo.bodyBold : typo.body).copyWith(
                fontWeight: bold ? FontWeight.w700 : FontWeight.w600,
                color: valueColor ?? AppColors.textPrimary,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
