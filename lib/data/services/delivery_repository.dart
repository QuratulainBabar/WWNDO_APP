import 'dart:math';

import '../../core/api/api_client.dart';
import '../../core/api/api_exception.dart';
import '../../core/config/demo_mode.dart';
import '../../core/geo/meetup_destination_validation.dart';
import '../../core/geo/meetup_origin_validation.dart';
import '../models/created_delivery.dart';
import '../models/matching_traveler.dart';
import '../models/traveler_request_summary.dart';

/// Result of POST /api/v1/deliveries/:id/cancel
class CancelDeliveryResult {
  const CancelDeliveryResult({
    required this.delivery,
    this.platformFeesRefunded,
  });

  final CreatedDelivery delivery;
  final bool? platformFeesRefunded;
}

/// Backend delivery API access for the Sender Create Delivery flow.
class DeliveryRepository {
  DeliveryRepository({
    required ApiClient apiClient,
    DemoModeProvider? demoMode,
  })  : _apiClient = apiClient,
        _demoMode = demoMode;

  final ApiClient _apiClient;
  final DemoModeProvider? _demoMode;

  /// In-memory deliveries created this session (demo mode + create race buffer).
  static final List<CreatedDelivery> _sessionCreated = [];

  bool get _isDemoMode => _demoMode?.enabled ?? false;

  static void rememberCreated(CreatedDelivery delivery) {
    _sessionCreated.removeWhere(
      (d) => d.id == delivery.id || d.displayId == delivery.displayId,
    );
    _sessionCreated.insert(0, delivery);
  }

  static void clearSessionCreated() => _sessionCreated.clear();

  /// POST /api/v1/deliveries (multipart)
  Future<CreatedDelivery> createDelivery(CreateDeliveryRequest request) async {
    _validateLocal(request);

    if (_isDemoMode) {
      throw const ApiException(
        message:
            'Demo mode is on — the parcel is not saved on the server, so the receiver will not get Alerts or email. Turn off Demo mode, sign in again, then post the delivery.',
        code: 'DEMO_MODE',
      );
    }

    final data = await _apiClient.postMultipart(
      '/deliveries',
      fields: request.toFormFields(),
      files: [
        for (final path in request.photoPaths)
          MultipartFilePart(field: 'photos', filePath: path),
      ],
      authenticated: true,
    );

    final created = CreatedDelivery.fromJson(data);
    rememberCreated(created);
    return created;
  }

  /// GET /api/v1/deliveries?role=
  Future<List<CreatedDelivery>> listDeliveries({String role = 'sender'}) async {
    if (_isDemoMode) {
      // Never treat sender session creates as receiver "incoming" parcels.
      // That fake list had no Alerts / email and looked like a live delivery.
      if (role == 'receiver') return const [];
      return List<CreatedDelivery>.unmodifiable(_sessionCreated);
    }

    final data = await _apiClient.get(
      '/deliveries?role=${Uri.encodeQueryComponent(role)}',
      authenticated: true,
    );
    final list = _extractDeliveriesList(data);
    final parsed = <CreatedDelivery>[];
    for (final item in list) {
      if (item is! Map) continue;
      try {
        parsed.add(
          CreatedDelivery.fromJson(Map<String, dynamic>.from(item)),
        );
      } catch (e) {
        assert(() {
          // Ignore malformed rows so one bad item cannot blank the whole list.
          // ignore: avoid_print
          print('listDeliveries parse skip: $e');
          return true;
        }());
      }
    }
    return parsed;
  }

  static List<dynamic> _extractDeliveriesList(Map<String, dynamic> data) {
    final direct = data['deliveries'];
    if (direct is List) return direct;
    // Some gateways nest again: { data: { deliveries: [...] } } already unwrapped
    // by ApiClient — still accept a bare list under alternate keys.
    final nested = data['data'];
    if (nested is Map && nested['deliveries'] is List) {
      return nested['deliveries'] as List;
    }
    if (nested is List) return nested;
    return const [];
  }

  /// GET /api/v1/deliveries/:id?role=
  Future<CreatedDelivery> getDelivery(
    String id, {
    String? role,
  }) async {
    if (_isDemoMode) {
      throw const ApiException(
        message: 'Delivery lookup is unavailable in demo mode.',
        code: 'DEMO_MODE',
      );
    }

    final suffix = role == null || role.isEmpty
        ? ''
        : '?role=${Uri.encodeQueryComponent(role)}';
    final data = await _apiClient.get(
      '/deliveries/${Uri.encodeComponent(id)}$suffix',
      authenticated: true,
    );
    return CreatedDelivery.fromJson(data);
  }

  /// POST /api/v1/deliveries/:id/accept
  Future<CreatedDelivery> acceptAsReceiver(
    String id, {
    String? paymentIntentId,
  }) async {
    if (_isDemoMode) {
      throw const ApiException(
        message: 'Accept is unavailable in demo mode.',
        code: 'DEMO_MODE',
      );
    }
    final body = <String, dynamic>{};
    if (paymentIntentId != null && paymentIntentId.isNotEmpty) {
      body['paymentIntentId'] = paymentIntentId;
    }
    final data = await _apiClient.post(
      '/deliveries/$id/accept',
      body: body.isEmpty ? null : body,
      authenticated: true,
    );
    return CreatedDelivery.fromJson(data);
  }

  /// POST /api/v1/deliveries/:id/request-traveler
  Future<void> requestTraveler({
    required String deliveryId,
    required String tripId,
    int matchScore = 0,
  }) async {
    if (_isDemoMode) {
      throw const ApiException(
        message: 'Request traveler is unavailable in demo mode.',
        code: 'DEMO_MODE',
      );
    }
    await _apiClient.post(
      '/deliveries/$deliveryId/request-traveler',
      authenticated: true,
      body: {
        'tripId': tripId,
        'matchScore': matchScore,
      },
    );
  }

  /// POST /api/v1/deliveries/:id/decline
  Future<CreatedDelivery> declineAsReceiver(String id) async {
    if (_isDemoMode) {
      throw const ApiException(
        message: 'Decline is unavailable in demo mode.',
        code: 'DEMO_MODE',
      );
    }
    final data = await _apiClient.post(
      '/deliveries/$id/decline',
      authenticated: true,
    );
    return CreatedDelivery.fromJson(data);
  }

  /// Live counts for posted deliveries where the receiver has accepted.
  Future<Map<String, int>> fetchMatchingTravelerCounts(
    List<CreatedDelivery> deliveries,
  ) async {
    if (_isDemoMode) return {};

    final counts = <String, int>{};
    final eligible = deliveries.where(
      (d) => d.status == 'posted' && d.isReceiverAccepted,
    );

    await Future.wait(
      eligible.map((delivery) async {
        final apiId = delivery.displayId;
        try {
          final travelers = await listMatchingTravelers(apiId);
          final count = travelers.length;
          counts[apiId] = count;
          if (delivery.id.isNotEmpty) {
            counts[delivery.id] = count;
          }
        } catch (_) {
          // Non-critical: keep badge without a count on failure.
        }
      }),
    );

    return counts;
  }

  /// Live traveler-request summaries for posted deliveries (sender badges / phases).
  Future<Map<String, List<TravelerRequestSummary>>>
      fetchTravelerRequestsForDeliveries(
    List<CreatedDelivery> deliveries,
  ) async {
    if (_isDemoMode) return {};

    final requestsByKey = <String, List<TravelerRequestSummary>>{};
    final eligible = deliveries.where(
      (d) => d.status == 'posted' && d.isReceiverAccepted,
    );

    await Future.wait(
      eligible.map((delivery) async {
        final apiId = delivery.displayId;
        try {
          final requests = await listTravelerRequests(apiId);
          requestsByKey[apiId] = requests;
          if (delivery.id.isNotEmpty) {
            requestsByKey[delivery.id] = requests;
          }
        } catch (_) {
          // Non-critical: keep last-known badge on failure.
        }
      }),
    );

    return requestsByKey;
  }

  /// GET /api/v1/deliveries/:id/matching-travelers
  /// Backend is the single source of truth (destination + luggage on open
  /// trips). Home badge counts call this same method — do not re-filter with
  /// the browse TripDateWindow or counts diverge from the list / notifies.
  Future<List<MatchingTraveler>> listMatchingTravelers(String deliveryId) async {
    if (_isDemoMode) return const [];

    final data = await _apiClient.get(
      '/deliveries/$deliveryId/matching-travelers',
      authenticated: true,
    );
    final list = data['travelers'];
    if (list is! List) return const <MatchingTraveler>[];
    return list
        .whereType<Map>()
        .map(
          (item) => MatchingTraveler.fromJson(Map<String, dynamic>.from(item)),
        )
        .toList();
  }

  /// GET /api/v1/deliveries/:id/traveler-requests
  Future<List<TravelerRequestSummary>> listTravelerRequests(
    String deliveryId,
  ) async {
    if (_isDemoMode) return const [];

    final data = await _apiClient.get(
      '/deliveries/$deliveryId/traveler-requests',
      authenticated: true,
    );
    final list = data['requests'];
    if (list is! List) return const <TravelerRequestSummary>[];
    return list
        .whereType<Map>()
        .map(
          (item) =>
              TravelerRequestSummary.fromJson(Map<String, dynamic>.from(item)),
        )
        .toList();
  }

  /// PATCH /api/v1/deliveries/:id
  Future<CreatedDelivery> updateDelivery(
    String id,
    UpdateDeliveryRequest request,
  ) async {
    if (_isDemoMode) {
      throw const ApiException(
        message: 'Edit is unavailable in demo mode.',
        code: 'DEMO_MODE',
      );
    }

    final newPhotos = request.newPhotoPaths
        .where((path) => path.trim().isNotEmpty && !path.startsWith('http'))
        .toList();

    if (newPhotos.isNotEmpty) {
      final data = await _apiClient.patchMultipart(
        '/deliveries/$id',
        fields: request.toFormFields(),
        files: [
          for (final path in newPhotos)
            MultipartFilePart(field: 'photos', filePath: path),
        ],
        authenticated: true,
      );
      return CreatedDelivery.fromJson(data);
    }

    final data = await _apiClient.patch(
      '/deliveries/$id',
      body: request.toFormFields(),
      authenticated: true,
    );
    return CreatedDelivery.fromJson(data);
  }

  /// POST /api/v1/deliveries/:id/cancel
  Future<CancelDeliveryResult> cancelDelivery(String id) async {
    if (_isDemoMode) {
      throw const ApiException(
        message: 'Cancel is unavailable in demo mode.',
        code: 'DEMO_MODE',
      );
    }

    final data = await _apiClient.post(
      '/deliveries/$id/cancel',
      authenticated: true,
    );
    return CancelDeliveryResult(
      delivery: CreatedDelivery.fromJson(data),
      platformFeesRefunded: data['platformFeesRefunded'] as bool?,
    );
  }

  void _validateLocal(CreateDeliveryRequest request) {
    if (!request.acknowledged) {
      throw const ApiException(
        message: 'Please acknowledge the parcel terms before posting.',
        code: 'VALIDATION_ERROR',
      );
    }
    if (request.photoPaths.isEmpty || request.photoPaths.length > 3) {
      throw const ApiException(
        message: 'Upload between 1 and 3 parcel photos.',
        code: 'VALIDATION_ERROR',
      );
    }
    if (request.preferredMeetupLocations.isEmpty) {
      throw const ApiException(
        message: 'Add at least one meetup location.',
        code: 'VALIDATION_ERROR',
      );
    }
    if (request.preferredMeetupLocations.length > 3) {
      throw const ApiException(
        message: 'Add up to 3 meetup locations.',
        code: 'VALIDATION_ERROR',
      );
    }
    if (request.maxBudget <= 0) {
      throw const ApiException(
        message: 'Maximum budget must be greater than zero.',
        code: 'VALIDATION_ERROR',
      );
    }
    if (request.weightKg <= 0) {
      throw const ApiException(
        message: 'Parcel weight must be greater than zero.',
        code: 'VALIDATION_ERROR',
      );
    }
    if (request.receiverEmail.trim().isEmpty) {
      throw const ApiException(
        message: 'Receiver email is required.',
        code: 'VALIDATION_ERROR',
      );
    }
    if (request.receiverPhone.trim().isEmpty) {
      throw const ApiException(
        message: 'Receiver phone number is required.',
        code: 'VALIDATION_ERROR',
      );
    }
    if (request.receiverMeetupLocation == null ||
        request.receiverMeetupLocation!.trim().isEmpty) {
      throw const ApiException(
        message: 'Select a meetup location.',
        code: 'VALIDATION_ERROR',
      );
    }

    final isCountry = request.deliveryType == DeliveryType.countryToCountry;
    final originCity = isCountry
        ? (request.originCity ??
            request.originAirport ??
            request.originCountry ??
            '')
        : (request.fromCity ?? '');
    final originCountryCode = request.fromCode;
    if (originCity.trim().isNotEmpty) {
      for (final loc in request.preferredMeetupLocations) {
        if (!MeetupOriginValidation.labelBelongsToOrigin(
          loc,
          originCity,
          originCountryCode: originCountryCode,
          sameCountrySufficient: isCountry,
        )) {
          throw const ApiException(
            message: MeetupOriginValidation.message,
            code: 'VALIDATION_ERROR',
          );
        }
      }
    }

    final destinationCity = isCountry
        ? (request.destinationCity ??
            request.destinationAirport ??
            request.destinationCountry ??
            '')
        : (request.toCity ?? '');
    final destinationCountryCode = request.toCode;
    if (destinationCity.trim().isNotEmpty) {
      if (!MeetupDestinationValidation.labelBelongsToDestination(
        request.receiverMeetupLocation!,
        destinationCity,
        destinationCountryCode: destinationCountryCode,
        sameCountrySufficient: isCountry,
      )) {
        throw const ApiException(
          message: MeetupDestinationValidation.message,
          code: 'VALIDATION_ERROR',
        );
      }
    }
  }

  CreatedDelivery _demoCreate(CreateDeliveryRequest request) {
    final n = 10000 + Random().nextInt(89999);
    return CreatedDelivery(
      id: 'demo-delivery-$n',
      publicId: 'WW-$n',
      deliveryType: request.deliveryType,
      route: request.routeLabel,
      travelDate:
          '${request.travelDate.year.toString().padLeft(4, '0')}-'
          '${request.travelDate.month.toString().padLeft(2, '0')}-'
          '${request.travelDate.day.toString().padLeft(2, '0')}',
      parcelCategory: request.parcelCategory,
      parcelSize: request.parcelSize,
      weightKg: request.weightKg,
      maxBudget: request.maxBudget,
      description: request.description,
      preferredMeetupLocations: request.preferredMeetupLocations,
      acknowledged: true,
      photos: [
        for (var i = 0; i < request.photoPaths.length; i++)
          DeliveryPhoto(id: 'demo-photo-$i', url: request.photoPaths[i]),
      ],
      status: 'posted',
      fromCity: request.fromCity,
      fromCode: request.fromCode,
      toCity: request.toCity,
      toCode: request.toCode,
      originCountry: request.originCountry,
      originAirport: request.originAirport,
      destinationCountry: request.destinationCountry,
      destinationAirport: request.destinationAirport,
      platformFee: request.platformFee,
      platformFeeShare: request.platformFeeShare,
      receiverEmail: request.receiverEmail,
      receiverPhone: request.receiverPhone,
    );
  }
}
