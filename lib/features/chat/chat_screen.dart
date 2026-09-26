import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';

import '../../core/theme/app_typography.dart';

import '../../core/widgets/app_avatar.dart';

import '../../core/widgets/back_link.dart';

import '../../core/layout/responsive.dart';

import '../../core/navigation/app_navigation.dart';

import '../../core/platform/platform_ui.dart';

import '../../data/models/chat_message.dart';

import '../../data/static_data.dart';

import 'chat_conversation_mixin.dart';

import 'widgets/chat_composer.dart';

import 'widgets/chat_image_attachment.dart';



class ChatScreen extends StatefulWidget {

  const ChatScreen({

    super.key,

    this.contactName,

    this.shipmentId,

    this.contactInitial = 'A',

    this.messages,

    this.backFallback = '/home',

  });



  final String? contactName;

  final String? shipmentId;

  final String contactInitial;

  final List<ChatMessage>? messages;

  final String backFallback;



  @override

  State<ChatScreen> createState() => _ChatScreenState();

}



class _ChatScreenState extends State<ChatScreen> with ChatConversationMixin {

  @override

  void initState() {

    super.initState();

    initChatMessages(widget.messages ?? StaticData.chatMessages);

  }



  @override

  void dispose() {

    disposeChatConversation();

    super.dispose();

  }



  @override

  Widget build(BuildContext context) {

    final typo = context.typo;

    final shipment = StaticData.activeShipment;

    final title = widget.contactName ?? shipment.travelerName ?? 'Chat';

    final shipmentId = widget.shipmentId ?? shipment.id;



    return Scaffold(

      backgroundColor: AppColors.background,

      body: Column(

        children: [

          _ChatHeader(title: title, backFallback: widget.backFallback),

          Container(

            width: double.infinity,

            padding: EdgeInsets.fromLTRB(context.horizontalPadding, 0, context.horizontalPadding, 12),

            color: AppColors.surface,

            child: Text(

              'All messages end-to-end secured · $shipmentId',

              textAlign: TextAlign.center,

              style: typo.sm,

            ),

          ),

          Divider(height: 1, thickness: 1, color: AppColors.border),

          Expanded(

            child: ListView(

              controller: chatScrollController,

              physics: PlatformUi.scrollPhysics,

              padding: EdgeInsets.all(context.horizontalPadding - 4),

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

                ...List.generate(chatMessages.length, (i) => _messageBubble(context, chatMessages[i], i)),

                _typingIndicator(),

              ],

            ),

          ),

          ChatComposer(

            controller: chatController,

            hintText: 'Message...',

            onSend: sendChatTextMessage,

            onAttach: showChatAttachmentOptions,

          ),

        ],

      ),

    );

  }



  bool _showIncomingAvatar(int index) {

    if (chatMessages[index].isMine) return false;

    if (index == chatMessages.length - 1) return true;

    return chatMessages[index + 1].isMine;

  }



  Widget _messageBubble(BuildContext context, ChatMessage message, int index) {

    final typo = context.typo;

    if (message.isImage) {

      final alignment = message.isMine ? Alignment.centerRight : Alignment.centerLeft;

      final crossAxisAlignment = message.isMine ? CrossAxisAlignment.end : CrossAxisAlignment.start;

      final borderRadius = message.isMine

          ? const BorderRadius.only(

              topLeft: Radius.circular(12),

              topRight: Radius.circular(12),

              bottomLeft: Radius.circular(12),

              bottomRight: Radius.circular(4),

            )

          : const BorderRadius.only(

              topLeft: Radius.circular(4),

              topRight: Radius.circular(12),

              bottomLeft: Radius.circular(12),

              bottomRight: Radius.circular(12),

            );

      return Align(

        alignment: alignment,

        child: Column(

          crossAxisAlignment: crossAxisAlignment,

          children: [

            ClipRRect(

              borderRadius: borderRadius,

              child: ChatImageAttachment(message: message),

            ),

            const SizedBox(height: 2),

            Text(message.displayTime, style: typo.bubbleTime),

            const SizedBox(height: 10),

          ],

        ),

      );

    }



    if (message.isMine) {

      return Align(

        alignment: Alignment.centerRight,

        child: Column(

          crossAxisAlignment: CrossAxisAlignment.end,

          children: [

            Container(

              constraints: const BoxConstraints(maxWidth: 240),

              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),

              decoration: const BoxDecoration(

                color: AppColors.primary,

                borderRadius: BorderRadius.only(

                  topLeft: Radius.circular(16),

                  topRight: Radius.circular(16),

                  bottomLeft: Radius.circular(16),

                  bottomRight: Radius.circular(4),

                ),

              ),

              child: Text(message.text, style: typo.bubbleTextMine),

            ),

            const SizedBox(height: 2),

            Text(message.displayTime, style: typo.bubbleTime),

            const SizedBox(height: 10),

          ],

        ),

      );

    }



    return Row(

      crossAxisAlignment: CrossAxisAlignment.end,

      children: [

        SizedBox(

          width: 30,

          child: _showIncomingAvatar(index)

              ? AppAvatar(initial: widget.contactInitial, size: AvatarSize.small)

              : null,

        ),

        const SizedBox(width: 8),

        Column(

          crossAxisAlignment: CrossAxisAlignment.start,

          children: [

            Container(

              constraints: const BoxConstraints(maxWidth: 240),

              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),

              decoration: BoxDecoration(

                color: AppColors.surface,

                border: Border.all(color: AppColors.border),

                borderRadius: const BorderRadius.only(

                  topLeft: Radius.circular(4),

                  topRight: Radius.circular(16),

                  bottomLeft: Radius.circular(16),

                  bottomRight: Radius.circular(16),

                ),

              ),

              child: Text(message.text, style: typo.bubbleText),

            ),

            const SizedBox(height: 2),

            Text(message.displayTime, style: typo.bubbleTime),

            const SizedBox(height: 10),

          ],

        ),

      ],

    );

  }



  Widget _typingIndicator() {

    return Padding(

      padding: const EdgeInsets.only(left: 38),

      child: Align(

        alignment: Alignment.centerLeft,

        child: Container(

          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),

          decoration: BoxDecoration(

            color: AppColors.surface,

            border: Border.all(color: AppColors.border),

            borderRadius: const BorderRadius.only(

              topLeft: Radius.circular(4),

              topRight: Radius.circular(16),

              bottomLeft: Radius.circular(16),

              bottomRight: Radius.circular(16),

            ),

          ),

          child: Row(

            mainAxisSize: MainAxisSize.min,

            children: [

              _dot(1),

              const SizedBox(width: 3),

              _dot(0.6),

              const SizedBox(width: 3),

              _dot(0.3),

            ],

          ),

        ),

      ),

    );

  }



  Widget _dot(double opacity) => Container(

        width: 6,

        height: 6,

        decoration: BoxDecoration(

          color: AppColors.textSecondary.withValues(alpha: opacity),

          shape: BoxShape.circle,

        ),

      );

}



class _ChatHeader extends StatelessWidget implements PreferredSizeWidget {

  const _ChatHeader({required this.title, required this.backFallback});



  final String title;

  final String backFallback;



  @override

  Size get preferredSize => const Size.fromHeight(52);



  @override

  Widget build(BuildContext context) {

    final typo = context.typo;

    return Material(

      color: AppColors.surface,

      child: SafeArea(

        bottom: false,

        child: Padding(

          padding: EdgeInsets.symmetric(horizontal: context.horizontalPadding, vertical: 12),

          child: Row(

            children: [

              SizedBox(

                width: 72,

                child: GestureDetector(

                  behavior: HitTestBehavior.opaque,

                  onTap: () => appNavigateBackFromContext(context, fallback: backFallback),

                  child: const Padding(

                    padding: EdgeInsets.symmetric(vertical: 4),

                    child: BackLinkLabel(),

                  ),

                ),

              ),

              Expanded(

                child: Text(

                  title,

                  textAlign: TextAlign.center,

                  style: typo.headerTitle.copyWith(fontWeight: FontWeight.w700),

                ),

              ),

              const SizedBox(width: 72),

            ],

          ),

        ),

      ),

    );

  }

}


