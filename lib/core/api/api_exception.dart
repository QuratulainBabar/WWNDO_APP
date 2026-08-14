class ApiException implements Exception {
  const ApiException({
    required this.message,
    this.statusCode,
    this.code,
    this.details,
  });

  final String message;
  final int? statusCode;
  final String? code;
  final Map<String, dynamic>? details;

  String? get clientSecret => details?['clientSecret'] as String?;
  String? get paymentIntentId => details?['paymentIntentId'] as String?;

  bool get requiresPayment =>
      code == 'PAYMENT_REQUIRED' || statusCode == 402;

  @override
  String toString() => message;
}
