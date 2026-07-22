import 'package:flutter/material.dart';

import '../../../core/platform/local_image.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../../data/models/chat_message.dart';

class ChatImageAttachment extends StatelessWidget {
  const ChatImageAttachment({super.key, required this.message});

  final ChatMessage message;

  @override
  Widget build(BuildContext context) {
    final typo = context.typo;
    final path = message.imagePath;
    final hasLocalImage = path != null && localImageExists(path);

    if (hasLocalImage) {
      return Stack(
        alignment: Alignment.bottomCenter,
        children: [
          buildLocalImage(
            path,
            width: 160,
            height: 110,
            fit: BoxFit.cover,
            errorBuilder: (context, error, stackTrace) => _placeholder(message, typo),
          ),
          Container(
            width: 160,
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            color: Colors.black.withValues(alpha: 0.45),
            child: Text(
              message.imageName ?? 'image.jpg',
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: typo.badgeSm.copyWith(color: Colors.white.withValues(alpha: 0.9)),
            ),
          ),
        ],
      );
    }

    return _placeholder(message, typo);
  }

  Widget _placeholder(ChatMessage message, AppTypography typo) {
    return Container(
      width: 160,
      height: 110,
      color: AppColors.primary,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text('📦', style: typo.actionIcon.copyWith(fontSize: 28)),
          Text(
            message.imageName ?? 'parcel_photo.jpg',
            style: typo.badgeSm.copyWith(color: Colors.white.withValues(alpha: 0.8)),
          ),
        ],
      ),
    );
  }
}
