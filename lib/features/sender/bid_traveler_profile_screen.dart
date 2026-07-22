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
import '../../data/models/bid.dart';
import '../../data/static_data.dart';
import 'bid_acceptance_payment_screen.dart';

/// Public traveler profile opened from Matching Travelers.
class BidTravelerProfileScreen extends StatelessWidget {
  const BidTravelerProfileScreen({
    super.key,
    required this.bid,
    this.shipmentId,
  });

  final Bid bid;
  final String? shipmentId;

  void _selectTraveler(BuildContext context) {
    final id = shipmentId;
    if (id == null) return;
    StaticData.selectMatchingTraveler(shipmentId: id, bid: bid);
    context.push(
      '/traveler-selected-confirmation',
      extra: BidAcceptanceContext(bid: bid, shipmentId: id),
    );
  }

  @override
  Widget build(BuildContext context) {
    final typo = context.typo;
    final travelDate = DateFormat('MMM d, yyyy').format(bid.travelDate);
    final matchColor = bid.routeMatchConfidence >= 90
        ? AppColors.success
        : bid.routeMatchConfidence >= 80
            ? AppColors.primary
            : AppColors.warning;
    final shipment =
        shipmentId == null ? null : StaticData.shipmentById(shipmentId!);
    final reviewStatus = StaticData.bidReviewStatus(bid.id);
    final isSelected = reviewStatus == BidReviewStatus.deliveryRequested ||
        reviewStatus == BidReviewStatus.accepted ||
        reviewStatus == BidReviewStatus.approved;
    final isLocked = reviewStatus == BidReviewStatus.locked;
    final canSelect = shipmentId != null && !isSelected && !isLocked;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: const BackHeader(title: 'Traveler Profile'),
      body: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              physics: PlatformUi.scrollPhysics,
              padding: context.pagePadding,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  AppCard(
                    margin: EdgeInsets.zero,
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        AppAvatar(initial: bid.initial, size: AvatarSize.large),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                bid.travelerName,
                                style: typo.h2.copyWith(fontWeight: FontWeight.w700),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                '⭐ ${bid.rating} · ${bid.reviewCount} reviews',
                                style: typo.sm,
                              ),
                              const SizedBox(height: 8),
                              AppBadge.verified(label: 'Verified'),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),
                  AppCard(
                    margin: EdgeInsets.zero,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'About',
                          style: typo.h3.copyWith(fontWeight: FontWeight.w700),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          bid.bio ??
                              'Verified traveler available for this route.',
                          style: typo.body,
                        ),
                        const SizedBox(height: 16),
                        _row(
                          context,
                          'Completed deliveries',
                          '${bid.completedDeliveries}',
                        ),
                        _row(context, 'Travel date', travelDate),
                        if (bid.flightNumber != null)
                          _row(context, 'Flight', bid.flightNumber!),
                        const SizedBox(height: 8),
                        AppBadge(
                          label: bid.routeMatchLabel,
                          color: matchColor,
                          backgroundColor: matchColor.withValues(alpha: 0.12),
                          semiBold: true,
                        ),
                      ],
                    ),
                  ),
                  if (shipment != null) ...[
                    const SizedBox(height: 12),
                    AppCard(
                      margin: EdgeInsets.zero,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Route Details',
                            style: typo.h3.copyWith(fontWeight: FontWeight.w700),
                          ),
                          const SizedBox(height: 12),
                          _row(
                            context,
                            'From',
                            '${shipment.fromCity} (${shipment.fromCode})',
                          ),
                          _row(
                            context,
                            'To',
                            '${shipment.toCity} (${shipment.toCode})',
                          ),
                          _row(context, 'Departure', travelDate),
                        ],
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
          if (shipmentId != null)
            SafeArea(
              top: false,
              child: Padding(
                padding: EdgeInsets.fromLTRB(
                  context.horizontalPadding,
                  8,
                  context.horizontalPadding,
                  16,
                ),
                child: AppButton(
                  label: isSelected
                      ? 'Selected'
                      : isLocked
                          ? 'Unavailable'
                          : 'Send Request',
                  onPressed: canSelect ? () => _selectTraveler(context) : null,
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _row(BuildContext context, String label, String value) {
    final typo = context.typo;
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: typo.sm.copyWith(color: AppColors.textSecondary)),
          Flexible(
            child: Text(
              value,
              textAlign: TextAlign.right,
              style: typo.sm.copyWith(fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }
}
