import '../../core/api/api_client.dart';
import '../../core/api/api_exception.dart';
import '../models/meetup_location.dart';

/// Location search via WWNGO backend Places proxy (`GOOGLE_MAPS_API_KEY` on server).
class PlacesSearchService {
  PlacesSearchService({required ApiClient apiClient}) : _apiClient = apiClient;

  final ApiClient _apiClient;

  Future<List<MeetupLocation>> search(String query) {
    return _autocomplete(query, mode: 'places');
  }

  /// City / locality autocomplete for From / To fields.
  Future<List<MeetupLocation>> searchCities(String query) {
    return _autocomplete(query, mode: 'cities');
  }

  Future<List<MeetupLocation>> _autocomplete(
    String query, {
    required String mode,
  }) async {
    final trimmed = query.trim();
    if (trimmed.length < 2) return const [];

    final encoded = Uri.encodeQueryComponent(trimmed);
    final data = await _apiClient.get(
      '/places/autocomplete?q=$encoded&mode=$mode',
      authenticated: true,
    );

    final list = data['predictions'];
    if (list is! List) return const [];
    return list
        .whereType<Map<String, dynamic>>()
        .map(MeetupLocation.fromJson)
        .where((p) => p.name.isNotEmpty || p.address.isNotEmpty)
        .toList();
  }

  /// Enrich a prediction with country ISO + coordinates (Places Details).
  Future<MeetupLocation> resolveDetails(MeetupLocation place) async {
    final placeId = place.placeId?.trim();
    if (placeId == null || placeId.isEmpty) return place;

    try {
      final data = await _apiClient.get(
        '/places/details?placeId=${Uri.encodeQueryComponent(placeId)}',
        authenticated: true,
      );
      final detailed = MeetupLocation.fromJson(data);
      return place.copyWith(
        name: detailed.name.isNotEmpty ? detailed.name : place.name,
        address: detailed.address.isNotEmpty ? detailed.address : place.address,
        placeId: detailed.placeId ?? place.placeId,
        latitude: detailed.latitude ?? place.latitude,
        longitude: detailed.longitude ?? place.longitude,
        countryCode: detailed.countryCode ?? place.countryCode,
      );
    } on ApiException {
      return place;
    }
  }
}
