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

  StreamSubscription<String?>? _liveResyncSub;
  VoidCallback? _liveRealtimeListener;
  ChatRealtimeProvider? _liveRealtime;
  String? _liveConversationId;
  String? _liveMyId;
  Future<List<ChatMessage>> Function()? _liveResyncMessages;
  bool _resyncInFlight = false;

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
    final confirmed = _withBufferedReceipt(server);
    setState(() {
      final alreadyIdx = confirmed.id == null
          ? -1
          : chatMessages.indexWhere(
              (m) => m.id != null && _sameId(m.id, confirmed.id),
            );
      final idx = chatMessages.indexWhere((m) => m.id == tempId);
      if (alreadyIdx != -1) {
        chatMessages[alreadyIdx] =
            _mergeReceipt(chatMessages[alreadyIdx], confirmed);
        if (idx != -1 && idx != alreadyIdx) chatMessages.removeAt(idx);
      } else if (idx != -1) {
        chatMessages[idx] = confirmed;
      } else {
        chatMessages.add(confirmed);
      }
    });
  }

  ChatMessage _withBufferedReceipt(ChatMessage message) {
    final buffered = _liveRealtime?.receiptStatusFor(message.id);
    if (buffered == null) return message;
    return message.copyWith(
      receiptStatus: maxChatReceiptStatus(message.receiptStatus, buffered),
    );
  }

  static bool _sameId(String? a, String? b) {
    if (a == null || b == null || a.isEmpty || b.isEmpty) return false;
    return a.toLowerCase() == b.toLowerCase();
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
    final confirmed = _withBufferedReceipt(server);
    final serverId = confirmed.id;
    if (serverId != null) {
      final existingIdx = chatMessages.indexWhere(
        (m) => m.id != null && _sameId(m.id, serverId),
      );
      if (existingIdx != -1) {
        setState(() {
          chatMessages[existingIdx] =
              _mergeReceipt(chatMessages[existingIdx], confirmed);
        });
        return true;
      }
    }
    final idx = chatMessages.indexWhere((m) {
      if (!m.pending || !m.isMine || m.isImage != confirmed.isImage) {
        return false;
      }
      if (m.isImage) return true;
      return m.text == confirmed.text;
    });
    if (idx != -1) {
      setState(
        () => chatMessages[idx] = confirmed.copyWith(pending: false),
      );
      return true;
    }
    return false;
  }

  void applyMessageReceipts(ChatMessageReceipt receipt) {
    if (!mounted || receipt.messageIds.isEmpty) return;
    final ids = receipt.messageIds
        .map((id) => id.toLowerCase())
        .where((id) => id.isNotEmpty)
        .toSet();
    if (ids.isEmpty) return;
    var changed = false;
    final nextMessages = List<ChatMessage>.of(chatMessages);
    for (var i = 0; i < nextMessages.length; i++) {
      final m = nextMessages[i];
      final id = m.id;
      if (id == null || !ids.contains(id.toLowerCase())) continue;
      final next = maxChatReceiptStatus(m.receiptStatus, receipt.status);
      if (next == m.receiptStatus && !m.pending) continue;
      nextMessages[i] = m.copyWith(pending: false, receiptStatus: next);
      changed = true;
    }
    if (!changed) return;
    setState(() => chatMessages = nextMessages);
  }

  /// Apply any receipt statuses cached on [ChatRealtimeProvider] to the open
  /// thread (covers races where receipts beat the optimistic confirm).
  void applyBufferedReceipts() {
    final realtime = _liveRealtime;
    if (!mounted || realtime == null) return;
    var changed = false;
    final nextMessages = List<ChatMessage>.of(chatMessages);
    for (var i = 0; i < nextMessages.length; i++) {
      final m = nextMessages[i];
      if (!m.isMine || m.id == null) continue;
      final buffered = realtime.receiptStatusFor(m.id);
      if (buffered == null) continue;
      final next = maxChatReceiptStatus(m.receiptStatus, buffered);
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

  /// Attach FCM/REST live listeners for an open thread.
  ///
  /// Call this **after** seeding [chatMessages] from REST. Pass [resyncMessages]
  /// so the screen can catch up when an FCM chat push arrives or the app resumes.
  void attachLiveChatListeners({
    required ChatRealtimeProvider realtime,
    required String conversationId,
    required String? myId,
    Future<List<ChatMessage>> Function()? resyncMessages,
    String? peerName, // ignore: unused_element — API compat; FCM shows banner
  }) {
    detachLiveChatListeners(leaveConversation: false);
    _liveRealtime = realtime;
    _liveConversationId = conversationId;
    _liveMyId = myId;
    _liveResyncMessages = resyncMessages;

    realtime.joinConversation(conversationId);

    // Provider cache + notifyListeners keeps ticks in sync after REST merges.
    _liveRealtimeListener = () {
      if (!mounted) return;
      applyBufferedReceipts();
    };
    realtime.addListener(_liveRealtimeListener!);
    applyBufferedReceipts();

    _liveResyncSub = realtime.onResyncNeeded.listen((targetId) {
      if (!mounted) return;
      if (targetId != null &&
          targetId.isNotEmpty &&
          !_sameConversation(targetId, conversationId)) {
        return;
      }
      unawaited(resyncLiveChatMessages());
    });
  }

  /// Merge a REST snapshot into the open thread without dropping optimistic
  /// pending sends.
  void mergeLiveChatMessages(List<ChatMessage> serverMessages) {
    if (!mounted) return;
    final myId = _liveMyId;
    final pending = chatMessages.where((m) => m.pending).toList();
    final byId = <String, ChatMessage>{};
    for (final m in serverMessages) {
      final id = m.id;
      if (id == null || id.isEmpty) continue;
      final resolved = m.senderId != null && myId != null
          ? m.copyWith(
              isMine: m.senderId!.toLowerCase() == myId.toLowerCase(),
            )
          : m;
      byId[id.toLowerCase()] = _withBufferedReceipt(resolved);
    }
    for (final m in chatMessages) {
      final id = m.id;
      if (id == null || id.isEmpty || m.pending) continue;
      final key = id.toLowerCase();
      final incoming = byId[key];
      if (incoming == null) {
        byId[key] = _withBufferedReceipt(m);
      } else {
        byId[key] = _mergeReceipt(m, incoming);
      }
    }
    final merged = byId.values.toList()
      ..sort((a, b) {
        final aAt = a.createdAt ?? DateTime.fromMillisecondsSinceEpoch(0);
        final bAt = b.createdAt ?? DateTime.fromMillisecondsSinceEpoch(0);
        return aAt.compareTo(bAt);
      });
    for (final p in pending) {
      final alreadyConfirmed = p.text.isNotEmpty &&
          merged.any((m) =>
              m.isMine &&
              !m.pending &&
              m.isImage == p.isImage &&
              (p.isImage || m.text == p.text));
      if (!alreadyConfirmed) merged.add(p);
    }
    setState(() => chatMessages = merged);
    scrollChatToBottom();
  }

  Future<void> resyncLiveChatMessages() async {
    final fetch = _liveResyncMessages;
    if (fetch == null || _resyncInFlight || !mounted) return;
    _resyncInFlight = true;
    try {
      final messages = await fetch();
      if (!mounted) return;
      mergeLiveChatMessages(messages);
      final conversationId = _liveConversationId;
      if (conversationId != null) {
        _liveRealtime?.ackRead(conversationId);
      }
    } catch (_) {
      // Best-effort catch-up after FCM / poll / resume.
    } finally {
      _resyncInFlight = false;
    }
  }

  static bool _sameConversation(String? a, String b) {
    if (a == null || a.isEmpty) return true;
    return a.toLowerCase() == b.toLowerCase();
  }

  void detachLiveChatListeners({bool leaveConversation = true}) {
    _liveResyncSub?.cancel();
    _liveResyncSub = null;
    final listener = _liveRealtimeListener;
    if (listener != null) {
      _liveRealtime?.removeListener(listener);
    }
    _liveRealtimeListener = null;
    if (leaveConversation) {
      final id = _liveConversationId;
      if (id != null) {
        _liveRealtime?.leaveConversation(id);
      }
    }
    _liveRealtime = null;
    _liveConversationId = null;
    _liveMyId = null;
    _liveResyncMessages = null;
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
