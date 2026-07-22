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
import '../../core/widgets/app_chip.dart';
import '../../core/widgets/back_header.dart';
import 'bid_acceptance_payment_screen.dart';
import 'bid_sort.dart';
import '../../data/models/bid.dart';
import '../../data/models/shipment.dart';
import '../../data/static_data.dart';

class BidRequestsScreen extends StatefulWidget {
  const BidRequestsScreen({super.key, required this.shipmentId});

  final String shipmentId;

  @override
  State<BidRequestsScreen> createState() => _BidRequestsScreenState();
}

class _BidRequestsScreenState extends State<BidRequestsScreen> {
  BidSortOption _sort = BidSortOption.bestMatchScore;

  @override
  void initState() {
    super.initState();
    StaticData.bidRequestsVersion.addListener(_onBidsChanged);
  }

  @override
  void dispose() {
    StaticData.bidRequestsVersion.removeListener(_onBidsChanged);
    super.dispose();
  }

  void _onBidsChanged() {
    if (mounted) setState(() {});
  }

  void _selectTraveler(Bid bid) {
    StaticData.selectMatchingTraveler(
      shipmentId: widget.shipmentId,
      bid: bid,
    );
    context.push(
      '/traveler-selected-confirmation',
      extra: BidAcceptanceContext(
        bid: bid,
        shipmentId: widget.shipmentId,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final shipment = StaticData.shipmentById(widget.shipmentId)!;
    final bids = BidSortOption.sorted(
      StaticData.openBidRequestsForShipment(widget.shipmentId),
      _sort,
    );

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: const BackHeader(title: 'Matching Travelers'),
      body: ListView.builder(
        physics: PlatformUi.scrollPhysics,
        padding: context.pagePadding,
        itemCount: bids.length + 2,
        itemBuilder: (context, i) {
          if (i == 0) {
            return Padding(
              padding: EdgeInsets.only(bottom: bids.isEmpty ? 0 : 12),
              child: _ParcelSummaryCard(shipment: shipment),
            );
          }

          if (i == 1) {
            return Padding(
              padding: EdgeInsets.only(bottom: bids.isEmpty ? 0 : 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Sort by',
                    style: context.typo.sm.copyWith(
                      fontWeight: FontWeight.w600,
                      color: AppColors.textSecondary,
                    ),
                  ),
                  const SizedBox(height: 6),
                  AppChipRow(
                    options: BidSortOption.labels,
                    selected: _sort.label,
                    onSelected: (label) {
                      setState(() => _sort = BidSortOption.fromLabel(label));
                    },
                  ),
                ],
              ),
            );
          }

          final bid = bids[i - 2];
          final status = StaticData.bidReviewStatus(bid.id);
          return _MatchingTravelerCard(
            bid: bid,
            status: status,
            onViewProfile: () => context.push(
              '/bid-traveler-profile',
              extra: BidAcceptanceContext(
                bid: bid,
                shipmentId: widget.shipmentId,
              ),
            ),
            onSelectTraveler: () => _selectTraveler(bid),
          );
        },
      ),
    );
  }
}

class _ParcelSummaryCard extends StatelessWidget {
  const _ParcelSummaryCard({required this.shipment});

  final Shipment shipment;

  @override
  Widget build(BuildContext context) {
    final typo = context.typo;

    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            shipment.id,
            style: typo.h3.copyWith(
              fontWeight: FontWeight.w700,
              color: AppColors.primary,
            ),
          ),
          const SizedBox(height: 8),
          Text(shipment.route, style: typo.sm),
          const SizedBox(height: 4),
          Text(
            'Travel date: ${DateFormat('MMM d, yyyy').format(shipment.travelDate)}'
            ' · Weight: ${shipment.parcelWeightKg} kg',
            style: typo.sm.copyWith(color: AppColors.textSecondary),
          ),
          const SizedBox(height: 12),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.kycBackground,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(Icons.auto_awesome, size: 18, color: AppColors.primary),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Receiver has accepted the request.',
                        style: typo.sm.copyWith(
                          fontWeight: FontWeight.w700,
                          color: AppColors.primaryDark,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'Here are the best matching travelers for your route.',
                        style: typo.sm.copyWith(color: AppColors.primary),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _MatchingTravelerCard extends StatelessWidget {
  const _MatchingTravelerCard({
    required this.bid,
    required this.status,
    required this.onViewProfile,
    required this.onSelectTraveler,
  });

  final Bid bid;
  final BidReviewStatus status;
  final VoidCallback onViewProfile;
  final VoidCallback onSelectTraveler;

  @override
  Widget build(BuildContext context) {
    final typo = context.typo;
    final travelDate = DateFormat('MMM d, yyyy').format(bid.travelDate);
    final matchColor = bid.routeMatchConfidence >= 90
        ? AppColors.success
        : bid.routeMatchConfidence >= 80
            ? AppColors.primary
            : AppColors.warning;
    final isSelected = status == BidReviewStatus.deliveryRequested ||
        status == BidReviewStatus.accepted ||
        status == BidReviewStatus.approved;
    final isLocked = status == BidReviewStatus.locked;

    return AppCard(
      highlighted: bid.featured,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              GestureDetector(
                onTap: onViewProfile,
                child: AppAvatar(initial: bid.initial),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    GestureDetector(
                      onTap: onViewProfile,
                      child: Text(
                        bid.travelerName,
                        style: typo.bodyBold.copyWith(fontWeight: FontWeight.w700),
                      ),
                    ),
                    Text('⭐ ${bid.rating}', style: typo.sm),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text('\$${bid.price.toInt()}', style: typo.priceLarge),
                  const SizedBox(height: 4),
                  AppBadge(
                    label: bid.routeMatchLabel,
                    color: matchColor,
                    backgroundColor: matchColor.withValues(alpha: 0.12),
                    semiBold: true,
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text('Travel date: $travelDate', style: typo.sm),
          if (isSelected) ...[
            const SizedBox(height: 8),
            Align(
              alignment: Alignment.centerRight,
              child: AppBadge.success(
                status == BidReviewStatus.approved
                    ? 'Request approved'
                    : status == BidReviewStatus.accepted
                        ? 'Selected · Locked'
                        : 'Selected · Awaiting response',
              ),
            ),
          ],
          if (isLocked) ...[
            const SizedBox(height: 8),
            Align(
              alignment: Alignment.centerRight,
              child: AppBadge(
                label: 'Locked',
                color: AppColors.textSecondary,
                backgroundColor: AppColors.border.withValues(alpha: 0.35),
                semiBold: true,
              ),
            ),
          ],
          if (bid.message != null) ...[
            const SizedBox(height: 8),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.06),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text('"${bid.message}"', style: typo.italicQuote),
            ),
          ],
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: AppButton(
                  label: 'View Profile',
                  small: true,
                  variant: AppButtonVariant.outline,
                  onPressed: onViewProfile,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: AppButton(
                  label: isSelected
                      ? 'Selected'
                      : isLocked
                          ? 'Unavailable'
                          : 'Send Request',
                  small: true,
                  onPressed: isSelected || isLocked ? null : onSelectTraveler,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
