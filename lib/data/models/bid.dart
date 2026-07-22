enum BidReviewStatus {
  open,
  rejected,
  deliveryRequested,
  approved,
  accepted,
  locked,
}

class Bid {
  const Bid({
    required this.id,
    required this.travelerName,
    required this.initial,
    required this.rating,
    required this.reviewCount,
    required this.price,
    required this.travelDate,
    required this.routeMatchConfidence,
    this.flightNumber,
    this.message,
    this.featured = false,
    this.bio,
    this.completedDeliveries = 0,
  });

  final String id;
  final String travelerName;
  final String initial;
  final double rating;
  final int reviewCount;
  final double price;
  final DateTime travelDate;
  /// Route match confidence as a percentage (0–100).
  final int routeMatchConfidence;
  final String? flightNumber;
  final String? message;
  final bool featured;
  final String? bio;
  final int completedDeliveries;

  String get routeMatchLabel => '$routeMatchConfidence% Match';

  Bid copyWith({
    String? id,
    String? travelerName,
    String? initial,
    double? rating,
    int? reviewCount,
    double? price,
    DateTime? travelDate,
    int? routeMatchConfidence,
    String? flightNumber,
    String? message,
    bool? featured,
    String? bio,
    int? completedDeliveries,
  }) {
    return Bid(
      id: id ?? this.id,
      travelerName: travelerName ?? this.travelerName,
      initial: initial ?? this.initial,
      rating: rating ?? this.rating,
      reviewCount: reviewCount ?? this.reviewCount,
      price: price ?? this.price,
      travelDate: travelDate ?? this.travelDate,
      routeMatchConfidence: routeMatchConfidence ?? this.routeMatchConfidence,
      flightNumber: flightNumber ?? this.flightNumber,
      message: message ?? this.message,
      featured: featured ?? this.featured,
      bio: bio ?? this.bio,
      completedDeliveries: completedDeliveries ?? this.completedDeliveries,
    );
  }
}
