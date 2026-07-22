import 'package:flutter/foundation.dart';

import '../core/api/api_exception.dart';
import '../core/config/demo_mode.dart';
import '../data/models/kyc_models.dart';
import '../data/services/auth_repository.dart';
import '../data/services/kyc_repository.dart';
import '../data/services/sumsub/sumsub_sdk_factory.dart';
import '../data/services/sumsub/sumsub_sdk_launcher.dart';

/// TEMPORARILY DISABLED - SUMSUB KYC
/// Retained as a compatibility provider. Its repository and SDK launcher are
/// inert, so no Sumsub or backend KYC operation can run.
class KycProvider extends ChangeNotifier {
  KycProvider({
    required AuthRepository authRepository,
    DemoModeProvider? demoMode,
    KycRepository? kycRepository,
    SumsubSdkLauncher? sdkLauncher,
  })  : _authRepository = authRepository,
        _demoMode = demoMode,
        _kycRepository = kycRepository ??
            KycRepository(
              apiClient: authRepository.apiClient,
              demoMode: demoMode,
              currentUser: () => authRepository.currentUser,
            ),
        _sdkLauncher = sdkLauncher ?? createSumsubSdkLauncher();

  final AuthRepository _authRepository;
  final KycRepository _kycRepository;
  final SumsubSdkLauncher _sdkLauncher;
  final DemoModeProvider? _demoMode;

  bool _loading = false;
  bool get loading => _loading;

  String? _error;
  String? get error => _error;

  SumsubSdkOutcome? _lastSdkOutcome;
  SumsubSdkOutcome? get lastSdkOutcome => _lastSdkOutcome;

  KycStatusResult? _lastStatus;
  KycStatusResult? get lastStatus => _lastStatus;

  bool get isSdkSupported => _sdkLauncher.isSupported;
  bool get isDemoMode => _demoMode?.enabled ?? false;

  KycStatusValue get statusValue =>
      _lastStatus?.kycStatus ??
      KycStatusValue.fromString(_authRepository.currentUser?.kycStatus);

  /// Returns local compatibility status only while Sumsub KYC is disabled.
  Future<KycStatusResult> refreshStatus({
    bool sync = true,
    bool silent = false,
  }) async {
    if (!silent) {
      _loading = true;
      _error = null;
      notifyListeners();
    }
    try {
      final ok = await _authRepository.ensureAuthenticated();
      if (!ok) {
        throw const ApiException(
          message: 'Please sign in again to continue.',
          code: 'UNAUTHORIZED',
          statusCode: 401,
        );
      }

      final result = await _kycRepository.fetchStatus(sync: sync);
      _lastStatus = result;
      final user = _kycRepository.userFromStatus(result);
      if (user != null) {
        await _authRepository.updateCurrentUser(user);
      }
      if (!silent) _error = null;
      return result;
    } on ApiException catch (e) {
      if (!silent) _error = e.message;
      rethrow;
    } finally {
      if (!silent) {
        _loading = false;
        notifyListeners();
      } else {
        notifyListeners();
      }
    }
  }

  /// TEMPORARILY DISABLED - SUMSUB KYC
  /// The inert launcher causes this flow to stop before requesting a token.
  Future<({SumsubSdkOutcome outcome, KycStatusResult? status})> startVerification() async {
    _loading = true;
    _error = null;
    _lastSdkOutcome = null;
    notifyListeners();

    try {
      if (!_sdkLauncher.isSupported) {
        final outcome = const SumsubSdkOutcome(
          status: SumsubSdkOutcomeStatus.failed,
          success: false,
          errorMessage: 'Identity verification is temporarily unavailable.',
        );
        _lastSdkOutcome = outcome;
        _error = outcome.errorMessage;
        return (outcome: outcome, status: null);
      }

      final ok = await _authRepository.ensureAuthenticated();
      if (!ok) {
        throw const ApiException(
          message: 'Please sign in again to continue.',
          code: 'UNAUTHORIZED',
          statusCode: 401,
        );
      }

      final token = await _kycRepository.fetchAccessToken();

      final outcome = await _sdkLauncher.launch(
        accessToken: token.accessToken,
        onTokenExpiration: () async {
          try {
            final refreshed = await _kycRepository.fetchAccessToken();
            return refreshed.accessToken;
          } catch (e) {
            debugPrint('Sumsub token refresh failed: $e');
            return null;
          }
        },
      );

      _lastSdkOutcome = outcome;

      KycStatusResult? status;
      try {
        status = await _kycRepository.fetchStatus(sync: true);
        _lastStatus = status;
        final user = _kycRepository.userFromStatus(status);
        if (user != null) {
          await _authRepository.updateCurrentUser(user);
        }
      } on ApiException catch (e) {
        // SDK finished; status sync failed — surface but keep SDK outcome.
        _error = e.message;
      }

      if (outcome.status == SumsubSdkOutcomeStatus.failed ||
          outcome.status == SumsubSdkOutcomeStatus.canceled) {
        _error = outcome.userMessage;
      }

      return (outcome: outcome, status: status);
    } on ApiException catch (e) {
      _error = e.message;
      final outcome = SumsubSdkOutcome(
        status: SumsubSdkOutcomeStatus.failed,
        success: false,
        errorMessage: e.message,
      );
      _lastSdkOutcome = outcome;
      return (outcome: outcome, status: null);
    } catch (e) {
      final message = e.toString();
      _error = message;
      final outcome = SumsubSdkOutcome(
        status: SumsubSdkOutcomeStatus.failed,
        success: false,
        errorMessage: message,
      );
      _lastSdkOutcome = outcome;
      return (outcome: outcome, status: null);
    } finally {
      _loading = false;
      notifyListeners();
    }
  }

  void clearError() {
    _error = null;
    notifyListeners();
  }
}
