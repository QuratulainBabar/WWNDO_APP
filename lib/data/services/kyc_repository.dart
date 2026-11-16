import '../../core/api/api_client.dart';
import '../../core/api/api_exception.dart';
import '../../core/config/demo_mode.dart';
import '../models/auth_user.dart';
import '../models/kyc_models.dart';

/// Backend KYC API access. Never holds Sumsub App Token / Secret Key.
class KycRepository {
  KycRepository({
    required ApiClient apiClient,
    DemoModeProvider? demoMode,
    AuthUser? Function()? currentUser,
  })  : _apiClient = apiClient,
        _demoMode = demoMode,
        _currentUser = currentUser;

  final ApiClient _apiClient;
  final DemoModeProvider? _demoMode;
  final AuthUser? Function()? _currentUser;

  bool get _isDemoMode => _demoMode?.enabled ?? false;

  /// POST /api/v1/kyc/access-token
  Future<SumsubAccessToken> fetchAccessToken() async {
    if (_isDemoMode) {
      throw const ApiException(
        message:
            'Sumsub SDK is unavailable in demo mode. Use demo verification instead.',
        code: 'DEMO_MODE',
      );
    }
    final data = await _apiClient.post('/kyc/access-token', authenticated: true);
    return SumsubAccessToken.fromJson(data);
  }

  /// POST /api/v1/kyc/dev-bypass — local testing only; the server rejects it
  /// unless KYC_DEV_BYPASS=true.
  Future<KycStatusResult> devBypass() async {
    final data = await _apiClient.post('/kyc/dev-bypass', authenticated: true);
    return KycStatusResult.fromJson(data);
  }

  /// GET /api/v1/kyc/status
  Future<KycStatusResult> fetchStatus({bool sync = true}) async {
    if (_isDemoMode) {
      final user = _currentUser?.call();
      return KycStatusResult(
        kycStatus: KycStatusValue.fromString(user?.kycStatus),
        synced: false,
        userJson: user?.toJson(),
      );
    }
    final data = await _apiClient.get(
      '/kyc/status?sync=${sync ? 'true' : 'false'}',
      authenticated: true,
    );
    return KycStatusResult.fromJson(data);
  }

  AuthUser? userFromStatus(KycStatusResult status) {
    final json = status.userJson;
    if (json == null) return null;
    return AuthUser.fromJson(json);
  }
}
