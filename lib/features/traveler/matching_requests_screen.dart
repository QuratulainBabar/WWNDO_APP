import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../core/layout/responsive.dart';
import '../../core/platform/platform_ui.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_typography.dart';
import '../../core/widgets/app_avatar.dart';
import '../../core/widgets/app_button.dart';
import '../../core/widgets/app_card.dart';
import '../../core/widgets/back_header.dart';
import '../../data/models/matching_request.dart';
import '../../data/static_data.dart';

class MatchingRequestsScreen extends StatelessWidget {
  const MatchingRequestsScreen({super.key, required this.tripId});

  final String tripId;

  @override
  Widget build(BuildContext context) {
    final typo = context.typo;
    final horizontal = context.horizontalPadding;
    final matchingRequests = StaticData.matchingRequestsForTrip(tripId);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: const BackHeader(title: 'Sender Requests'),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: EdgeInsets.fromLTRB(horizontal, 4, horizontal, 12),
            child: Text(
              'These senders want to deliver parcels on your route. Tap any request to view full details.',
              style: typo.sm.copyWith(height: 1.45),
            ),
          ),
          Expanded(
            child: ValueListenableBuilder<int>(
              valueListenable: StaticData.travelerBidsVersion,
              builder: (context, _, _) {
                if (matchingRequests.isEmpty) {
                  return Center(
                    child: Padding(
                      padding: EdgeInsets.symmetric(horizontal: horizontal),
                      child: Text(
                        'No sender requests for this trip yet.',
                        style: typo.sm,
                        textAlign: TextAlign.center,
                      ),
                    ),
                  );
                }

                return ListView.builder(
                  physics: PlatformUi.scrollPhysics,
                  padding: EdgeInsets.fromLTRB(horizontal, 0, horizontal, 24),
                  itemCount: matchingRequests.length,
                  itemBuilder: (context, i) {
                    final matchingRequest = matchingRequests[i];
                    return _SenderRequestCard(
                      matchingRequest: matchingRequest,
                      onViewDetails: () => context.push(
                        '/request/${matchingRequest.request.id}',
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _SenderRequestCard extends StatelessWidget {
  const _SenderRequestCard({
    required this.matchingRequest,
    required this.onViewDetails,
  });

  final MatchingRequest matchingRequest;
  final VoidCallback onViewDetails;

  @override
  Widget build(BuildContext context) {
    final typo = context.typo;
    final request = matchingRequest.request;

    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              AppAvatar(initial: request.senderInitial, size: AvatarSize.small),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      request.senderName,
                      style: typo.body.copyWith(fontWeight: FontWeight.w700),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '★ ${request.senderRating} · ${DateFormat('MMM d, yyyy').format(request.travelDate)}',
                      style: typo.sm.copyWith(color: AppColors.textSecondary),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          // Route text only — no leading icons (per design).
          Text(
            request.route,
            style: typo.h3.copyWith(fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 8),
          Text(
            '\$${request.maxBudget.toStringAsFixed(0)} USD',
            style: typo.priceSmall.copyWith(fontSize: 18),
          ),
          const SizedBox(height: 14),
          AppButton(label: 'View Details', small: true, onPressed: onViewDetails),
        ],
      ),
    );
  }
}
