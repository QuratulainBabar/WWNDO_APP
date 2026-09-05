import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';

import '../core/config/demo_mode.dart';
import '../data/models/app_notification.dart';
import '../data/models/wallet_role.dart';
import '../data/services/auth_repository.dart';
import '../data/services/chat_repository.dart';
import '../data/services/notification_realtime_service.dart';
import '../data/services/notification_repository.dart';
import '../data/notification_service.dart';

/// Keeps sender / traveler / receiver notification badges and inbox in sync via SSE.
class NotificationRealtimeProvider extends ChangeNotifier
    with WidgetsBindingObserver {
  NotificationRealtimeProvider({
    NotificationRealtimeService? realtimeService,
  }) : _realtimeService = realtimeService ?? NotificationRealtimeService();

  final NotificationRealtimeService _realtimeService;
  final List<AppNotification> _recentIncoming = [];

  WalletRole? _activeRole;
  int _unreadCount = 0;
  int _chatUnreadCount = 0;
  int _senderRequestUnreadCount = 0;
  int _deliveryUpdateTick = 0;
  StreamSubscription<AppNotification>? _notificationSub;
  StreamSubscription<int>? _unreadSub;
  AuthRepository? _authRepository;
  DemoModeProvider? _demoMode;
  Timer? _chatBadgePoll;
  bool _observingLifecycle = false;

  int get unreadCount => _unreadCount;
  /// Total unread chat messages across all conversations (Chat tab badge).
  int get chatUnreadCount => _chatUnreadCount;
  /// Traveler home "Sender Requests" quick-action badge (unread pending requests).
  int get senderRequestUnreadCount => _senderRequestUnreadCount;
  int get deliveryUpdateTick => _deliveryUpdateTick;
  /// True only when the SSE subscription is actually open (not a stale flag).
  bool get isConnected => _realtimeService.isConnected;
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
    _ensureLifecycleObserver();
    _authRepository = authRepository;
    _demoMode = demoMode;

    if (demoMode?.enabled ?? false) {
      _stopChatBadgePoll();
      await stop();
      return;
    }

    if (_activeRole == role && _realtimeService.isConnected) {
      _ensureChatBadgePoll();
      return;
    }

    await _teardownStreams();
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
      if (_recentIncoming.length > NotificationService.inboxLimit) {
        _recentIncoming.removeRange(
          NotificationService.inboxLimit,
          _recentIncoming.length,
        );
      }
      if (notification.isDeliveryRelated) {
        _deliveryUpdateTick++;
      }
      notifyListeners();
    });

    _unreadSub = _realtimeService.onUnreadCount.listen((count) {
      if (_unreadCount != count) {
        final increased = count > _unreadCount;
        _unreadCount = count;
        // Alert badge can update even when the nested notification payload
        // fails to parse — still invalidate delivery screens so status UI
        // (e.g. receiver In Transit) refreshes immediately.
        if (increased) {
          _deliveryUpdateTick++;
        }
        notifyListeners();
      }
    });

    await _realtimeService.connect(
      role: role,
      tokenProvider: authRepository.tokenStorage.getAccessToken,
    );

    await refreshChatUnread(
      authRepository: authRepository,
      demoMode: demoMode,
      threadType: role.chatInboxThreadType,
    );
    _ensureChatBadgePoll();
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

  /// Refresh the total unread chat count by summing per-conversation unread
  /// from the chat list endpoint. Non-critical — failures keep the last count.
  Future<void> refreshChatUnread({
    AuthRepository? authRepository,
    DemoModeProvider? demoMode,
    String? threadType,
  }) async {
    final auth = authRepository ?? _authRepository;
    final demo = demoMode ?? _demoMode;
    if (auth == null) return;

    if (demo?.enabled ?? false) {
      if (_chatUnreadCount != 0) {
        _chatUnreadCount = 0;
        notifyListeners();
      }
      return;
    }

    final chatRepository = ChatRepository(
      apiClient: auth.apiClient,
      demoMode: demo,
    );
    try {
      final conversations = await chatRepository.listConversations(
        threadType: threadType ?? _activeRole?.chatInboxThreadType,
      );
      final total = conversations.fold<int>(
        0,
        (sum, c) => sum + (c.unreadCount < 0 ? 0 : c.unreadCount),
      );
      setChatUnreadCount(total);
    } catch (_) {
      // Badge refresh is non-critical.
    }
  }

  void setChatUnreadCount(int count) {
    final next = count < 0 ? 0 : count;
    if (_chatUnreadCount != next) {
      _chatUnreadCount = next;
      notifyListeners();
    }
  }

  /// Instantly bump the Chat tab badge when an FCM chat push arrives (thread
  /// not open). A following [refreshChatUnread] reconciles the exact total.
  void bumpChatUnread([int amount = 1]) {
    if (amount <= 0) return;
    setChatUnreadCount(_chatUnreadCount + amount);
  }

  /// Instantly drop [amount] from the Chat tab badge (e.g. after opening a thread).
  void applyConversationRead(int amount) {
    if (amount <= 0) return;
    setChatUnreadCount(_chatUnreadCount - amount);
  }

  void setUnreadCount(int count) {
    if (_unreadCount != count) {
      _unreadCount = count;
      notifyListeners();
    }
  }

  void setSenderRequestUnreadCount(int count) {
    final next = count < 0 ? 0 : count;
    if (_senderRequestUnreadCount != next) {
      _senderRequestUnreadCount = next;
      notifyListeners();
    }
  }

  /// Local invalidation when the current user creates/updates a delivery
  /// (SSE may not notify the actor, e.g. sender after posting).
  void notifyDeliveryUpdated() {
    _deliveryUpdateTick++;
    notifyListeners();
  }

  Future<void> stop() async {
    _stopChatBadgePoll();
    await _teardownStreams();
    _activeRole = null;
    _authRepository = null;
    _demoMode = null;
    _deliveryUpdateTick = 0;
    _senderRequestUnreadCount = 0;
    _chatUnreadCount = 0;
    _recentIncoming.clear();
    notifyListeners();
  }

  Future<void> _teardownStreams() async {
    await _notificationSub?.cancel();
    await _unreadSub?.cancel();
    _notificationSub = null;
    _unreadSub = null;
    await _realtimeService.disconnect();
  }

  void _ensureLifecycleObserver() {
    if (_observingLifecycle) return;
    WidgetsBinding.instance.addObserver(this);
    _observingLifecycle = true;
  }

  void _ensureChatBadgePoll() {
    if (_demoMode?.enabled ?? false) {
      _stopChatBadgePoll();
      return;
    }
    if (_chatBadgePoll != null) return;
    // Keep bottom-bar Chat badge fresh on Home / any screen when FCM is delayed.
    _chatBadgePoll = Timer.periodic(const Duration(seconds: 6), (_) {
      unawaited(refreshChatUnread());
    });
  }

  void _stopChatBadgePoll() {
    _chatBadgePoll?.cancel();
    _chatBadgePoll = null;
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      unawaited(refreshChatUnread());
      _ensureChatBadgePoll();
    } else if (state == AppLifecycleState.paused ||
        state == AppLifecycleState.detached) {
      _stopChatBadgePoll();
    }
  }

  @override
  void dispose() {
    if (_observingLifecycle) {
      WidgetsBinding.instance.removeObserver(this);
      _observingLifecycle = false;
    }
    _stopChatBadgePoll();
    stop();
    _realtimeService.dispose();
    super.dispose();
  }
}
