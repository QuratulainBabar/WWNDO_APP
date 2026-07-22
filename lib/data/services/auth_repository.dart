import '../../core/api/api_client.dart';
import '../../core/api/api_exception.dart';
import '../../core/auth/selected_role.dart';
import '../../core/config/demo_mode.dart';
import '../models/auth_user.dart';
import '../models/otp_channel.dart';
import '../static_data.dart';
import 'demo_auth_service.dart';
import 'token_storage.dart';

class AuthRepository {
  AuthRepository({
    TokenStorage? tokenStorage,
    DemoModeProvider? demoMode,
  })  : _tokenStorage = tokenStorage ?? TokenStorage(),
        _demoMode = demoMode {
    _apiClient = ApiClient(
      getAccessToken: _tokenStorage.getAccessToken,
      refreshTokens: refreshSession,
    );
  }

  final TokenStorage _tokenStorage;
  final DemoModeProvider? _demoMode;
  late final ApiClient _apiClient;

  AuthUser? _currentUser;
  AuthUser? get currentUser => _currentUser;

  /// Shared HTTP client for feature repositories (KYC, etc.).
  ApiClient get apiClient => _apiClient;

  TokenStorage get tokenStorage => _tokenStorage;

  bool get _isDemoMode => _demoMode?.enabled ?? false;

  Future<void> init() async {
    _currentUser = await _tokenStorage.getUser();
    // Warm token cache from disk so authenticated calls (KYC, etc.) work.
    await Future.wait([
      _tokenStorage.getAccessToken(),
      _tokenStorage.getRefreshToken(),
    ]);
    if (_isDemoMode) return;

    final refreshToken = await _tokenStorage.getRefreshToken();
    if (refreshToken != null) {
      try {
        await refreshSession();
      } on ApiException {
        await _tokenStorage.clear();
        _currentUser = null;
      }
    }
  }

  /// Ensures a usable access token exists (refreshes when needed).
  Future<bool> ensureAuthenticated() async {
    if (_isDemoMode) return _currentUser != null;

    final access = await _tokenStorage.getAccessToken();
    if (access != null && access.isNotEmpty) return true;

    try {
      return await refreshSession();
    } on ApiException {
      return false;
    }
  }

  Future<AuthUser> signInAsDemo() async {
    _currentUser = await DemoAuthService.signInAsDemo(_tokenStorage);
    return _currentUser!;
  }

  Future<AuthUser> register({
    required String name,
    required String email,
    required String phone,
    required String dialCode,
    required String phoneNumber,
    required String password,
    required String countryCode,
    required bool acceptedTerms,
  }) async {
    if (_isDemoMode) {
      _currentUser = await DemoAuthService.register(
        storage: _tokenStorage,
        name: name,
        email: email,
        phone: phone,
        countryCode: countryCode,
      );
      return _currentUser!;
    }

    final data = await _apiClient.post(
      '/auth/register',
      body: {
        'name': name,
        'email': email,
        'dialCode': dialCode,
        'phoneNumber': phoneNumber,
        'phone': phone,
        'password': password,
        'countryCode': countryCode,
        'acceptedTerms': acceptedTerms,
      },
    );

    return _persistAuthResponse(data);
  }

  Future<AuthUser> login({
    required String email,
    required String password,
  }) async {
    if (_isDemoMode) {
      _currentUser = await DemoAuthService.login(
        storage: _tokenStorage,
        email: email,
        password: password,
      );
      return _currentUser!;
    }

    final data = await _apiClient.post(
      '/auth/login',
      body: {
        'email': email,
        'password': password,
      },
    );

    return _persistAuthResponse(data);
  }

  Future<AuthUser> _persistAuthResponse(Map<String, dynamic> data) async {
    var user = AuthUser.fromJson(data['user'] as Map<String, dynamic>);
    final accessToken = data['accessToken'] as String;
    final refreshToken = data['refreshToken'] as String;

    // Restore locally cached role if the API user has none yet.
    if (!user.hasRole) {
      final cached = await SelectedRoleStore.loadForUser(
        userId: user.id,
        email: user.email,
      );
      if (cached != null) {
        user = user.copyWith(role: SelectedRoleStore.apiValue(cached));
      }
    } else {
      final parsed = SelectedRoleStore.roleFromUser(user);
      if (parsed != null) {
        await SelectedRoleStore.saveForUser(
          userId: user.id,
          email: user.email,
          role: parsed,
        );
      }
    }

    await _tokenStorage.saveSession(
      accessToken: accessToken,
      refreshToken: refreshToken,
      user: user,
    );
    _currentUser = user;
    return user;
  }

  Future<bool> refreshSession() async {
    if (_isDemoMode) {
      return DemoAuthService.refreshSession(
        storage: _tokenStorage,
        currentUser: _currentUser,
      );
    }

    final refreshToken = await _tokenStorage.getRefreshToken();
    if (refreshToken == null) return false;

    final data = await _apiClient.post(
      '/auth/refresh',
      body: {'refreshToken': refreshToken},
    );

    await _persistAuthResponse(data);
    return true;
  }

  Future<void> logout() async {
    if (_isDemoMode) {
      await DemoAuthService.logout(_tokenStorage);
      _currentUser = null;
      return;
    }

    final refreshToken = await _tokenStorage.getRefreshToken();
    await _tokenStorage.clear();
    _currentUser = null;

    if (refreshToken == null) return;

    try {
      await _apiClient
          .post(
            '/auth/logout',
            body: {'refreshToken': refreshToken},
          )
          .timeout(const Duration(seconds: 4));
    } catch (_) {
      // Local session is already cleared; server revoke is best-effort.
    }
  }

  Future<AuthUser> fetchProfile() async {
    if (_isDemoMode) {
      _currentUser ??= StaticData.demoAuthUser;
      return _currentUser!;
    }

    final data = await _apiClient.get('/auth/me', authenticated: true);
    final user = AuthUser.fromJson(data['user'] as Map<String, dynamic>);
    _currentUser = user;
    try {
      await _tokenStorage.saveUser(user);
    } catch (_) {}
    return user;
  }

  Future<AuthUser> updateProfile({
    required String name,
    required String email,
    required String phone,
    required String dialCode,
    required String phoneNumber,
    required String countryCode,
  }) async {
    final user = _currentUser;
    if (user == null) {
      throw const ApiException(message: 'Not signed in', code: 'UNAUTHORIZED');
    }

    if (_isDemoMode) {
      await DemoAuthService.simulateNetworkDelay();
      final updated = user.copyWith(
        name: name.trim(),
        email: email.trim(),
        phone: phone.trim(),
        dialCode: dialCode,
        phoneNumber: phoneNumber,
        countryCode: countryCode,
      );
      _currentUser = updated;
      try {
        await _tokenStorage.saveUser(updated);
      } catch (_) {}
      return updated;
    }

    final data = await _apiClient.patch(
      '/auth/profile',
      authenticated: true,
      body: {
        'name': name.trim(),
        'email': email.trim(),
        'dialCode': dialCode,
        'phoneNumber': phoneNumber,
        'phone': phone.trim(),
        'countryCode': countryCode,
      },
    );

    final updated = AuthUser.fromJson(data['user'] as Map<String, dynamic>);
    _currentUser = updated;
    try {
      await _tokenStorage.saveUser(updated);
    } catch (_) {}
    return updated;
  }

  Future<void> sendPasswordResetOtp({
    required String contact,
    required OtpChannel channel,
  }) async {
    if (_isDemoMode) {
      await DemoAuthService.sendPasswordResetOtp(contact: contact, channel: channel);
      return;
    }

    await _apiClient.post(
      '/auth/forgot-password',
      body: {
        'contact': contact,
        'method': channel.apiMethod,
      },
    );
  }

  Future<String> verifyPasswordResetOtp({
    required String contact,
    required OtpChannel channel,
    required String code,
  }) async {
    if (_isDemoMode) {
      return DemoAuthService.verifyPasswordResetOtp(
        contact: contact,
        channel: channel,
        code: code,
      );
    }

    final data = await _apiClient.post(
      '/auth/verify-otp',
      body: {
        'contact': contact,
        'method': channel.apiMethod,
        'code': code,
      },
    );

    return data['resetToken'] as String;
  }

  Future<void> sendLoginOtp({
    required String contact,
    required OtpChannel channel,
  }) async {
    if (_isDemoMode) {
      await DemoAuthService.sendLoginOtp(contact: contact, channel: channel);
      return;
    }

    await _apiClient.post(
      '/auth/login/otp/send',
      body: {
        'contact': contact,
        'method': channel.apiMethod,
      },
    );
  }

  Future<AuthUser> verifyLoginOtp({
    required String contact,
    required OtpChannel channel,
    required String code,
  }) async {
    if (_isDemoMode) {
      _currentUser = await DemoAuthService.verifyLoginOtp(
        storage: _tokenStorage,
        contact: contact,
        channel: channel,
        code: code,
      );
      return _currentUser!;
    }

    final data = await _apiClient.post(
      '/auth/login/otp/verify',
      body: {
        'contact': contact,
        'method': channel.apiMethod,
        'code': code,
      },
    );

    return _persistAuthResponse(data);
  }

  Future<void> sendCrossVerificationOtp({required OtpChannel channel}) async {
    final user = _currentUser;
    if (user == null) {
      throw const ApiException(message: 'Not signed in', code: 'UNAUTHORIZED');
    }

    if (_isDemoMode) {
      await DemoAuthService.sendCrossVerificationOtp(user: user, channel: channel);
      return;
    }

    if (channel == OtpChannel.email) {
      await _apiClient.post(
        '/auth/verify-email/send',
        authenticated: true,
      );
      return;
    }

    await _apiClient.post(
      '/auth/verify-contact/send',
      authenticated: true,
      body: {'method': channel.apiMethod},
    );
  }

  Future<AuthUser> verifyCrossVerificationOtp({
    required OtpChannel channel,
    required String code,
  }) async {
    final user = _currentUser;
    if (user == null) {
      throw const ApiException(message: 'Not signed in', code: 'UNAUTHORIZED');
    }

    if (_isDemoMode) {
      _currentUser = await DemoAuthService.verifyCrossVerificationOtp(
        storage: _tokenStorage,
        user: user,
        channel: channel,
        code: code,
      );
      return _currentUser!;
    }

    final data = channel == OtpChannel.email
        ? await _apiClient.post(
            '/auth/verify-email/verify',
            authenticated: true,
            body: {'code': code},
          )
        : await _apiClient.post(
            '/auth/verify-contact/verify',
            authenticated: true,
            body: {
              'method': channel.apiMethod,
              'code': code,
            },
          );

    final updated = AuthUser.fromJson(data['user'] as Map<String, dynamic>);
    _currentUser = updated;
    await _tokenStorage.saveUser(updated);
    return updated;
  }

  Future<AuthUser> setRole(String role) async {
    final user = _currentUser;
    if (user == null) {
      throw const ApiException(message: 'Not signed in', code: 'UNAUTHORIZED');
    }

    if (_isDemoMode) {
      _currentUser = await DemoAuthService.setRole(
        storage: _tokenStorage,
        user: user,
        role: role,
      );
      return _currentUser!;
    }

    final data = await _apiClient.post(
      '/auth/role',
      authenticated: true,
      body: {'role': role},
    );

    final updated = AuthUser.fromJson(data['user'] as Map<String, dynamic>);
    _currentUser = updated;
    try {
      await _tokenStorage.saveUser(updated);
    } catch (_) {
      // In-memory user is enough to continue onboarding on web.
    }
    final parsed = SelectedRoleStore.tryParse(updated.role ?? role);
    if (parsed != null) {
      await SelectedRoleStore.saveForUser(
        userId: updated.id,
        email: updated.email,
        role: parsed,
      );
    }
    return updated;
  }

  Future<void> updateCurrentUser(AuthUser user) async {
    _currentUser = user;
    await _tokenStorage.saveUser(user);
  }

  Future<AuthUser> submitKycForReview() async {
    return _updateKycStatus('submitted');
  }

  Future<AuthUser> approveKyc() async {
    return _updateKycStatus('approved');
  }

  Future<AuthUser> rejectKyc() async {
    return _updateKycStatus('rejected');
  }

  Future<AuthUser> resetKycForRetry() async {
    return _updateKycStatus('pending');
  }

  Future<AuthUser> _updateKycStatus(String kycStatus) async {
    final user = _currentUser;
    if (user == null) {
      throw const ApiException(message: 'Not signed in', code: 'UNAUTHORIZED');
    }

    if (_isDemoMode) {
      await DemoAuthService.simulateNetworkDelay();
    }

    final updated = user.copyWith(
      kycStatus: kycStatus,
      isVerified: kycStatus == 'approved',
    );
    await updateCurrentUser(updated);
    return updated;
  }

  Future<void> resetPassword({
    required String resetToken,
    required String password,
  }) async {
    if (_isDemoMode) {
      await DemoAuthService.resetPassword();
      return;
    }

    await _apiClient.post(
      '/auth/reset-password',
      body: {
        'resetToken': resetToken,
        'password': password,
      },
    );
  }

  Future<void> changePassword({
    required String currentPassword,
    required String newPassword,
  }) async {
    if (_isDemoMode) {
      await DemoAuthService.changePassword(
        currentPassword: currentPassword,
        newPassword: newPassword,
      );
      return;
    }

    await _apiClient.post(
      '/auth/change-password',
      authenticated: true,
      body: {
        'currentPassword': currentPassword,
        'newPassword': newPassword,
      },
    );
  }

  Future<void> verifyPassword(String password) async {
    if (_isDemoMode) {
      await DemoAuthService.verifyPassword(password);
      return;
    }

    await _apiClient.post(
      '/auth/verify-password',
      authenticated: true,
      body: {'password': password},
    );
  }
}
