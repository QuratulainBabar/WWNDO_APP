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

  final _messageController = StreamController<ChatMessage>.broadcast();
  final _receiptController = StreamController<ChatMessageReceipt>.broadcast();

  /// Invoked when a peer message arrives for a conversation that is not open,
  /// so the chat tab badge can refresh live.
  void Function()? onIncomingPeerMessage;

  Stream<ChatMessage> get onMessage => _messageController.stream;
  Stream<ChatMessageReceipt> get onReceipt => _receiptController.stream;

  bool get isConnected => _socket?.isConnected ?? false;

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
    }

    await _connect();
  }

  Future<void> ensureConnected() async {
    if (_demoMode) return;
    await _connect();
  }

  void joinConversation(String conversationId) {
    _socket?.joinConversation(conversationId);
  }

  void ackRead(String conversationId) {
    _socket?.ackRead(conversationId);
  }

  void leaveConversation(String conversationId) {
    _socket?.leaveConversation(conversationId);
  }

  Future<void> stop() async {
    await _teardownSocket();
    notifyListeners();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      ensureConnected();
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
      _socketReceiptSub = _socket!.onReceipt.listen(_receiptController.add);
    } else {
      _socket!.setUserId(_userId);
    }

    await _socket!.connect();
    notifyListeners();
  }

  void _handleIncoming(ChatMessage message) {
    if (!_messageController.isClosed) {
      _messageController.add(message);
    }
    final senderId = message.senderId;
    if (senderId == null || senderId == _userId) return;
    final conversationId = message.conversationId;
    if (conversationId != null && _socket?.isJoined(conversationId) == true) {
      return;
    }
    onIncomingPeerMessage?.call();
  }

  Future<void> _teardownSocket() async {
    await _socketMessageSub?.cancel();
    await _socketReceiptSub?.cancel();
    _socketMessageSub = null;
    _socketReceiptSub = null;
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
    super.dispose();
  }
}
