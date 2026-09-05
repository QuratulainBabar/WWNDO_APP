import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:socket_io_client/socket_io_client.dart' as io;

import '../../core/config/api_config.dart';
import '../models/chat_message.dart';

/// Real-time chat via Socket.io (join conversation + listen for messages).
class SocketChatService {
  SocketChatService({required this.getAccessToken});

  final Future<String?> Function() getAccessToken;

  io.Socket? _socket;
  String? _userId;
  bool _connecting = false;
  final _joinedConversations = <String>{};
  final _messageController = StreamController<ChatMessage>.broadcast();
  final _receiptController = StreamController<ChatMessageReceipt>.broadcast();
  final _connectedController = StreamController<void>.broadcast();

  Stream<ChatMessage> get onMessage => _messageController.stream;
  Stream<ChatMessageReceipt> get onReceipt => _receiptController.stream;

  /// Fires after every successful connect / reconnect (rooms re-joined).
  Stream<void> get onConnected => _connectedController.stream;

  bool get isConnected => _socket?.connected ?? false;

  void setUserId(String? userId) {
    _userId = userId;
  }

  Future<void> connect() async {
    if (_socket?.connected == true || _connecting) return;
    final token = await getAccessToken();
    if (token == null || token.isEmpty) return;

    // Reuse an existing socket instance: just ask it to reconnect with a
    // fresh token. Recreating via io.io() without forceNew returns a cached
    // manager whose onConnect may never fire again, so join_conversation is
    // skipped and open chats stop receiving.
    if (_socket != null) {
      _socket!.auth = {'token': token};
      if (!_socket!.connected) {
        _connecting = true;
        _socket!.connect();
      }
      return;
    }

    _connecting = true;
    _socket = io.io(
      ApiConfig.socketUrl,
      io.OptionBuilder()
          .setTransports(['websocket', 'polling'])
          .setPath('/socket.io')
          .setAuth({'token': token})
          .enableForceNew()
          .enableAutoConnect()
          .enableReconnection()
          .setReconnectionAttempts(99)
          .setReconnectionDelay(800)
          .setReconnectionDelayMax(8000)
          .build(),
    );

    _socket!.onConnect((_) {
      _connecting = false;
      _rejoinConversations();
      if (!_connectedController.isClosed) {
        _connectedController.add(null);
      }
    });
    _socket!.onReconnect((_) {
      _connecting = false;
      _rejoinConversations();
      if (!_connectedController.isClosed) {
        _connectedController.add(null);
      }
    });
    _socket!.onDisconnect((_) {
      _connecting = false;
    });
    _socket!.onConnectError((err) {
      _connecting = false;
      if (kDebugMode) {
        debugPrint('[SocketChat] connect error: $err');
      }
    });
    _socket!.on('chat_message', _onChatMessage);
    _socket!.on('message_receipts', _onMessageReceipts);
  }

  void _rejoinConversations() {
    for (final id in _joinedConversations) {
      _socket?.emit('join_conversation', id);
    }
  }

  void _onChatMessage(dynamic data) {
    final map = _asStringKeyedMap(data);
    if (map == null) return;
    try {
      final message = ChatMessage.fromJson(map);
      if (!_messageController.isClosed) {
        _messageController.add(message);
      }
      final senderId = message.senderId;
      final myId = _userId;
      if (senderId != null &&
          senderId.isNotEmpty &&
          message.id != null &&
          (myId == null ||
              senderId.toLowerCase() != myId.toLowerCase())) {
        _socket?.emit('ack_delivered', {
          'conversationId': message.conversationId,
          'messageId': message.id,
        });
      }
    } catch (err, st) {
      if (kDebugMode) {
        debugPrint('[SocketChat] chat_message parse failed: $err\n$st');
      }
    }
  }

  void _onMessageReceipts(dynamic data) {
    final map = _asStringKeyedMap(data);
    if (map == null) return;
    try {
      final receipt = ChatMessageReceipt.fromJson(map);
      if (receipt.conversationId.isEmpty || receipt.messageIds.isEmpty) {
        return;
      }
      if (!_receiptController.isClosed) {
        _receiptController.add(receipt);
      }
    } catch (err, st) {
      if (kDebugMode) {
        debugPrint('[SocketChat] message_receipts parse failed: $err\n$st');
      }
    }
  }

  static Map<String, dynamic>? _asStringKeyedMap(dynamic data) {
    if (data is Map<String, dynamic>) return data;
    if (data is Map) return Map<String, dynamic>.from(data);
    return null;
  }

  void joinConversation(String conversationId) {
    if (conversationId.isEmpty) return;
    _joinedConversations.add(conversationId);
    if (_socket?.connected == true) {
      _socket?.emit('join_conversation', conversationId);
    } else {
      // Ensure we are connecting; onConnect will rejoin.
      unawaited(connect());
    }
  }

  void ackRead(String conversationId) {
    if (conversationId.isEmpty) return;
    _socket?.emit('ack_read', {'conversationId': conversationId});
  }

  void leaveConversation(String conversationId) {
    _joinedConversations.remove(conversationId);
    _socket?.emit('leave_conversation', conversationId);
  }

  bool isJoined(String conversationId) =>
      _joinedConversations.contains(conversationId);

  void dispose() {
    _socket?.off('chat_message');
    _socket?.off('message_receipts');
    _socket?.dispose();
    _socket = null;
    _connecting = false;
    _joinedConversations.clear();
    _messageController.close();
    _receiptController.close();
    _connectedController.close();
  }
}
