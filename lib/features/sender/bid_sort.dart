import '../../data/models/bid.dart';

enum BidSortOption {
  bestMatchScore,
  lowestPrice,
  earliestDeparture,
  highestRating;

  String get label => switch (this) {
        BidSortOption.bestMatchScore => 'Best Match',
        BidSortOption.lowestPrice => 'Lowest Price',
        BidSortOption.earliestDeparture => 'Earliest Departure',
        BidSortOption.highestRating => 'Highest Rating',
      };

  static const labels = [
    'Best Match',
    'Lowest Price',
    'Earliest Departure',
    'Highest Rating',
  ];

  static BidSortOption fromLabel(String label) {
    return BidSortOption.values.firstWhere((o) => o.label == label);
  }

  static List<Bid> sorted(List<Bid> bids, BidSortOption option) {
    final list = List<Bid>.from(bids);
    switch (option) {
      case BidSortOption.lowestPrice:
        list.sort((a, b) => a.price.compareTo(b.price));
      case BidSortOption.highestRating:
        list.sort((a, b) => b.rating.compareTo(a.rating));
      case BidSortOption.earliestDeparture:
        list.sort((a, b) => a.travelDate.compareTo(b.travelDate));
      case BidSortOption.bestMatchScore:
        list.sort(
          (a, b) => b.routeMatchConfidence.compareTo(a.routeMatchConfidence),
        );
    }
    return list;
  }
}
