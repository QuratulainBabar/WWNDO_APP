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
import '../../core/widgets/app_badge.dart';
import '../../core/widgets/app_card.dart';
import '../../core/widgets/back_header.dart';
import '../../data/models/traveler_bid.dart';
import '../../data/services/trip_repository.dart';
import '../../data/static_data.dart';
import '../../providers/auth_provider.dart';

/// Counter offers sent by the traveler — loaded from API.
class TravelerMyBidsScreen extends StatefulWidget {
  const TravelerMyBidsScreen({super.key});

  @override
  State<TravelerMyBidsScreen> createState() => _TravelerMyBidsScreenState();
}

class _TravelerMyBidsScreenState extends State<TravelerMyBidsScreen> {
  bool _loading = true;
  String? _error;
  List<TravelerBid> _offers = const [];

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
      final offers = await _repo().listCounterOffers();
      if (!mounted) return;
      StaticData.syncTravelerBidsFromApi(offers);
      setState(() {
        _offers = offers;
        _loading = false;
      });
    } catch (_) {
      if (!mounted) return;
      // Demo / offline fallback to in-memory bids.
      final fallback = List<TravelerBid>.from(StaticData.travelerBids);
      setState(() {
        _offers = fallback;
        _loading = false;
        if (fallback.isEmpty) {
          _error = 'Unable to load counter offers.';
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final typo = context.typo;
    final horizontal = context.horizontalPadding;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: const BackHeader(title: 'Counter Offers Sent'),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: EdgeInsets.fromLTRB(horizontal, 4, horizontal, 12),
            child: Text(
              'These are the counter offers you have sent to senders.',
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
                            TextButton(onPressed: _load, child: const Text('Retry')),
                          ],
                        ),
                      )
                    : _offers.isEmpty
                        ? Center(
                            child: Padding(
                              padding: EdgeInsets.symmetric(horizontal: horizontal),
                              child: Text(
                                'No counter offers yet.',
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
                                    onTap: () => context.push(
                                      '/traveler-bid-detail/${bid.id}',
                                      extra: bid,
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
                    const SizedBox(height: 2),
                    Text(bid.route, style: typo.sm),
                  ],
                ),
              ),
              _StatusBadge(status: bid.status),
            ],
          ),
          const SizedBox(height: 14),
          _DetailRow(
            label: 'Offer amount',
            value: '\$${bid.amount.toInt()}',
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
