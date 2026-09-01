import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../core/api/api_exception.dart';
import '../../core/config/demo_mode.dart';
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
import '../../data/models/bid.dart';
import '../../data/models/created_delivery.dart';
import '../../data/models/matching_traveler.dart';
import '../../data/models/traveler_request_summary.dart';
import '../../data/platform_fees.dart';
import '../../data/services/delivery_repository.dart';
import '../../providers/auth_provider.dart';
import '../../providers/notification_realtime_provider.dart';
import 'bid_acceptance_payment_screen.dart';
import 'bid_sort.dart';

class BidRequestsScreen extends StatefulWidget {
  const BidRequestsScreen({super.key, required this.shipmentId});

  final String shipmentId;

  @override
  State<BidRequestsScreen> createState() => _BidRequestsScreenState();
}

class _BidRequestsScreenState extends State<BidRequestsScreen> {
  BidSortOption _sort = BidSortOption.bestMatchScore;
  List<Bid>? _apiBids;
  CreatedDelivery? _delivery;
  List<TravelerRequestSummary> _travelerRequests = const [];
  bool _loading = true;
  String? _error;

  NotificationRealtimeProvider? _realtimeProvider;
  VoidCallback? _realtimeListener;
  int _lastDeliveryUpdateTick = 0;

  TravelerRequestSummary? _requestFor(Bid bid) {
    for (final r in _travelerRequests) {
      if (r.tripId == bid.id || r.tripPublicId == bid.id) return r;
    }
    return null;
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _load();
      _attachRealtimeListener();
    });
  }

  void _attachRealtimeListener() {
    final realtime = context.read<NotificationRealtimeProvider>();
    if (_realtimeProvider == realtime && _realtimeListener != null) return;
    if (_realtimeListener != null) {
      _realtimeProvider?.removeListener(_realtimeListener!);
    }
    _realtimeProvider = realtime;
    _lastDeliveryUpdateTick = realtime.deliveryUpdateTick;
    _realtimeListener = () {
      if (!mounted) return;
      final tick = realtime.deliveryUpdateTick;
      if (tick != _lastDeliveryUpdateTick) {
        _lastDeliveryUpdateTick = tick;
        _load();
      }
    };
    realtime.addListener(_realtimeListener!);
  }

  @override
  void dispose() {
    if (_realtimeListener != null) {
      _realtimeProvider?.removeListener(_realtimeListener!);
    }
    super.dispose();
  }

  DeliveryRepository _repository() {
    final auth = context.read<AuthProvider>();
    return DeliveryRepository(
      apiClient: auth.repository.apiClient,
      demoMode: context.read<DemoModeProvider>(),
    );
  }

  Future<void> _load() async {
    final demo = context.read<DemoModeProvider>().enabled;
    if (demo) {
      setState(() {
        _loading = false;
        _error = 'Turn off Demo mode to browse matching travelers from the API.';
      });
      return;
    }

    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final repo = _repository();
      final results = await Future.wait([
        repo.getDelivery(widget.shipmentId, role: 'sender'),
        repo.listMatchingTravelers(widget.shipmentId),
        repo.listTravelerRequests(widget.shipmentId),
      ]);
      final travelers = results[1] as List<MatchingTraveler>;
      if (!mounted) return;
      setState(() {
        _delivery = results[0] as CreatedDelivery;
        _apiBids = travelers.map((t) => t.toBid()).toList();
        _travelerRequests = results[2] as List<TravelerRequestSummary>;
        _loading = false;
      });
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _error = e.message;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _error = 'Unable to load matching travelers.';
      });
    }
  }

  BidReviewStatus _reviewStatusFor(Bid bid) {
    final request = _requestFor(bid);
    if (request == null) return BidReviewStatus.open;
    if (request.isAccepted) return BidReviewStatus.approved;
    return BidReviewStatus.deliveryRequested;
  }

  Future<void> _selectTraveler(Bid bid) async {
    if (_travelerRequests.length >= PlatformFees.maxTravelerRequestsPerDelivery) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('You can request at most 2 travelers for this parcel.'),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    try {
      await _repository().requestTraveler(
        deliveryId: widget.shipmentId,
        tripId: bid.id,
        matchScore: bid.routeMatchConfidence,
      );
    } catch (e) {
      if (!mounted) return;
      final message = e is ApiException
          ? e.message
          : 'Unable to send request to this traveler.';
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(message), behavior: SnackBarBehavior.floating),
      );
      return;
    }

    await _load();
    if (!mounted) return;
    context.push(
      '/traveler-selected-confirmation',
      extra: BidAcceptanceContext(
        bid: bid,
        shipmentId: widget.shipmentId,
      ),
    );
  }

  List<Bid> _visibleBids() =>
      BidSortOption.sorted(_apiBids ?? const [], _sort);

  @override
  Widget build(BuildContext context) {
    final typo = context.typo;
    final delivery = _delivery;
    final bids = _visibleBids();

    if (_loading) {
      return Scaffold(
        backgroundColor: AppColors.background,
        appBar: const BackHeader(title: 'Matching Travelers'),
        body: const Center(
          child: SizedBox(
            width: 28,
            height: 28,
            child: CircularProgressIndicator(strokeWidth: 2.5),
          ),
        ),
      );
    }

    if (_error != null || delivery == null) {
      return Scaffold(
        backgroundColor: AppColors.background,
        appBar: const BackHeader(title: 'Matching Travelers'),
        body: Center(
          child: Padding(
            padding: context.pagePadding,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  _error ?? 'This delivery could not be found.',
                  textAlign: TextAlign.center,
                  style: typo.sm.copyWith(color: AppColors.textSecondary),
                ),
                const SizedBox(height: 16),
                TextButton(onPressed: _load, child: const Text('Retry')),
              ],
            ),
          ),
        ),
      );
    }

    final summary = _ParcelSummary(
      id: delivery.displayId,
      route: delivery.route.isNotEmpty ? delivery.route : '—',
      travelDate: delivery.travelDateParsed ?? DateTime.now(),
      weightKg: delivery.weightKg,
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
              child: _ParcelSummaryCard(summary: summary),
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
          return _MatchingTravelerCard(
            bid: bid,
            status: _reviewStatusFor(bid),
            onViewProfile: () => context.push(
              '/bid-traveler-profile',
              extra: BidAcceptanceContext(
                bid: bid,
                shipmentId: widget.shipmentId,
              ),
            ),
            onReviewOffer: () => context.push(
              '/sender-counter-offer?delivery=${widget.shipmentId}',
            ),
            onSelectTraveler: () => _selectTraveler(bid),
          );
        },
      ),
    );
  }
}

class _ParcelSummary {
  const _ParcelSummary({
    required this.id,
    required this.route,
    required this.travelDate,
    required this.weightKg,
  });

  final String id;
  final String route;
  final DateTime travelDate;
  final double weightKg;
}

class _ParcelSummaryCard extends StatelessWidget {
  const _ParcelSummaryCard({required this.summary});

  final _ParcelSummary summary;

  @override
  Widget build(BuildContext context) {
    final typo = context.typo;

    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            summary.id,
            style: typo.h3.copyWith(
              fontWeight: FontWeight.w700,
              color: AppColors.primary,
            ),
          ),
          const SizedBox(height: 8),
          Text(summary.route, style: typo.sm),
          const SizedBox(height: 4),
          Text(
            'Travel date: ${DateFormat('MMM d, yyyy').format(summary.travelDate)}'
            ' · Weight: ${summary.weightKg} kg',
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
    required this.onReviewOffer,
    required this.onSelectTraveler,
  });

  final Bid bid;
  final BidReviewStatus status;
  final VoidCallback onViewProfile;
  final VoidCallback onReviewOffer;
  final VoidCallback onSelectTraveler;

  @override
  Widget build(BuildContext context) {
    final typo = context.typo;
    final requested = status == BidReviewStatus.deliveryRequested;
    final accepted = status == BidReviewStatus.approved ||
        status == BidReviewStatus.accepted;

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: AppCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                AppAvatar(initial: bid.initial, size: AvatarSize.medium),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(bid.travelerName, style: typo.bodyBold),
                      Text(
                        '★ ${bid.rating.toStringAsFixed(1)} · ${bid.reviewCount} reviews',
                        style: typo.sm.copyWith(color: AppColors.textSecondary),
                      ),
                    ],
                  ),
                ),
                if (accepted)
                  AppBadge(
                    label: 'Accepted',
                    color: AppColors.primary,
                    backgroundColor: AppColors.primary.withValues(alpha: 0.12),
                  )
                else if (requested)
                  AppBadge(
                    label: 'Requested',
                    color: AppColors.warning,
                    backgroundColor: AppColors.warning.withValues(alpha: 0.12),
                  )
                else if (bid.featured)
                  AppBadge.success('Best match'),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              '\$${bid.price.toStringAsFixed(2)} proposed',
              style: typo.sm.copyWith(color: AppColors.textSecondary),
            ),
            const SizedBox(height: 4),
            Text(
              'Travel date: ${DateFormat('MMM d, yyyy').format(bid.travelDate)}'
              ' · Match ${bid.routeMatchConfidence}%',
              style: typo.sm.copyWith(color: AppColors.textSecondary),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: AppButton(
                    label: 'View profile',
                    variant: AppButtonVariant.outline,
                    onPressed: onViewProfile,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: AppButton(
                    label: accepted
                        ? 'Review offer'
                        : requested
                            ? 'Requested'
                            : 'Select traveler',
                    onPressed: accepted
                        ? onReviewOffer
                        : requested
                            ? null
                            : onSelectTraveler,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
