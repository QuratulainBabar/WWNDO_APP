import 'user.dart';

class AuthUser {
  const AuthUser({
    required this.id,
    required this.name,
    required this.email,
    required this.phone,
    required this.countryCode,
    required this.bio,
    required this.rating,
    required this.reviewCount,
    required this.walletBalance,
    required this.memberSince,
    required this.isVerified,
    required this.kycStatus,
    required this.accountStatus,
    this.dialCode,
    this.phoneNumber,
    this.emailVerified = false,
    this.phoneVerified = false,
    this.role,
    this.avatarUrl,
  });

  final String id;
  final String name;
  final String email;
  final String phone;
  /// International dial code with leading `+`, when known (e.g. `+256`).
  final String? dialCode;
  /// National significant number digits, when known.
  final String? phoneNumber;
  final String countryCode;
  final String bio;
  final double rating;
  final int reviewCount;
  final double walletBalance;
  final String memberSince;
  final bool isVerified;
  final String kycStatus;
  final String accountStatus;
  final bool emailVerified;
  final bool phoneVerified;

  /// App role: sender | traveler | receiver
  final String? role;

  /// Public profile photo URL from `/auth/profile/avatar`.
  final String? avatarUrl;

  /// Section I — both email and phone verified and linked.
  bool get isFullyCrossVerified => emailVerified && phoneVerified;

  /// Section I system state label.
  String get verificationState => isFullyCrossVerified ? 'verified' : 'unverified';

  String get firstName => name.split(' ').first;
  String get initial => name.isNotEmpty ? name[0] : '?';
  bool get isKycApproved => kycStatus.toLowerCase() == 'approved';

  bool get isKycSubmitted => kycStatus.toLowerCase() == 'submitted';

  bool get isKycRejected => kycStatus.toLowerCase() == 'rejected';

  bool get isKycPending => kycStatus.toLowerCase() == 'pending';

  bool get needsKyc => !isKycApproved;

  bool get hasRole => role == 'sender' || role == 'traveler' || role == 'receiver';

  factory AuthUser.fromJson(Map<String, dynamic> json) {
    return AuthUser(
      id: json['id'].toString(),
      name: json['name'] as String,
      email: json['email'] as String,
      phone: json['phone'] as String,
      dialCode: json['dialCode'] as String?,
      phoneNumber: json['phoneNumber'] as String?,
      countryCode: json['countryCode'] as String,
      bio: (json['bio'] as String?) ?? '',
      rating: (json['rating'] as num?)?.toDouble() ?? 0,
      reviewCount: (json['reviewCount'] as num?)?.toInt() ?? 0,
      walletBalance: (json['walletBalance'] as num?)?.toDouble() ?? 0,
      memberSince: json['memberSince'] as String? ?? '',
      isVerified: json['isVerified'] as bool? ?? false,
      kycStatus: json['kycStatus'] as String? ?? 'pending',
      accountStatus: json['accountStatus'] as String? ?? 'active',
      emailVerified: json['emailVerified'] as bool? ?? false,
      phoneVerified: json['phoneVerified'] as bool? ?? false,
      role: json['role']?.toString(),
      avatarUrl: (json['avatarUrl'] as String?)?.trim().isNotEmpty == true
          ? (json['avatarUrl'] as String).trim()
          : null,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'email': email,
        'phone': phone,
        'dialCode': dialCode,
        'phoneNumber': phoneNumber,
        'countryCode': countryCode,
        'bio': bio,
        'rating': rating,
        'reviewCount': reviewCount,
        'walletBalance': walletBalance,
        'memberSince': memberSince,
        'isVerified': isVerified,
        'kycStatus': kycStatus,
        'accountStatus': accountStatus,
        'emailVerified': emailVerified,
        'phoneVerified': phoneVerified,
        'role': role,
        'avatarUrl': avatarUrl,
      };

  UserProfile toUserProfile() {
    return UserProfile(
      name: name,
      email: email,
      phone: phone,
      countryCode: countryCode,
      rating: rating,
      reviewCount: reviewCount,
      walletBalance: walletBalance,
      memberSince: memberSince,
      bio: bio,
      isVerified: isVerified,
    );
  }

  AuthUser copyWith({
    String? name,
    String? email,
    String? phone,
    String? dialCode,
    String? phoneNumber,
    String? countryCode,
    String? bio,
    bool? emailVerified,
    bool? phoneVerified,
    bool? isVerified,
    String? kycStatus,
    String? accountStatus,
    String? role,
    String? avatarUrl,
    bool clearRole = false,
    bool clearAvatarUrl = false,
  }) {
    final nextEmailVerified = emailVerified ?? this.emailVerified;
    final nextPhoneVerified = phoneVerified ?? this.phoneVerified;
    final fully = nextEmailVerified && nextPhoneVerified;
    return AuthUser(
      id: id,
      name: name ?? this.name,
      email: email ?? this.email,
      phone: phone ?? this.phone,
      dialCode: dialCode ?? this.dialCode,
      phoneNumber: phoneNumber ?? this.phoneNumber,
      countryCode: countryCode ?? this.countryCode,
      bio: bio ?? this.bio,
      rating: rating,
      reviewCount: reviewCount,
      walletBalance: walletBalance,
      memberSince: memberSince,
      isVerified: isVerified ?? fully,
      kycStatus: kycStatus ?? this.kycStatus,
      accountStatus: accountStatus ?? this.accountStatus,
      emailVerified: nextEmailVerified,
      phoneVerified: nextPhoneVerified,
      role: clearRole ? null : (role ?? this.role),
      avatarUrl: clearAvatarUrl ? null : (avatarUrl ?? this.avatarUrl),
    );
  }
}
