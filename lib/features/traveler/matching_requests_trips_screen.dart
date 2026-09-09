import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../core/config/demo_mode.dart';
import '../../core/layout/responsive.dart';
import '../../core/platform/platform_ui.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_typography.dart';
import '../../core/widgets/app_avatar.dart';
import '../../core/widgets/app_button.dart';
import '../../core/widgets/app_card.dart';
import '../../core/widgets/back_header.dart';
import '../../core/widgets/stacked_route_endpoints.dart';
import '../../data/models/sender_trip_request.dart';
import '../../data/services/trip_repository.dart';
import '../../providers/auth_provider.dart';
import '../../providers/notification_realtime_provider.dart';

/// Traveler Sender Requests — one card per request (no intermediate trip list).
class MatchingRequestsTripsScreen extends StatefulWidget {
  const MatchingRequestsTripsScreen({super.key});

  @override
  State<MatchingRequestsTripsScreen> createState() =>
      _MatchingRequestsTripsScreenState();
}

class _MatchingRequestsTripsScreenState
    extends State<MatchingRequestsTripsScreen> {
  bool _loading = true;
  String? _error;
  List<SenderTripRequest> _requests = const [];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _load());
  }

  TripRepository _repo() {
    final auth = context.read<AuthProvider>();
    final demoMode = context.read<DemoModeProvider>();
    return TripRepository(
      apiClient: auth.repository.apiClient,
      demoMode: demoMode,
    );
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final requests = await _repo().listSenderRequests();
      if (!mounted) return;
      setState(() {
        _requests = requests;
        _loading = false;
      });
      await _markOpenedRequestsRead();
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _error = 'Unable to load sender requests.';
      });
    }
  }

  Future<void> _markOpenedRequestsRead() async {
    final unread = _requests.where((r) => r.unread).toList();
    if (unread.isEmpty) return;

    final tripIds = unread
        .map((r) => r.tripPublicId.isNotEmpty ? r.tripPublicId : r.tripId)
        .where((id) => id.isNotEmpty)
        .toSet();

    final realtime = context.read<NotificationRealtimeProvider>();
    final optimisticBadge =
        (realtime.senderRequestUnreadCount - unread.length).clamp(0, 999);
    realtime.setSenderRequestUnreadCount(optimisticBadge);
    setState(() {
      _requests = _requests.map((r) => r.unread ? r.markRead() : r).toList();
    });

    var latestUnread = realtime.senderRequestUnreadCount;
    var latestNotifications = realtime.unreadCount;
    for (final tripId in tripIds) {
      try {
        final result = await _repo().markSenderRequestsRead(tripId);
        latestUnread = result.unreadCount;
        latestNotifications = result.notificationsUnread;
      } catch (_) {
        // Keep optimistic read state; traveler already saw the list.
      }
    }
    if (!mounted) return;
    realtime.setSenderRequestUnreadCount(latestUnread);
    realtime.setUnreadCount(latestNotifications);
  }

  Future<void> _openRequest(SenderTripRequest request) async {
    await context.push('/request/${request.id}');
    if (mounted) _load();
  }

  @override
  Widget build(BuildContext context) {
    final typo = context.typo;
    final horizontal = context.horizontalPadding;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: const BackHeader(title: 'Sender Requests'),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: EdgeInsets.fromLTRB(horizontal, 4, horizontal, 12),
            child: Text(
              'Select a trip to view sender requests.',
              style: typo.sm.copyWith(height: 1.45),
            ),
          ),
          Expanded(
            child: _loading
                ? const Center(
                    child: SizedBox(
                      width: 22,
                      height: 22,
                      child: CircularProgressIndicator(
                        strokeWidth: 2.5,
                        color: AppColors.primary,
                      ),
                    ),
                  )
                : _error != null
                    ? Center(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              _error!,
                              style: typo.sm
                                  .copyWith(color: AppColors.textSecondary),
                            ),
                            TextButton(
                              onPressed: _load,
                              child: const Text('Retry'),
                            ),
                          ],
                        ),
                      )
                    : _requests.isEmpty
                        ? Center(
                            child: Padding(
                              padding: EdgeInsets.symmetric(
                                horizontal: horizontal,
                              ),
                              child: Text(
                                'No trips with sender requests yet.',
                                style: typo.sm.copyWith(
                                  color: AppColors.textSecondary,
                                ),
                                textAlign: TextAlign.center,
                              ),
                            ),
                          )
                        : RefreshIndicator(
                            onRefresh: _load,
                            child: ListView.builder(
                              physics: AlwaysScrollableScrollPhysics(
                                parent: PlatformUi.scrollPhysics,
                              ),
                              padding: EdgeInsets.fromLTRB(
                                horizontal,
                                0,
                                horizontal,
                                24,
                              ),
                              itemCount: _requests.length,
                              itemBuilder: (context, i) {
                                final request = _requests[i];
                                final tripKey = _tripKey(request);
                                final requestCount = _requests
                                    .where((r) => _tripKey(r) == tripKey)
                                    .length;
                                return Padding(
                                  padding: const EdgeInsets.only(bottom: 12),
                                  child: _SenderRequestSummaryCard(
                                    request: request,
                                    requestCount: requestCount,
                                    onViewDetails: () => _openRequest(request),
                                  ),
                                );
                              },
                            ),
                          ),
          ),
        ],
      ),
    );
  }

  String _tripKey(SenderTripRequest request) {
    if (request.tripPublicId.isNotEmpty) return request.tripPublicId;
    if (request.tripId.isNotEmpty) return request.tripId;
    return request.id;
  }
}

/// Shared card: sender + amount + date + route, then View Details → full request.
class _SenderRequestSummaryCard extends StatelessWidget {
  const _SenderRequestSummaryCard({
    required this.request,
    required this.requestCount,
    required this.onViewDetails,
  });

  final SenderTripRequest request;
  final int requestCount;
  final VoidCallback onViewDetails;

  @override
  Widget build(BuildContext context) {
    final typo = context.typo;

    return AppCard(
      margin: EdgeInsets.zero,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              AppAvatar(
                initial: request.senderInitial,
                size: AvatarSize.medium,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      request.senderName,
                      style: typo.h3.copyWith(fontWeight: FontWeight.w700),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      DateFormat('MMM d, yyyy').format(request.travelDate),
                      style: typo.sm.copyWith(color: AppColors.textSecondary),
                    ),
                  ],
                ),
              ),
              _RequestCountBadge(count: requestCount),
            ],
          ),
          const SizedBox(height: 12),
          StackedRouteEndpoints(
            from: request.displayFrom,
            to: request.displayTo,
            fallbackRoute: request.displayRoute,
            emphasized: true,
          ),
          const SizedBox(height: 8),
          Text(
            '\$${request.maxBudget.toStringAsFixed(0)} USD',
            style: typo.priceSmall,
          ),
          const SizedBox(height: 14),
          AppButton(
            label: 'View Details',
            onPressed: onViewDetails,
          ),
        ],
      ),
    );
  }
}

class _RequestCountBadge extends StatelessWidget {
  const _RequestCountBadge({required this.count});

  final int count;

  @override
  Widget build(BuildContext context) {
    final typo = context.typo;
    final label = count > 99 ? '99+' : '$count';
    return Container(
      width: 28,
      height: 28,
      alignment: Alignment.center,
      decoration: const BoxDecoration(
        color: AppColors.primary,
        shape: BoxShape.circle,
      ),
      child: Text(
        label,
        style: typo.sm.copyWith(
          color: Colors.white,
          fontWeight: FontWeight.w700,
          fontSize: 12,
        ),
      ),
    );
  }
}
