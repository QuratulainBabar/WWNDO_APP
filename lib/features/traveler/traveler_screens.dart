import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_typography.dart';
import '../../core/widgets/app_avatar.dart';
import '../../core/widgets/app_badge.dart';
import '../../core/widgets/app_button.dart';
import '../../core/widgets/app_card.dart';
import '../../core/widgets/app_chip.dart';
import '../../core/layout/responsive.dart';
import '../../core/platform/platform_ui.dart';
import '../../core/widgets/back_header.dart';
import '../../core/widgets/back_link.dart';
import '../../core/widgets/stacked_route_endpoints.dart';
import '../../data/models/delivery_request.dart';
import '../../data/static_data.dart';

class BrowseRequestsScreen extends StatefulWidget {
  const BrowseRequestsScreen({super.key});

  @override
  State<BrowseRequestsScreen> createState() => _BrowseRequestsScreenState();
}

class _BrowseRequestsScreenState extends State<BrowseRequestsScreen> {
  String _filter = 'All';

  List<DeliveryRequest> get _filtered {
    if (_filter == 'All') return StaticData.deliveryRequests;
    return StaticData.deliveryRequests
        .where((r) => r.categoryTypeLabel == _filter)
        .toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: const BackHeader(title: 'Requests'),
      body: Column(
        children: [
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            physics: PlatformUi.scrollPhysics,
            padding: EdgeInsets.symmetric(horizontal: context.horizontalPadding, vertical: 10),
            child: Row(
              children: StaticData.requestFilters
                  .map(
                    (f) => AppChip(
                      label: f,
                      selected: f == _filter,
                      onTap: () => setState(() => _filter = f),
                    ),
                  )
                  .toList(),
            ),
          ),
          Expanded(
            child: ListView.builder(
              physics: PlatformUi.scrollPhysics,
              padding: EdgeInsets.symmetric(horizontal: context.horizontalPadding),
              itemCount: _filtered.length,
              itemBuilder: (context, i) => _RequestCard(
                request: _filtered[i],
                onViewDetails: () => context.push('/request/${_filtered[i].id}'),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _RequestCard extends StatelessWidget {
  const _RequestCard({required this.request, required this.onViewDetails});

  final DeliveryRequest request;
  final VoidCallback onViewDetails;

  @override
  Widget build(BuildContext context) {
    final typo = context.typo;
    return AppCard(
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onViewDetails,
          borderRadius: BorderRadius.circular(16),
          hoverColor: Colors.transparent,
          splashColor: Colors.transparent,
          highlightColor: Colors.transparent,
          splashFactory: NoSplash.splashFactory,
          overlayColor: const WidgetStatePropertyAll(Colors.transparent),
          child: Padding(
            padding: EdgeInsets.zero,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          StackedRouteEndpoints(
                            from: request.fromCity,
                            to: request.toCity,
                            fallbackRoute: request.route,
                            emphasized: true,
                          ),
                          Text(
                            DateFormat('MMM d, yyyy').format(request.travelDate),
                            style: typo.sm,
                          ),
                        ],
                      ),
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text('max budget', style: typo.sm),
                        Text(
                          '\$${request.maxBudget.toInt()}',
                          style: typo.priceSmall,
                        ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 6,
                  children: [
                    AppBadge(
                      label: request.categoryTypeLabel,
                      color: AppColors.primary,
                      backgroundColor: AppColors.primary.withValues(alpha: 0.12),
                    ),
                    AppBadge(
                      label: '${request.weightKg} kg',
                      color: AppColors.primary,
                      backgroundColor: AppColors.primary.withValues(alpha: 0.12),
                    ),
                    AppBadge(
                      label: request.size,
                      color: AppColors.primary,
                      backgroundColor: AppColors.primary.withValues(alpha: 0.12),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    AppAvatar(initial: request.senderInitial, size: AvatarSize.small),
                    const SizedBox(width: 8),
                    Text(
                      request.senderName,
                      style: typo.sm.copyWith(fontWeight: FontWeight.w700),
                    ),
                    const SizedBox(width: 8),
                    Text('★ ${request.senderRating}', style: typo.sm),
                  ],
                ),
                const SizedBox(height: 10),
                Text(
                  'Message from sender',
                  style: typo.sm.copyWith(fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 4),
                Text(
                  request.displaySenderMessage,
                  style: typo.sm.copyWith(height: 1.4),
                ),
                const SizedBox(height: 10),
                AppButton(
                  label: 'View details',
                  small: true,
                  onPressed: onViewDetails,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class PostTripSuccessScreen extends StatelessWidget {
  const PostTripSuccessScreen({super.key, required this.route});

  final String route;

  @override
  Widget build(BuildContext context) {
    final typo = context.typo;

    return Scaffold(
      backgroundColor: AppColors.surface,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const BackLink(fallbackRoute: '/traveler-home'),
              Expanded(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      width: 80,
                      height: 80,
                      decoration: BoxDecoration(
                        color: AppColors.success.withValues(alpha: 0.12),
                        shape: BoxShape.circle,
                      ),
                      alignment: Alignment.center,
                      child: const Icon(Icons.check, size: 40, color: AppColors.success),
                    ),
                    const SizedBox(height: 20),
                    Text('Trip posted!', style: typo.h1, textAlign: TextAlign.center),
                    const SizedBox(height: 8),
                    Text(
                      'Your $route trip is now discoverable to senders and matched by route similarity.',
                      textAlign: TextAlign.center,
                      style: typo.sm.copyWith(height: 1.5),
                    ),
                    const SizedBox(height: 32),
                    AppButton(
                      label: 'View sender requests',
                      onPressed: () => context.go('/matching-requests'),
                    ),
                    const SizedBox(height: AppButton.stackGap),
                    AppButton(
                      label: 'Back to home',
                      variant: AppButtonVariant.outline,
                      onPressed: () => context.go('/traveler-home'),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
