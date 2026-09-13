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
import '../../core/widgets/stacked_route_endpoints.dart';
import '../../data/models/bid.dart';
import '../../data/static_data.dart';

class BidAcceptedScreen extends StatelessWidget {
  const BidAcceptedScreen({
    super.key,
    required this.bid,
    this.accepted = true,
  });

  final Bid bid;
  final bool accepted;

  @override
  Widget build(BuildContext context) {
    final typo = context.typo;
    final travelDate = DateFormat('MMM d, yyyy').format(bid.travelDate);
    final route = StaticData.activeShipment.route;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: const BackHeader(title: 'Accepted Bid Details'),
      body: SafeArea(
        child: SingleChildScrollView(
          physics: PlatformUi.scrollPhysics,
          padding: context.pagePadding,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              AppBadge.success('Bid accepted'),
              const SizedBox(height: 8),
              AppBadge.success('Escrow funded · Selection locked'),
              const SizedBox(height: 16),
              AppCard(
                margin: EdgeInsets.zero,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        AppAvatar(initial: bid.initial, size: AvatarSize.large),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                bid.travelerName,
                                style: typo.h3.copyWith(fontWeight: FontWeight.w700),
                              ),
                              const SizedBox(height: 4),
                              Text('⭐ ${bid.rating}', style: typo.sm),
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
                      'Bid details',
                      style: typo.h3.copyWith(fontWeight: FontWeight.w700),
                    ),
                    const SizedBox(height: 12),
                    StackedRouteEndpoints.split(
                      route,
                      sectionLabel: 'Route',
                      bottomPadding: 8,
                    ),
                    _detailRow(context, 'Travel date', travelDate),
                    _detailRow(
                      context,
                      'Accepted bid amount',
                      '\$${bid.price.toInt()}',
                      valueStyle: typo.priceSmall.copyWith(fontSize: 16),
                    ),
                    if (bid.message != null) ...[
                      const SizedBox(height: 8),
                      Text('Traveler message', style: typo.sm),
                      const SizedBox(height: 8),
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: AppColors.primary.withValues(alpha: 0.06),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text('"${bid.message}"', style: typo.italicQuote),
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(height: 24),
              AppButton(
                label: 'Chat with Traveler',
                onPressed: accepted
                    ? () => context.go('/sender-chats')
                    : null,
              ),
              const SizedBox(height: AppButton.stackGap),
              AppButton(
                label: 'Back to Home',
                variant: AppButtonVariant.outline,
                onPressed: () => context.go('/home'),
              ),
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
