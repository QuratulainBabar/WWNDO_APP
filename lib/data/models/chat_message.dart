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
}
