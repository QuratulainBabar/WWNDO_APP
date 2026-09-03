import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/api/api_exception.dart';
import '../../../core/config/demo_mode.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/widgets/app_avatar.dart';
import '../../../core/widgets/app_card.dart';
import '../../../data/models/review.dart';
import '../../../data/models/wallet_role.dart';
import '../../../data/services/review_repository.dart';
import '../../../providers/auth_provider.dart';

class RecentReviewsSection extends StatefulWidget {
  const RecentReviewsSection({
    super.key,
    required this.role,
    this.limit = 10,
  });

  final WalletRole role;
  final int limit;

  @override
  State<RecentReviewsSection> createState() => _RecentReviewsSectionState();
}

class _RecentReviewsSectionState extends State<RecentReviewsSection> {
  List<Review> _reviews = const [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _load());
  }

  ReviewRepository _repository() {
    final auth = context.read<AuthProvider>();
    final demoMode = context.read<DemoModeProvider>();
    return ReviewRepository(
      apiClient: auth.repository.apiClient,
      demoMode: demoMode,
    );
  }

  Future<void> _load({bool silent = false}) async {
    if (!silent && mounted) setState(() => _loading = true);
    try {
      final reviews = await _repository().listMyReviews(
        widget.role,
        limit: widget.limit,
      );
      if (!mounted) return;
      setState(() {
        _reviews = reviews;
        _loading = false;
      });
    } on ApiException {
      if (!mounted) return;
      setState(() {
        if (!silent) _reviews = const [];
        _loading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        if (!silent) _reviews = const [];
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final typo = context.typo;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Recent reviews', style: typo.h3.copyWith(fontWeight: FontWeight.w700)),
        const SizedBox(height: 10),
        if (_loading && _reviews.isEmpty)
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 12),
            child: Center(
              child: SizedBox(
                width: 24,
                height: 24,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
            ),
          )
        else if (_reviews.isEmpty)
          SizedBox(
            width: double.infinity,
            child: AppCard(
              child: Text(
                'No reviews yet.',
                style: typo.sm.copyWith(color: AppColors.textSecondary),
              ),
            ),
          )
        else
          ..._reviews.map(
            (r) => AppCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      AppAvatar(initial: r.initial, size: AvatarSize.small),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          r.reviewerName,
                          style: typo.sm.copyWith(fontWeight: FontWeight.w700),
                        ),
                      ),
                      Text(
                        '${'★' * r.rating}${'☆' * (5 - r.rating)}',
                        style: typo.starRating,
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Text('"${r.text}"', style: typo.reviewText),
                  const SizedBox(height: 4),
                  Text(r.date, style: typo.sm),
                ],
              ),
            ),
          ),
      ],
    );
  }
}
