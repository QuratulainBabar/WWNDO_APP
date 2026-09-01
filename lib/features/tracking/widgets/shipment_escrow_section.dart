import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/theme/app_typography.dart';
import '../../../data/wallet_service.dart';
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
    await context.read<WalletProvider>().refreshShipmentEscrow(widget.shipmentId);
  }

  @override
  Widget build(BuildContext context) {
    final typo = context.typo;
    return ValueListenableBuilder<int>(
      valueListenable: WalletService.walletVersion,
      builder: (context, _, __) {
        final shipmentId = widget.shipmentId;
        final escrow = WalletService.escrowCentsForShipment(shipmentId);
        final frozen = WalletService.isEscrowFrozen(shipmentId);
        final refunded = WalletService.isEscrowRefunded(shipmentId);
        final released = WalletService.isEscrowReleased(shipmentId);

        String statusLabel;
        if (released) {
          statusLabel = 'Released to traveler (NFC CP2)';
        } else if (refunded) {
          statusLabel = 'Refunded to sender';
        } else if (frozen) {
          statusLabel = 'Frozen — dispute under review';
        } else if (escrow > 0) {
          statusLabel = 'Held until NFC Checkpoint 2';
        } else {
          statusLabel = 'No active escrow';
        }

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Shipment escrow',
              style: typo.h3.copyWith(fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 8),
            _detailRow(context, 'Amount', WalletService.formatCents(escrow)),
            _detailRow(context, 'Status', statusLabel),
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
              style: typo.bodyBold.copyWith(fontWeight: FontWeight.w700),
            ),
          ),
        ],
      ),
    );
  }
}
