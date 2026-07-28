import '../../core/api/api_client.dart';
import '../../core/api/api_exception.dart';
import '../../core/config/demo_mode.dart';
import '../models/sender_trip_request.dart';
import '../models/traveler_bid.dart';
import '../models/traveler_trip.dart';

enum TripType {
  cityToCity,
  countryToCountry,
}

extension TripTypeApi on TripType {
  String get apiValue => switch (this) {
        TripType.cityToCity => 'city_to_city',
        TripType.countryToCountry => 'country_to_country',
      };
}

class CreateTripRequest {
  const CreateTripRequest({
    required this.tripType,
    required this.travelDate,
    required this.luggageCapacityKg,
    this.fromCity,
    this.fromCode,
    this.toCity,
    this.toCode,
    this.originCountry,
    this.originCountryCode,
    this.destinationCountry,
    this.destinationCountryCode,
    this.originAirport,
    this.destinationAirport,
    this.flightNumber,
  });

  final TripType tripType;
  final DateTime travelDate;
  final double luggageCapacityKg;
  final String? fromCity;
  final String? fromCode;
  final String? toCity;
  final String? toCode;
  final String? originCountry;
  final String? originCountryCode;
  final String? destinationCountry;
  final String? destinationCountryCode;
  final String? originAirport;
  final String? destinationAirport;
  final String? flightNumber;

  Map<String, dynamic> toJson() => _tripBodyJson(
        tripType: tripType,
        travelDate: travelDate,
        luggageCapacityKg: luggageCapacityKg,
        fromCity: fromCity,
        fromCode: fromCode,
        toCity: toCity,
        toCode: toCode,
        originCountry: originCountry,
        originCountryCode: originCountryCode,
        destinationCountry: destinationCountry,
        destinationCountryCode: destinationCountryCode,
        originAirport: originAirport,
        destinationAirport: destinationAirport,
        flightNumber: flightNumber,
      );
}

/// PATCH /api/v1/trips/:id — same fields as create (except trip type).
class UpdateTripRequest {
  const UpdateTripRequest({
    required this.travelDate,
    required this.luggageCapacityKg,
    required this.tripType,
    this.fromCity,
    this.fromCode,
    this.toCity,
    this.toCode,
    this.originCountry,
    this.originCountryCode,
    this.destinationCountry,
    this.destinationCountryCode,
    this.originAirport,
    this.destinationAirport,
    this.flightNumber,
  });

  final DateTime travelDate;
  final double luggageCapacityKg;
  final TripType tripType;
  final String? fromCity;
  final String? fromCode;
  final String? toCity;
  final String? toCode;
  final String? originCountry;
  final String? originCountryCode;
  final String? destinationCountry;
  final String? destinationCountryCode;
  final String? originAirport;
  final String? destinationAirport;
  final String? flightNumber;

  factory UpdateTripRequest.fromCreateRequest(CreateTripRequest request) {
    return UpdateTripRequest(
      travelDate: request.travelDate,
      luggageCapacityKg: request.luggageCapacityKg,
      tripType: request.tripType,
      fromCity: request.fromCity,
      fromCode: request.fromCode,
      toCity: request.toCity,
      toCode: request.toCode,
      originCountry: request.originCountry,
      originCountryCode: request.originCountryCode,
      destinationCountry: request.destinationCountry,
      destinationCountryCode: request.destinationCountryCode,
      originAirport: request.originAirport,
      destinationAirport: request.destinationAirport,
      flightNumber: request.flightNumber,
    );
  }

  Map<String, dynamic> toJson() => _tripBodyJson(
        tripType: tripType,
        travelDate: travelDate,
        luggageCapacityKg: luggageCapacityKg,
        fromCity: fromCity,
        fromCode: fromCode,
        toCity: toCity,
        toCode: toCode,
        originCountry: originCountry,
        originCountryCode: originCountryCode,
        destinationCountry: destinationCountry,
        destinationCountryCode: destinationCountryCode,
        originAirport: originAirport,
        destinationAirport: destinationAirport,
        flightNumber: flightNumber,
        includeEmptyFlightNumber: true,
      );
}

Map<String, dynamic> _tripBodyJson({
  required TripType tripType,
  required DateTime travelDate,
  required double luggageCapacityKg,
  String? fromCity,
  String? fromCode,
  String? toCity,
  String? toCode,
  String? originCountry,
  String? originCountryCode,
  String? destinationCountry,
  String? destinationCountryCode,
  String? originAirport,
  String? destinationAirport,
  String? flightNumber,
  bool includeEmptyFlightNumber = false,
}) {
  final date =
      '${travelDate.year.toString().padLeft(4, '0')}-${travelDate.month.toString().padLeft(2, '0')}-${travelDate.day.toString().padLeft(2, '0')}';
  final body = <String, dynamic>{
    'tripType': tripType.apiValue,
    'travelDate': date,
    'luggageCapacityKg': luggageCapacityKg,
  };
  if (flightNumber != null && flightNumber.trim().isNotEmpty) {
    body['flightNumber'] = flightNumber.trim();
  } else if (includeEmptyFlightNumber) {
    body['flightNumber'] = '';
  }
  if (tripType == TripType.cityToCity) {
    body['fromCity'] = fromCity;
    body['toCity'] = toCity;
    if (fromCode != null && fromCode.isNotEmpty) body['fromCode'] = fromCode;
    if (toCode != null && toCode.isNotEmpty) body['toCode'] = toCode;
  } else {
    body['originCountry'] = originCountry;
    body['destinationCountry'] = destinationCountry;
    if (originCountryCode != null && originCountryCode.isNotEmpty) {
      body['originCountryCode'] = originCountryCode;
    }
    if (destinationCountryCode != null && destinationCountryCode.isNotEmpty) {
      body['destinationCountryCode'] = destinationCountryCode;
    }
    if (originAirport != null && originAirport.isNotEmpty) {
      body['originAirport'] = originAirport;
    }
    if (destinationAirport != null && destinationAirport.isNotEmpty) {
      body['destinationAirport'] = destinationAirport;
    }
  }
  return body;
}

/// Backend trips API for traveler trip posting and listing.
class TripRepository {
  TripRepository({
    required ApiClient apiClient,
    DemoModeProvider? demoMode,
  })  : _apiClient = apiClient,
        _demoMode = demoMode;

  final ApiClient _apiClient;
  final DemoModeProvider? _demoMode;

  bool get _isDemoMode => _demoMode?.enabled ?? false;

  /// POST /api/v1/trips
  Future<TravelerTrip> createTrip(CreateTripRequest request) async {
    if (_isDemoMode) {
      throw const ApiException(
        message: 'Trip posting is unavailable in demo mode.',
        code: 'DEMO_MODE',
      );
    }

    final data = await _apiClient.post(
      '/trips',
      body: request.toJson(),
      authenticated: true,
    );
    return _mapTrip(data);
  }

  /// GET /api/v1/trips/discover
  Future<List<TravelerTrip>> listDiscoverableTrips({
    TripType? tripType,
    int limit = 50,
  }) async {
    if (_isDemoMode) return const [];

    final query = <String>['limit=$limit'];
    if (tripType != null) {
      query.add('tripType=${tripType.apiValue}');
    }
    final data = await _apiClient.get(
      '/trips/discover?${query.join('&')}',
      authenticated: true,
    );
    final list = data['trips'];
    if (list is! List) return const <TravelerTrip>[];
    return list
        .whereType<Map>()
        .map((item) => _mapTrip(Map<String, dynamic>.from(item)))
        .toList();
  }

  /// GET /api/v1/trips/sender-requests/count
  Future<int> countSenderRequests() async {
    if (_isDemoMode) return 0;
    final data = await _apiClient.get(
      '/trips/sender-requests/count',
      authenticated: true,
    );
    return (data['count'] as num?)?.toInt() ?? 0;
  }

  /// GET /api/v1/trips/sender-requests
  Future<List<SenderTripRequest>> listSenderRequests() async {
    if (_isDemoMode) return const [];
    final data = await _apiClient.get(
      '/trips/sender-requests',
      authenticated: true,
    );
    final list = data['requests'];
    if (list is! List) return const <SenderTripRequest>[];
    return list
        .whereType<Map>()
        .map((item) => SenderTripRequest.fromJson(Map<String, dynamic>.from(item)))
        .toList();
  }

  /// GET /api/v1/trips/sender-request-trips
  Future<List<({TravelerTrip trip, int requestCount})>>
      listSenderRequestTrips() async {
    if (_isDemoMode) return const [];
    final data = await _apiClient.get(
      '/trips/sender-request-trips',
      authenticated: true,
    );
    final list = data['trips'];
    if (list is! List) return const [];
    return list.whereType<Map>().map((item) {
      final map = Map<String, dynamic>.from(item);
      return (
        trip: _mapTrip(map),
        requestCount: (map['requestCount'] as num?)?.toInt() ?? 0,
      );
    }).toList();
  }

  /// GET /api/v1/trips/:id/sender-requests
  Future<List<SenderTripRequest>> listSenderRequestsForTrip(
    String tripId,
  ) async {
    if (_isDemoMode) return const [];
    final data = await _apiClient.get(
      '/trips/$tripId/sender-requests',
      authenticated: true,
    );
    final list = data['requests'];
    if (list is! List) return const <SenderTripRequest>[];
    return list
        .whereType<Map>()
        .map((item) => SenderTripRequest.fromJson(Map<String, dynamic>.from(item)))
        .toList();
  }

  /// GET /api/v1/trips/sender-requests/:requestId
  Future<SenderTripRequest> getSenderRequest(String requestId) async {
    if (_isDemoMode) {
      throw const ApiException(
        message: 'Sender request details are unavailable in demo mode.',
        code: 'DEMO_MODE',
      );
    }
    final data = await _apiClient.get(
      '/trips/sender-requests/${Uri.encodeComponent(requestId)}',
      authenticated: true,
    );
    return SenderTripRequest.fromJson(Map<String, dynamic>.from(data));
  }

  /// POST /api/v1/trips/sender-requests/:requestId/counter-offers
  Future<TravelerBid> sendCounterOffer({
    required String requestId,
    required double amount,
  }) async {
    if (_isDemoMode) {
      throw const ApiException(
        message: 'Counter offers are unavailable in demo mode.',
        code: 'DEMO_MODE',
      );
    }
    final data = await _apiClient.post(
      '/trips/sender-requests/${Uri.encodeComponent(requestId)}/counter-offers',
      body: {'amount': amount},
      authenticated: true,
    );
    return TravelerBid.fromJson(Map<String, dynamic>.from(data));
  }

  /// GET /api/v1/trips/counter-offers
  Future<List<TravelerBid>> listCounterOffers() async {
    if (_isDemoMode) return const [];
    final data = await _apiClient.get(
      '/trips/counter-offers',
      authenticated: true,
    );
    final list = data['offers'];
    if (list is! List) return const <TravelerBid>[];
    return list
        .whereType<Map>()
        .map((item) => TravelerBid.fromJson(Map<String, dynamic>.from(item)))
        .toList();
  }

  /// GET /api/v1/trips/counter-offers/:offerId
  Future<TravelerBid> getCounterOffer(String offerId) async {
    if (_isDemoMode) {
      throw const ApiException(
        message: 'Counter offer details are unavailable in demo mode.',
        code: 'DEMO_MODE',
      );
    }
    final data = await _apiClient.get(
      '/trips/counter-offers/${Uri.encodeComponent(offerId)}',
      authenticated: true,
    );
    return TravelerBid.fromJson(Map<String, dynamic>.from(data));
  }

  /// POST /api/v1/trips/:id/sender-requests/read
  /// Marks pending requests for the trip as read; returns remaining unread count.
  Future<({int markedCount, int unreadCount, int notificationsUnread})>
      markSenderRequestsRead(String tripId) async {
    if (_isDemoMode) {
      return (markedCount: 0, unreadCount: 0, notificationsUnread: 0);
    }
    final data = await _apiClient.post(
      '/trips/$tripId/sender-requests/read',
      authenticated: true,
    );
    return (
      markedCount: (data['markedCount'] as num?)?.toInt() ?? 0,
      unreadCount: (data['unreadCount'] as num?)?.toInt() ?? 0,
      notificationsUnread: (data['notificationsUnread'] as num?)?.toInt() ?? 0,
    );
  }

  /// GET /api/v1/trips/discover/:id
  Future<TravelerTrip> getDiscoverableTrip(String idOrPublicId) async {
    if (_isDemoMode) {
      throw const ApiException(
        message: 'Trip details are unavailable in demo mode.',
        code: 'DEMO_MODE',
      );
    }

    final id = idOrPublicId.trim();
    if (id.isEmpty) {
      throw const ApiException(
        message: 'Trip not found',
        code: 'NOT_FOUND',
        statusCode: 404,
      );
    }

    final data = await _apiClient.get(
      '/trips/discover/${Uri.encodeComponent(id)}',
      authenticated: true,
    );
    return _mapTrip(data);
  }

  /// GET /api/v1/trips
  Future<List<TravelerTrip>> listMyTrips() async {
    if (_isDemoMode) return const [];

    final data = await _apiClient.get('/trips', authenticated: true);
    final list = data['trips'];
    if (list is! List) return const <TravelerTrip>[];
    return list
        .whereType<Map>()
        .map((item) => _mapTrip(Map<String, dynamic>.from(item)))
        .toList();
  }

  /// GET /api/v1/trips/:id
  Future<TravelerTrip> getMyTrip(String idOrPublicId) async {
    if (_isDemoMode) {
      throw const ApiException(
        message: 'Trip lookup is unavailable in demo mode.',
        code: 'DEMO_MODE',
      );
    }

    final data = await _apiClient.get(
      '/trips/$idOrPublicId',
      authenticated: true,
    );
    return _mapTrip(data);
  }

  /// PATCH /api/v1/trips/:id
  Future<TravelerTrip> updateTrip(
    String idOrPublicId,
    UpdateTripRequest request,
  ) async {
    if (_isDemoMode) {
      throw const ApiException(
        message: 'Edit is unavailable in demo mode.',
        code: 'DEMO_MODE',
      );
    }

    final data = await _apiClient.patch(
      '/trips/$idOrPublicId',
      body: request.toJson(),
      authenticated: true,
    );
    return _mapTrip(data);
  }

  /// POST /api/v1/trips/:id/cancel
  Future<TravelerTrip> cancelTrip(String idOrPublicId) async {
    if (_isDemoMode) {
      throw const ApiException(
        message: 'Cancel is unavailable in demo mode.',
        code: 'DEMO_MODE',
      );
    }

    final data = await _apiClient.post(
      '/trips/$idOrPublicId/cancel',
      authenticated: true,
    );
    return _mapTrip(data);
  }

  TravelerTrip _mapTrip(Map<String, dynamic> json) {
    final travelRaw = json['travelDate'];
    final travelDate = travelRaw is String
        ? (DateTime.tryParse(travelRaw) ?? DateTime.now())
        : DateTime.now();
    final origin = json['origin'] as String? ??
        json['fromCity'] as String? ??
        json['originCountry'] as String? ??
        '';
    final destination = json['destination'] as String? ??
        json['toCity'] as String? ??
        json['destinationCountry'] as String? ??
        '';
    return TravelerTrip(
      id: json['id'] as String? ?? json['publicId'] as String? ?? '',
      publicId: json['publicId'] as String?,
      origin: origin,
      destination: destination,
      travelDate: travelDate,
      luggageCapacityKg: (json['luggageCapacityKg'] as num?)?.toDouble() ?? 0,
      status: tripStatusFromApi(json['status'] as String?),
      tripType: json['tripType'] as String?,
      travelerName: json['travelerName'] as String?,
      travelerRating: (json['travelerRating'] as num?)?.toDouble(),
      travelerReviewCount: (json['travelerReviewCount'] as num?)?.toInt(),
      flightNumber: json['flightNumber'] as String?,
      fromCode: json['fromCode'] as String?,
      toCode: json['toCode'] as String?,
      originCountry: json['originCountry'] as String?,
      destinationCountry: json['destinationCountry'] as String?,
      originCountryCode: json['originCountryCode'] as String?,
      destinationCountryCode: json['destinationCountryCode'] as String?,
      originAirport: json['originAirport'] as String?,
      destinationAirport: json['destinationAirport'] as String?,
    );
  }
}
