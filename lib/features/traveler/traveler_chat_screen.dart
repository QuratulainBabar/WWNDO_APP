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
import '../../data/models/traveler_bid.dart';
import '../../data/services/chat_repository.dart';
import '../../data/static_data.dart';
import '../../providers/auth_provider.dart';
import '../../providers/chat_realtime_provider.dart';
import '../../providers/notification_realtime_provider.dart';
import '../chat/chat_conversation_mixin.dart';
import '../chat/widgets/chat_composer.dart';
import '../chat/widgets/chat_thread_widgets.dart';

class TravelerChatScreen extends StatefulWidget {
  const TravelerChatScreen({
    super.key,
    this.bid,
    this.backFallback,
    this.conversationId,
    this.contactName,
  });

  final TravelerBid? bid;
  final String? backFallback;
  final String? conversationId;
  final String? contactName;

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
  ChatRealtimeProvider? _chatRealtime;

  @override
  ChatThread? get chatThread => null;

  @override
  String? get liveChatConversationId => _isDemo ? null : _conversationId;

  @override
  Future<ChatMessage> Function(String conversationId, String filePath)?
      get uploadLiveChatImage => _isDemo
          ? null
          : (id, path) => _repo().sendImage(id, path);

  @override
  void initState() {
    super.initState();
    _peerName = widget.contactName ?? widget.bid?.senderName ?? 'Contact';
    _conversationId = widget.conversationId;
    _shipmentId = widget.bid?.requestId ?? '';
    initChatMessages(const []);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _load();
    });
  }

  @override
  void dispose() {
    if (_conversationId != null) {
      _chatRealtime?.leaveConversation(_conversationId!);
    }
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
      final myId = auth.repository.currentUser?.id;
      final chatRt = context.read<ChatRealtimeProvider>();
      _chatRealtime = chatRt;
      await chatRt.start(
        getAccessToken: auth.repository.tokenStorage.getAccessToken,
        userId: myId,
        demoMode: context.read<DemoModeProvider>().enabled,
      );
      attachLiveChatListeners(
        realtime: chatRt,
        conversationId: id,
        myId: myId,
      );

      setState(() {
        chatMessages = List.of(detail.messages);
        _peerName = detail.name;
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
        createdAt: DateTime.now(),
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
    final sender = _peerName.isNotEmpty
        ? _peerName
        : (widget.bid?.senderName ?? 'Contact');
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
                'Thread locked until the sender accepts your bid and payment is complete.',
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
                              peerInitial: widget.bid?.senderInitial ??
                                  (sender.isNotEmpty
                                      ? sender[0].toUpperCase()
                                      : 'S'),
                            ),
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
