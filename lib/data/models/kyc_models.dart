/// KYC / Sumsub models used by repository + provider layers.
library;

enum KycStatusValue {
  pending,
  submitted,
  approved,
  rejected;

  static KycStatusValue fromString(String? raw) {
    switch ((raw ?? '').toLowerCase()) {
      case 'submitted':
        return KycStatusValue.submitted;
      case 'approved':
        return KycStatusValue.approved;
      case 'rejected':
        return KycStatusValue.rejected;
      default:
        return KycStatusValue.pending;
    }
  }

  String get apiValue => name;

  String get label => switch (this) {
        KycStatusValue.pending => 'Pending',
        KycStatusValue.submitted => 'Pending',
        KycStatusValue.approved => 'Approved',
        KycStatusValue.rejected => 'Rejected',
      };

  String get detailLabel => switch (this) {
        KycStatusValue.pending => 'Verification required',
        KycStatusValue.submitted => 'Pending review',
        KycStatusValue.approved => 'Approved',
        KycStatusValue.rejected => 'Rejected',
      };
}

class SumsubAccessToken {
  const SumsubAccessToken({
    required this.accessToken,
    required this.userId,
    required this.levelName,
    this.expiresIn,
  });

  final String accessToken;
  final String userId;
  final String levelName;
  final int? expiresIn;

  factory SumsubAccessToken.fromJson(Map<String, dynamic> json) {
    final token = (json['accessToken'] ?? json['token']) as String?;
    if (token == null || token.isEmpty) {
      throw const FormatException('Missing Sumsub access token');
    }
    return SumsubAccessToken(
      accessToken: token,
      userId: (json['userId'] ?? '').toString(),
      levelName: (json['levelName'] ?? '').toString(),
      expiresIn: (json['expiresIn'] as num?)?.toInt(),
    );
  }
}

class KycStatusResult {
  const KycStatusResult({
    required this.kycStatus,
    this.reviewStatus,
    this.applicantId,
    this.synced = false,
    this.userJson,
  });

  final KycStatusValue kycStatus;
  final String? reviewStatus;
  final String? applicantId;
  final bool synced;
  final Map<String, dynamic>? userJson;

  factory KycStatusResult.fromJson(Map<String, dynamic> json) {
    return KycStatusResult(
      kycStatus: KycStatusValue.fromString(json['kycStatus'] as String?),
      reviewStatus: json['reviewStatus'] as String?,
      applicantId: json['applicantId']?.toString(),
      synced: json['synced'] as bool? ?? false,
      userJson: json['user'] is Map<String, dynamic>
          ? json['user'] as Map<String, dynamic>
          : null,
    );
  }
}

/// Normalized outcome after the Sumsub MobileSDK closes.
enum SumsubSdkOutcomeStatus {
  approved,
  pending,
  rejected,
  canceled,
  failed,
  incomplete,
  unknown,
}

class SumsubSdkOutcome {
  const SumsubSdkOutcome({
    required this.status,
    this.success = true,
    this.errorMessage,
    this.rawStatus,
  });

  final SumsubSdkOutcomeStatus status;
  final bool success;
  final String? errorMessage;
  final String? rawStatus;

  bool get isTerminalSuccess =>
      status == SumsubSdkOutcomeStatus.approved ||
      status == SumsubSdkOutcomeStatus.pending ||
      status == SumsubSdkOutcomeStatus.rejected;

  String get userMessage => switch (status) {
        SumsubSdkOutcomeStatus.approved => 'Identity verification approved.',
        SumsubSdkOutcomeStatus.pending =>
          'Documents submitted. Verification is pending review.',
        SumsubSdkOutcomeStatus.rejected =>
          'Verification was rejected. Please try again with a valid document.',
        SumsubSdkOutcomeStatus.canceled => 'Verification was canceled.',
        SumsubSdkOutcomeStatus.failed =>
          errorMessage ?? 'Verification failed. Please try again.',
        SumsubSdkOutcomeStatus.incomplete =>
          'Verification is incomplete. Please finish all steps.',
        SumsubSdkOutcomeStatus.unknown =>
          errorMessage ?? 'Verification finished with an unknown status.',
      };
}
