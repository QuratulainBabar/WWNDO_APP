class ProfileTrustMetrics {
  const ProfileTrustMetrics({
    required this.completedDeliveries,
    required this.cancellationRate,
    required this.disputeRate,
  });

  final int completedDeliveries;
  final double cancellationRate;
  final double disputeRate;

  static const empty = ProfileTrustMetrics(
    completedDeliveries: 0,
    cancellationRate: 0,
    disputeRate: 0,
  );

  factory ProfileTrustMetrics.fromJson(Map<String, dynamic> json) {
    return ProfileTrustMetrics(
      completedDeliveries:
          (json['completedDeliveries'] as num?)?.toInt() ?? 0,
      cancellationRate:
          (json['cancellationRate'] as num?)?.toDouble() ?? 0,
      disputeRate: (json['disputeRate'] as num?)?.toDouble() ?? 0,
    );
  }
}
