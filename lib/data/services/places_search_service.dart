import 'dart:convert';

import 'package:http/http.dart' as http;

import '../../core/api/api_exception.dart';
import '../../core/config/api_config.dart';
import '../models/meetup_location.dart';

/// Location search via Google Places API (New).
/// Same key as backend `GOOGLE_MAPS_API_KEY` / [ApiConfig.googleMapsApiKey].
class PlacesSearchService {
  PlacesSearchService({
    http.Client? httpClient,
    String? googleMapsApiKey,
  })  : _http = httpClient ?? http.Client(),
        _apiKey = (googleMapsApiKey ?? ApiConfig.googleMapsApiKey).trim();

  static const _autocompleteUrl =
      'https://places.googleapis.com/v1/places:autocomplete';
  static const _placeDetailsBase = 'https://places.googleapis.com/v1/places';

  static const _autocompleteFieldMask =
      'suggestions.placePrediction.placeId,'
      'suggestions.placePrediction.text,'
      'suggestions.placePrediction.structuredFormat';

  static const _detailsFieldMask =
      'id,displayName,formattedAddress,location,addressComponents';

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

    final body = <String, dynamic>{'input': trimmed};
    final types = switch (mode) {
      'cities' => const ['locality', 'administrative_area_level_1'],
      'airports' => const ['airport'],
      _ => null,
    };
    if (types != null) {
      body['includedPrimaryTypes'] = types;
    }

    try {
      final response = await _http.post(
        Uri.parse(_autocompleteUrl),
        headers: {
          'Content-Type': 'application/json',
          'X-Goog-Api-Key': _apiKey,
          'X-Goog-FieldMask': _autocompleteFieldMask,
        },
        body: jsonEncode(body),
      );

      final json = _decodeJson(response.body);
      if (response.statusCode < 200 || response.statusCode >= 300) {
        throw ApiException(
          message: _errorMessage(json) ??
              'Places autocomplete failed (${response.statusCode})',
          statusCode: response.statusCode,
          code: 'PLACES_API_ERROR',
        );
      }

      final suggestions = json['suggestions'];
      if (suggestions is! List) return const [];

      return suggestions.whereType<Map>().map((raw) {
        final item = Map<String, dynamic>.from(raw);
        final prediction = item['placePrediction'];
        if (prediction is! Map) {
          return const MeetupLocation(name: '', address: '');
        }
        final pred = Map<String, dynamic>.from(prediction);
        final structured = pred['structuredFormat'];
        final structuredMap = structured is Map
            ? Map<String, dynamic>.from(structured)
            : const <String, dynamic>{};
        final mainText = _textValue(structuredMap['mainText']);
        final secondaryText = _textValue(structuredMap['secondaryText']);
        final fullText = _textValue(pred['text']);
        final name =
            mainText.isNotEmpty ? mainText : (fullText.isNotEmpty ? fullText : '');
        final address = fullText.isNotEmpty
            ? fullText
            : [
                if (mainText.isNotEmpty) mainText,
                if (secondaryText.isNotEmpty) secondaryText,
              ].join(', ');
        final placeId = (pred['placeId'] as String?)?.trim();
        return MeetupLocation(
          name: name,
          address: address,
          placeId: placeId?.isEmpty == true ? null : placeId,
        );
      }).where((p) => p.name.isNotEmpty || p.address.isNotEmpty).toList();
    } on ApiException {
      rethrow;
    } catch (_) {
      throw const ApiException(
        message: 'Unable to search locations. Please try again.',
        code: 'PLACES_NETWORK_ERROR',
      );
    }
  }

  /// Enrich a prediction with country ISO + coordinates (Place Details New).
  /// Preserves the user's autocomplete selection ([MeetupLocation.name] and
  /// [MeetupLocation.address]) — only adds metadata from Place Details.
  Future<MeetupLocation> resolveDetails(MeetupLocation place) async {
    final placeId = place.placeId?.trim();
    if (placeId == null || placeId.isEmpty) return place;
    if (_apiKey.isEmpty) return place;

    try {
      final resourceId = placeId.startsWith('places/')
          ? placeId.substring('places/'.length)
          : placeId;
      final uri = Uri.parse(
        '$_placeDetailsBase/${Uri.encodeComponent(resourceId)}',
      );

      final response = await _http.get(
        uri,
        headers: {
          'X-Goog-Api-Key': _apiKey,
          'X-Goog-FieldMask': _detailsFieldMask,
        },
      );
      if (response.statusCode < 200 || response.statusCode >= 300) {
        return place;
      }

      final resultMap = _decodeJson(response.body);
      if (resultMap.isEmpty) return place;

      final components = resultMap['addressComponents'];
      String? countryCode;
      String? locality;
      String? adminArea2;
      if (components is List) {
        for (final raw in components.whereType<Map>()) {
          final component = Map<String, dynamic>.from(raw);
          final types = component['types'];
          if (types is! List) continue;
          final typeSet = types.map((t) => t.toString()).toSet();
          final longName = (component['longText'] as String?)?.trim();
          if (typeSet.contains('country')) {
            countryCode = component['shortText'] as String?;
          } else if (typeSet.contains('locality') ||
              typeSet.contains('postal_town')) {
            if (longName != null && longName.isNotEmpty) locality = longName;
          } else if (typeSet.contains('administrative_area_level_2')) {
            if (longName != null && longName.isNotEmpty) adminArea2 = longName;
          }
        }
      }
      locality ??= adminArea2;

      final location = resultMap['location'];
      final lat =
          location is Map ? (location['latitude'] as num?)?.toDouble() : null;
      final lng =
          location is Map ? (location['longitude'] as num?)?.toDouble() : null;

      final formattedAddress =
          (resultMap['formattedAddress'] as String? ?? '').trim();
      final resolvedId = (resultMap['id'] as String?)?.trim();

      return place.copyWith(
        address: place.address.trim().isNotEmpty
            ? place.address
            : (formattedAddress.isNotEmpty ? formattedAddress : place.address),
        placeId: (resolvedId != null && resolvedId.isNotEmpty)
            ? resolvedId
            : place.placeId,
        latitude: lat ?? place.latitude,
        longitude: lng ?? place.longitude,
        countryCode: countryCode ?? place.countryCode,
        locality: locality ?? place.locality,
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

  String _textValue(dynamic value) {
    if (value is Map) {
      return (value['text'] as String? ?? '').trim();
    }
    if (value is String) return value.trim();
    return '';
  }

  String? _errorMessage(Map<String, dynamic> json) {
    final error = json['error'];
    if (error is Map) {
      final message = error['message'];
      if (message is String && message.trim().isNotEmpty) return message.trim();
    }
    return null;
  }

  Map<String, dynamic> _decodeJson(String body) {
    if (body.isEmpty) return const {};
    final decoded = jsonDecode(body);
    if (decoded is Map<String, dynamic>) return decoded;
    if (decoded is Map) return Map<String, dynamic>.from(decoded);
    return const {};
  }
}
