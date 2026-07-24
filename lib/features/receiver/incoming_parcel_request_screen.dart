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
import '../../data/models/created_delivery.dart';
import '../../data/models/incoming_parcel_request.dart';
import '../../data/models/receiver_delivery_status.dart';
import '../../data/models/wallet_role.dart';
import '../../data/services/delivery_repository.dart';
import '../../data/static_data.dart';
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

    final walletBalance = WalletService.availableUsd(WalletRole.receiver);
    final minBalance = StaticData.receiverAcceptMinBalanceUsd;
    if (walletBalance < minBalance) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'You need at least \$${minBalance.toStringAsFixed(0)} in your wallet to accept this request.',
          ),
        ),
      );
      return;
    }

    setState(() => _acting = true);
    try {
      final feeUsd = delivery.platformFeeShare ??
          StaticData.receiverIncomingPlatformFeeUsd;
      final feeCents = (feeUsd * 100).round();
      if (!WalletService.ensureAvailableWithCardFallback(
        role: WalletRole.receiver,
        amountCents: feeCents,
      )) {
        throw const ApiException(
          message: 'Insufficient wallet balance.',
          code: 'INSUFFICIENT_FUNDS',
        );
      }

      final updated = await _repo().acceptAsReceiver(delivery.displayId);
      WalletService.chargePlatformFee(
        role: WalletRole.receiver,
        shipmentId: updated.displayId,
        amountCents: feeCents,
        description: '${updated.displayId} · Platform fee',
      );

      if (!mounted) return;
      setState(() {
        _delivery = updated;
        _acting = false;
      });
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
                  'Your parcel request has been accepted. We will match a traveler and notify you once confirmed.',
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
                    final minBalance = StaticData.receiverAcceptMinBalanceUsd;
                    final canAccept = walletBalance >= minBalance && !_acting;
                    final platformFee = _delivery!.platformFeeShare ??
                        StaticData.receiverIncomingPlatformFeeUsd;
                    final isPending = status.isPendingRequest &&
                        current.status == IncomingParcelRequestStatus.pending;

                    return SingleChildScrollView(
                      physics: PlatformUi.scrollPhysics,
                      padding: context.pagePadding,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          AppBadge(
                            label: current.status.label,
                            color: current.status.color,
                            backgroundColor: current.status.backgroundColor,
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
                                  '\$${platformFee.toStringAsFixed(2)}',
                                  bold: true,
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  'Non-refundable platform fee to process and secure this parcel.',
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
                            Container(
                              width: double.infinity,
                              padding: const EdgeInsets.all(14),
                              decoration: BoxDecoration(
                                color: AppColors.primary.withValues(alpha: 0.06),
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color: AppColors.primary.withValues(alpha: 0.25),
                                ),
                              ),
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Icon(
                                    Icons.shield_outlined,
                                    size: 20,
                                    color: AppColors.primary,
                                  ),
                                  const SizedBox(width: 10),
                                  Expanded(
                                    child: Text(
                                      'You must have at least \$${minBalance.toStringAsFixed(0)} in your wallet to accept this request.',
                                      style: typo.sm.copyWith(
                                        color: AppColors.primary,
                                        fontWeight: FontWeight.w600,
                                        height: 1.4,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            if (walletBalance < minBalance) ...[
                              const SizedBox(height: 10),
                              Text(
                                'Insufficient wallet balance. Top up your wallet to accept this request.',
                                style: typo.sm.copyWith(
                                  color: AppColors.danger,
                                  fontWeight: FontWeight.w600,
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
