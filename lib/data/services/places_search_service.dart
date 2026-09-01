import 'dart:convert';

import 'package:http/http.dart' as http;

import '../../core/api/api_client.dart';
import '../../core/api/api_exception.dart';
import '../../core/config/api_config.dart';
import '../models/meetup_location.dart';

/// Location search via Google Places API (same key as backend `GOOGLE_MAPS_API_KEY`).
class PlacesSearchService {
  PlacesSearchService({
    ApiClient? apiClient,
    http.Client? httpClient,
    String? googleMapsApiKey,
  })  : _http = httpClient ?? http.Client(),
        _apiKey = (googleMapsApiKey ?? ApiConfig.googleMapsApiKey).trim();

  static const _autocompleteUrl =
      'https://maps.googleapis.com/maps/api/place/autocomplete/json';
  static const _detailsUrl =
      'https://maps.googleapis.com/maps/api/place/details/json';

  final http.Client _http;
  final String _apiKey;

  Future<List<MeetupLocation>> search(String query) {
    return _autocomplete(query, mode: 'places');
  }

  /// City / locality autocomplete for From / To fields.
  Future<List<MeetupLocation>> searchCities(String query) {
    return _autocomplete(query, mode: 'cities');
  }

  /// Airport autocomplete for country-to-country route fields.
  Future<List<MeetupLocation>> searchAirports(String query) {
    return _autocomplete(query, mode: 'airports');
  }

  Future<List<MeetupLocation>> _autocomplete(
    String query, {
    required String mode,
  }) async {
    final trimmed = query.trim();
    if (trimmed.length < 2) return const [];
    _assertConfigured();

    final types = switch (mode) {
      'cities' => '(cities)',
      'airports' => 'airport',
      _ => 'establishment|geocode',
    };

    final uri = Uri.parse(_autocompleteUrl).replace(
      queryParameters: {
        'input': trimmed,
        'key': _apiKey,
        'types': types,
      },
    );

    try {
      final response = await _http.get(uri);
      final json = _decodeJson(response.body);
      final status = json['status'] as String? ?? 'UNKNOWN';

      if (status != 'OK' && status != 'ZERO_RESULTS') {
        throw ApiException(
          message: json['error_message'] as String? ??
              'Places autocomplete failed ($status)',
          statusCode: response.statusCode,
          code: 'PLACES_API_ERROR',
        );
      }

      final list = json['predictions'];
      if (list is! List) return const [];

      return list.whereType<Map>().map((item) {
        final map = Map<String, dynamic>.from(item);
        final structured = map['structured_formatting'];
        final structuredMap = structured is Map
            ? Map<String, dynamic>.from(structured)
            : const <String, dynamic>{};
        return MeetupLocation(
          name: structuredMap['main_text'] as String? ??
              map['description'] as String? ??
              '',
          address: map['description'] as String? ?? '',
          placeId: map['place_id'] as String?,
        );
      }).where((p) => p.name.isNotEmpty || p.address.isNotEmpty).toList();
    } on ApiException {
      rethrow;
    } catch (e) {
      throw ApiException(
        message: 'Unable to search locations. Please try again.',
        code: 'PLACES_NETWORK_ERROR',
      );
    }
  }

  /// Enrich a prediction with country ISO + coordinates (Places Details).
  /// Preserves the user's autocomplete selection ([MeetupLocation.name] and
  /// [MeetupLocation.address]) — only adds metadata from Place Details.
  Future<MeetupLocation> resolveDetails(MeetupLocation place) async {
    final placeId = place.placeId?.trim();
    if (placeId == null || placeId.isEmpty) return place;
    if (_apiKey.isEmpty) return place;

    try {
      final uri = Uri.parse(_detailsUrl).replace(
        queryParameters: {
          'place_id': placeId,
          'fields':
              'place_id,name,formatted_address,geometry,address_component',
          'key': _apiKey,
        },
      );

      final response = await _http.get(uri);
      final json = _decodeJson(response.body);
      final status = json['status'] as String? ?? 'UNKNOWN';
      if (status != 'OK') return place;

      final result = json['result'];
      if (result is! Map) return place;
      final resultMap = Map<String, dynamic>.from(result);

      final components = resultMap['address_components'];
      String? countryCode;
      if (components is List) {
        for (final raw in components.whereType<Map>()) {
          final component = Map<String, dynamic>.from(raw);
          final types = component['types'];
          if (types is! List) continue;
          final typeSet = types.map((t) => t.toString()).toSet();
          if (typeSet.contains('country')) {
            countryCode = component['short_name'] as String?;
            break;
          }
        }
      }

      final geometry = resultMap['geometry'];
      final location = geometry is Map ? geometry['location'] : null;
      final lat = location is Map ? (location['lat'] as num?)?.toDouble() : null;
      final lng = location is Map ? (location['lng'] as num?)?.toDouble() : null;

      final formattedAddress = (resultMap['formatted_address'] as String? ??
              resultMap['name'] as String? ??
              '')
          .trim();

      return place.copyWith(
        address: place.address.trim().isNotEmpty
            ? place.address
            : (formattedAddress.isNotEmpty ? formattedAddress : place.address),
        placeId: resultMap['place_id'] as String? ?? place.placeId,
        latitude: lat ?? place.latitude,
        longitude: lng ?? place.longitude,
        countryCode: countryCode ?? place.countryCode,
      );
    } catch (_) {
      return place;
    }
  }

  void _assertConfigured() {
    if (_apiKey.isEmpty) {
      throw const ApiException(
        message:
            'Google Maps is not configured. Set GOOGLE_MAPS_API_KEY for the app.',
        code: 'MAPS_NOT_CONFIGURED',
        statusCode: 503,
      );
    }
  }

  Map<String, dynamic> _decodeJson(String body) {
    if (body.isEmpty) return const {};
    final decoded = jsonDecode(body);
    if (decoded is Map<String, dynamic>) return decoded;
    if (decoded is Map) return Map<String, dynamic>.from(decoded);
    return const {};
  }
}
