import 'package:flutter/material.dart';

import '../../../core/config/api_config.dart';
import '../../../core/platform/local_image.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../../data/models/chat_message.dart';
import '../../../l10n/app_localizations.dart';

class ChatImageAttachment extends StatelessWidget {
  const ChatImageAttachment({super.key, required this.message});

  final ChatMessage message;

  @override
  Widget build(BuildContext context) {
    final typo = context.typo;
    final path = message.imagePath;
    final hasLocalImage = path != null && localImageExists(path);
    final remoteUrl = message.remoteImageUrl;

    if (hasLocalImage) {
      return buildLocalImage(
        path,
        width: 160,
        height: 110,
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) =>
            _networkOrPlaceholder(context, typo, remoteUrl),
      );
    }

    return _networkOrPlaceholder(context, typo, remoteUrl);
  }

  Widget _networkOrPlaceholder(
    BuildContext context,
    AppTypography typo,
    String? remoteUrl,
  ) {
    if (remoteUrl == null || remoteUrl.isEmpty) {
      return _placeholder(context, typo);
    }
    return Image.network(
      ApiConfig.resolveUploadUrl(remoteUrl),
      width: 160,
      height: 110,
      fit: BoxFit.cover,
      loadingBuilder: (context, child, progress) {
        if (progress == null) return child;
        return SizedBox(
          width: 160,
          height: 110,
          child: Center(
            child: SizedBox(
              width: 22,
              height: 22,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: AppColors.primary,
                value: progress.expectedTotalBytes != null
                    ? progress.cumulativeBytesLoaded /
                        progress.expectedTotalBytes!
                    : null,
              ),
            ),
          ),
        );
      },
      errorBuilder: (context, error, stackTrace) =>
          _placeholder(context, typo),
    );
  }

  Widget _placeholder(BuildContext context, AppTypography typo) {
    return Container(
      width: 160,
      height: 110,
      color: AppColors.primary,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text('📷', style: typo.actionIcon.copyWith(fontSize: 28)),
          Text(
            context.l10n.photo,
            style: typo.badgeSm.copyWith(color: Colors.white.withValues(alpha: 0.8)),
          ),
        ],
      ),
    );
  }
}
