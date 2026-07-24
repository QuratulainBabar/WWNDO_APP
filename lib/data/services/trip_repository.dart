import '../../core/api/api_client.dart';
import '../../core/api/api_exception.dart';
import '../../core/config/demo_mode.dart';
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

  Map<String, dynamic> toJson() {
    final date =
        '${travelDate.year.toString().padLeft(4, '0')}-${travelDate.month.toString().padLeft(2, '0')}-${travelDate.day.toString().padLeft(2, '0')}';
    final body = <String, dynamic>{
      'tripType': tripType.apiValue,
      'travelDate': date,
      'luggageCapacityKg': luggageCapacityKg,
    };
    if (flightNumber != null && flightNumber!.trim().isNotEmpty) {
      body['flightNumber'] = flightNumber!.trim();
    }
    if (tripType == TripType.cityToCity) {
      body['fromCity'] = fromCity;
      body['toCity'] = toCity;
      if (fromCode != null && fromCode!.isNotEmpty) body['fromCode'] = fromCode;
      if (toCode != null && toCode!.isNotEmpty) body['toCode'] = toCode;
    } else {
      body['originCountry'] = originCountry;
      body['destinationCountry'] = destinationCountry;
      if (originCountryCode != null && originCountryCode!.isNotEmpty) {
        body['originCountryCode'] = originCountryCode;
      }
      if (destinationCountryCode != null && destinationCountryCode!.isNotEmpty) {
        body['destinationCountryCode'] = destinationCountryCode;
      }
      if (originAirport != null && originAirport!.isNotEmpty) {
        body['originAirport'] = originAirport;
      }
      if (destinationAirport != null && destinationAirport!.isNotEmpty) {
        body['destinationAirport'] = destinationAirport;
      }
    }
    return body;
  }
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
      origin: origin,
      destination: destination,
      travelDate: travelDate,
      luggageCapacityKg: (json['luggageCapacityKg'] as num?)?.toDouble() ?? 0,
      status: TripStatus.openBid,
    );
  }
}
