class UserProfile {
  const UserProfile({
    required this.name,
    required this.email,
    required this.phone,
    required this.countryCode,
    required this.rating,
    required this.reviewCount,
    required this.walletBalance,
    required this.memberSince,
    required this.bio,
    required this.isVerified,
  });

  final String name;
  final String email;
  final String phone;
  final String countryCode;
  final double rating;
  final int reviewCount;
  final double walletBalance;
  final String memberSince;
  final String bio;
  final bool isVerified;

  String get firstName => name.split(' ').first;
  String get initial => name.isNotEmpty ? name[0] : '?';
}
