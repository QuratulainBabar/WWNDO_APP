class ParcelCreationResult {
  const ParcelCreationResult({
    required this.requestId,
    required this.routeHash,
    required this.budgetConstraintUsd,
    required this.category,
    required this.route,
    required this.photoCount,
    required this.recipientName,
  });

  final String requestId;
  final String routeHash;
  final double budgetConstraintUsd;
  final String category;
  final String route;
  final int photoCount;
  final String recipientName;
}
