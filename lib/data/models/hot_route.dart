class HotRoute {
  const HotRoute({
    required this.fromCity,
    required this.toCity,
    required this.travelerCount,
    required this.fromPrice,
  });

  final String fromCity;
  final String toCity;
  final int travelerCount;
  final double fromPrice;
}
