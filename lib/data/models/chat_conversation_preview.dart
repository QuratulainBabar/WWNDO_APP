import 'chat_message.dart';

/// Inbox row for WhatsApp-style chat list.
class ChatConversationPreview {
  const ChatConversationPreview({
    required this.id,
    required this.name,
    required this.initial,
    required this.lastMessage,
    required this.time,
    required this.shipmentId,
    this.unreadCount = 0,
    this.messages = const [],
  });

  final String id;
  final String name;
  final String initial;
  final String lastMessage;
  final String time;
  final String shipmentId;
  final int unreadCount;
  final List<ChatMessage> messages;
}
