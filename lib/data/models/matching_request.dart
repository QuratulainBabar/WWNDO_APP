import 'delivery_request.dart';

class MatchingRequest {
  const MatchingRequest({
    required this.request,
    required this.matchScore,
    required this.tripId,
  });

  final DeliveryRequest request;
  final int matchScore;
  final String tripId;

  String get matchLabel => '$matchScore% Match';
}
