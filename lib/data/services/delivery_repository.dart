import 'dart:math';

import '../../core/api/api_client.dart';
import '../../core/api/api_exception.dart';
import '../../core/config/demo_mode.dart';
import '../../core/geo/meetup_destination_validation.dart';
import '../../core/geo/meetup_origin_validation.dart';
import '../models/created_delivery.dart';
import '../models/matching_traveler.dart';

/// Backend delivery API access for the Sender Create Delivery flow.
class DeliveryRepository {
  DeliveryRepository({
    required ApiClient apiClient,
    DemoModeProvider? demoMode,
  })  : _apiClient = apiClient,
        _demoMode = demoMode;

  final ApiClient _apiClient;
  final DemoModeProvider? _demoMode;

  bool get _isDemoMode => _demoMode?.enabled ?? false;

  /// POST /api/v1/deliveries (multipart)
  Future<CreatedDelivery> createDelivery(CreateDeliveryRequest request) async {
    _validateLocal(request);

    if (_isDemoMode) {
      return _demoCreate(request);
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

    return CreatedDelivery.fromJson(data);
  }

  /// GET /api/v1/deliveries?role=
  Future<List<CreatedDelivery>> listDeliveries({String role = 'sender'}) async {
    if (_isDemoMode) return const [];

    final data = await _apiClient.get(
      '/deliveries?role=${Uri.encodeQueryComponent(role)}',
      authenticated: true,
    );
    final list = data['deliveries'];
    if (list is! List) return const <CreatedDelivery>[];
    return list
        .whereType<Map>()
        .map((item) => CreatedDelivery.fromJson(Map<String, dynamic>.from(item)))
        .toList();
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
      '/deliveries/$id$suffix',
      authenticated: true,
    );
    return CreatedDelivery.fromJson(data);
  }

  /// POST /api/v1/deliveries/:id/accept
  Future<CreatedDelivery> acceptAsReceiver(String id) async {
    if (_isDemoMode) {
      throw const ApiException(
        message: 'Accept is unavailable in demo mode.',
        code: 'DEMO_MODE',
      );
    }
    final data = await _apiClient.post(
      '/deliveries/$id/accept',
      authenticated: true,
    );
    return CreatedDelivery.fromJson(data);
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

  /// GET /api/v1/deliveries/:id/matching-travelers
  /// Backend filters to travelers whose trip To matches the delivery To.
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

    final originCity = request.deliveryType == DeliveryType.cityToCity
        ? (request.fromCity ?? '')
        : (request.originCity ?? '');
    if (originCity.trim().isNotEmpty) {
      for (final loc in request.preferredMeetupLocations) {
        if (!MeetupOriginValidation.labelBelongsToOrigin(loc, originCity)) {
          throw const ApiException(
            message: MeetupOriginValidation.message,
            code: 'VALIDATION_ERROR',
          );
        }
      }
    }

    final destinationCity = request.deliveryType == DeliveryType.cityToCity
        ? (request.toCity ?? '')
        : (request.destinationCity ?? request.destinationCountry ?? '');
    if (destinationCity.trim().isNotEmpty) {
      if (!MeetupDestinationValidation.labelBelongsToDestination(
        request.receiverMeetupLocation!,
        destinationCity,
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
