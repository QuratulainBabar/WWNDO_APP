import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/widgets/app_badge.dart';
import '../../../core/widgets/app_card.dart';
import '../../../core/widgets/profile_avatar.dart';
import '../../../core/widgets/star_rating_display.dart';
import '../../../data/models/auth_user.dart';
import '../../../data/models/wallet_role.dart';
import '../../../l10n/app_localizations.dart';

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

  /// Backend sends English short months (`Aug 2026`); reformat for the UI locale.
  static String _localizedMemberSince(String raw, String languageCode) {
    final trimmed = raw.trim();
    if (trimmed.isEmpty) return trimmed;
    try {
      final parsed = DateFormat('MMM yyyy', 'en_US').parseStrict(trimmed);
      return DateFormat('MMM yyyy', languageCode).format(parsed);
    } catch (_) {
      return trimmed;
    }
  }

  @override
  Widget build(BuildContext context) {
    final typo = context.typo;
    final l10n = context.l10n;
    final profile = authUser?.toUserProfile();
    final displayName = profile?.name.isNotEmpty == true ? profile!.name : name;
    final displayInitial =
        profile != null && profile.initial.isNotEmpty ? profile.initial : initial;
    final rawMemberSince = profile?.memberSince.isNotEmpty == true
        ? profile!.memberSince
        : memberSince;
    final displayMemberSince =
        _localizedMemberSince(rawMemberSince, l10n.locale.languageCode);
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
                      AppBadge.verified(label: '✓ ${l10n.kycApproved}')
                    else
                      AppBadge(
                        label: l10n.unverifiedBadge,
                        color: AppColors.warning,
                        backgroundColor: const Color(0x1AF59E0B),
                        small: true,
                      ),
                  ],
                ),
                Text(
                  '$subtitle · ${l10n.memberSinceLabel(displayMemberSince)}',
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
