import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../core/layout/responsive.dart';
import '../../core/platform/platform_ui.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_typography.dart';
import '../../core/widgets/app_badge.dart';
import '../../core/widgets/app_button.dart';
import '../../core/widgets/app_card.dart';
import '../../core/widgets/back_header.dart';
import '../../core/widgets/cancel_request_confirmation_dialog.dart';
import '../../data/models/incoming_parcel_request.dart';
import '../../data/models/wallet_role.dart';
import '../../data/static_data.dart';
import '../../data/wallet_service.dart';

class IncomingParcelRequestScreen extends StatelessWidget {
  const IncomingParcelRequestScreen({super.key, required this.requestId});

  final String requestId;

  IncomingParcelRequest get _request =>
      StaticData.incomingParcelRequestById(requestId) ??
      StaticData.demoIncomingParcelRequest;

  @override
  Widget build(BuildContext context) {
    final typo = context.typo;
    final request = _request;

    return ValueListenableBuilder<int>(
      valueListenable: StaticData.incomingParcelRequestsVersion,
      builder: (context, _, __) {
        return ValueListenableBuilder<int>(
          valueListenable: WalletService.walletVersion,
          builder: (context, _, __) {
            final current = StaticData.incomingParcelRequestById(requestId) ?? request;
            final walletBalance = WalletService.availableUsd(WalletRole.receiver);
            final minBalance = StaticData.receiverAcceptMinBalanceUsd;
            final canAccept = walletBalance >= minBalance;
            final platformFee = StaticData.receiverIncomingPlatformFeeUsd;
            final isPending = current.status == IncomingParcelRequestStatus.pending;

            return Scaffold(
          backgroundColor: AppColors.background,
          appBar: const BackHeader(title: 'Parcel Request'),
          body: SingleChildScrollView(
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
                  style: typo.body.copyWith(color: AppColors.textSecondary),
                ),
                const SizedBox(height: 16),
                AppCard(
                  margin: EdgeInsets.zero,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Parcel details',
                        style: typo.h3.copyWith(fontWeight: FontWeight.w700),
                      ),
                      const SizedBox(height: 12),
                      _detailRow(context, 'Parcel type', current.parcelType),
                      _detailRow(context, 'Weight', '${current.weightKg} kg'),
                      _detailRow(context, 'Pickup location', current.pickupLocation),
                      _detailRow(context, 'Receiver location', current.receiverLocation),
                      _detailRow(
                        context,
                        'Travel date',
                        DateFormat('MMM d, yyyy').format(current.travelDate),
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
                        style: typo.h3.copyWith(fontWeight: FontWeight.w700),
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
                        style: typo.sm.copyWith(color: AppColors.textSecondary),
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
                        style: typo.h3.copyWith(fontWeight: FontWeight.w700),
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
                      border: Border.all(color: AppColors.primary.withValues(alpha: 0.25)),
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
                  if (!canAccept) ...[
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
                          onPressed: () => _reject(context, current.id),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: AppButton(
                          label: 'Accept',
                          onPressed: canAccept ? () => _accept(context, current.id) : null,
                        ),
                      ),
                    ],
                  ),
                ] else ...[
                  const SizedBox(height: 8),
                  Text(
                    current.status == IncomingParcelRequestStatus.accepted
                        ? 'You accepted this parcel request.'
                        : 'You declined this parcel request.',
                    style: typo.sm.copyWith(color: AppColors.textSecondary),
                  ),
                ],
              ],
            ),
          ),
            );
          },
        );
      },
    );
  }

  Future<void> _accept(BuildContext context, String id) async {
    final error = StaticData.validateReceiverIncomingAccept(id);
    if (error != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(error)),
      );
      return;
    }

    final accepted = StaticData.acceptIncomingParcelRequest(id);
    if (!accepted) return;

    if (!context.mounted) return;
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
                  child: const Icon(Icons.check_rounded, color: AppColors.success, size: 36),
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
                  style: typo.sm.copyWith(height: 1.5, color: AppColors.textSecondary),
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

  Future<void> _reject(BuildContext context, String id) async {
    final confirmed = await showCancelRequestConfirmation(context);
    if (!confirmed || !context.mounted) return;

    StaticData.rejectIncomingParcelRequest(id);
    if (context.mounted) context.pop();
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
