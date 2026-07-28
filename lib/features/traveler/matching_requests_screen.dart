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
import '../../data/models/sender_trip_request.dart';
import '../../data/services/trip_repository.dart';
import '../../providers/auth_provider.dart';
import '../../providers/notification_realtime_provider.dart';

/// Sender requests for a single trip — loaded from API.
class MatchingRequestsScreen extends StatefulWidget {
  const MatchingRequestsScreen({super.key, required this.tripId});

  final String tripId;

  @override
  State<MatchingRequestsScreen> createState() => _MatchingRequestsScreenState();
}

class _MatchingRequestsScreenState extends State<MatchingRequestsScreen> {
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
      final requests = await _repo().listSenderRequestsForTrip(widget.tripId);
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
        _error = 'Unable to load sender requests for this trip.';
      });
    }
  }

  Future<void> _markOpenedRequestsRead() async {
    final unreadOnThisTrip = _requests.where((r) => r.unread).length;
    if (unreadOnThisTrip == 0) return;

    final realtime = context.read<NotificationRealtimeProvider>();
    final optimisticBadge =
        (realtime.senderRequestUnreadCount - unreadOnThisTrip).clamp(0, 999);
    realtime.setSenderRequestUnreadCount(optimisticBadge);
    setState(() {
      _requests = _requests.map((r) => r.unread ? r.markRead() : r).toList();
    });

    try {
      final result = await _repo().markSenderRequestsRead(widget.tripId);
      if (!mounted) return;
      realtime.setSenderRequestUnreadCount(result.unreadCount);
      realtime.setUnreadCount(result.notificationsUnread);
    } catch (_) {
      // Keep optimistic read state; traveler already saw the requests.
    }
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
              'These senders want to deliver parcels\non your route. Tap any request to view full details.',
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
                              style: typo.sm.copyWith(color: AppColors.textSecondary),
                            ),
                            TextButton(onPressed: _load, child: const Text('Retry')),
                          ],
                        ),
                      )
                    : _requests.isEmpty
                        ? Center(
                            child: Padding(
                              padding: EdgeInsets.symmetric(horizontal: horizontal),
                              child: Text(
                                'No sender requests for this trip yet.',
                                style: typo.sm.copyWith(color: AppColors.textSecondary),
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
                              padding: EdgeInsets.fromLTRB(horizontal, 0, horizontal, 24),
                              itemCount: _requests.length,
                              itemBuilder: (context, i) {
                                final request = _requests[i];
                                return Padding(
                                  padding: const EdgeInsets.only(bottom: 12),
                                  child: _SenderRequestCard(
                                    request: request,
                                    onViewDetails: () => context.push(
                                      '/request/${request.id}',
                                    ),
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
}

class _SenderRequestCard extends StatelessWidget {
  const _SenderRequestCard({
    required this.request,
    required this.onViewDetails,
  });

  final SenderTripRequest request;
  final VoidCallback onViewDetails;

  @override
  Widget build(BuildContext context) {
    final typo = context.typo;
    final rating = request.senderRating;
    final ratingLabel = rating != null && rating > 0
        ? rating.toStringAsFixed(1)
        : '—';

    return AppCard(
      margin: EdgeInsets.zero,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              AppAvatar(initial: request.senderInitial, size: AvatarSize.medium),
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
                      '★ $ratingLabel · ${DateFormat('MMM d, yyyy').format(request.travelDate)}',
                      style: typo.sm.copyWith(color: AppColors.textSecondary),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            request.route,
            style: typo.body.copyWith(
              fontWeight: FontWeight.w700,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 6),
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
