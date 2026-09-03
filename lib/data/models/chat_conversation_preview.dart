import '../../core/time/local_time.dart';
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
    this.lastMessageAt,
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
  final DateTime? lastMessageAt;

  /// True when the latest message is an image attachment.
  bool get lastMessageIsImage => isImageChatPreview(lastMessage);

  String get displayTime {
    final ts = lastMessageAt;
    if (ts != null) return LocalTime.inbox(ts);
    return time;
  }

  /// Normalized inbox preview text (never the raw `[Image]` token).
  String get displayLastMessage {
    if (lastMessageIsImage) return 'Photo';
    if (lastMessage.trim().isEmpty) return '';
    return lastMessage;
  }

  ChatConversationPreview copyWith({int? unreadCount}) {
    return ChatConversationPreview(
      id: id,
      name: name,
      initial: initial,
      lastMessage: lastMessage,
      time: time,
      shipmentId: shipmentId,
      deliveryId: deliveryId,
      unreadCount: unreadCount ?? this.unreadCount,
      messages: messages,
      threadType: threadType,
      unlocked: unlocked,
      lastMessageAt: lastMessageAt,
    );
  }

  factory ChatConversationPreview.fromJson(Map<String, dynamic> json) {
    final name = json['name'] as String? ?? 'Contact';
    final initialRaw = json['initial'] as String?;
    final rawLast = (json['lastMessage'] as String? ?? '').trim();
    final flaggedImage = json['lastMessageIsImage'] == true ||
        json['lastMessageIsImage'] == 1 ||
        json['lastMessageIsImage'] == 'true';
    final lastIsImage = flaggedImage || isImageChatPreview(rawLast);
    return ChatConversationPreview(
      id: json['id'] as String? ?? '',
      name: name,
      initial: (initialRaw != null && initialRaw.isNotEmpty)
          ? initialRaw[0].toUpperCase()
          : (name.isNotEmpty ? name[0].toUpperCase() : '?'),
      lastMessage: lastIsImage ? 'Photo' : rawLast,
      time: json['time'] as String? ?? '',
      shipmentId: json['shipmentId'] as String? ?? '',
      deliveryId: json['deliveryId'] as String? ?? '',
      unreadCount: (json['unreadCount'] as num?)?.toInt() ?? 0,
      threadType: json['threadType'] as String?,
      unlocked: _readBool(json['unlocked'], fallback: true),
      lastMessageAt: LocalTime.parse(
        json['lastMessageAt'] ?? json['updatedAt'] ?? json['createdAt'],
      ),
    );
  }
}

bool isImageChatPreview(String? value) {
  final v = (value ?? '').trim().toLowerCase();
  if (v.isEmpty) return false;
  return v == '[image]' ||
      v == 'photo' ||
      v == 'image' ||
      v == '📷 photo' ||
      v.startsWith('📷');
}

bool _readBool(dynamic value, {required bool fallback}) {
  if (value is bool) return value;
  if (value is num) return value != 0;
  if (value is String) {
    final v = value.trim().toLowerCase();
    if (v == 'true' || v == '1') return true;
    if (v == 'false' || v == '0') return false;
  }
  return fallback;
}
