import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../core/platform/keyboard_utils.dart';
import '../../core/api/api_exception.dart';
import '../../core/config/demo_mode.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_typography.dart';
import '../../core/widgets/app_avatar.dart';
import '../../core/widgets/back_link.dart';
import '../../core/widgets/screen_body.dart';
import '../../data/models/chat_conversation_preview.dart';
import '../../data/models/wallet_role.dart';
import '../../data/services/chat_repository.dart';
import '../../data/static_data.dart';
import '../../providers/auth_provider.dart';

/// WhatsApp-style inbox: search + conversation list before opening a chat.
class ChatListScreen extends StatefulWidget {
  const ChatListScreen({
    super.key,
    required this.role,
    required this.chatBasePath,
  });

  final WalletRole role;
  final String chatBasePath;

  @override
  State<ChatListScreen> createState() => _ChatListScreenState();
}

class _ChatListScreenState extends State<ChatListScreen> {
  final _searchController = TextEditingController();
  String _query = '';
  bool _loading = true;
  String? _error;
  List<ChatConversationPreview> _conversations = const [];

  String get _homeRoute => switch (widget.role) {
        WalletRole.sender => '/home',
        WalletRole.traveler => '/traveler-home',
        WalletRole.receiver => '/receiver-home',
      };

  bool get _useApi => !context.read<DemoModeProvider>().enabled;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _load();
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
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

  Future<void> _load({bool silent = false}) async {
    if (!_useApi) {
      setState(() {
        _conversations = StaticData.chatInboxFor(widget.role);
        _loading = false;
        _error = null;
      });
      return;
    }

    if (!silent) {
      setState(() {
        _loading = true;
        _error = null;
      });
    }

    try {
      final threadType = widget.role == WalletRole.traveler
          ? 'sender_traveler'
          : widget.role == WalletRole.receiver
              ? 'traveler_receiver'
              : null;
      final list = await _repo().listConversations(threadType: threadType);
      if (!mounted) return;
      setState(() {
        _conversations = list;
        _loading = false;
        _error = null;
      });
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
        _error = 'Unable to load chats.';
      });
    }
  }

  List<ChatConversationPreview> get _filtered {
    final all = _useApi ? _conversations : StaticData.chatInboxFor(widget.role);
    final q = _query.trim().toLowerCase();
    if (q.isEmpty) return all;
    return all
        .where(
          (c) =>
              c.name.toLowerCase().contains(q) ||
              c.lastMessage.toLowerCase().contains(q) ||
              c.shipmentId.toLowerCase().contains(q),
        )
        .toList();
  }

  @override
  Widget build(BuildContext context) {
    final typo = context.typo;
    final conversations = _filtered;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: ScreenBody(
        onRefresh: () => _load(silent: true),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            BackLink(onTap: () => context.go(_homeRoute)),
            const SizedBox(height: 16),
            Text('Chats', style: typo.h1.copyWith(fontWeight: FontWeight.w700)),
            const SizedBox(height: 16),
            TextField(
              controller: _searchController,
              onTap: ensureSoftKeyboardVisible,
              onTapOutside: dismissKeyboardOnTapOutside,
              textInputAction: TextInputAction.search,
              onChanged: (value) => setState(() => _query = value),
              style: typo.input,
              decoration: InputDecoration(
                hintText: 'Search chats',
                hintStyle: typo.searchHint,
                prefixIcon: const Icon(
                  Icons.search_rounded,
                  color: AppColors.textSecondary,
                ),
                suffixIcon: _query.isEmpty
                    ? null
                    : IconButton(
                        icon: const Icon(Icons.close_rounded),
                        onPressed: () {
                          _searchController.clear();
                          setState(() => _query = '');
                        },
                      ),
              ),
            ),
            const SizedBox(height: 8),
            if (_useApi && _loading && _conversations.isEmpty)
              const Padding(
                padding: EdgeInsets.only(top: 48),
                child: Center(
                  child: SizedBox(
                    width: 22,
                    height: 22,
                    child: CircularProgressIndicator(
                      strokeWidth: 2.5,
                      color: AppColors.primary,
                    ),
                  ),
                ),
              )
            else if (_useApi && _error != null && _conversations.isEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 48),
                child: Center(
                  child: Column(
                    children: [
                      Text(
                        _error!,
                        style: typo.sm.copyWith(color: AppColors.textSecondary),
                      ),
                      TextButton(
                        onPressed: () => _load(),
                        child: const Text('Retry'),
                      ),
                    ],
                  ),
                ),
              )
            else if (conversations.isEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 64),
                child: Center(
                  child: Column(
                    children: [
                      Container(
                        width: 72,
                        height: 72,
                        decoration: BoxDecoration(
                          color: AppColors.primary.withValues(alpha: 0.10),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.forum_outlined,
                          color: AppColors.primary,
                          size: 32,
                        ),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        _query.isEmpty ? 'No chats yet' : 'No matching chats',
                        style: typo.bodyBold.copyWith(fontSize: 16),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        _query.isEmpty
                            ? 'Your conversations will appear here.'
                            : 'Try a different search term.',
                        textAlign: TextAlign.center,
                        style:
                            typo.sm.copyWith(color: AppColors.textSecondary),
                      ),
                    ],
                  ),
                ),
              )
            else
              for (final conversation in conversations)
                _ChatListTile(
                  conversation: conversation,
                  onTap: () async {
                    await context.push(
                      '${widget.chatBasePath}/${conversation.id}',
                    );
                    if (mounted && _useApi) _load(silent: true);
                  },
                ),
          ],
        ),
      ),
    );
  }
}

class _ChatListTile extends StatelessWidget {
  const _ChatListTile({
    required this.conversation,
    required this.onTap,
  });

  final ChatConversationPreview conversation;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final typo = context.typo;
    final unread = conversation.unreadCount > 0;
    final locked = !conversation.unlocked;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Material(
          color: unread
              ? AppColors.primary.withValues(alpha: 0.04)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(14),
          child: InkWell(
            onTap: onTap,
            borderRadius: BorderRadius.circular(14),
            hoverColor: Colors.transparent,
            splashColor: Colors.transparent,
            highlightColor: Colors.transparent,
            splashFactory: NoSplash.splashFactory,
            overlayColor: const WidgetStatePropertyAll(Colors.transparent),
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _Avatar(initial: conversation.initial, locked: locked),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                conversation.name,
                                style: typo.bodyBold.copyWith(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w700,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Text(
                              conversation.displayTime,
                              style: typo.caption.copyWith(
                                fontSize: 12,
                                color: unread
                                    ? AppColors.primary
                                    : AppColors.textSecondary,
                                fontWeight:
                                    unread ? FontWeight.w700 : FontWeight.w400,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 3),
                        Row(
                          children: [
                            Expanded(
                              child: conversation.lastMessageIsImage
                                  ? Row(
                                      children: [
                                        Icon(
                                          Icons.photo_outlined,
                                          size: 16,
                                          color: unread
                                              ? AppColors.textPrimary
                                              : AppColors.textSecondary,
                                        ),
                                        const SizedBox(width: 4),
                                        Expanded(
                                          child: Text(
                                            conversation.displayLastMessage,
                                            style: typo.sm.copyWith(
                                              color: unread
                                                  ? AppColors.textPrimary
                                                  : AppColors.textSecondary,
                                              fontWeight: unread
                                                  ? FontWeight.w600
                                                  : FontWeight.w400,
                                            ),
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                        ),
                                      ],
                                    )
                                  : Text(
                                      conversation.displayLastMessage.isEmpty
                                          ? 'Tap to start chatting'
                                          : conversation.displayLastMessage,
                                      style: typo.sm.copyWith(
                                        color: unread
                                            ? AppColors.textPrimary
                                            : AppColors.textSecondary,
                                        fontWeight: unread
                                            ? FontWeight.w600
                                            : FontWeight.w400,
                                      ),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                            ),
                            if (unread) ...[
                              const SizedBox(width: 8),
                              Container(
                                constraints:
                                    const BoxConstraints(minWidth: 20),
                                height: 20,
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 6,
                                ),
                                decoration: BoxDecoration(
                                  color: AppColors.primary,
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                alignment: Alignment.center,
                                child: Text(
                                  conversation.unreadCount > 99
                                      ? '99+'
                                      : '${conversation.unreadCount}',
                                  style: typo.caption.copyWith(
                                    fontSize: 11,
                                    color: Colors.white,
                                    fontWeight: FontWeight.w700,
                                    height: 1,
                                  ),
                                ),
                              ),
                            ],
                          ],
                        ),
                        if (conversation.shipmentId.isNotEmpty) ...[
                          const SizedBox(height: 6),
                          _ShipmentChip(shipmentId: conversation.shipmentId),
                        ],
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        const Padding(
          padding: EdgeInsets.only(left: 62),
          child: Divider(height: 1, thickness: 1, color: AppColors.border),
        ),
      ],
    );
  }
}

/// Avatar with an optional lock badge for threads that aren't unlocked yet.
class _Avatar extends StatelessWidget {
  const _Avatar({required this.initial, required this.locked});

  final String initial;
  final bool locked;

  @override
  Widget build(BuildContext context) {
    if (!locked) return AppAvatar(initial: initial);
    return Stack(
      clipBehavior: Clip.none,
      children: [
        AppAvatar(initial: initial),
        Positioned(
          right: -2,
          bottom: -2,
          child: Container(
            padding: const EdgeInsets.all(3),
            decoration: BoxDecoration(
              color: AppColors.surface,
              shape: BoxShape.circle,
              border: Border.all(color: AppColors.border),
            ),
            child: const Icon(
              Icons.lock_rounded,
              size: 11,
              color: AppColors.textSecondary,
            ),
          ),
        ),
      ],
    );
  }
}

/// Small pill showing the linked shipment id on an inbox row.
class _ShipmentChip extends StatelessWidget {
  const _ShipmentChip({required this.shipmentId});

  final String shipmentId;

  @override
  Widget build(BuildContext context) {
    final typo = context.typo;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: AppColors.primary.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(
            Icons.local_shipping_outlined,
            size: 13,
            color: AppColors.primary,
          ),
          const SizedBox(width: 4),
          Text(
            shipmentId,
            style: typo.caption.copyWith(
              fontSize: 11,
              color: AppColors.primary,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}
