import 'dart:async';

import 'package:socket_io_client/socket_io_client.dart' as io;

import '../../core/config/api_config.dart';
import '../models/chat_message.dart';

/// Real-time chat via Socket.io (join conversation + listen for messages).
class SocketChatService {
  SocketChatService({required this.getAccessToken});

  final Future<String?> Function() getAccessToken;

  io.Socket? _socket;
  final _messageController = StreamController<ChatMessage>.broadcast();

  Stream<ChatMessage> get onMessage => _messageController.stream;

  bool get isConnected => _socket?.connected ?? false;

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
          .build(),
    );

    _socket!.onConnect((_) {});
    _socket!.on('chat_message', (data) {
      if (data is! Map) return;
      try {
        final map = Map<String, dynamic>.from(data);
        _messageController.add(ChatMessage.fromJson(map));
      } catch (_) {}
    });
  }

  void joinConversation(String conversationId) {
    _socket?.emit('join_conversation', conversationId);
  }

  void leaveConversation(String conversationId) {
    _socket?.emit('leave_conversation', conversationId);
  }

  void dispose() {
    _socket?.dispose();
    _socket = null;
    _messageController.close();
  }
}
