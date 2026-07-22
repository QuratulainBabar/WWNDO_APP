import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../data/models/wallet_role.dart';
import '../../data/wallet_service.dart';
import '../theme/app_colors.dart';
import '../theme/app_typography.dart';

class WalletCard extends StatelessWidget {
  const WalletCard({
    super.key,
    required this.role,
    this.onTap,
  });

  final WalletRole role;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final typo = context.typo;

    return ValueListenableBuilder<int>(
      valueListenable: WalletService.walletVersion,
      builder: (context, _, __) {
        final available = WalletService.availableUsd(role);
        final escrow = WalletService.escrowUsd(role);

        return Padding(
          padding: const EdgeInsets.only(right: 8),
          child: GestureDetector(
            onTap: onTap ?? () => context.push('/wallet?role=${role.queryParam}'),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text('Wallet', style: typo.walletLabel),
                  Text('\$${available.toStringAsFixed(2)}', style: typo.walletAmount),
                  if (escrow > 0)
                    Text(
                      'Escrow \$${escrow.toStringAsFixed(2)}',
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
  }
}
