class Review {
  const Review({
    required this.reviewerName,
    required this.initial,
    required this.rating,
    required this.text,
    required this.date,
    this.id,
    this.shipmentId,
  });

  final String? id;
  final String reviewerName;
  final String initial;
  final int rating;
  final String text;
  final String date;
  final String? shipmentId;

  factory Review.fromJson(Map<String, dynamic> json) {
    final reviewerName = (json['reviewerName'] as String?)?.trim().isNotEmpty == true
        ? (json['reviewerName'] as String).trim()
        : 'User';
    final explicitInitial = (json['initial'] as String?)?.trim();
    final initial = (explicitInitial != null && explicitInitial.isNotEmpty)
        ? explicitInitial[0].toUpperCase()
        : (reviewerName.isNotEmpty ? reviewerName[0].toUpperCase() : '?');
    final ratingRaw = json['rating'];
    final rating = ratingRaw is num
        ? ratingRaw.round().clamp(1, 5)
        : int.tryParse('$ratingRaw')?.clamp(1, 5) ?? 5;
    final text = (json['text'] as String?)?.trim().isNotEmpty == true
        ? (json['text'] as String).trim()
        : ((json['body'] as String?)?.trim() ?? '');
    final date = (json['date'] as String?)?.trim().isNotEmpty == true
        ? (json['date'] as String).trim()
        : _formatDate(json['createdAt']);

    return Review(
      id: json['id']?.toString(),
      reviewerName: reviewerName,
      initial: initial,
      rating: rating,
      text: text,
      date: date,
      shipmentId: json['shipmentId']?.toString(),
    );
  }

  static String _formatDate(Object? raw) {
    if (raw == null) return '';
    final parsed = DateTime.tryParse(raw.toString());
    if (parsed == null) return raw.toString();
    const months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
    ];
    return '${months[parsed.month - 1]} ${parsed.day}, ${parsed.year}';
  }
}
