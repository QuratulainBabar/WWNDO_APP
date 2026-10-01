import 'package:flutter/material.dart';
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
import '../../core/widgets/app_button.dart';
import '../../core/widgets/app_card.dart';
import '../../core/widgets/back_header.dart';
import '../../core/widgets/stacked_route_endpoints.dart';
import '../../data/models/traveler_bid.dart';
import '../../data/services/trip_repository.dart';
import '../../data/static_data.dart';
import '../../data/wallet_service.dart';
import '../../providers/auth_provider.dart';
import '../chat/open_delivery_chat.dart';
import '../tracking/widgets/parcel_photo_viewer.dart';

class TravelerBidDetailScreen extends StatefulWidget {
  const TravelerBidDetailScreen({
    super.key,
    this.offerId,
    this.bid,
  });

  final String? offerId;
  final TravelerBid? bid;

  @override
  State<TravelerBidDetailScreen> createState() =>
      _TravelerBidDetailScreenState();
}

class _TravelerBidDetailScreenState extends State<TravelerBidDetailScreen> {
  bool _loading = true;
  String? _error;
  TravelerBid? _bid;

  @override
  void initState() {
    super.initState();
    _bid = widget.bid;
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
    final id = (widget.offerId ?? widget.bid?.id ?? '').trim();
    if (id.isEmpty) {
      setState(() {
        _loading = false;
        _error = _bid == null ? 'Counter offer not found.' : null;
      });
      return;
    }

    // Show cached bid immediately while refreshing from API.
    if (_bid != null) {
      setState(() => _loading = false);
    } else {
      setState(() {
        _loading = true;
        _error = null;
      });
    }

    try {
      final offer = await _repo().getCounterOffer(id);
      if (!mounted) return;
      StaticData.upsertTravelerBid(offer);
      setState(() {
        _bid = offer;
        _loading = false;
        _error = null;
      });
    } catch (_) {
      if (!mounted) return;
      final fallback =
          widget.bid ?? StaticData.travelerBidById(id);
      setState(() {
        _bid = fallback;
        _loading = false;
        if (fallback == null) {
          _error = 'Unable to load bid details.';
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final typo = context.typo;

    if (_loading && _bid == null) {
      return Scaffold(
        backgroundColor: AppColors.background,
        appBar: BackHeader(title: 'Bid Details'),
        body: Center(
          child: SizedBox(
            width: 22,
            height: 22,
            child: CircularProgressIndicator(
              strokeWidth: 2.5,
              color: AppColors.primary,
            ),
          ),
        ),
      );
    }

    final bid = _bid;
    if (_error != null || bid == null) {
      return Scaffold(
        backgroundColor: AppColors.background,
        appBar: const BackHeader(title: 'Bid Details'),
        body: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                _error ?? 'Bid not found.',
                style: typo.sm.copyWith(color: AppColors.textSecondary),
              ),
              TextButton(onPressed: _load, child: Text(context.tr('Retry'))),
            ],
          ),
        ),
      );
    }

    final deliveryDate = DateFormat('MMM d, yyyy').format(bid.deliveryDate);
    final deliveryId = bid.deliveryPublicId ?? '';
    final amountLabel = bid.isAccepted
        ? 'Accepted bid amount'
        : 'Offer amount';

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: const BackHeader(title: 'Bid Details'),
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: _load,
          child: SingleChildScrollView(
            physics: AlwaysScrollableScrollPhysics(
              parent: PlatformUi.scrollPhysics,
            ),
            padding: context.pagePadding,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _StatusBadge(status: bid.status),
                const SizedBox(height: 16),
                AppCard(
                  margin: EdgeInsets.zero,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          AppAvatar(
                            initial: bid.senderInitial,
                            size: AvatarSize.large,
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  bid.senderName,
                                  style: typo.h3.copyWith(
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text('Sender', style: typo.sm),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const Padding(
                        padding: EdgeInsets.symmetric(vertical: 20),
                        child: Divider(height: 1),
                      ),
                      Text('Parcel photo', style: typo.sm),
                      const SizedBox(height: 8),
                      ParcelPhotoViewer(
                        photoUrls: bid.parcelPhotoUrls,
                        title: '',
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'Bid details',
                        style: typo.h3.copyWith(fontWeight: FontWeight.w700),
                      ),
                      const SizedBox(height: 12),
                      StackedRouteEndpoints(
                        from: bid.displayFrom,
                        to: bid.displayTo,
                        fallbackRoute: bid.route,
                        sectionLabel: context.l10n.route,
                        bottomPadding: 8,
                      ),
                      _detailRow(context, 'Delivery date', deliveryDate),
                      _detailRow(
                        context,
                        amountLabel,
                        WalletService.formatMajor(bid.amount),
                        valueStyle: typo.priceSmall.copyWith(
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      _detailRow(context, 'Bid status', bid.status.label),
                    ],
                  ),
                ),
                if (bid.isAccepted && deliveryId.isNotEmpty) ...[
                  const SizedBox(height: 24),
                  AppButton(
                    label: 'Chat with Sender',
                    onPressed: () => openDeliveryChat(
                      context,
                      chatBasePath: '/traveler-chats',
                      threadType: 'sender_traveler',
                      deliveryKey: deliveryId,
                    ),
                  ),
                ],
              ],
            ),
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
              style: valueStyle ??
                  typo.body.copyWith(fontWeight: FontWeight.w500),
            ),
          ),
        ],
      ),
    );
  }
}

class _StatusBadge extends StatelessWidget {
  const _StatusBadge({required this.status});

  final TravelerBidStatus status;

  @override
  Widget build(BuildContext context) {
    if (status == TravelerBidStatus.accepted) {
      return AppBadge.success('Bid accepted');
    }
    return AppBadge(
      label: status.label,
      color: status.color,
      backgroundColor: status.color.withValues(alpha: 0.12),
      small: true,
      semiBold: true,
    );
  }
}
