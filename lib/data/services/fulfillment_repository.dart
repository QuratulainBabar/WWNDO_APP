import '../../core/api/api_client.dart';
import 'platform_repository.dart';

/// NFC checkpoints, timeline, disputes — wraps [PlatformRepository].
class FulfillmentRepository {
  FulfillmentRepository({ApiClient? apiClient})
      : _platform = PlatformRepository(apiClient: apiClient);

  final PlatformRepository _platform;

  Future<Map<String, dynamic>> getTimeline(String publicId) =>
      _platform.getTrackingTimeline(publicId);

  Future<Map<String, dynamic>> confirmNfc({
    required String deliveryId,
    required int checkpoint,
    String? deviceId,
    double? gpsLat,
    double? gpsLng,
  }) =>
      _platform.confirmNfcCheckpoint(
        deliveryId: deliveryId,
        checkpoint: checkpoint,
        deviceId: deviceId,
        gpsLat: gpsLat,
        gpsLng: gpsLng,
      );

  Future<Map<String, dynamic>> openDispute({
    required String deliveryId,
    required String reason,
  }) =>
      _platform.openDispute(deliveryId: deliveryId, reason: reason);

  Future<List<Map<String, dynamic>>> listNfcCheckpoints(String deliveryId) =>
      _platform.listNfcCheckpoints(deliveryId);
}
