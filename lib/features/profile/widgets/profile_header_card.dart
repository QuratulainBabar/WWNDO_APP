import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/widgets/app_badge.dart';
import '../../../core/widgets/app_card.dart';
import '../../../core/widgets/profile_avatar.dart';
import '../../../core/widgets/star_rating_display.dart';
import '../../../data/models/auth_user.dart';
import '../../../data/models/wallet_role.dart';

class ProfileHeaderCard extends StatelessWidget {
  const ProfileHeaderCard({
    super.key,
    required this.role,
    required this.name,
    required this.initial,
    required this.subtitle,
    required this.memberSince,
    required this.bio,
    required this.rating,
    this.authUser,
  });

  final WalletRole role;
  final String name;
  final String initial;
  final String subtitle;
  final String memberSince;
  final String bio;
  final double rating;
  final AuthUser? authUser;

  @override
  Widget build(BuildContext context) {
    final typo = context.typo;
    final profile = authUser?.toUserProfile();
    final displayName = profile?.name.isNotEmpty == true ? profile!.name : name;
    final displayInitial =
        profile != null && profile.initial.isNotEmpty ? profile.initial : initial;
    final displayMemberSince = profile?.memberSince.isNotEmpty == true
        ? profile!.memberSince
        : memberSince;
    final displayBio = () {
      final fromAuth = profile?.bio.trim() ?? '';
      if (fromAuth.isNotEmpty) return fromAuth;
      return bio.trim();
    }();
    final displayRating = profile?.rating ?? rating;
    final crossVerified = authUser?.isFullyCrossVerified ?? false;

    return AppCard(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ProfileAvatar(
            initial: displayInitial,
            role: role,
            avatarUrl: authUser?.avatarUrl,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Wrap(
                  spacing: 8,
                  runSpacing: 6,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    Text(displayName, style: typo.h2),
                    if (crossVerified)
                      AppBadge.verified(label: '✓ Verified')
                    else
                      const AppBadge(
                        label: 'Unverified',
                        color: AppColors.warning,
                        backgroundColor: Color(0x1AF59E0B),
                        small: true,
                      ),
                  ],
                ),
                Text(
                  '$subtitle · Member since $displayMemberSince',
                  style: typo.sm,
                ),
                const SizedBox(height: 6),
                StarRatingDisplay(rating: displayRating),
                if (displayBio.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Text(displayBio, style: typo.link),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}
