import 'models/delivery_request.dart';
import 'models/shipment.dart';
import 'models/traveler_trip.dart';

/// Computes route similarity between a traveler trip and a sender parcel/request.
abstract final class RouteSimilarity {
  /// Returns a 0–100 match score based on origin/destination overlap and date proximity.
  static int score({
    required String tripOrigin,
    required String tripDestination,
    required DateTime tripDate,
    required String requestOrigin,
    required String requestDestination,
    required DateTime requestDate,
  }) {
    final originScore = _placeScore(tripOrigin, requestOrigin);
    final destScore = _placeScore(tripDestination, requestDestination);
    if (originScore == 0 || destScore == 0) return 0;

    final base = ((originScore + destScore) / 2 * 80).round();
    final dateBonus = _dateBonus(tripDate, requestDate);
    return (base + dateBonus).clamp(0, 100);
  }

  static int scoreTripToRequest(TravelerTrip trip, DeliveryRequest request) {
    return score(
      tripOrigin: trip.origin,
      tripDestination: trip.destination,
      tripDate: trip.travelDate,
      requestOrigin: request.fromCity,
      requestDestination: request.toCity,
      requestDate: request.travelDate,
    );
  }

  static int scoreTripToShipment(TravelerTrip trip, Shipment shipment) {
    return score(
      tripOrigin: trip.origin,
      tripDestination: trip.destination,
      tripDate: trip.travelDate,
      requestOrigin: shipment.fromCity,
      requestDestination: shipment.toCity,
      requestDate: shipment.travelDate,
    );
  }

  static double _placeScore(String a, String b) {
    final left = _normalize(a);
    final right = _normalize(b);
    if (left.isEmpty || right.isEmpty) return 0;
    if (left == right) return 1;
    if (left.contains(right) || right.contains(left)) return 0.75;

    final leftTokens = left.split(RegExp(r'\s+'));
    final rightTokens = right.split(RegExp(r'\s+'));
    for (final token in leftTokens) {
      if (token.length < 3) continue;
      if (rightTokens.any((t) => t.contains(token) || token.contains(t))) {
        return 0.55;
      }
    }
    return 0;
  }

  static int _dateBonus(DateTime a, DateTime b) {
    final days = a.difference(b).inDays.abs();
    if (days == 0) return 20;
    if (days <= 2) return 15;
    if (days <= 5) return 10;
    if (days <= 10) return 5;
    return 0;
  }

  static String _normalize(String value) {
    return value
        .toLowerCase()
        .replaceAll(RegExp(r'[^a-z0-9\s]'), ' ')
        .replaceAll(RegExp(r'\s+'), ' ')
        .trim();
  }
}
