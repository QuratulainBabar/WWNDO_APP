/// Result of `POST /api/v1/wallet/fx/quote` (Stripe FX Quotes).
class FxQuote {
  const FxQuote({
    required this.fromCurrency,
    required this.toCurrency,
    required this.amountCents,
    required this.convertedAmountCents,
    required this.exchangeRate,
    required this.baseRate,
    this.fxFeeRate = 0,
    this.quoteId,
    this.lockDuration = 'none',
    this.lockStatus = 'active',
    this.lockExpiresAt,
    this.created,
  });

  final String fromCurrency;
  final String toCurrency;
  final int amountCents;
  final int convertedAmountCents;
  final double exchangeRate;
  final double baseRate;
  final double fxFeeRate;
  final String? quoteId;
  final String lockDuration;
  final String lockStatus;
  final int? lockExpiresAt;
  final int? created;

  factory FxQuote.fromJson(Map<String, dynamic> json) {
    return FxQuote(
      fromCurrency: (json['fromCurrency'] ?? '').toString().toUpperCase(),
      toCurrency: (json['toCurrency'] ?? '').toString().toUpperCase(),
      amountCents: _asInt(json['amountCents']),
      convertedAmountCents: _asInt(json['convertedAmountCents']),
      exchangeRate: _asDouble(json['exchangeRate']),
      baseRate: _asDouble(json['baseRate'] ?? json['exchangeRate']),
      fxFeeRate: _asDouble(json['fxFeeRate']),
      quoteId: json['quoteId']?.toString(),
      lockDuration: (json['lockDuration'] ?? 'none').toString(),
      lockStatus: (json['lockStatus'] ?? 'active').toString(),
      lockExpiresAt: json['lockExpiresAt'] == null
          ? null
          : _asInt(json['lockExpiresAt']),
      created: json['created'] == null ? null : _asInt(json['created']),
    );
  }

  static int _asInt(Object? value) {
    if (value is int) return value;
    if (value is num) return value.round();
    return int.tryParse(value?.toString() ?? '') ?? 0;
  }

  static double _asDouble(Object? value) {
    if (value is double) return value;
    if (value is num) return value.toDouble();
    return double.tryParse(value?.toString() ?? '') ?? 0;
  }
}
