import 'package:flutter/material.dart';

import '../../core/layout/responsive.dart';
import '../../core/platform/platform_ui.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_typography.dart';
import '../../core/widgets/app_avatar.dart';
import '../../core/widgets/back_header.dart';
import '../../data/models/chat_message.dart';
import '../../data/models/traveler_bid.dart';
import '../../data/static_data.dart';
import '../chat/chat_conversation_mixin.dart';
import '../chat/widgets/chat_composer.dart';
import '../chat/widgets/chat_image_attachment.dart';

class TravelerChatScreen extends StatefulWidget {
  const TravelerChatScreen({
    super.key,
    required this.bid,
    this.backFallback,
  });

  final TravelerBid bid;
  final String? backFallback;

  @override
  State<TravelerChatScreen> createState() => _TravelerChatScreenState();
}

class _TravelerChatScreenState extends State<TravelerChatScreen> with ChatConversationMixin {
  @override
  ChatThread? get chatThread => ChatThread.senderTraveler;

  @override
  void initState() {
    super.initState();
    initChatMessages(StaticData.chatMessagesForThread(ChatThread.senderTraveler));
  }

  @override
  void dispose() {
    disposeChatConversation();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final typo = context.typo;
    final sender = widget.bid.senderName;
    final unlocked = StaticData.isThreadUnlocked(ChatThread.senderTraveler);
    final lockReasons = StaticData.chatThreadLockReasons(ChatThread.senderTraveler);
    final meetup = StaticData.thread1ProposedMeetupLocation;
    final canRevealContacts = StaticData.canRevealThread1Contacts;

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
              'Chat is available because your bid has been accepted by the sender.',
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
            padding: EdgeInsets.fromLTRB(context.horizontalPadding, 0, context.horizontalPadding, 12),
            color: AppColors.surface,
            child: Column(
              children: [
                Text(
                  'Traveler ↔ Sender · ${StaticData.activeShipment.id}',
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
                const SizedBox(height: 6),
                Text(
                  canRevealContacts
                      ? 'Sender contact: ${StaticData.currentUser.phone} · ${StaticData.currentUser.email}'
                      : 'Contact details hidden until both users accept meetup location',
                  textAlign: TextAlign.center,
                  style: typo.sm.copyWith(
                    color: canRevealContacts
                        ? AppColors.success
                        : AppColors.textSecondary,
                  ),
                ),
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
                'Thread locked: ${lockReasons.join(' · ')}',
                style: typo.sm.copyWith(
                  color: AppColors.warning,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          Expanded(
            child: ValueListenableBuilder<int>(
              valueListenable: StaticData.chatThreadsVersion,
              builder: (context, _, __) {
                chatMessages = List.of(
                  StaticData.chatMessagesForThread(ChatThread.senderTraveler),
                );
                return ListView(
                  controller: chatScrollController,
                  physics: PlatformUi.scrollPhysics,
                  padding: EdgeInsets.all(context.horizontalPadding),
                  children: [
                    Center(
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                        decoration: BoxDecoration(
                          color: AppColors.background,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Text('Today', style: typo.datePill),
                      ),
                    ),
                    const SizedBox(height: 14),
                    ...chatMessages.map(
                      (m) => _ChatBubble(message: m, senderInitial: widget.bid.senderInitial),
                    ),
                  ],
                );
              },
            ),
          ),
          ChatComposer(
            controller: chatController,
            hintText: 'Message $sender…',
            onSend: sendChatTextMessage,
            onAttach: showChatAttachmentOptions,
            borderRadius: 12,
            circularSendButton: false,
            enabled: unlocked,
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
        mainAxisAlignment: isMine ? MainAxisAlignment.end : MainAxisAlignment.start,
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
