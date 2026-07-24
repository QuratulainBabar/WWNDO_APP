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
import '../../data/services/chat_repository.dart';
import '../../providers/auth_provider.dart';
import '../chat/chat_conversation_mixin.dart';
import '../chat/widgets/chat_composer.dart';
import '../chat/widgets/chat_image_attachment.dart';

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
      setState(() {
        chatMessages = List.of(detail.messages);
        _peerName = widget.contactName ?? detail.name;
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
    } catch (_) {
      if (!mounted) return;
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
            color: AppColors.primary.withValues(alpha: 0.08),
            child: Text(
              'Chat is available because the Sender has accepted this traveler\'s bid.',
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
                    : ListView(
                        controller: chatScrollController,
                        physics: PlatformUi.scrollPhysics,
                        padding: EdgeInsets.all(context.horizontalPadding),
                        children: [
                          if (chatMessages.isNotEmpty) ...[
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
                          ],
                          if (chatMessages.isEmpty)
                            Padding(
                              padding: const EdgeInsets.only(top: 48),
                              child: Center(
                                child: Text(
                                  'No messages yet.',
                                  style: typo.sm.copyWith(
                                    color: AppColors.textSecondary,
                                  ),
                                ),
                              ),
                            )
                          else
                            ...chatMessages.map(
                              (m) => _ChatBubble(
                                message: m,
                                travelerInitial: initial,
                              ),
                            ),
                        ],
                      ),
          ),
          ChatComposer(
            controller: chatController,
            hintText: 'Message $traveler…',
            onSend: _sendApiMessage,
            onAttach: showChatAttachmentOptions,
            borderRadius: 12,
            circularSendButton: false,
            enabled: !_loading && _error == null && _conversationId != null,
          ),
        ],
      ),
    );
  }
}

class _ChatBubble extends StatelessWidget {
  const _ChatBubble({required this.message, required this.travelerInitial});

  final ChatMessage message;
  final String travelerInitial;

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
            AppAvatar(initial: travelerInitial, size: AvatarSize.small),
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
