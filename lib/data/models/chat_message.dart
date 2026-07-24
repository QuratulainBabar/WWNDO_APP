enum ChatThread {
  senderTraveler,
  travelerReceiver,
}

class ChatMessage {
  const ChatMessage({
    required this.text,
    required this.isMine,
    required this.time,
    this.isImage = false,
    this.imageName,
    this.imagePath,
  });

  final String text;
  final bool isMine;
  final String time;
  final bool isImage;
  final String? imageName;
  final String? imagePath;

  factory ChatMessage.fromJson(Map<String, dynamic> json) {
    return ChatMessage(
      text: json['text'] as String? ?? '',
      isMine: json['isMine'] as bool? ?? false,
      time: json['time'] as String? ?? '',
      isImage: json['isImage'] as bool? ?? false,
      imageName: json['imageName'] as String?,
    );
  }
}
