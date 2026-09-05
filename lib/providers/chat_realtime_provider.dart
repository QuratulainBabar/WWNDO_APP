import 'dart:async';

import 'package:flutter/widgets.dart';

import '../data/models/chat_message.dart';
import '../data/services/socket_chat_service.dart';

/// App-wide Socket.io connection so delivery receipts work even when the user
/// is not currently looking at a given thread.
class ChatRealtimeProvider extends ChangeNotifier with WidgetsBindingObserver {
  SocketChatService? _socket;
  Future<String?> Function()? _getAccessToken;
  String? _userId;
  bool _demoMode = false;
  bool _observingLifecycle = false;

  StreamSubscription<ChatMessage>? _socketMessageSub;
  StreamSubscription<ChatMessageReceipt>? _socketReceiptSub;
  StreamSubscription<void>? _socketConnectedSub;

  final _messageController = StreamController<ChatMessage>.broadcast();
  final _receiptController = StreamController<ChatMessageReceipt>.broadcast();
  final _resyncController = StreamController<String?>.broadcast();

  /// Latest known receipt status by message id (lowercase). Survives races
  /// where a receipt arrives before the optimistic send is confirmed.
  final Map<String, ChatReceiptStatus> _receiptByMessageId = {};

  /// Conversation ids that currently have an open chat screen mounted.
  final _openConversations = <String>{};

  /// Invoked when a peer message arrives for a conversation that is not open,
  /// so the chat tab badge can refresh live.
  void Function()? onIncomingPeerMessage;

  Stream<ChatMessage> get onMessage => _messageController.stream;
  Stream<ChatMessageReceipt> get onReceipt => _receiptController.stream;

  /// Emits the conversation id that should refresh, or `null` to refresh all
  /// open conversations (e.g. after a socket reconnect).
  Stream<String?> get onResyncNeeded => _resyncController.stream;

  bool get isConnected => _socket?.isConnected ?? false;

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

    if (demoMode) {
      await _teardownSocket();
      _demoMode = true;
      _getAccessToken = getAccessToken;
      _userId = userId;
      return;
    }

    final userChanged = _userId != userId && _socket != null;
    _getAccessToken = getAccessToken;
    _userId = userId;
    _demoMode = false;

    if (userChanged) {
      await _teardownSocket();
      _getAccessToken = getAccessToken;
      _userId = userId;
      _demoMode = false;
      _receiptByMessageId.clear();
    }

    await _connect();
  }

  Future<void> ensureConnected() async {
    if (_demoMode) return;
    await _connect();
  }

  void joinConversation(String conversationId) {
    if (conversationId.isEmpty) return;
    _openConversations.add(conversationId.toLowerCase());
    _socket?.joinConversation(conversationId);
  }

  void ackRead(String conversationId) {
    _socket?.ackRead(conversationId);
  }

  void leaveConversation(String conversationId) {
    _openConversations.remove(conversationId.toLowerCase());
    _socket?.leaveConversation(conversationId);
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
    await _teardownSocket();
    notifyListeners();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      unawaited(_onAppResumed());
    }
  }

  Future<void> _onAppResumed() async {
    await ensureConnected();
    if (_openConversations.isNotEmpty) {
      requestResync();
    }
  }

  void _ensureLifecycleObserver() {
    if (_observingLifecycle) return;
    WidgetsBinding.instance.addObserver(this);
    _observingLifecycle = true;
  }

  Future<void> _connect() async {
    final getToken = _getAccessToken;
    if (getToken == null) return;

    if (_socket == null) {
      _socket = SocketChatService(getAccessToken: getToken);
      _socket!.setUserId(_userId);
      _socketMessageSub = _socket!.onMessage.listen(_handleIncoming);
      _socketReceiptSub = _socket!.onReceipt.listen(_handleReceipt);
      _socketConnectedSub = _socket!.onConnected.listen((_) {
        // After reconnect, open chats may have missed `chat_message` events.
        if (_openConversations.isNotEmpty) {
          requestResync();
        }
        notifyListeners();
      });
    } else {
      _socket!.setUserId(_userId);
    }

    // Re-assert joins for any screen that is still open.
    for (final id in _openConversations) {
      _socket!.joinConversation(id);
    }

    await _socket!.connect();
    notifyListeners();
  }

  void _handleReceipt(ChatMessageReceipt receipt) {
    var changed = false;
    for (final id in receipt.messageIds) {
      if (id.isEmpty) continue;
      final key = id.toLowerCase();
      final prev = _receiptByMessageId[key];
      final next = prev == null
          ? receipt.status
          : maxChatReceiptStatus(prev, receipt.status);
      if (prev != next) {
        _receiptByMessageId[key] = next;
        changed = true;
      }
    }
    if (!_receiptController.isClosed) {
      _receiptController.add(receipt);
    }
    if (changed) notifyListeners();
  }

  void _handleIncoming(ChatMessage message) {
    if (!_messageController.isClosed) {
      _messageController.add(message);
    }
    final senderId = message.senderId;
    if (senderId == null ||
        _userId == null ||
        senderId.toLowerCase() == _userId!.toLowerCase()) {
      return;
    }
    final conversationId = message.conversationId;
    if (conversationId != null && isConversationOpen(conversationId)) {
      // Open chat UI receives the body via [onMessage]; no inbox badge bump.
      return;
    }
    onIncomingPeerMessage?.call();
  }

  Future<void> _teardownSocket() async {
    await _socketMessageSub?.cancel();
    await _socketReceiptSub?.cancel();
    await _socketConnectedSub?.cancel();
    _socketMessageSub = null;
    _socketReceiptSub = null;
    _socketConnectedSub = null;
    _socket?.dispose();
    _socket = null;
  }

  @override
  void dispose() {
    if (_observingLifecycle) {
      WidgetsBinding.instance.removeObserver(this);
      _observingLifecycle = false;
    }
    _teardownSocket();
    _messageController.close();
    _receiptController.close();
    _resyncController.close();
    _openConversations.clear();
    _receiptByMessageId.clear();
    super.dispose();
  }
}
