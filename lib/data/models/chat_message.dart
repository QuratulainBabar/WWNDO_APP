enum ChatThread {
  senderTraveler,
  travelerReceiver,
}

class ChatMessage {
  const ChatMessage({
    required this.text,
    required this.isMine,
    required this.time,
    this.id,
    this.senderId,
    this.isImage = false,
    this.imageName,
    this.imagePath,
    this.createdAt,
    this.pending = false,
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

  /// Raw author id from realtime payloads; each client derives [isMine] from it.
  final String? senderId;
  final bool isImage;
  final String? imageName;
  final String? imagePath;

  /// Server timestamp — drives day separators and message grouping in the thread.
  final DateTime? createdAt;

  ChatMessage copyWith({bool? isMine, bool? pending}) {
    return ChatMessage(
      text: text,
      isMine: isMine ?? this.isMine,
      time: time,
      id: id,
      senderId: senderId,
      isImage: isImage,
      imageName: imageName,
      imagePath: imagePath,
      createdAt: createdAt,
      pending: pending ?? this.pending,
    );
  }

  factory ChatMessage.fromJson(Map<String, dynamic> json) {
    return ChatMessage(
      text: json['text'] as String? ?? '',
      isMine: json['isMine'] as bool? ?? false,
      time: json['time'] as String? ?? '',
      id: json['id']?.toString(),
      senderId: json['senderId']?.toString(),
      isImage: json['isImage'] as bool? ?? false,
      imageName: json['imageName'] as String?,
      createdAt: DateTime.tryParse(json['createdAt']?.toString() ?? '')?.toLocal(),
    );
  }
}
