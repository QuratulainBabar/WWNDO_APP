class ProfileTrustMetrics {
  const ProfileTrustMetrics({
    required this.completedDeliveries,
    required this.cancellationRate,
    required this.disputeRate,
  });

  final int completedDeliveries;
  final double cancellationRate;
  final double disputeRate;
}
