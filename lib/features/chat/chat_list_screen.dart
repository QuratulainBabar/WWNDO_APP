import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

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

  bool get _useApi =>
      widget.role == WalletRole.receiver || widget.role == WalletRole.sender;

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
      final list = await _repo().listConversations();
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
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            BackLink(onTap: () => context.go(_homeRoute)),
            const SizedBox(height: 16),
            Text('Chats', style: typo.h1.copyWith(fontWeight: FontWeight.w700)),
            const SizedBox(height: 16),
            TextField(
              controller: _searchController,
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
                padding: const EdgeInsets.only(top: 48),
                child: Center(
                  child: Text(
                    'No chats yet.',
                    style: typo.sm.copyWith(color: AppColors.textSecondary),
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

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: onTap,
            hoverColor: Colors.transparent,
            splashColor: Colors.transparent,
            highlightColor: Colors.transparent,
            splashFactory: NoSplash.splashFactory,
            overlayColor: const WidgetStatePropertyAll(Colors.transparent),
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 4),
              child: Row(
                children: [
                  AppAvatar(initial: conversation.initial),
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
                                  fontWeight: FontWeight.w700,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Text(
                              conversation.time,
                              style: typo.caption.copyWith(
                                color: unread
                                    ? AppColors.primary
                                    : AppColors.textSecondary,
                                fontWeight:
                                    unread ? FontWeight.w600 : FontWeight.w400,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                conversation.lastMessage,
                                style: typo.sm.copyWith(
                                  color: AppColors.textSecondary,
                                  fontWeight:
                                      unread ? FontWeight.w600 : FontWeight.w400,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            if (unread) ...[
                              const SizedBox(width: 8),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 7,
                                  vertical: 2,
                                ),
                                decoration: BoxDecoration(
                                  color: AppColors.primary,
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                alignment: Alignment.center,
                                child: Text(
                                  '${conversation.unreadCount}',
                                  style: typo.caption.copyWith(
                                    color: Colors.white,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ),
                            ],
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        const Divider(
          height: 1,
          thickness: 1,
          color: Color(0xFFD1D5DB),
        ),
      ],
    );
  }
}
