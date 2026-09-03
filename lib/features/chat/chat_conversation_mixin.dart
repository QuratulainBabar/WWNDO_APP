import 'dart:async';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';

import '../../core/api/api_exception.dart';
import '../../core/platform/platform_ui.dart';
import '../../core/widgets/app_toast.dart';
import '../../data/models/chat_message.dart';
import '../../data/static_data.dart';
import '../../providers/chat_realtime_provider.dart';
import 'widgets/chat_attachment_sheet.dart';

mixin ChatConversationMixin<T extends StatefulWidget> on State<T> {
  final TextEditingController chatController = TextEditingController();
  final ScrollController chatScrollController = ScrollController();
  final ImagePicker chatImagePicker = ImagePicker();

  late List<ChatMessage> chatMessages;
  ChatThread? get chatThread => null;

  StreamSubscription<ChatMessage>? _liveMessageSub;
  StreamSubscription<ChatMessageReceipt>? _liveReceiptSub;

  /// Live conversation id — when set with [uploadLiveChatImage], attachments
  /// are uploaded to the server instead of staying local-only.
  String? get liveChatConversationId => null;

  Future<ChatMessage> Function(String conversationId, String filePath)?
      get uploadLiveChatImage => null;

  void initChatMessages(List<ChatMessage> initial) {
    chatMessages = List.of(initial);
  }

  void disposeChatConversation() {
    detachLiveChatListeners();
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
  /// the API response), just drop the temp copy and keep the higher receipt.
  void confirmOptimisticMessage(String tempId, ChatMessage server) {
    if (!mounted) return;
    setState(() {
      final alreadyIdx = server.id == null
          ? -1
          : chatMessages.indexWhere((m) => m.id == server.id);
      final idx = chatMessages.indexWhere((m) => m.id == tempId);
      if (alreadyIdx != -1) {
        chatMessages[alreadyIdx] = _mergeReceipt(chatMessages[alreadyIdx], server);
        if (idx != -1 && idx != alreadyIdx) chatMessages.removeAt(idx);
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
    if (serverId != null) {
      final existingIdx = chatMessages.indexWhere((m) => m.id == serverId);
      if (existingIdx != -1) {
        setState(() {
          chatMessages[existingIdx] =
              _mergeReceipt(chatMessages[existingIdx], server);
        });
        return true;
      }
    }
    final idx = chatMessages.indexWhere((m) {
      if (!m.pending || !m.isMine || m.isImage != server.isImage) return false;
      if (m.isImage) return true;
      return m.text == server.text;
    });
    if (idx != -1) {
      setState(() => chatMessages[idx] = server.copyWith(pending: false));
      return true;
    }
    return false;
  }

  void applyMessageReceipts(ChatMessageReceipt receipt) {
    if (!mounted || receipt.messageIds.isEmpty) return;
    final ids = receipt.messageIds.toSet();
    var changed = false;
    final nextMessages = List<ChatMessage>.of(chatMessages);
    for (var i = 0; i < nextMessages.length; i++) {
      final m = nextMessages[i];
      if (m.id == null || !ids.contains(m.id)) continue;
      final next = maxChatReceiptStatus(m.receiptStatus, receipt.status);
      if (next == m.receiptStatus && !m.pending) continue;
      nextMessages[i] = m.copyWith(pending: false, receiptStatus: next);
      changed = true;
    }
    if (!changed) return;
    setState(() => chatMessages = nextMessages);
  }

  ChatMessage _mergeReceipt(ChatMessage local, ChatMessage incoming) {
    return local.copyWith(
      id: incoming.id ?? local.id,
      conversationId: incoming.conversationId ?? local.conversationId,
      senderId: incoming.senderId ?? local.senderId,
      isMine: incoming.isMine,
      pending: false,
      receiptStatus: maxChatReceiptStatus(
        local.receiptStatus,
        incoming.receiptStatus,
      ),
      imagePath: local.imagePath ?? incoming.imagePath,
      imageName: incoming.imageName ?? local.imageName,
    );
  }

  void attachLiveChatListeners({
    required ChatRealtimeProvider realtime,
    required String conversationId,
    required String? myId,
  }) {
    detachLiveChatListeners();
    realtime.joinConversation(conversationId);
    _liveMessageSub = realtime.onMessage.listen((message) {
      if (!mounted) return;
      if (message.conversationId != null &&
          message.conversationId!.isNotEmpty &&
          message.conversationId != conversationId) {
        return;
      }
      final resolved = message.senderId != null
          ? message.copyWith(isMine: message.senderId == myId)
          : message;
      if (resolved.isMine) {
        if (reconcileOwnEcho(resolved)) {
          scrollChatToBottom();
          return;
        }
      } else if (resolved.id != null &&
          chatMessages.any((m) => m.id == resolved.id)) {
        return;
      }
      setState(() => chatMessages.add(resolved));
      scrollChatToBottom();
      if (!resolved.isMine) {
        realtime.ackRead(conversationId);
      }
    });
    _liveReceiptSub = realtime.onReceipt.listen((receipt) {
      if (!mounted) return;
      if (receipt.conversationId != conversationId) return;
      applyMessageReceipts(receipt);
    });
  }

  void detachLiveChatListeners() {
    _liveMessageSub?.cancel();
    _liveReceiptSub?.cancel();
    _liveMessageSub = null;
    _liveReceiptSub = null;
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

    final message = ChatMessage(
      text: text,
      isMine: true,
      time: chatNowTime,
      createdAt: DateTime.now(),
    );
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
      createdAt: DateTime.now(),
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

      final conversationId = liveChatConversationId;
      final upload = uploadLiveChatImage;
      if (conversationId != null &&
          conversationId.isNotEmpty &&
          upload != null) {
        await sendLiveChatImage(
          conversationId: conversationId,
          path: file.path,
          name: file.name,
          upload: upload,
        );
        return;
      }

      addChatImageMessage(path: file.path, name: file.name);
    } catch (e) {
      if (!mounted) return;
      AppToast.error(context, 'Could not attach image: $e');
    }
  }

  Future<void> sendLiveChatImage({
    required String conversationId,
    required String path,
    required String name,
    required Future<ChatMessage> Function(String conversationId, String filePath)
        upload,
  }) async {
    final tempId = addOptimisticMessage(
      ChatMessage(
        text: '',
        isMine: true,
        time: chatNowTime,
        createdAt: DateTime.now(),
        id: nextLocalMessageId(),
        pending: true,
        isImage: true,
        imageName: name,
        imagePath: path,
      ),
    );
    try {
      final server = await upload(conversationId, path);
      final merged = server.copyWith(
        imagePath: path,
        imageName: server.remoteImageUrl ?? server.imageName ?? name,
      );
      confirmOptimisticMessage(tempId, merged);
      scrollChatToBottom();
    } on ApiException catch (e) {
      if (!mounted) return;
      removeOptimisticMessage(tempId);
      AppToast.error(context, e.message);
    } catch (_) {
      if (!mounted) return;
      removeOptimisticMessage(tempId);
      AppToast.error(context, 'Unable to send image.');
    }
  }
}
