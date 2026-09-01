import 'dart:async';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/api/api_exception.dart';
import '../../core/config/demo_mode.dart';
import '../../core/layout/responsive.dart';
import '../../core/platform/platform_ui.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_typography.dart';
import '../../core/widgets/back_header.dart';
import '../../data/models/chat_message.dart';
import '../../data/services/chat_repository.dart';
import '../../data/services/socket_chat_service.dart';
import '../../providers/auth_provider.dart';
import '../../providers/notification_realtime_provider.dart';
import '../chat/chat_conversation_mixin.dart';
import '../chat/widgets/chat_composer.dart';
import '../chat/widgets/chat_thread_widgets.dart';

class SenderChatScreen extends StatefulWidget {
  const SenderChatScreen({
    super.key,
    this.backFallback,
    this.contactName,
    this.conversationId,
  });

  final String? backFallback;
  /// When opened from inbox, show this contact until the API loads.
  final String? contactName;
  final String? conversationId;

  @override
  State<SenderChatScreen> createState() => _SenderChatScreenState();
}

class _SenderChatScreenState extends State<SenderChatScreen>
    with ChatConversationMixin {
  @override
  ChatThread? get chatThread => null;

  bool _loading = true;
  String? _error;
  String _peerName = 'Contact';
  String _shipmentId = '';
  String? _conversationId;
  bool _unlocked = true;
  StreamSubscription<ChatMessage>? _socketSub;
  SocketChatService? _socket;

  @override
  void initState() {
    super.initState();
    initChatMessages(const []);
    _conversationId = widget.conversationId;
    _peerName = widget.contactName ?? 'Contact';
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _load();
    });
  }

  @override
  void dispose() {
    _socketSub?.cancel();
    if (_conversationId != null) {
      _socket?.leaveConversation(_conversationId!);
    }
    _socket?.dispose();
    disposeChatConversation();
    super.dispose();
  }

  ChatRepository _repo() {
    final auth = context.read<AuthProvider>();
    final demoMode = context.read<DemoModeProvider>();
    return ChatRepository(
      apiClient: auth.repository.apiClient,
      demoMode: demoMode,
    );
  }

  Future<void> _load() async {
    final id = _conversationId;
    if (id == null || id.isEmpty) {
      setState(() {
        _loading = false;
        _error = 'Conversation not found.';
      });
      return;
    }

    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final detail = await _repo().getConversation(id);
      if (!mounted) return;

      final auth = context.read<AuthProvider>();
      final myId = auth.repository.currentUser?.id;
      _socket = SocketChatService(
        getAccessToken: auth.repository.tokenStorage.getAccessToken,
      );
      await _socket!.connect();
      _socket!.joinConversation(id);
      _socketSub = _socket!.onMessage.listen((message) {
        if (!mounted) return;
        // The realtime payload is viewer-neutral — derive alignment locally.
        final resolved = message.senderId != null
            ? message.copyWith(isMine: message.senderId == myId)
            : message;
        // Reconcile the echo of a message we optimistically appended locally.
        if (resolved.isMine) {
          if (reconcileOwnEcho(resolved)) {
            scrollChatToBottom();
            return;
          }
        } else if (resolved.id != null &&
            chatMessages.any((m) => m.id == resolved.id)) {
          return; // duplicate peer message
        }
        setState(() => chatMessages.add(resolved));
        scrollChatToBottom();
      });

      setState(() {
        chatMessages = List.of(detail.messages);
        _peerName = widget.contactName ?? detail.name;
        _shipmentId = detail.shipmentId;
        _unlocked = detail.unlocked;
        _loading = false;
      });
      scrollChatToBottom();
      // Opening the thread marked it read server-side — clear the tab badge now
      // instead of waiting for the next poll.
      if (mounted) {
        context.read<NotificationRealtimeProvider>().refreshChatUnread(
              authRepository: auth.repository,
              demoMode: context.read<DemoModeProvider>(),
            );
      }
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _error = e.message;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _error = 'Unable to load conversation.';
      });
    }
  }

  Future<void> _sendApiMessage() async {
    final text = chatController.text.trim();
    final id = _conversationId;
    if (text.isEmpty || id == null) return;

    chatController.clear();
    // Show the message immediately, then reconcile with the server response.
    final tempId = addOptimisticMessage(
      ChatMessage(
        text: text,
        isMine: true,
        time: chatNowTime,
        id: nextLocalMessageId(),
        pending: true,
      ),
    );
    try {
      final message = await _repo().sendMessage(id, text);
      confirmOptimisticMessage(tempId, message);
      scrollChatToBottom();
    } on ApiException catch (e) {
      if (!mounted) return;
      removeOptimisticMessage(tempId);
      chatController.text = text;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.message)),
      );
    } catch (_) {
      if (!mounted) return;
      removeOptimisticMessage(tempId);
      chatController.text = text;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Unable to send message.')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final typo = context.typo;
    final traveler = _peerName;
    final initial = traveler.isNotEmpty ? traveler[0] : '?';

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: BackHeader(
        title: traveler,
        showBottomBorder: false,
        fallbackRoute: widget.backFallback ?? '/sender-chats',
      ),
      body: Column(
        children: [
          Container(
            width: double.infinity,
            padding: EdgeInsets.fromLTRB(
              context.horizontalPadding,
              12,
              context.horizontalPadding,
              12,
            ),
            color: _unlocked
                ? AppColors.primary.withValues(alpha: 0.08)
                : AppColors.warning.withValues(alpha: 0.12),
            child: Text(
              _unlocked
                  ? 'Chat is open — coordinate meetup details with your traveler.'
                  : 'Chat unlocks after you accept a traveler and payment is complete.',
              textAlign: TextAlign.center,
              style: typo.sm.copyWith(
                color: _unlocked ? AppColors.primary : AppColors.warning,
                fontWeight: FontWeight.w600,
                height: 1.45,
              ),
            ),
          ),
          Container(
            width: double.infinity,
            padding: EdgeInsets.fromLTRB(
              context.horizontalPadding,
              12,
              context.horizontalPadding,
              12,
            ),
            color: AppColors.surface,
            child: Text(
              _shipmentId.isEmpty
                  ? 'Sender ↔ Traveler'
                  : 'Sender ↔ Traveler · $_shipmentId',
              textAlign: TextAlign.center,
              style: typo.sm,
            ),
          ),
          Expanded(
            child: _loading
                ? const Center(
                    child: SizedBox(
                      width: 22,
                      height: 22,
                      child: CircularProgressIndicator(
                        strokeWidth: 2.5,
                        color: AppColors.primary,
                      ),
                    ),
                  )
                : _error != null
                    ? Center(
                        child: Padding(
                          padding: context.pagePadding,
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                _error!,
                                textAlign: TextAlign.center,
                                style: typo.sm.copyWith(
                                  color: AppColors.textSecondary,
                                ),
                              ),
                              TextButton(
                                onPressed: _load,
                                child: const Text('Retry'),
                              ),
                            ],
                          ),
                        ),
                      )
                    : chatMessages.isEmpty
                        ? const ChatEmptyState()
                        : ListView(
                            controller: chatScrollController,
                            physics: PlatformUi.scrollPhysics,
                            padding: EdgeInsets.fromLTRB(
                              context.horizontalPadding,
                              4,
                              context.horizontalPadding,
                              12,
                            ),
                            children: buildChatThreadChildren(
                              chatMessages,
                              peerInitial: initial,
                            ),
                          ),
          ),
          ChatComposer(
            controller: chatController,
            hintText: 'Message $traveler…',
            onSend: _sendApiMessage,
            onAttach: showChatAttachmentOptions,
            borderRadius: 12,
            circularSendButton: false,
            enabled: _unlocked &&
                !_loading &&
                _error == null &&
                _conversationId != null,
          ),
        ],
      ),
    );
  }
}
