import 'dart:async';

import 'package:socket_io_client/socket_io_client.dart' as io;

import '../../core/config/api_config.dart';
import '../models/chat_message.dart';

/// Real-time chat via Socket.io (join conversation + listen for messages).
class SocketChatService {
  SocketChatService({required this.getAccessToken});

  final Future<String?> Function() getAccessToken;

  io.Socket? _socket;
  String? _userId;
  final _joinedConversations = <String>{};
  final _messageController = StreamController<ChatMessage>.broadcast();
  final _receiptController = StreamController<ChatMessageReceipt>.broadcast();

  Stream<ChatMessage> get onMessage => _messageController.stream;
  Stream<ChatMessageReceipt> get onReceipt => _receiptController.stream;

  bool get isConnected => _socket?.connected ?? false;

  void setUserId(String? userId) {
    _userId = userId;
  }

  Future<void> connect() async {
    if (_socket?.connected == true) return;
    final token = await getAccessToken();
    if (token == null || token.isEmpty) return;

    _socket?.dispose();
    _socket = io.io(
      ApiConfig.socketUrl,
      io.OptionBuilder()
          .setTransports(['websocket'])
          .setPath('/socket.io')
          .setAuth({'token': token})
          .enableAutoConnect()
          .enableReconnection()
          .build(),
    );

    _socket!.onConnect((_) {
      for (final id in _joinedConversations) {
        _socket?.emit('join_conversation', id);
      }
    });
    _socket!.on('chat_message', (data) {
      if (data is! Map) return;
      try {
        final map = Map<String, dynamic>.from(data);
        final message = ChatMessage.fromJson(map);
        _messageController.add(message);
        final senderId = message.senderId;
        if (senderId != null &&
            senderId.isNotEmpty &&
            senderId != _userId &&
            message.id != null) {
          _socket?.emit('ack_delivered', {
            'conversationId': message.conversationId,
            'messageId': message.id,
          });
        }
      } catch (_) {}
    });
    _socket!.on('message_receipts', (data) {
      if (data is! Map) return;
      try {
        final receipt = ChatMessageReceipt.fromJson(
          Map<String, dynamic>.from(data),
        );
        if (receipt.conversationId.isEmpty || receipt.messageIds.isEmpty) {
          return;
        }
        _receiptController.add(receipt);
      } catch (_) {}
    });
  }

  void joinConversation(String conversationId) {
    if (conversationId.isEmpty) return;
    _joinedConversations.add(conversationId);
    _socket?.emit('join_conversation', conversationId);
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
    _socket?.dispose();
    _socket = null;
    _joinedConversations.clear();
    _messageController.close();
    _receiptController.close();
  }
}
