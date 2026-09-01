import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/widgets/app_avatar.dart';
import '../../../data/models/chat_message.dart';
import 'chat_image_attachment.dart';

/// Builds the scrollable children for a chat thread: day separators plus
/// grouped, tailed message bubbles. Shared by sender / traveler / receiver
/// conversation screens so every role gets the same polished layout.
List<Widget> buildChatThreadChildren(
  List<ChatMessage> messages, {
  required String peerInitial,
}) {
  final children = <Widget>[];
  var placedGenericSeparator = false;
  DateTime? lastDay;

  for (var i = 0; i < messages.length; i++) {
    final message = messages[i];
    final prev = i > 0 ? messages[i - 1] : null;
    final next = i < messages.length - 1 ? messages[i + 1] : null;

    final day = _dayOf(message);
    if (day != null) {
      if (lastDay == null || day != lastDay) {
        children.add(ChatDaySeparator(day: day));
        lastDay = day;
      }
    } else if (!placedGenericSeparator && lastDay == null) {
      children.add(const ChatDaySeparator(day: null));
      placedGenericSeparator = true;
    }

    final isFirstInGroup =
        prev == null || prev.isMine != message.isMine || _dayOf(prev) != day;
    final isLastInGroup =
        next == null || next.isMine != message.isMine || _dayOf(next) != day;

    children.add(
      Padding(
        padding: EdgeInsets.only(top: isFirstInGroup ? 12 : 2),
        child: ChatMessageBubble(
          message: message,
          peerInitial: peerInitial,
          isLastInGroup: isLastInGroup,
        ),
      ),
    );
  }

  return children;
}

DateTime? _dayOf(ChatMessage m) {
  final ts = m.createdAt;
  if (ts == null) return null;
  return DateTime(ts.year, ts.month, ts.day);
}

/// Centered pill marking a change of day in the conversation.
class ChatDaySeparator extends StatelessWidget {
  const ChatDaySeparator({super.key, required this.day});

  /// Null renders a generic "Today" pill when messages carry no timestamp.
  final DateTime? day;

  String _label() {
    final d = day;
    if (d == null) return 'Today';
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final diff = today.difference(d).inDays;
    if (diff <= 0) return 'Today';
    if (diff == 1) return 'Yesterday';
    if (diff < 7) return DateFormat('EEEE').format(d);
    return DateFormat('MMM d, yyyy').format(d);
  }

  @override
  Widget build(BuildContext context) {
    final typo = context.typo;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Center(
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 5),
          decoration: BoxDecoration(
            color: AppColors.textSecondary.withValues(alpha: 0.10),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Text(
            _label(),
            style: typo.datePill.copyWith(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: AppColors.textSecondary,
            ),
          ),
        ),
      ),
    );
  }
}

/// Friendly placeholder shown when a conversation has no messages yet.
class ChatEmptyState extends StatelessWidget {
  const ChatEmptyState({super.key, this.message});

  final String? message;

  @override
  Widget build(BuildContext context) {
    final typo = context.typo;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 68,
              height: 68,
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.10),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.chat_bubble_outline_rounded,
                color: AppColors.primary,
                size: 30,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'No messages yet',
              style: typo.bodyBold.copyWith(fontSize: 16),
            ),
            const SizedBox(height: 6),
            Text(
              message ?? 'Say hello to get the conversation started.',
              textAlign: TextAlign.center,
              style: typo.sm.copyWith(color: AppColors.textSecondary),
            ),
          ],
        ),
      ),
    );
  }
}

/// A single message bubble with grouping-aware tail, avatar, and meta row.
class ChatMessageBubble extends StatelessWidget {
  const ChatMessageBubble({
    super.key,
    required this.message,
    required this.peerInitial,
    required this.isLastInGroup,
  });

  final ChatMessage message;
  final String peerInitial;

  /// Last message of a same-author run — gets the tail, avatar, and meta row.
  final bool isLastInGroup;

  @override
  Widget build(BuildContext context) {
    final typo = context.typo;
    final isMine = message.isMine;
    const round = Radius.circular(18);
    const tail = Radius.circular(6);

    final radius = BorderRadius.only(
      topLeft: round,
      topRight: round,
      bottomLeft: !isMine && isLastInGroup ? tail : round,
      bottomRight: isMine && isLastInGroup ? tail : round,
    );

    final Widget bubble = message.isImage
        ? ClipRRect(
            borderRadius: radius,
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 240),
              child: ChatImageAttachment(message: message),
            ),
          )
        : Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
            decoration: BoxDecoration(
              color: isMine ? AppColors.primary : AppColors.surface,
              borderRadius: radius,
              border: isMine ? null : Border.all(color: AppColors.border),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.04),
                  blurRadius: 6,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Text(
              message.text,
              style: typo.body.copyWith(
                color: isMine ? Colors.white : AppColors.textPrimary,
              ),
            ),
          );

    // Reserve avatar width for peer messages so grouped bubbles stay aligned;
    // only the last in a run actually shows the avatar.
    final avatarSlot = SizedBox(
      width: 30,
      child: isLastInGroup
          ? AppAvatar(initial: peerInitial, size: AvatarSize.small)
          : null,
    );

    return Row(
      mainAxisAlignment:
          isMine ? MainAxisAlignment.end : MainAxisAlignment.start,
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        if (!isMine) ...[avatarSlot, const SizedBox(width: 8)],
        Flexible(
          child: Column(
            crossAxisAlignment:
                isMine ? CrossAxisAlignment.end : CrossAxisAlignment.start,
            children: [
              bubble,
              if (isMine || isLastInGroup) ...[
                const SizedBox(height: 3),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (isLastInGroup)
                        Text(
                          message.displayTime,
                          style: typo.bubbleTime.copyWith(
                            fontSize: 11,
                            color: AppColors.textSecondary,
                          ),
                        ),
                      if (isMine) ...[
                        if (isLastInGroup) const SizedBox(width: 3),
                        ChatReceiptTicks(message: message),
                      ],
                    ],
                  ),
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }
}

/// WhatsApp-style ticks for outgoing messages:
/// clock → sending, 1 grey → sent, 2 grey → delivered, 2 blue → read.
class ChatReceiptTicks extends StatelessWidget {
  const ChatReceiptTicks({super.key, required this.message});

  final ChatMessage message;

  @override
  Widget build(BuildContext context) {
    if (!message.isMine) return const SizedBox.shrink();

    if (message.pending) {
      return const Icon(
        Icons.schedule_rounded,
        size: 14,
        color: AppColors.textSecondary,
      );
    }

    final read = message.receiptStatus == ChatReceiptStatus.read;
    final delivered = read ||
        message.receiptStatus == ChatReceiptStatus.delivered;

    return Icon(
      delivered ? Icons.done_all_rounded : Icons.done_rounded,
      size: 15,
      color: read ? AppColors.chatReadReceipt : AppColors.textSecondary,
    );
  }
}
