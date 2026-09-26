import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/config/api_config.dart';
import '../../data/models/wallet_role.dart';
import '../../data/profile_demo_store.dart';
import '../../providers/auth_provider.dart';
import 'app_avatar.dart';
import 'captured_image_preview.dart';

class ProfileAvatar extends StatelessWidget {
  const ProfileAvatar({
    super.key,
    required this.initial,
    required this.role,
    this.size = AvatarSize.large,
    this.avatarUrl,
  });

  final String initial;
  final WalletRole role;
  final AvatarSize size;
  final String? avatarUrl;

  double get _dimension => switch (size) {
        AvatarSize.small => 30,
        AvatarSize.medium => 42,
        AvatarSize.large => 64,
      };

  @override
  Widget build(BuildContext context) {
    final authAvatarUrl = avatarUrl ??
        context.select<AuthProvider, String?>((a) => a.user?.avatarUrl);

    return ValueListenableBuilder<int>(
      valueListenable: ProfileDemoStore.version,
      builder: (context, _, __) {
        final bytes = ProfileDemoStore.photoBytesFor(role);
        if (bytes != null && bytes.isNotEmpty) {
          return ClipOval(
            child: Image.memory(
              bytes,
              width: _dimension,
              height: _dimension,
              fit: BoxFit.cover,
              gaplessPlayback: true,
            ),
          );
        }
        final path = ProfileDemoStore.photoPathFor(role);
        if (path != null && path.isNotEmpty) {
          return CapturedImagePreview(
            path: path,
            width: _dimension,
            height: _dimension,
            clipOval: true,
          );
        }

        final url = (authAvatarUrl ?? '').trim();
        if (url.isNotEmpty) {
          return ClipOval(
            child: Image.network(
              ApiConfig.resolveUploadUrl(url),
              width: _dimension,
              height: _dimension,
              fit: BoxFit.cover,
              gaplessPlayback: true,
              errorBuilder: (_, __, ___) =>
                  AppAvatar(initial: initial, size: size),
            ),
          );
        }

        return AppAvatar(initial: initial, size: size);
      },
    );
  }
}
