import '../../core/api/api_client.dart';

/// Platform APIs: NFC, meetup, tracking timeline, sender requests, disputes.
class PlatformRepository {
  PlatformRepository({ApiClient? apiClient})
      : _api = apiClient ?? ApiClient();

  final ApiClient _api;

  Future<List<Map<String, dynamic>>> listNfcCheckpoints(String deliveryId) async {
    final res = await _api.get(
      '/nfc/deliveries/$deliveryId/checkpoints',
      authenticated: true,
    );
    final list = res['checkpoints'] as List? ??
        (res['data'] is Map ? (res['data'] as Map)['checkpoints'] as List? : null) ??
        const [];
    return list
        .whereType<Map>()
        .map((e) => Map<String, dynamic>.from(e))
        .toList();
  }

  Future<Map<String, dynamic>> confirmNfcCheckpoint({
    required String deliveryId,
    required int checkpoint,
    String? deviceId,
    double? gpsLat,
    double? gpsLng,
    String? paymentIntentId,
  }) async {
    final body = <String, dynamic>{
      'deviceId': deviceId,
      'gpsLat': gpsLat,
      'gpsLng': gpsLng,
      'confirm': true,
    };
    if (paymentIntentId != null && paymentIntentId.isNotEmpty) {
      body['paymentIntentId'] = paymentIntentId;
    }
    final res = await _api.post(
      '/nfc/deliveries/$deliveryId/checkpoints/$checkpoint',
      body: body,
      authenticated: true,
    );
    final checkpointData = res['checkpoint'];
    if (checkpointData is Map) {
      return Map<String, dynamic>.from(checkpointData);
    }
    return Map<String, dynamic>.from(res);
  }

  Future<Map<String, dynamic>> getMeetupStatus(String deliveryId) async {
    final res = await _api.get(
      '/meetup/deliveries/$deliveryId/meetup',
      authenticated: true,
    );
    return Map<String, dynamic>.from(res);
  }

  Future<Map<String, dynamic>> proposeMeetup({
    required String deliveryId,
    required String location,
  }) async {
    final res = await _api.post(
      '/meetup/deliveries/$deliveryId/meetup/propose',
      body: {'location': location},
      authenticated: true,
    );
    return Map<String, dynamic>.from(res);
  }

  Future<Map<String, dynamic>> agreeMeetup(String deliveryId) async {
    final res = await _api.post(
      '/meetup/deliveries/$deliveryId/meetup/agree',
      authenticated: true,
    );
    return Map<String, dynamic>.from(res);
  }

  Future<Map<String, dynamic>> getTrackingTimeline(String publicId) async {
    final res = await _api.get(
      '/tracking/deliveries/$publicId/timeline',
      authenticated: true,
    );
    return Map<String, dynamic>.from(res);
  }

  Future<Map<String, dynamic>> markInTransit(String publicId) async {
    final res = await _api.post(
      '/tracking/deliveries/$publicId/in-transit',
      authenticated: true,
    );
    return Map<String, dynamic>.from(res);
  }

  Future<Map<String, dynamic>> acceptSenderRequest(String requestId) async {
    final res = await _api.post(
      '/trips/sender-requests/$requestId/accept',
      authenticated: true,
    );
    return Map<String, dynamic>.from(res);
  }

  Future<Map<String, dynamic>> declineSenderRequest(String requestId) async {
    final res = await _api.post(
      '/trips/sender-requests/$requestId/decline',
      authenticated: true,
    );
    return Map<String, dynamic>.from(res);
  }

  Future<Map<String, dynamic>> submitReceiverPayment({
    required String deliveryId,
    required int feeCents,
    String? paymentIntentId,
  }) async {
    final body = <String, dynamic>{'feeCents': feeCents};
    if (paymentIntentId != null && paymentIntentId.isNotEmpty) {
      body['paymentIntentId'] = paymentIntentId;
    }
    final res = await _api.post(
      '/deliveries/$deliveryId/receiver-payment',
      body: body,
      authenticated: true,
    );
    return Map<String, dynamic>.from(res);
  }

  Future<Map<String, dynamic>> openDispute({
    required String deliveryId,
    required String reason,
  }) async {
    final res = await _api.post(
      '/deliveries/$deliveryId/dispute',
      body: {'reason': reason},
      authenticated: true,
    );
    return Map<String, dynamic>.from(res);
  }
}
