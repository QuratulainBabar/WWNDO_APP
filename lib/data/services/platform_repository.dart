import '../../core/api/api_client.dart';

/// Platform APIs: NFC, meetup, tracking timeline, sender requests, disputes.
class PlatformRepository {
  PlatformRepository({ApiClient? apiClient})
      : _api = apiClient ?? ApiClient();

  final ApiClient _api;

  Future<List<Map<String, dynamic>>> listNfcCheckpoints(String deliveryId) async {
    final res = await _api.get('/nfc/deliveries/$deliveryId/checkpoints');
    final list = res['data']?['checkpoints'] as List? ?? [];
    return list.cast<Map<String, dynamic>>();
  }

  Future<Map<String, dynamic>> confirmNfcCheckpoint({
    required String deliveryId,
    required int checkpoint,
    String? deviceId,
    double? gpsLat,
    double? gpsLng,
  }) async {
    final res = await _api.post(
      '/nfc/deliveries/$deliveryId/checkpoints/$checkpoint',
      body: {
        'deviceId': deviceId,
        'gpsLat': gpsLat,
        'gpsLng': gpsLng,
        'confirm': true,
      },
    );
    return (res['data']?['checkpoint'] as Map?)?.cast<String, dynamic>() ?? {};
  }

  Future<Map<String, dynamic>> getMeetupStatus(String deliveryId) async {
    final res = await _api.get('/meetup/deliveries/$deliveryId/meetup');
    return (res['data'] as Map?)?.cast<String, dynamic>() ?? {};
  }

  Future<Map<String, dynamic>> proposeMeetup({
    required String deliveryId,
    required String location,
  }) async {
    final res = await _api.post(
      '/meetup/deliveries/$deliveryId/meetup/propose',
      body: {'location': location},
    );
    return (res['data'] as Map?)?.cast<String, dynamic>() ?? {};
  }

  Future<Map<String, dynamic>> agreeMeetup(String deliveryId) async {
    final res = await _api.post('/meetup/deliveries/$deliveryId/meetup/agree');
    return (res['data'] as Map?)?.cast<String, dynamic>() ?? {};
  }

  Future<Map<String, dynamic>> getTrackingTimeline(String publicId) async {
    final res = await _api.get('/tracking/deliveries/$publicId/timeline');
    return (res['data'] as Map?)?.cast<String, dynamic>() ?? {};
  }

  Future<Map<String, dynamic>> acceptSenderRequest(String requestId) async {
    final res = await _api.post('/trips/sender-requests/$requestId/accept');
    return (res['data'] as Map?)?.cast<String, dynamic>() ?? {};
  }

  Future<Map<String, dynamic>> declineSenderRequest(String requestId) async {
    final res = await _api.post('/trips/sender-requests/$requestId/decline');
    return (res['data'] as Map?)?.cast<String, dynamic>() ?? {};
  }

  Future<Map<String, dynamic>> submitReceiverPayment({
    required String deliveryId,
    required int feeCents,
  }) async {
    final res = await _api.post(
      '/deliveries/$deliveryId/receiver-payment',
      body: {'feeCents': feeCents},
    );
    return (res['data'] as Map?)?.cast<String, dynamic>() ?? {};
  }

  Future<Map<String, dynamic>> openDispute({
    required String deliveryId,
    required String reason,
  }) async {
    final res = await _api.post(
      '/deliveries/$deliveryId/dispute',
      body: {'reason': reason},
    );
    return (res['data'] as Map?)?.cast<String, dynamic>() ?? {};
  }
}
