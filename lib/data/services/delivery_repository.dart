import 'dart:math';

import '../../core/api/api_client.dart';
import '../../core/api/api_exception.dart';
import '../../core/config/demo_mode.dart';
import '../models/created_delivery.dart';

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

  /// GET /api/v1/deliveries/:id
  Future<CreatedDelivery> getDelivery(String id) async {
    if (_isDemoMode) {
      throw const ApiException(
        message: 'Delivery lookup is unavailable in demo mode.',
        code: 'DEMO_MODE',
      );
    }

    final data = await _apiClient.get(
      '/deliveries/$id',
      authenticated: true,
    );
    return CreatedDelivery.fromJson(data);
  }

  /// GET /api/v1/deliveries
  Future<List<CreatedDelivery>> listDeliveries() async {
    if (_isDemoMode) return const [];

    final data = await _apiClient.get(
      '/deliveries',
      authenticated: true,
    );
    final list = data['deliveries'];
    if (list is! List) return const [];
    return list
        .whereType<Map<String, dynamic>>()
        .map(CreatedDelivery.fromJson)
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
