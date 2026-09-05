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

  String? get clientSecret {
    final value = details?['clientSecret'];
    if (value == null) return null;
    final text = value.toString().trim();
    return text.isEmpty ? null : text;
  }

  String? get paymentIntentId {
    final value = details?['paymentIntentId'];
    if (value == null) return null;
    final text = value.toString().trim();
    return text.isEmpty ? null : text;
  }

  String? get paymentRole {
    final value = details?['role'];
    if (value == null) return null;
    final text = value.toString().trim();
    return text.isEmpty ? null : text;
  }

  bool get requiresPayment =>
      code == 'PAYMENT_REQUIRED' || statusCode == 402;

  @override
  String toString() => message;
}
