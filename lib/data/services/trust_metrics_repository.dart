import '../../core/api/api_client.dart';
import '../../core/config/demo_mode.dart';
import '../models/profile_trust_metrics.dart';
import '../models/wallet_role.dart';
import '../static_data.dart';

/// Backend trust indicators API (completed deliveries, cancel/dispute rates).
class TrustMetricsRepository {
  TrustMetricsRepository({
    required ApiClient apiClient,
    DemoModeProvider? demoMode,
  })  : _apiClient = apiClient,
        _demoMode = demoMode;

  final ApiClient _apiClient;
  final DemoModeProvider? _demoMode;

  bool get _isDemoMode => _demoMode?.enabled ?? false;

  /// GET /api/v1/trust-metrics?role=
  Future<ProfileTrustMetrics> fetch(WalletRole role) async {
    if (_isDemoMode) {
      return switch (role) {
        WalletRole.sender => StaticData.senderTrustMetrics,
        WalletRole.traveler => StaticData.travelerTrustMetrics,
        WalletRole.receiver => StaticData.receiverTrustMetrics,
      };
    }

    final data = await _apiClient.get(
      '/trust-metrics?role=${role.queryParam}',
      authenticated: true,
    );
    return ProfileTrustMetrics.fromJson(data);
  }
}
