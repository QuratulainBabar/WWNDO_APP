import 'dart:async';

import 'package:flutter/foundation.dart';

import '../core/config/demo_mode.dart';
import '../data/models/app_notification.dart';
import '../data/models/wallet_role.dart';
import '../data/services/auth_repository.dart';
import '../data/services/notification_realtime_service.dart';
import '../data/services/notification_repository.dart';

/// Keeps receiver/sender notification badges and inbox in sync via SSE.
class NotificationRealtimeProvider extends ChangeNotifier {
  NotificationRealtimeProvider({
    NotificationRealtimeService? realtimeService,
  }) : _realtimeService = realtimeService ?? NotificationRealtimeService();

  final NotificationRealtimeService _realtimeService;
  final List<AppNotification> _recentIncoming = [];

  WalletRole? _activeRole;
  int _unreadCount = 0;
  bool _connected = false;
  StreamSubscription<AppNotification>? _notificationSub;
  StreamSubscription<int>? _unreadSub;

  int get unreadCount => _unreadCount;
  bool get isConnected => _connected;
  WalletRole? get activeRole => _activeRole;

  /// New notifications pushed since the last [consumeIncoming] call.
  List<AppNotification> consumeIncoming() {
    if (_recentIncoming.isEmpty) return const [];
    final copy = List<AppNotification>.from(_recentIncoming);
    _recentIncoming.clear();
    return copy;
  }

  Future<void> start({
    required WalletRole role,
    required AuthRepository authRepository,
    DemoModeProvider? demoMode,
  }) async {
    if (demoMode?.enabled ?? false) {
      await stop();
      return;
    }

    if (_activeRole == role && _connected) return;

    await stop();
    _activeRole = role;

    final repository = NotificationRepository(
      apiClient: authRepository.apiClient,
      demoMode: demoMode,
    );

    try {
      _unreadCount = await repository.unreadCount(role: role);
      notifyListeners();
    } catch (_) {
      // Non-fatal; SSE may still connect.
    }

    _notificationSub = _realtimeService.onNotification.listen((notification) {
      _recentIncoming.removeWhere((item) => item.id == notification.id);
      _recentIncoming.insert(0, notification);
      notifyListeners();
    });

    _unreadSub = _realtimeService.onUnreadCount.listen((count) {
      if (_unreadCount != count) {
        _unreadCount = count;
        notifyListeners();
      }
    });

    await _realtimeService.connect(
      role: role,
      tokenProvider: authRepository.tokenStorage.getAccessToken,
    );
    _connected = true;
    notifyListeners();
  }

  Future<void> refreshUnread({
    required WalletRole role,
    required AuthRepository authRepository,
    DemoModeProvider? demoMode,
  }) async {
    if (demoMode?.enabled ?? false) return;

    final repository = NotificationRepository(
      apiClient: authRepository.apiClient,
      demoMode: demoMode,
    );
    try {
      final count = await repository.unreadCount(role: role);
      if (_unreadCount != count) {
        _unreadCount = count;
        notifyListeners();
      }
    } catch (_) {
      // Badge refresh is non-critical.
    }
  }

  void setUnreadCount(int count) {
    if (_unreadCount != count) {
      _unreadCount = count;
      notifyListeners();
    }
  }

  Future<void> stop() async {
    await _notificationSub?.cancel();
    await _unreadSub?.cancel();
    _notificationSub = null;
    _unreadSub = null;
    await _realtimeService.disconnect();
    _connected = false;
    _activeRole = null;
    _recentIncoming.clear();
    notifyListeners();
  }

  @override
  void dispose() {
    stop();
    _realtimeService.dispose();
    super.dispose();
  }
}
