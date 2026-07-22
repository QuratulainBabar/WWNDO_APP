import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../core/layout/responsive.dart';
import '../../core/platform/platform_ui.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_typography.dart';
import '../../core/widgets/app_avatar.dart';
import '../../core/widgets/app_badge.dart';
import '../../core/widgets/app_card.dart';
import '../../core/widgets/back_header.dart';
import '../../data/models/traveler_bid.dart';
import '../../data/static_data.dart';

class TravelerMyBidsScreen extends StatelessWidget {
  const TravelerMyBidsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final typo = context.typo;
    final bids = StaticData.travelerBids;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: const BackHeader(title: 'Counter Offers Sent'),
      body: ListView.builder(
        physics: PlatformUi.scrollPhysics,
        padding: context.pagePadding,
        itemCount: bids.length + 1,
        itemBuilder: (context, i) {
          if (i == 0) {
            return Padding(
              padding: const EdgeInsets.only(bottom: 16),
              child: Text(
                'These are the counter offers you have sent to senders.',
                style: typo.sm.copyWith(color: AppColors.textSecondary, height: 1.4),
              ),
            );
          }
          final bid = bids[i - 1];
          return _CounterOfferCard(
            bid: bid,
            onTap: () => context.push('/traveler-bid-detail', extra: bid),
          );
        },
      ),
    );
  }
}

class _CounterOfferCard extends StatelessWidget {
  const _CounterOfferCard({
    required this.bid,
    required this.onTap,
  });

  final TravelerBid bid;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final typo = context.typo;
    final sentOn = DateFormat('MMM d, yyyy').format(bid.offerSentAt);

    return AppCard(
      onTap: onTap,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              AppAvatar(initial: bid.senderInitial, size: AvatarSize.small),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      bid.senderName,
                      style: typo.bodyBold.copyWith(fontWeight: FontWeight.w700),
                    ),
                    const SizedBox(height: 2),
                    Text(bid.route, style: typo.sm),
                  ],
                ),
              ),
              _StatusBadge(status: bid.status),
            ],
          ),
          const SizedBox(height: 14),
          _DetailRow(
            label: 'Offer amount',
            value: '\$${bid.amount.toInt()}',
            valueStyle: typo.bodyBold.copyWith(
              fontWeight: FontWeight.w800,
              color: AppColors.transit,
            ),
          ),
          const SizedBox(height: 8),
          _DetailRow(
            label: 'Sent on',
            value: sentOn,
            valueStyle: typo.sm.copyWith(color: AppColors.textPrimary),
          ),
        ],
      ),
    );
  }
}

class _DetailRow extends StatelessWidget {
  const _DetailRow({
    required this.label,
    required this.value,
    required this.valueStyle,
  });

  final String label;
  final String value;
  final TextStyle valueStyle;

  @override
  Widget build(BuildContext context) {
    final typo = context.typo;
    return Row(
      children: [
        Expanded(
          child: Text(
            label,
            style: typo.sm.copyWith(color: AppColors.textSecondary),
          ),
        ),
        Text(value, style: valueStyle),
      ],
    );
  }
}

class _StatusBadge extends StatelessWidget {
  const _StatusBadge({required this.status});

  final TravelerBidStatus status;

  @override
  Widget build(BuildContext context) {
    return AppBadge(
      label: status.label,
      color: status.color,
      backgroundColor: status.color.withValues(alpha: 0.12),
      small: true,
      semiBold: true,
    );
  }
}
