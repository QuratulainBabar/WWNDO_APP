import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../l10n/app_localizations.dart';

import '../../core/config/demo_mode.dart';
import '../../core/layout/responsive.dart';
import '../../core/platform/platform_ui.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_typography.dart';
import '../../core/widgets/app_avatar.dart';
import '../../core/widgets/app_badge.dart';
import '../../core/widgets/app_card.dart';
import '../../core/widgets/back_header.dart';
import '../../core/widgets/stacked_route_endpoints.dart';
import '../../data/models/traveler_bid.dart';
import '../../data/services/trip_repository.dart';
import '../../data/static_data.dart';
import '../../data/wallet_service.dart';
import '../../providers/auth_provider.dart';
import '../../providers/notification_realtime_provider.dart';

/// Counter offers / accepted max-budget offers for the traveler — loaded from API.
///
/// Default (Counter Offers Sent): traveler-submitted counters still awaiting
/// the sender. Once the sender accepts or rejects, that delivery is removed.
///
/// When [showAcceptedOffers] is true, lists only deliveries where the traveler
/// accepted the sender's exact maximum budget and the sender has not finalized
/// yet (accepted / rejected / completed deliveries are removed from this list).
class TravelerMyBidsScreen extends StatefulWidget {
  const TravelerMyBidsScreen({
    super.key,
    this.showAcceptedOffers = false,
  });

  final bool showAcceptedOffers;

  @override
  State<TravelerMyBidsScreen> createState() => _TravelerMyBidsScreenState();
}

class _TravelerMyBidsScreenState extends State<TravelerMyBidsScreen> {
  bool _loading = true;
  String? _error;
  List<TravelerBid> _offers = const [];
  VoidCallback? _realtimeListener;
  NotificationRealtimeProvider? _realtimeProvider;
  int _lastDeliveryUpdateTick = 0;

  bool get _acceptedOnly => widget.showAcceptedOffers;

  bool _matchesListFilter(TravelerBid o) => _acceptedOnly
      ? o.isPendingExactMaxBudgetAcceptance
      : o.isCounterOfferSent;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _load();
      _attachRealtimeListener();
    });
  }

  @override
  void dispose() {
    if (_realtimeListener != null) {
      _realtimeProvider?.removeListener(_realtimeListener!);
    }
    super.dispose();
  }

  void _attachRealtimeListener() {
    if (!mounted) return;
    final realtime = context.read<NotificationRealtimeProvider>();
    _realtimeProvider = realtime;
    _lastDeliveryUpdateTick = realtime.deliveryUpdateTick;
    _realtimeListener ??= () {
      if (!mounted) return;
      final tick = realtime.deliveryUpdateTick;
      if (tick != _lastDeliveryUpdateTick) {
        _lastDeliveryUpdateTick = tick;
        // Sender accept / delivery updates → drop finalized items immediately.
        _load(silent: true);
      }
    };
    realtime.addListener(_realtimeListener!);
  }

  TripRepository _repo() {
    final auth = context.read<AuthProvider>();
    final demoMode = context.read<DemoModeProvider>();
    return TripRepository(
      apiClient: auth.repository.apiClient,
      demoMode: demoMode,
    );
  }

  Future<void> _load({bool silent = false}) async {
    if (!silent) {
      setState(() {
        _loading = true;
        _error = null;
      });
    }
    try {
      final offers = (await _repo().listCounterOffers(
        acceptancesOnly: _acceptedOnly,
      ))
          .where(_matchesListFilter)
          .toList();
      if (!mounted) return;
      // Keep local Counter Offers Sent cache in sync only for the counter list.
      if (!_acceptedOnly) {
        StaticData.syncTravelerBidsFromApi(offers);
      }
      setState(() {
        _offers = offers;
        _loading = false;
        _error = null;
      });
    } catch (_) {
      if (!mounted) return;
      // Demo / offline fallback to in-memory bids.
      final fallback =
          StaticData.travelerBids.where(_matchesListFilter).toList();
      setState(() {
        _offers = fallback;
        _loading = false;
        if (fallback.isEmpty) {
          _error = _acceptedOnly
              ? 'Unable to load accepted offers.'
              : 'Unable to load counter offers.';
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final typo = context.typo;
    final horizontal = context.horizontalPadding;
    final title =
        _acceptedOnly ? 'Accepted Offers' : 'Counter Offers Sent';
    final subtitle = _acceptedOnly
        ? 'Offers where you accepted the sender\'s max budget. Once the sender confirms, they move to My Deliveries.'
        : 'These are the counter offers you have sent to senders.';
    final emptyLabel = _acceptedOnly
        ? 'No pending accepted offers.'
        : 'No counter offers yet.';

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: BackHeader(title: title),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: EdgeInsets.fromLTRB(horizontal, 4, horizontal, 12),
            child: Text(
              subtitle,
              style: typo.sm.copyWith(color: AppColors.textSecondary, height: 1.4),
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
                : _error != null && _offers.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              _error!,
                              style: typo.sm.copyWith(color: AppColors.textSecondary),
                            ),
                            TextButton(onPressed: _load, child: Text(context.tr('Retry'))),
                          ],
                        ),
                      )
                    : _offers.isEmpty
                        ? Center(
                            child: Padding(
                              padding: EdgeInsets.symmetric(horizontal: horizontal),
                              child: Text(
                                emptyLabel,
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
                              itemCount: _offers.length,
                              itemBuilder: (context, i) {
                                final bid = _offers[i];
                                return Padding(
                                  padding: const EdgeInsets.only(bottom: 12),
                                  child: _CounterOfferCard(
                                    bid: bid,
                                    onTap: () async {
                                      await context.push(
                                        '/traveler-bid-detail/${bid.id}',
                                        extra: bid,
                                      );
                                      if (mounted) await _load(silent: true);
                                    },
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
      margin: EdgeInsets.zero,
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
                    const SizedBox(height: 6),
                    StackedRouteEndpoints(
                      from: bid.displayFrom,
                      to: bid.displayTo,
                      fallbackRoute: bid.route,
                    ),
                  ],
                ),
              ),
              _StatusBadge(status: bid.status),
            ],
          ),
          const SizedBox(height: 14),
          _DetailRow(
            label: 'Offer amount',
            value: WalletService.formatMajor(bid.amount),
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
