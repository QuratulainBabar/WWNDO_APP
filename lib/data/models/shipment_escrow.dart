/// Per-shipment escrow row from GET /wallet/escrow/:shipmentId (and wallet summary).
class ShipmentEscrow {
  const ShipmentEscrow({
    required this.shipmentId,
    required this.amountCents,
    required this.status,
    this.role,
  });

  final String shipmentId;
  final int amountCents;

  /// Backend status: `held`, `frozen`, `refunded`, `released`, or `none`.
  final String status;
  final String? role;

  bool get isHeld => status == 'held';
  bool get isFrozen => status == 'frozen';
  bool get isRefunded => status == 'refunded';
  bool get isReleased => status == 'released';
  bool get isActive => isHeld || isFrozen;

  factory ShipmentEscrow.none(String shipmentId) => ShipmentEscrow(
        shipmentId: shipmentId,
        amountCents: 0,
        status: 'none',
      );

  factory ShipmentEscrow.fromJson(Map<String, dynamic> json) {
    return ShipmentEscrow(
      shipmentId: json['shipmentId']?.toString() ?? '',
      amountCents: (json['amountCents'] as num?)?.toInt() ?? 0,
      status: (json['status']?.toString() ?? 'none').toLowerCase(),
      role: json['role']?.toString(),
    );
  }
}
