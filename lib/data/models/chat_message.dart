import '../../core/config/api_config.dart';
import '../../core/time/local_time.dart';

enum ChatThread {
  senderTraveler,
  travelerReceiver,
}

/// WhatsApp-style per-message receipt. [pending] is client-only (clock icon).
enum ChatReceiptStatus {
  sent,
  delivered,
  read,
}

int chatReceiptRank(ChatReceiptStatus status) {
  switch (status) {
    case ChatReceiptStatus.sent:
      return 1;
    case ChatReceiptStatus.delivered:
      return 2;
    case ChatReceiptStatus.read:
      return 3;
  }
}

ChatReceiptStatus maxChatReceiptStatus(
  ChatReceiptStatus a,
  ChatReceiptStatus b,
) {
  return chatReceiptRank(a) >= chatReceiptRank(b) ? a : b;
}

ChatReceiptStatus parseChatReceiptStatus(dynamic value) {
  switch (value?.toString()) {
    case 'read':
      return ChatReceiptStatus.read;
    case 'delivered':
      return ChatReceiptStatus.delivered;
    default:
      return ChatReceiptStatus.sent;
  }
}

/// Real-time tick update from the peer (delivered or read).
class ChatMessageReceipt {
  const ChatMessageReceipt({
    required this.conversationId,
    required this.status,
    required this.messageIds,
    this.at,
  });

  final String conversationId;
  final ChatReceiptStatus status;
  final List<String> messageIds;
  final DateTime? at;

  factory ChatMessageReceipt.fromJson(Map<String, dynamic> json) {
    final ids = json['messageIds'];
    return ChatMessageReceipt(
      conversationId: json['conversationId']?.toString() ?? '',
      status: parseChatReceiptStatus(json['status']),
      messageIds: ids is List
          ? ids.map((id) => id.toString()).where((id) => id.isNotEmpty).toList()
          : const [],
      at: LocalTime.parse(json['at']),
    );
  }
}

class ChatMessage {
  const ChatMessage({
    required this.text,
    required this.isMine,
    required this.time,
    this.id,
    this.conversationId,
    this.senderId,
    this.isImage = false,
    this.imageName,
    this.imagePath,
    this.createdAt,
    this.pending = false,
    this.receiptStatus = ChatReceiptStatus.sent,
  });

  final String text;
  final bool isMine;
  final String time;

  /// True for an optimistic outgoing message that hasn't been confirmed by the
  /// server yet. Used to reconcile against the socket echo / API response.
  final bool pending;

  /// Server message id — used to de-duplicate the socket echo of a message the
  /// sender already appended from its API response.
  final String? id;

  /// Conversation this message belongs to (realtime payloads).
  final String? conversationId;

  /// Raw author id from realtime payloads; each client derives [isMine] from it.
  final String? senderId;
  final bool isImage;
  final String? imageName;
  final String? imagePath;

  /// Server timestamp — drives day separators and message grouping in the thread.
  final DateTime? createdAt;

  /// Delivery/read receipt. Ignored for incoming bubbles.
  final ChatReceiptStatus receiptStatus;

  /// Clock label in the user's local timezone.
  String get displayTime {
    final ts = createdAt;
    if (ts != null) return LocalTime.clock(ts);
    return time;
  }

  /// Absolute URL for a chat image stored on the server.
  String? get remoteImageUrl {
    for (final candidate in [imagePath, imageName]) {
      if (!_looksLikeRemote(candidate)) continue;
      return ApiConfig.resolveUploadUrl(candidate!);
    }
    return null;
  }

  static bool _looksLikeRemote(String? value) {
    if (value == null || value.isEmpty) return false;
    final v = value.replaceAll('\\', '/');
    return v.startsWith('http://') ||
        v.startsWith('https://') ||
        v.startsWith('/uploads') ||
        v.contains('/uploads/') ||
        v.contains('/chat/');
  }

  ChatMessage copyWith({
    bool? isMine,
    bool? pending,
    String? id,
    String? conversationId,
    String? senderId,
    String? imagePath,
    String? imageName,
    ChatReceiptStatus? receiptStatus,
  }) {
    return ChatMessage(
      text: text,
      isMine: isMine ?? this.isMine,
      time: time,
      id: id ?? this.id,
      conversationId: conversationId ?? this.conversationId,
      senderId: senderId ?? this.senderId,
      isImage: isImage,
      imageName: imageName ?? this.imageName,
      imagePath: imagePath ?? this.imagePath,
      createdAt: createdAt,
      pending: pending ?? this.pending,
      receiptStatus: receiptStatus ?? this.receiptStatus,
    );
  }

  factory ChatMessage.fromJson(Map<String, dynamic> json) {
    final createdAt = LocalTime.parse(json['createdAt']);
    final isImage = json['isImage'] == true ||
        json['isImage'] == 1 ||
        json['isImage'] == 'true';
    final imageName = json['imageName']?.toString();
    final imageUrl = json['imageUrl']?.toString() ??
        json['imagePath']?.toString() ??
        (isImage && _looksLikeRemote(imageName) ? imageName : null);
    return ChatMessage(
      text: json['text']?.toString() ?? '',
      isMine: json['isMine'] == true || json['isMine'] == 1 || json['isMine'] == 'true',
      time: createdAt != null
          ? LocalTime.clock(createdAt)
          : (json['time']?.toString() ?? ''),
      id: json['id']?.toString(),
      conversationId: json['conversationId']?.toString(),
      senderId: json['senderId']?.toString(),
      isImage: isImage || _looksLikeRemote(imageUrl) || _looksLikeRemote(imageName),
      imageName: imageName,
      imagePath: imageUrl,
      createdAt: createdAt,
      receiptStatus: parseChatReceiptStatus(json['status']),
    );
  }
}
