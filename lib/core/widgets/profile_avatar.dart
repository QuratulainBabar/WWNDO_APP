import 'package:flutter/material.dart';

import '../../data/models/wallet_role.dart';
import '../../data/profile_demo_store.dart';
import 'app_avatar.dart';
import 'captured_image_preview.dart';

class ProfileAvatar extends StatelessWidget {
  const ProfileAvatar({
    super.key,
    required this.initial,
    required this.role,
    this.size = AvatarSize.large,
  });

  final String initial;
  final WalletRole role;
  final AvatarSize size;

  double get _dimension => switch (size) {
        AvatarSize.small => 30,
        AvatarSize.medium => 42,
        AvatarSize.large => 64,
      };

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<int>(
      valueListenable: ProfileDemoStore.version,
      builder: (context, _, __) {
        final path = ProfileDemoStore.photoPathFor(role);
        if (path != null && path.isNotEmpty) {
          return CapturedImagePreview(
            path: path,
            width: _dimension,
            height: _dimension,
            clipOval: true,
          );
        }
        return AppAvatar(initial: initial, size: size);
      },
    );
  }
}
