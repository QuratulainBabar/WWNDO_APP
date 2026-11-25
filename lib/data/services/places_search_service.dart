import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

import '../../core/api/api_client.dart';
import '../../core/api/api_exception.dart';
import '../../core/config/api_config.dart';
import '../../core/geo/world_airports.dart';
import '../../core/geo/world_cities.dart';
import '../../core/geo/world_countries.dart';
import '../models/meetup_location.dart';

/// Location search via the WWNGO backend Places proxy, with optional direct
/// Google Places API (New) and local city/airport catalog fallbacks.
///
/// Prefer the backend: Android-restricted API keys often return
/// "The caller does not have permission" for plain REST calls from the app.
class PlacesSearchService {
  PlacesSearchService({
    ApiClient? apiClient,
    http.Client? httpClient,
    String? googleMapsApiKey,
  })  : _api = apiClient,
        _http = httpClient ?? http.Client(),
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

  final ApiClient? _api;
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

    Object? lastError;

    // Backend first — uses the server key (no Android package attestation).
    if (_api != null) {
      try {
        return await _autocompleteBackend(trimmed, mode: mode);
      } catch (e) {
        lastError = e;
        if (kDebugMode) {
          debugPrint('Places backend autocomplete failed: $e');
        }
      }
    }

    if (_apiKey.isNotEmpty) {
      try {
        return await _autocompleteGoogle(trimmed, mode: mode);
      } catch (e) {
        lastError = e;
        if (kDebugMode) {
          debugPrint('Places Google autocomplete failed: $e');
        }
      }
    }

    // Offline / permission-safe fallback for route pickers.
    if (mode == 'cities' || mode == 'airports') {
      final local = _autocompleteLocal(trimmed, mode: mode);
      if (local.isNotEmpty) return local;
    }

    throw _toSearchException(lastError);
  }

  Future<List<MeetupLocation>> _autocompleteGoogle(
    String trimmed, {
    required String mode,
  }) async {
    final body = <String, dynamic>{'input': trimmed};
    final types = switch (mode) {
      // Include country so From/To city search also matches nation names.
      'cities' => const [
          'locality',
          'administrative_area_level_1',
          'country',
        ],
      'airports' => const ['airport'],
      _ => null,
    };
    if (types != null) {
      body['includedPrimaryTypes'] = types;
    }

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

    return suggestions
        .whereType<Map>()
        .map((raw) {
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
        })
        .where((p) => p.name.isNotEmpty || p.address.isNotEmpty)
        .toList();
  }

  Future<List<MeetupLocation>> _autocompleteBackend(
    String trimmed, {
    required String mode,
  }) async {
    final data = await _api!.get(
      '/places/autocomplete'
      '?q=${Uri.encodeQueryComponent(trimmed)}'
      '&mode=${Uri.encodeQueryComponent(mode)}',
      authenticated: true,
    );

    final predictions = data['predictions'];
    if (predictions is! List) return const [];

    return predictions
        .whereType<Map>()
        .map((raw) {
          final item = Map<String, dynamic>.from(raw);
          final name = (item['name'] as String? ?? '').trim();
          final address = (item['address'] as String? ?? '').trim();
          final placeId = (item['placeId'] as String?)?.trim();
          return MeetupLocation(
            name: name,
            address: address.isNotEmpty ? address : name,
            placeId: placeId?.isEmpty == true ? null : placeId,
          );
        })
        .where((p) => p.name.isNotEmpty || p.address.isNotEmpty)
        .toList();
  }

  List<MeetupLocation> _autocompleteLocal(
    String trimmed, {
    required String mode,
  }) {
    if (mode == 'airports') {
      return WorldAirports.search(trimmed, limit: 12)
          .map(
            (a) => MeetupLocation(
              name: a.resultTitle,
              address: a.locationSubtitle,
              countryCode: a.countryIso,
              locality: a.city,
            ),
          )
          .toList();
    }

    final cities = WorldCities.search(query: trimmed)
        .take(12)
        .map((c) {
          final country = WorldCountries.byIso(c.countryIso).name;
          return MeetupLocation(
            name: c.name,
            address: '${c.name}, $country',
            countryCode: c.countryIso,
            locality: c.name,
          );
        });

    final countries = WorldCountries.search(trimmed)
        .take(8)
        .map(
          (c) => MeetupLocation(
            name: c.name,
            address: c.name,
            countryCode: c.iso,
          ),
        );

    final seen = <String>{};
    final out = <MeetupLocation>[];
    for (final place in [...cities, ...countries]) {
      final key = '${place.name}|${place.countryCode ?? ''}'.toLowerCase();
      if (seen.add(key)) out.add(place);
    }
    return out;
  }

  /// Enrich a prediction with country ISO + coordinates (Place Details).
  /// Preserves the user's autocomplete selection ([MeetupLocation.name] and
  /// [MeetupLocation.address]) — only adds metadata from Place Details.
  Future<MeetupLocation> resolveDetails(MeetupLocation place) async {
    final placeId = place.placeId?.trim();
    if (placeId == null || placeId.isEmpty) return place;

    if (_api != null) {
      try {
        return await _resolveDetailsBackend(place, placeId);
      } catch (e) {
        if (kDebugMode) {
          debugPrint('Places backend details failed: $e');
        }
      }
    }

    if (_apiKey.isNotEmpty) {
      try {
        final resolved = await _resolveDetailsGoogle(place, placeId);
        if (resolved.latitude != null ||
            resolved.countryCode != null ||
            resolved.locality != null) {
          return resolved;
        }
      } catch (e) {
        if (kDebugMode) {
          debugPrint('Places Google details failed: $e');
        }
      }
    }

    return place;
  }

  Future<MeetupLocation> _resolveDetailsGoogle(
    MeetupLocation place,
    String placeId,
  ) async {
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
  }

  Future<MeetupLocation> _resolveDetailsBackend(
    MeetupLocation place,
    String placeId,
  ) async {
    final data = await _api!.get(
      '/places/details?placeId=${Uri.encodeQueryComponent(placeId)}',
      authenticated: true,
    );
    if (data.isEmpty) return place;

    final lat = (data['latitude'] as num?)?.toDouble();
    final lng = (data['longitude'] as num?)?.toDouble();
    final countryCode = (data['countryCode'] as String?)?.trim();
    final locality = (data['locality'] as String?)?.trim();
    final resolvedId = (data['placeId'] as String?)?.trim();

    return place.copyWith(
      placeId: (resolvedId != null && resolvedId.isNotEmpty)
          ? resolvedId
          : place.placeId,
      latitude: lat ?? place.latitude,
      longitude: lng ?? place.longitude,
      countryCode: (countryCode != null && countryCode.isNotEmpty)
          ? countryCode
          : place.countryCode,
      locality: (locality != null && locality.isNotEmpty)
          ? locality
          : place.locality,
    );
  }

  ApiException _toSearchException(Object? lastError) {
    if (lastError is ApiException) {
      final message = lastError.message.trim();
      final lower = message.toLowerCase();
      if (lower.contains('permission') ||
          lower.contains('permission_denied') ||
          lastError.statusCode == 403) {
        return const ApiException(
          message:
              'Location search is temporarily unavailable. Please try again.',
          code: 'PLACES_PERMISSION_DENIED',
          statusCode: 403,
        );
      }
      if (message.isNotEmpty) return lastError;
    }
    if (_apiKey.isEmpty && _api == null) {
      return const ApiException(
        message:
            'Google Maps is not configured. Set GOOGLE_MAPS_API_KEY for the app.',
        code: 'MAPS_NOT_CONFIGURED',
        statusCode: 503,
      );
    }
    return const ApiException(
      message: 'Unable to search locations. Please try again.',
      code: 'PLACES_NETWORK_ERROR',
    );
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
