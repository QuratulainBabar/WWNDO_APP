import '../../core/api/api_client.dart';
import '../../core/config/demo_mode.dart';
import '../models/app_notification.dart';
import '../models/wallet_role.dart';
import '../notification_service.dart';

/// Backend notification inbox API.
class NotificationRepository {
  NotificationRepository({
    required ApiClient apiClient,
    DemoModeProvider? demoMode,
  })  : _apiClient = apiClient,
        _demoMode = demoMode;

  final ApiClient _apiClient;
  final DemoModeProvider? _demoMode;

  bool get _isDemoMode => _demoMode?.enabled ?? false;

  Future<List<AppNotification>> list({
    required WalletRole role,
    int limit = NotificationService.inboxLimit,
  }) async {
    if (_isDemoMode) return const [];

    final data = await _apiClient.get(
      '/notifications?role=${role.queryParam}&limit=$limit',
      authenticated: true,
    );
    final list = data['notifications'];
    if (list is! List) return const [];
    return list
        .whereType<Map>()
        .map((item) => AppNotification.fromJson(
              Map<String, dynamic>.from(item),
              fallbackRole: role,
            ))
        .toList();
  }

  Future<int> unreadCount({required WalletRole role}) async {
    if (_isDemoMode) return 0;

    final data = await _apiClient.get(
      '/notifications/unread-count?role=${role.queryParam}',
      authenticated: true,
    );
    return (data['count'] as num?)?.toInt() ?? 0;
  }

  Future<void> markRead({
    required WalletRole role,
    required String id,
  }) async {
    if (_isDemoMode) return;
    await _apiClient.patch(
      '/notifications/$id/read?role=${role.queryParam}',
      authenticated: true,
    );
  }

  Future<void> markAllRead({required WalletRole role}) async {
    if (_isDemoMode) return;
    await _apiClient.post(
      '/notifications/mark-all-read?role=${role.queryParam}',
      authenticated: true,
    );
  }
}
