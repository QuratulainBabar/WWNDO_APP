import 'package:flutter/material.dart';

import '../../data/models/wallet_role.dart';
import '../notifications/role_notifications_screen.dart';

class SenderNotificationsScreen extends StatelessWidget {
  const SenderNotificationsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const RoleNotificationsScreen(role: WalletRole.sender);
  }
}

class TravelerNotificationsScreen extends StatelessWidget {
  const TravelerNotificationsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const RoleNotificationsScreen(
      role: WalletRole.traveler,
      useBackLink: true,
    );
  }
}
