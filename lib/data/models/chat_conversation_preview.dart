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
    this.deliveryId = '',
    this.unreadCount = 0,
    this.messages = const [],
    this.threadType,
    this.unlocked = true,
  });

  final String id;
  final String name;
  final String initial;
  final String lastMessage;
  final String time;
  final String shipmentId;

  /// Internal delivery UUID this conversation belongs to (from the backend).
  final String deliveryId;
  final int unreadCount;
  final List<ChatMessage> messages;
  final String? threadType;
  final bool unlocked;

  factory ChatConversationPreview.fromJson(Map<String, dynamic> json) {
    final name = json['name'] as String? ?? 'Contact';
    final initialRaw = json['initial'] as String?;
    return ChatConversationPreview(
      id: json['id'] as String? ?? '',
      name: name,
      initial: (initialRaw != null && initialRaw.isNotEmpty)
          ? initialRaw[0].toUpperCase()
          : (name.isNotEmpty ? name[0].toUpperCase() : '?'),
      lastMessage: json['lastMessage'] as String? ?? '',
      time: json['time'] as String? ?? '',
      shipmentId: json['shipmentId'] as String? ?? '',
      deliveryId: json['deliveryId'] as String? ?? '',
      unreadCount: (json['unreadCount'] as num?)?.toInt() ?? 0,
      threadType: json['threadType'] as String?,
      unlocked: json['unlocked'] as bool? ?? true,
    );
  }
}
