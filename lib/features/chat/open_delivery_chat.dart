import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../core/config/demo_mode.dart';
import '../../data/services/chat_repository.dart';
import '../../providers/auth_provider.dart';

/// Opens the 1:1 conversation for a delivery directly, skipping the chat inbox.
///
/// Looks up the existing conversation for [deliveryKey] (which may be the
/// internal delivery UUID or the public delivery id) within [threadType] and
/// pushes straight into the thread. When the conversation can't be resolved
/// (it hasn't been created yet, or a transient lookup failure) it shows a brief
/// notice instead of navigating — importantly it never switches to another
/// role's chat inbox, which would strand the user on the wrong home screen.
Future<void> openDeliveryChat(
  BuildContext context, {
  required String chatBasePath,
  required String threadType,
  required String deliveryKey,
}) async {
  final auth = context.read<AuthProvider>();
  final demoMode = context.read<DemoModeProvider>();

  // No backend to resolve against in demo mode — go to the inbox.
  if (demoMode.enabled || deliveryKey.trim().isEmpty) {
    if (context.mounted) context.go(chatBasePath);
    return;
  }

  String? conversationId;
  try {
    final repo = ChatRepository(
      apiClient: auth.repository.apiClient,
      demoMode: demoMode,
    );
    final conversations = await repo.listConversations(threadType: threadType);
    for (final c in conversations) {
      if (c.deliveryId == deliveryKey || c.shipmentId == deliveryKey) {
        conversationId = c.id;
        break;
      }
    }
  } catch (_) {
    // Fall through to the inbox on any failure.
  }

  if (!context.mounted) return;
  if (conversationId != null && conversationId.isNotEmpty) {
    // Push the thread over the current screen so "back" pops straight to where
    // it was opened from, leaving the tab shell / home branch state untouched.
    // ('/sender-chats' -> 'sender', etc.)
    final role = chatBasePath.replaceFirst('/', '').split('-').first;
    context.push('/conversation/$role/$conversationId');
  } else {
    // No thread to open yet. Do NOT navigate to [chatBasePath] here — for a
    // cross-role chat (e.g. traveler -> receiver) that inbox lives in another
    // tab shell and would leave the user on the wrong home when they go back.
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('This chat isn’t available yet.'),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }
}
