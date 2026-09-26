import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../l10n/app_localizations.dart';

import '../../core/layout/responsive.dart';
import '../../core/platform/platform_ui.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_typography.dart';
import '../../core/widgets/app_button.dart';
import '../../core/widgets/back_header.dart';
import '../../data/models/wallet_role.dart';
import '../../data/static_data.dart';
import '../../data/wallet_service.dart';
import '../../providers/wallet_provider.dart';
import 'bid_acceptance_payment_screen.dart';

class BidPaymentSuccessScreen extends StatefulWidget {
  const BidPaymentSuccessScreen({super.key, required this.acceptance});

  final BidAcceptanceContext acceptance;

  @override
  State<BidPaymentSuccessScreen> createState() =>
      _BidPaymentSuccessScreenState();
}

class _BidPaymentSuccessScreenState extends State<BidPaymentSuccessScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      // Keep sender wallet balance in sync after escrow + platform fee charge.
      context
          .read<WalletProvider>()
          .refresh(
            WalletRole.sender,
            silent: true,
            includeFullHistory: true,
          )
          .ignore();
    });
  }

  @override
  Widget build(BuildContext context) {
    final typo = context.typo;
    final acceptance = widget.acceptance;
    final total = StaticData.totalPayment(
      acceptance.bid.price,
      category: StaticData.shipmentById(acceptance.shipmentId)
              ?.parcelCategory ??
          'Documents',
      shipmentId: acceptance.shipmentId,
    );

    return Scaffold(
      backgroundColor: AppColors.surface,
      appBar: const BackHeader(title: 'Payment'),
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            final padding = context.pagePadding;
            return SingleChildScrollView(
              physics: PlatformUi.scrollPhysics,
              padding: padding,
              child: ConstrainedBox(
                constraints: BoxConstraints(
                  minHeight: constraints.maxHeight - padding.vertical,
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      width: 80,
                      height: 80,
                      decoration: BoxDecoration(
                        color: AppColors.success.withValues(alpha: 0.12),
                        shape: BoxShape.circle,
                      ),
                      alignment: Alignment.center,
                      child: const Icon(
                        Icons.check,
                        size: 40,
                        color: AppColors.success,
                      ),
                    ),
                    const SizedBox(height: 20),
                    Text(
                      'Payment Successful',
                      style: typo.h1,
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Bid Accepted',
                      style: typo.h3,
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      '${WalletService.formatMajor(total)} deposited securely in escrow.',
                      textAlign: TextAlign.center,
                      style: typo.sm.copyWith(height: 1.5),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Platform fees collected · Selected bid locked · Parties notified',
                      textAlign: TextAlign.center,
                      style: typo.sm.copyWith(color: AppColors.textSecondary),
                    ),
                    const SizedBox(height: 32),
                    AppButton(
                      label: context.tr('Continue'),
                      onPressed: () async {
                        if (mounted) {
                          await context.read<WalletProvider>().refresh(
                                WalletRole.sender,
                                silent: true,
                                includeFullHistory: true,
                              );
                        }
                        if (!context.mounted) return;
                        context.push(
                          '/bid-accepted',
                          extra: acceptance.bid,
                        );
                      },
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}
