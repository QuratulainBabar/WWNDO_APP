import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../data/models/wallet_role.dart';
import '../../data/wallet_service.dart';
import '../../l10n/app_localizations.dart';
import '../../providers/currency_provider.dart';
import '../../providers/wallet_provider.dart';
import '../theme/app_colors.dart';
import '../theme/app_typography.dart';

class WalletCard extends StatefulWidget {
  const WalletCard({
    super.key,
    required this.role,
    this.onTap,
  });

  final WalletRole role;
  final VoidCallback? onTap;

  @override
  State<WalletCard> createState() => _WalletCardState();
}

class _WalletCardState extends State<WalletCard> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      context.read<WalletProvider>().refresh(widget.role, silent: true).ignore();
    });
  }

  @override
  void didUpdateWidget(covariant WalletCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.role != widget.role) {
      context.read<WalletProvider>().refresh(widget.role, silent: true).ignore();
    }
  }

  @override
  Widget build(BuildContext context) {
    final typo = context.typo;
    context.watch<CurrencyProvider>();

    return Consumer<WalletProvider>(
      builder: (context, wallet, _) {
        return ValueListenableBuilder<int>(
          valueListenable: WalletService.walletVersion,
          builder: (context, _, __) {
            final available = WalletService.availableUsd(widget.role);
            // Traveler: show related held escrow (sender-funded). Sender: own escrow.
            final escrow = WalletService.displayEscrowUsd(widget.role);

            return Padding(
              padding: const EdgeInsets.only(right: 8),
              child: GestureDetector(
                onTap: widget.onTap ??
                    () => context.push('/wallet?role=${widget.role.queryParam}'),
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(context.l10n.wallet, style: typo.walletLabel),
                      Text(
                        WalletService.formatMajor(available),
                        style: typo.walletAmount,
                      ),
                      if (escrow > 0)
                        Text(
                          context.l10n.escrowAmount(
                            WalletService.formatMajor(escrow),
                          ),
                          style: typo.sm.copyWith(
                            color: AppColors.primary,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }
}
