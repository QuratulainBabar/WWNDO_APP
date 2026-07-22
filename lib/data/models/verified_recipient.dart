class VerifiedRecipient {
  const VerifiedRecipient({
    required this.id,
    required this.name,
    required this.phone,
    required this.verified,
  });

  final String id;
  final String name;
  final String phone;
  final bool verified;
}
