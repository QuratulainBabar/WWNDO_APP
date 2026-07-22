class Review {
  const Review({
    required this.reviewerName,
    required this.initial,
    required this.rating,
    required this.text,
    required this.date,
  });

  final String reviewerName;
  final String initial;
  final int rating;
  final String text;
  final String date;
}
