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

  // TEMPORARILY DISABLED - SUMSUB KYC
  // Retained for restoring the preserved API calls below.
  // ignore: unused_field
  final ApiClient _apiClient;
  final DemoModeProvider? _demoMode;
  final AuthUser? Function()? _currentUser;

  // ignore: unused_element
  bool get _isDemoMode => _demoMode?.enabled ?? false;

  /// POST /api/v1/kyc/access-token
  Future<SumsubAccessToken> fetchAccessToken() async {
    // TEMPORARILY DISABLED - SUMSUB KYC
    // No backend call or SDK access token may be issued while KYC is paused.
    throw const ApiException(
      message: 'Identity verification is temporarily unavailable.',
      code: 'KYC_DISABLED',
      statusCode: 503,
    );

    /*
    Preserved Sumsub implementation:
    if (_isDemoMode) {
      throw const ApiException(
        message:
            'Sumsub SDK is unavailable in demo mode. Use demo verification instead.',
        code: 'DEMO_MODE',
      );
    }
    final data = await _apiClient.post('/kyc/access-token', authenticated: true);
    return SumsubAccessToken.fromJson(data);
    */
  }

  /// GET /api/v1/kyc/status
  Future<KycStatusResult> fetchStatus({bool sync = true}) async {
    // TEMPORARILY DISABLED - SUMSUB KYC
    // Return local compatibility data only; never synchronize with the backend.
    final user = _currentUser?.call();
    return KycStatusResult(
      kycStatus: KycStatusValue.fromString(user?.kycStatus),
      synced: false,
      userJson: user?.toJson(),
    );

    /*
    Preserved Sumsub implementation:
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
    */
  }

  AuthUser? userFromStatus(KycStatusResult status) {
    final json = status.userJson;
    if (json == null) return null;
    return AuthUser.fromJson(json);
  }
}
