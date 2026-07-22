import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../core/layout/responsive.dart';
import '../../core/platform/platform_ui.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_typography.dart';
import '../../core/widgets/app_avatar.dart';
import '../../core/widgets/app_badge.dart';
import '../../core/widgets/app_button.dart';
import '../../core/widgets/app_card.dart';
import '../../core/widgets/back_header.dart';
import '../../data/models/traveler_bid.dart';
import '../../data/static_data.dart';

class TravelerBidDetailScreen extends StatelessWidget {
  const TravelerBidDetailScreen({super.key, required this.bid});

  final TravelerBid bid;

  @override
  Widget build(BuildContext context) {
    final typo = context.typo;
    final deliveryDate = DateFormat('MMM d, yyyy').format(bid.deliveryDate);
    final proposedMeetup = StaticData.thread1ProposedMeetupLocation;
    final travelerAccepted = StaticData.travelerLocationAgreementAccepted;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: const BackHeader(title: 'Bid Details'),
      body: SafeArea(
        child: SingleChildScrollView(
          physics: PlatformUi.scrollPhysics,
          padding: context.pagePadding,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _StatusBadge(status: bid.status),
              const SizedBox(height: 16),
              AppCard(
                margin: EdgeInsets.zero,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        AppAvatar(initial: bid.senderInitial, size: AvatarSize.large),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                bid.senderName,
                                style: typo.h3.copyWith(fontWeight: FontWeight.w700),
                              ),
                              const SizedBox(height: 4),
                              Text('Sender', style: typo.sm),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const Padding(
                      padding: EdgeInsets.symmetric(vertical: 20),
                      child: Divider(height: 1),
                    ),
                    Text(
                      'Parcel photo',
                      style: typo.sm,
                    ),
                    const SizedBox(height: 8),
                    _StaticParcelPhoto(count: bid.parcelPhotoCount),
                    const SizedBox(height: 16),
                    Text(
                      'Bid details',
                      style: typo.h3.copyWith(fontWeight: FontWeight.w700),
                    ),
                    const SizedBox(height: 12),
                    _detailRow(context, 'Pickup → Destination', bid.route),
                    _detailRow(context, 'Delivery date', deliveryDate),
                    _detailRow(
                      context,
                      'Accepted bid amount',
                      '\$${bid.amount.toStringAsFixed(2)}',
                      valueStyle: typo.priceSmall.copyWith(fontSize: 16),
                    ),
                    _detailRow(context, 'Bid status', bid.status.label),
                  ],
                ),
              ),
              if (bid.isAccepted) ...[
                const SizedBox(height: 24),
                if (proposedMeetup != null) ...[
                  AppCard(
                    margin: EdgeInsets.zero,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Meetup location agreement',
                          style: typo.h3.copyWith(fontWeight: FontWeight.w700),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Proposed location: $proposedMeetup',
                          style: typo.sm,
                        ),
                        const SizedBox(height: 12),
                        AppButton(
                          label: travelerAccepted
                              ? 'Location accepted'
                              : 'Accept meetup location',
                          onPressed: travelerAccepted
                              ? null
                              : () {
                                  StaticData.acceptThread1LocationAgreement(
                                    bySender: false,
                                  );
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                      content: Text(
                                        'Meetup location accepted. Thread 1 can now unlock.',
                                      ),
                                    ),
                                  );
                                },
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                ],
                AppButton(
                  label: 'Chat with Sender',
                  onPressed: () => context.go('/traveler-chats'),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _detailRow(
    BuildContext context,
    String label,
    String value, {
    TextStyle? valueStyle,
  }) {
    final typo = context.typo;
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: typo.sm),
          const SizedBox(width: 16),
          Flexible(
            child: Text(
              value,
              textAlign: TextAlign.right,
              style: valueStyle ?? typo.bodyBold.copyWith(fontWeight: FontWeight.w700),
            ),
          ),
        ],
      ),
    );
  }
}

class _StatusBadge extends StatelessWidget {
  const _StatusBadge({required this.status});

  final TravelerBidStatus status;

  @override
  Widget build(BuildContext context) {
    if (status == TravelerBidStatus.accepted) {
      return AppBadge.success('Bid accepted');
    }
    return AppBadge(
      label: status.label,
      color: status.color,
      backgroundColor: status.color.withValues(alpha: 0.12),
      small: true,
      semiBold: true,
    );
  }
}

class _StaticParcelPhoto extends StatelessWidget {
  const _StaticParcelPhoto({required this.count});

  final int count;

  @override
  Widget build(BuildContext context) {
    final typo = context.typo;

    return Container(
      width: 120,
      height: 120,
      decoration: BoxDecoration(
        color: AppColors.primary.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border, width: 1.5),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.photo_outlined, size: 32, color: AppColors.primary),
          const SizedBox(height: 6),
          Text(
            count > 1 ? 'Photo 1 of $count' : 'Parcel photo',
            style: typo.sm.copyWith(
              fontSize: 11,
              color: AppColors.textSecondary,
              fontWeight: FontWeight.w600,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}
