import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../theme/app_typography.dart';

enum AvatarSize { small, medium, large }

class AppAvatar extends StatelessWidget {
  const AppAvatar({
    super.key,
    required this.initial,
    this.size = AvatarSize.medium,
  });

  final String initial;
  final AvatarSize size;

  double get _dimension => switch (size) {
        AvatarSize.small => 30,
        AvatarSize.medium => 42,
        AvatarSize.large => 64,
      };

  TextStyle _textStyle(AppTypography typo) => switch (size) {
        AvatarSize.small => typo.avatarSm,
        AvatarSize.medium => typo.avatarMd,
        AvatarSize.large => typo.avatarLg,
      };

  @override
  Widget build(BuildContext context) {
    final typo = context.typo;
    final color = AppColors.primary.withValues(alpha: 0.12);

    return Container(
      width: _dimension,
      height: _dimension,
      decoration: BoxDecoration(
        color: color,
        shape: BoxShape.circle,
      ),
      alignment: Alignment.center,
      child: Text(
        initial.toUpperCase(),
        style: _textStyle(typo),
      ),
    );
  }
}
