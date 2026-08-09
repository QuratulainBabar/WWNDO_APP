import 'dart:async';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/api/api_exception.dart';
import '../../core/config/demo_mode.dart';
import '../../core/layout/responsive.dart';
import '../../core/platform/platform_ui.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_typography.dart';
import '../../core/widgets/app_avatar.dart';
import '../../core/widgets/back_header.dart';
import '../../data/models/chat_message.dart';
import '../../data/models/traveler_bid.dart';
import '../../data/services/chat_repository.dart';
import '../../data/services/socket_chat_service.dart';
import '../../data/static_data.dart';
import '../../providers/auth_provider.dart';
import '../chat/chat_conversation_mixin.dart';
import '../chat/widgets/chat_composer.dart';
import '../chat/widgets/chat_image_attachment.dart';

class TravelerChatScreen extends StatefulWidget {
  const TravelerChatScreen({
    super.key,
    required this.bid,
    this.backFallback,
    this.conversationId,
  });

  final TravelerBid bid;
  final String? backFallback;
  final String? conversationId;

  @override
  State<TravelerChatScreen> createState() => _TravelerChatScreenState();
}

class _TravelerChatScreenState extends State<TravelerChatScreen>
    with ChatConversationMixin {
  bool _loading = true;
  String? _error;
  String _peerName = '';
  String _shipmentId = '';
  String? _conversationId;
  bool _unlocked = true;
  String? _meetupLocation;
  StreamSubscription<ChatMessage>? _socketSub;
  SocketChatService? _socket;

  @override
  ChatThread? get chatThread => null;

  @override
  void initState() {
    super.initState();
    _peerName = widget.bid.senderName;
    _conversationId = widget.conversationId;
    initChatMessages(const []);
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

  bool get _isDemo => context.read<DemoModeProvider>().enabled;

  Future<void> _load() async {
    if (_isDemo) {
      setState(() {
        chatMessages = List.of(
          StaticData.chatMessagesForThread(ChatThread.senderTraveler),
        );
        _unlocked = StaticData.isThreadUnlocked(ChatThread.senderTraveler);
        _meetupLocation = StaticData.thread1ProposedMeetupLocation;
        _shipmentId = StaticData.activeShipment.id;
        _loading = false;
      });
      return;
    }

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
      _socket = SocketChatService(
        getAccessToken: auth.repository.tokenStorage.getAccessToken,
      );
      await _socket!.connect();
      _socket!.joinConversation(id);
      _socketSub = _socket!.onMessage.listen((message) {
        if (!mounted) return;
        setState(() => chatMessages.add(message));
        scrollChatToBottom();
      });

      setState(() {
        chatMessages = List.of(detail.messages);
        _peerName = detail.name;
        _shipmentId = detail.shipmentId;
        _loading = false;
      });
      scrollChatToBottom();
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
    try {
      final message = await _repo().sendMessage(id, text);
      if (!mounted) return;
      setState(() => chatMessages.add(message));
      scrollChatToBottom();
    } on ApiException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.message)),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final typo = context.typo;
    final sender = _peerName.isNotEmpty ? _peerName : widget.bid.senderName;
    final unlocked = _isDemo
        ? StaticData.isThreadUnlocked(ChatThread.senderTraveler)
        : _unlocked;
    final meetup = _isDemo
        ? StaticData.thread1ProposedMeetupLocation
        : _meetupLocation;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: BackHeader(
        title: sender,
        showBottomBorder: false,
        fallbackRoute: widget.backFallback ?? '/traveler-chats',
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
            color: AppColors.primary.withValues(alpha: 0.08),
            child: Text(
              'Sender ↔ Traveler chat',
              textAlign: TextAlign.center,
              style: typo.sm.copyWith(
                color: AppColors.primary,
                fontWeight: FontWeight.w600,
                height: 1.45,
              ),
            ),
          ),
          Container(
            width: double.infinity,
            padding: EdgeInsets.fromLTRB(
              context.horizontalPadding,
              0,
              context.horizontalPadding,
              12,
            ),
            color: AppColors.surface,
            child: Column(
              children: [
                Text(
                  _shipmentId.isEmpty
                      ? 'Traveler ↔ Sender'
                      : 'Traveler ↔ Sender · $_shipmentId',
                  textAlign: TextAlign.center,
                  style: typo.sm,
                ),
                if (meetup != null) ...[
                  const SizedBox(height: 6),
                  Text(
                    'Proposed meetup: $meetup',
                    style: typo.sm.copyWith(
                      color: AppColors.primary,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ],
            ),
          ),
          if (!unlocked)
            Container(
              width: double.infinity,
              padding: EdgeInsets.fromLTRB(
                context.horizontalPadding,
                8,
                context.horizontalPadding,
                8,
              ),
              color: AppColors.warning.withValues(alpha: 0.12),
              child: Text(
                'Thread locked until meetup is agreed and bid accepted',
                style: typo.sm.copyWith(
                  color: AppColors.warning,
                  fontWeight: FontWeight.w700,
                ),
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
                    ? Center(child: Text(_error!, style: typo.body))
                    : ListView(
                        controller: chatScrollController,
                        physics: PlatformUi.scrollPhysics,
                        padding: EdgeInsets.all(context.horizontalPadding),
                        children: [
                          Center(
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color: AppColors.background,
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Text('Today', style: typo.datePill),
                            ),
                          ),
                          const SizedBox(height: 14),
                          ...chatMessages.map(
                            (m) => _ChatBubble(
                              message: m,
                              senderInitial: widget.bid.senderInitial,
                            ),
                          ),
                        ],
                      ),
          ),
          ChatComposer(
            controller: chatController,
            hintText: 'Message $sender…',
            onSend: _isDemo ? sendChatTextMessage : _sendApiMessage,
            onAttach: showChatAttachmentOptions,
            borderRadius: 12,
            circularSendButton: false,
            enabled: unlocked && !_loading,
          ),
        ],
      ),
    );
  }
}

class _ChatBubble extends StatelessWidget {
  const _ChatBubble({required this.message, required this.senderInitial});

  final ChatMessage message;
  final String senderInitial;

  @override
  Widget build(BuildContext context) {
    final typo = context.typo;
    final isMine = message.isMine;

    if (message.isImage) {
      return Padding(
        padding: const EdgeInsets.only(bottom: 12),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            Flexible(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  ClipRRect(
                    borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(14),
                      topRight: Radius.circular(14),
                      bottomLeft: Radius.circular(14),
                      bottomRight: Radius.circular(4),
                    ),
                    child: ChatImageAttachment(message: message),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    message.time,
                    style: typo.caption.copyWith(color: AppColors.textSecondary),
                  ),
                ],
              ),
            ),
          ],
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        mainAxisAlignment:
            isMine ? MainAxisAlignment.end : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          if (!isMine) ...[
            AppAvatar(initial: senderInitial, size: AvatarSize.small),
            const SizedBox(width: 8),
          ],
          Flexible(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                color: isMine ? AppColors.primary : AppColors.surface,
                borderRadius: BorderRadius.only(
                  topLeft: const Radius.circular(14),
                  topRight: const Radius.circular(14),
                  bottomLeft: Radius.circular(isMine ? 14 : 4),
                  bottomRight: Radius.circular(isMine ? 4 : 14),
                ),
                border: isMine ? null : Border.all(color: AppColors.border),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    message.text,
                    style: typo.body.copyWith(
                      color: isMine ? Colors.white : AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    message.time,
                    style: typo.caption.copyWith(
                      color: isMine ? Colors.white70 : AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
