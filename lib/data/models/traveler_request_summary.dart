class TravelerRequestSummary {
  const TravelerRequestSummary({
    required this.id,
    required this.status,
    required this.tripId,
    required this.tripPublicId,
    required this.travelerName,
    this.matchScore = 0,
    this.createdAt,
  });

  final String id;
  final String status;
  final String tripId;
  final String tripPublicId;
  final String travelerName;
  final int matchScore;
  final DateTime? createdAt;

  bool get isAccepted => status == 'accepted';

  bool get isPending => status == 'pending';

  factory TravelerRequestSummary.fromJson(Map<String, dynamic> json) {
    final createdRaw = json['createdAt'];
    return TravelerRequestSummary(
      id: json['id'] as String? ?? '',
      status: json['status'] as String? ?? 'pending',
      tripId: json['tripId'] as String? ?? '',
      tripPublicId: json['tripPublicId'] as String? ?? '',
      travelerName: (json['travelerName'] as String?)?.trim().isNotEmpty == true
          ? (json['travelerName'] as String).trim()
          : 'Traveler',
      matchScore: (json['matchScore'] as num?)?.toInt() ?? 0,
      createdAt: createdRaw != null
          ? DateTime.tryParse(createdRaw.toString())
          : null,
    );
  }
}
