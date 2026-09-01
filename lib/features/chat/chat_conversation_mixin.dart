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

  int _localSeq = 0;

  /// Unique client-side id for an optimistic (not-yet-sent) message.
  String nextLocalMessageId() =>
      'local-${DateTime.now().microsecondsSinceEpoch}-${_localSeq++}';

  /// Append an optimistic outgoing message and show it instantly.
  /// Returns its temporary id so it can be reconciled once the server confirms.
  String addOptimisticMessage(ChatMessage message) {
    setState(() => chatMessages.add(message));
    scrollChatToBottom();
    return message.id!;
  }

  /// Replace the optimistic message [tempId] with the confirmed [server]
  /// message. If the confirmed message is already present (its socket echo beat
  /// the API response), just drop the temp copy.
  void confirmOptimisticMessage(String tempId, ChatMessage server) {
    if (!mounted) return;
    setState(() {
      final alreadyHasServer =
          server.id != null && chatMessages.any((m) => m.id == server.id);
      final idx = chatMessages.indexWhere((m) => m.id == tempId);
      if (alreadyHasServer) {
        if (idx != -1) chatMessages.removeAt(idx);
      } else if (idx != -1) {
        chatMessages[idx] = server;
      } else {
        chatMessages.add(server);
      }
    });
  }

  /// Drop the optimistic message [tempId] after a send failure.
  void removeOptimisticMessage(String tempId) {
    if (!mounted) return;
    setState(() => chatMessages.removeWhere((m) => m.id == tempId));
  }

  /// Handle the socket echo of one of my own messages. Returns true when the
  /// echo was reconciled (already present, or matched a pending temp) so the
  /// caller must NOT append it again.
  bool reconcileOwnEcho(ChatMessage server) {
    final serverId = server.id;
    if (serverId != null && chatMessages.any((m) => m.id == serverId)) {
      return true;
    }
    final idx = chatMessages.indexWhere(
      (m) =>
          m.pending &&
          m.isMine &&
          m.text == server.text &&
          m.isImage == server.isImage,
    );
    if (idx != -1) {
      setState(() => chatMessages[idx] = server);
      return true;
    }
    return false;
  }

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
