import 'dart:async';

import 'package:flutter/widgets.dart';

import '../data/models/chat_message.dart';

/// Coordinates open chat threads without Socket.io.
///
/// New peer messages arrive via FCM → [requestResync] → open screens fetch REST.
/// A short HTTP poll while a thread is open covers cases where FCM is delayed
/// (e.g. web / flaky push).
class ChatRealtimeProvider extends ChangeNotifier with WidgetsBindingObserver {
  bool _demoMode = false;
  bool _observingLifecycle = false;

  final _messageController = StreamController<ChatMessage>.broadcast();
  final _receiptController = StreamController<ChatMessageReceipt>.broadcast();
  final _resyncController = StreamController<String?>.broadcast();

  /// Latest known receipt status by message id (lowercase). Survives races
  /// where a receipt arrives before the optimistic send is confirmed.
  final Map<String, ChatReceiptStatus> _receiptByMessageId = {};

  /// Conversation ids that currently have an open chat screen mounted.
  final _openConversations = <String>{};

  Timer? _openPollTimer;

  /// Invoked when a peer message arrives for a conversation that is not open,
  /// so the chat tab badge can refresh live.
  void Function()? onIncomingPeerMessage;

  /// Kept for API compatibility; chat no longer pushes bodies over sockets.
  Stream<ChatMessage> get onMessage => _messageController.stream;
  Stream<ChatMessageReceipt> get onReceipt => _receiptController.stream;

  /// Emits the conversation id that should refresh, or `null` to refresh all
  /// open conversations (e.g. after app resume / FCM).
  Stream<String?> get onResyncNeeded => _resyncController.stream;

  /// Always false — chat realtime no longer uses Socket.io.
  bool get isConnected => false;

  bool isConversationOpen(String conversationId) =>
      _openConversations.contains(conversationId.toLowerCase());

  /// Highest receipt status seen for [messageId], if any.
  ChatReceiptStatus? receiptStatusFor(String? messageId) {
    if (messageId == null || messageId.isEmpty) return null;
    return _receiptByMessageId[messageId.toLowerCase()];
  }

  Future<void> start({
    required Future<String?> Function() getAccessToken,
    String? userId,
    bool demoMode = false,
  }) async {
    _ensureLifecycleObserver();
    // Token / user kept on the start() signature for existing call sites.
    // Chat no longer opens a Socket.io session.
    _demoMode = demoMode;
    if (demoMode) {
      _stopOpenPoll();
    } else {
      _ensureOpenPoll();
    }
    notifyListeners();
  }

  Future<void> ensureConnected() async {
    // No-op: chat updates are FCM + REST, not sockets.
  }

  void joinConversation(String conversationId) {
    if (conversationId.isEmpty) return;
    _openConversations.add(conversationId.toLowerCase());
    _ensureOpenPoll();
  }

  void ackRead(String conversationId) {
    // Read state is applied by GET /conversations/:id (called on resync/open).
  }

  void leaveConversation(String conversationId) {
    _openConversations.remove(conversationId.toLowerCase());
    if (_openConversations.isEmpty) {
      _stopOpenPoll();
    }
  }

  /// Ask any open chat screen matching [conversationId] (or all if null) to
  /// re-fetch messages from REST and merge them into the live thread.
  void requestResync([String? conversationId]) {
    if (_resyncController.isClosed || _openConversations.isEmpty) return;
    if (conversationId != null &&
        conversationId.isNotEmpty &&
        !isConversationOpen(conversationId)) {
      // Still refresh whatever thread is open — covers ID mismatches from push
      // payloads so the sender does not need a manual page refresh.
      _resyncController.add(null);
      return;
    }
    _resyncController.add(conversationId);
  }

  Future<void> stop() async {
    _stopOpenPoll();
    _openConversations.clear();
    notifyListeners();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      unawaited(_onAppResumed());
    }
  }

  Future<void> _onAppResumed() async {
    if (_openConversations.isNotEmpty) {
      requestResync();
    }
  }

  void _ensureLifecycleObserver() {
    if (_observingLifecycle) return;
    WidgetsBinding.instance.addObserver(this);
    _observingLifecycle = true;
  }

  void _ensureOpenPoll() {
    if (_demoMode || _openConversations.isEmpty) {
      _stopOpenPoll();
      return;
    }
    if (_openPollTimer != null) return;
    // Backup for delayed/missed FCM while a thread is visible.
    _openPollTimer = Timer.periodic(const Duration(seconds: 4), (_) {
      if (_openConversations.isEmpty) {
        _stopOpenPoll();
        return;
      }
      requestResync();
    });
  }

  void _stopOpenPoll() {
    _openPollTimer?.cancel();
    _openPollTimer = null;
  }

  @override
  void dispose() {
    if (_observingLifecycle) {
      WidgetsBinding.instance.removeObserver(this);
      _observingLifecycle = false;
    }
    _stopOpenPoll();
    _messageController.close();
    _receiptController.close();
    _resyncController.close();
    _openConversations.clear();
    _receiptByMessageId.clear();
    super.dispose();
  }
}
