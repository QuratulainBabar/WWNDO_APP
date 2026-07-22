import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';

import '../../core/platform/platform_ui.dart';
import '../../data/models/chat_message.dart';
import '../../data/static_data.dart';
import 'widgets/chat_attachment_sheet.dart';

mixin ChatConversationMixin<T extends StatefulWidget> on State<T> {
  final TextEditingController chatController = TextEditingController();
  final ScrollController chatScrollController = ScrollController();
  final ImagePicker chatImagePicker = ImagePicker();

  late List<ChatMessage> chatMessages;
  ChatThread? get chatThread => null;

  void initChatMessages(List<ChatMessage> initial) {
    chatMessages = List.of(initial);
  }

  void disposeChatConversation() {
    chatController.dispose();
    chatScrollController.dispose();
  }

  String get chatNowTime => DateFormat('h:mm a').format(DateTime.now());

  void scrollChatToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!chatScrollController.hasClients) return;
      chatScrollController.animateTo(
        chatScrollController.position.maxScrollExtent,
        duration: const Duration(milliseconds: 280),
        curve: Curves.easeOut,
      );
    });
  }

  void sendChatTextMessage() {
    final text = chatController.text.trim();
    if (text.isEmpty) return;

    final message = ChatMessage(text: text, isMine: true, time: chatNowTime);
    if (chatThread != null) {
      StaticData.appendChatMessage(chatThread!, message);
      setState(() {
        chatMessages = List.of(StaticData.chatMessagesForThread(chatThread!));
        chatController.clear();
      });
    } else {
      setState(() {
        chatMessages.add(message);
        chatController.clear();
      });
    }
    scrollChatToBottom();
  }

  void addChatImageMessage({required String path, required String name}) {
    final message = ChatMessage(
      text: '',
      isMine: true,
      time: chatNowTime,
      isImage: true,
      imageName: name,
      imagePath: path,
    );
    if (chatThread != null) {
      StaticData.appendChatMessage(chatThread!, message);
      setState(() {
        chatMessages = List.of(StaticData.chatMessagesForThread(chatThread!));
      });
    } else {
      setState(() {
        chatMessages.add(message);
      });
    }
    scrollChatToBottom();
  }

  Future<void> showChatAttachmentOptions() async {
    FocusScope.of(context).unfocus();
    final source = await PlatformUi.showAppBottomSheet<ImageSource>(
      context,
      child: const ChatAttachmentSheet(),
    );
    if (!mounted || source == null) return;
    await pickChatImage(source);
  }

  Future<void> pickChatImage(ImageSource source) async {
    try {
      final file = await chatImagePicker.pickImage(
        source: source,
        imageQuality: 85,
        maxWidth: 1920,
      );
      if (!mounted || file == null) return;
      addChatImageMessage(path: file.path, name: file.name);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Could not attach image: $e')),
      );
    }
  }
}
