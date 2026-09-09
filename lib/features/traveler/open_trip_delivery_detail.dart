import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../core/config/demo_mode.dart';
import '../../core/geo/destination_match.dart';
import '../../core/widgets/app_toast.dart';
import '../../data/models/created_delivery.dart';
import '../../data/models/traveler_trip.dart';
import '../../data/services/delivery_repository.dart';
import '../../providers/auth_provider.dart';

final _tripPublicIdPattern = RegExp(r'^TR-', caseSensitive: false);

bool _isTripPublicId(String id) => _tripPublicIdPattern.hasMatch(id.trim());

bool _sameId(String? a, String? b) {
  final left = a?.trim().toLowerCase() ?? '';
  final right = b?.trim().toLowerCase() ?? '';
  return left.isNotEmpty && left == right;
}

Iterable<String> _tripKeys(TravelerTrip trip) sync* {
  for (final value in [trip.displayId, trip.publicId, trip.id]) {
    final key = value?.trim() ?? '';
    if (key.isNotEmpty) yield key;
  }
}

/// True when [delivery] is booked / requested on this exact TR-… trip.
bool _deliveryLinkedToTrip(TravelerTrip trip, CreatedDelivery delivery) {
  for (final key in _tripKeys(trip)) {
    if (_sameId(key, delivery.tripPublicId) || _sameId(key, delivery.tripId)) {
      return true;
    }
  }
  return false;
}

/// Delivery already belongs to a different traveler trip.
bool _deliveryLinkedToOtherTrip(TravelerTrip trip, CreatedDelivery delivery) {
  final linkedTrip = delivery.tripPublicId?.trim() ?? '';
  if (linkedTrip.isEmpty) return false;
  return !_deliveryLinkedToTrip(trip, delivery);
}

/// WW-… public id (or a non-TR lookup key) for `/shipment/:id`.
String? _shipmentNavId(CreatedDelivery delivery) {
  final publicId = delivery.publicId.trim();
  if (publicId.isNotEmpty && !_isTripPublicId(publicId)) return publicId;
  final id = delivery.id.trim();
  if (id.isNotEmpty && !_isTripPublicId(id)) return id;
  return null;
}

String? _iataCode(Iterable<String?> values) {
  final pattern = RegExp(r'\(([A-Z]{3})\)');
  for (final value in values) {
    final match = pattern.firstMatch(value?.trim() ?? '');
    if (match != null) return match.group(1);
  }
  return null;
}

bool _hasPlaceIdentity(Iterable<String?> values) {
  if (_iataCode(values) != null) return true;
  for (final value in values) {
    if ((value ?? '').trim().isNotEmpty) return true;
  }
  return false;
}

bool _endpointMatches(List<String?> tripValues, List<String?> deliveryValues) {
  final tripIata = _iataCode(tripValues);
  final deliveryIata = _iataCode(deliveryValues);
  if (tripIata != null && deliveryIata != null) {
    return tripIata == deliveryIata;
  }
  for (final tripValue in tripValues) {
    for (final deliveryValue in deliveryValues) {
      if (DestinationMatch.placesMatch(tripValue, deliveryValue)) return true;
    }
  }
  return false;
}

/// True when [delivery] is the same corridor as [trip] (city-to-city or
/// country-to-country). Both origin and destination must match so a
/// Lahore → Peshawar card cannot open a London → Paris shipment.
bool _tripMatchesDeliveryRoute(TravelerTrip trip, CreatedDelivery delivery) {
  final tripFrom = [
    trip.displayOrigin,
    trip.origin,
    trip.originAirport,
  ];
  final deliveryFrom = [
    delivery.exactDisplayFrom,
    delivery.fromCity,
    delivery.originAirport,
  ];
  final tripTo = [
    trip.displayDestination,
    trip.destination,
    trip.destinationAirport,
  ];
  final deliveryTo = [
    delivery.exactDisplayTo,
    delivery.toCity,
    delivery.destinationAirport,
  ];

  final fromMatch = _endpointMatches(tripFrom, deliveryFrom);
  final toMatch = _endpointMatches(tripTo, deliveryTo);
  if (fromMatch && toMatch) return true;

  // Country ISO is not a city identity. Only use it when neither side has a
  // city/airport/IATA to compare (otherwise LHR→CDG could open MAN→LYS).
  if (!trip.isCountryToCountry) return false;
  if (_hasPlaceIdentity(tripFrom) && _hasPlaceIdentity(deliveryFrom)) {
    return false;
  }
  if (_hasPlaceIdentity(tripTo) && _hasPlaceIdentity(deliveryTo)) {
    return false;
  }

  final fromCountry = DestinationMatch.codesMatch(
        trip.originCountryCode,
        delivery.fromCode,
      ) ||
      DestinationMatch.placesMatch(trip.originCountry, delivery.originCountry);
  final toCountry = DestinationMatch.codesMatch(
        trip.destinationCountryCode,
        delivery.toCode,
      ) ||
      DestinationMatch.placesMatch(
        trip.destinationCountry,
        delivery.destinationCountry,
      );
  return fromCountry && toCountry;
}

bool _deliveryBelongsToSelectedTrip(
  TravelerTrip trip,
  CreatedDelivery delivery,
) {
  if (_shipmentNavId(delivery) == null) return false;
  if (_deliveryLinkedToOtherTrip(trip, delivery)) return false;
  if (_deliveryLinkedToTrip(trip, delivery)) return true;
  return _tripMatchesDeliveryRoute(trip, delivery);
}

CreatedDelivery? _bestDeliveryForTrip(
  TravelerTrip trip,
  List<CreatedDelivery> deliveries,
) {
  CreatedDelivery? best;
  var bestScore = -1;
  final tripDay = DateTime(
    trip.travelDate.year,
    trip.travelDate.month,
    trip.travelDate.day,
  );

  for (final delivery in deliveries) {
    if (!_deliveryBelongsToSelectedTrip(trip, delivery)) continue;

    var score = _deliveryLinkedToTrip(trip, delivery) ? 1000 : 10;
    final deliveryDate = delivery.travelDateParsed;
    if (deliveryDate != null) {
      final deliveryDay = DateTime(
        deliveryDate.year,
        deliveryDate.month,
        deliveryDate.day,
      );
      final days = tripDay.difference(deliveryDay).inDays.abs();
      if (days == 0) {
        score += 50;
      } else if (days <= 2) {
        score += 20;
      } else if (days <= 5) {
        score += 8;
      }
    }
    if (score > bestScore) {
      bestScore = score;
      best = delivery;
    }
  }
  return best;
}

/// Opens the existing traveler WW-XXXX shipment screen for the delivery
/// linked to [trip] — the same `/shipment/{WW-id}?traveler=true` screen used
/// when opening that trip from My Trips / My Deliveries.
///
/// Never navigates to the removed TR-XXXX `/view-trip` screen.
Future<void> openTravelerTripDeliveryDetail(
  BuildContext context,
  TravelerTrip trip,
) async {
  final tripKey = trip.displayId.trim();
  if (tripKey.isEmpty) return;

  Future<void> openShipment(String shipmentId) async {
    final id = shipmentId.trim();
    if (!context.mounted || id.isEmpty || _isTripPublicId(id)) return;
    await context.push('/shipment/$id?traveler=true');
  }

  Future<void> openDelivery(CreatedDelivery delivery) async {
    if (!_deliveryBelongsToSelectedTrip(trip, delivery)) return;
    final id = _shipmentNavId(delivery);
    if (id == null) return;
    await openShipment(id);
  }

  final demoMode = context.read<DemoModeProvider>();
  final auth = context.read<AuthProvider>();
  final repo = DeliveryRepository(
    apiClient: auth.repository.apiClient,
    demoMode: demoMode,
  );

  Future<CreatedDelivery?> lookup(String id) async {
    final key = id.trim();
    if (key.isEmpty) return null;
    try {
      return await repo.getDelivery(key, role: 'traveler');
    } catch (_) {
      return null;
    }
  }

  if (!demoMode.enabled) {
    final lookupKeys = <String>[];
    final linked = trip.linkedDeliveryPublicId?.trim() ?? '';
    if (linked.isNotEmpty && !_isTripPublicId(linked)) {
      lookupKeys.add(linked);
    }
    for (final key in _tripKeys(trip)) {
      if (!lookupKeys.contains(key)) lookupKeys.add(key);
    }

    for (final key in lookupKeys) {
      final delivery = await lookup(key);
      if (!context.mounted) return;
      if (delivery == null || !_deliveryBelongsToSelectedTrip(trip, delivery)) {
        continue;
      }
      await openDelivery(delivery);
      return;
    }
  }

  try {
    final deliveries = await repo.listDeliveries(role: 'traveler');
    final matched = _bestDeliveryForTrip(trip, deliveries);
    if (!context.mounted) return;
    if (matched != null) {
      await openDelivery(matched);
      return;
    }
  } catch (_) {
    // Show the same missing-delivery message below.
  }

  if (!context.mounted) return;
  AppToast.info(
    context,
    'No delivery is linked to this trip yet.',
  );
}
