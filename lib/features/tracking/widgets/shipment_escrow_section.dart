import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/theme/app_typography.dart';
import '../../../data/wallet_service.dart';
import '../../../l10n/app_localizations.dart';
import '../../../providers/wallet_provider.dart';

/// Live shipment escrow amount/status from GET /wallet/escrow/:id.
class ShipmentEscrowSection extends StatefulWidget {
  const ShipmentEscrowSection({super.key, required this.shipmentId});

  final String shipmentId;

  @override
  State<ShipmentEscrowSection> createState() => _ShipmentEscrowSectionState();
}

class _ShipmentEscrowSectionState extends State<ShipmentEscrowSection> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _load());
  }

  @override
  void didUpdateWidget(covariant ShipmentEscrowSection oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.shipmentId != widget.shipmentId) {
      _load();
    }
  }

  Future<void> _load() async {
    if (!mounted) return;
    await context.read<WalletProvider>().refreshShipmentEscrow(
      widget.shipmentId,
    );
  }

  @override
  Widget build(BuildContext context) {
    final typo = context.typo;
    return ValueListenableBuilder<int>(
      valueListenable: WalletService.walletVersion,
      builder: (context, _, _) {
        final shipmentId = widget.shipmentId;
        final escrow = WalletService.escrowCentsForShipment(shipmentId);
        final frozen = WalletService.isEscrowFrozen(shipmentId);
        final refunded = WalletService.isEscrowRefunded(shipmentId);
        final released = WalletService.isEscrowReleased(shipmentId);

        String statusLabel;
        if (released) {
          statusLabel = context.l10n.releasedToTravelerCp2;
        } else if (refunded) {
          statusLabel = context.l10n.refundedToSender;
        } else if (frozen) {
          statusLabel = context.l10n.escrowFrozenDispute;
        } else if (escrow > 0) {
          statusLabel = context.l10n.heldUntilCp2;
        } else {
          statusLabel = context.l10n.noActiveEscrow;
        }

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              context.l10n.shipmentEscrow,
              style: typo.h3.copyWith(fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 8),
            _detailRow(
              context,
              context.l10n.amount,
              WalletService.formatCents(escrow),
            ),
            _detailRow(context, context.l10n.status, statusLabel),
          ],
        );
      },
    );
  }

  Widget _detailRow(BuildContext context, String label, String value) {
    final typo = context.typo;
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: typo.sm),
          Flexible(
            child: Text(
              value,
              textAlign: TextAlign.end,
              style: typo.bodyBold.copyWith(fontWeight: FontWeight.w400),
            ),
          ),
        ],
      ),
    );
  }
}
