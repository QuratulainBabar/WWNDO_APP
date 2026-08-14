import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../core/api/api_exception.dart';
import '../../core/config/demo_mode.dart';
import '../../core/platform/keyboard_utils.dart';
import '../../core/layout/responsive.dart';
import '../../core/platform/platform_ui.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_typography.dart';
import '../../core/widgets/app_avatar.dart';
import '../../core/widgets/app_badge.dart';
import '../../core/widgets/app_button.dart';
import '../../core/widgets/app_card.dart';
import '../../core/widgets/app_labeled_field.dart';
import '../../core/widgets/app_toast.dart';
import '../../core/widgets/back_header.dart';
import '../../data/models/delivery_request.dart';
import '../../data/models/matching_request.dart';
import '../../data/models/sender_trip_request.dart';
import '../../data/models/traveler_bid.dart';
import '../../data/services/trip_repository.dart';
import '../../data/static_data.dart';
import '../../providers/auth_provider.dart';
import '../tracking/widgets/parcel_photo_viewer.dart';

class ParcelRequestDetailScreen extends StatefulWidget {
  const ParcelRequestDetailScreen({super.key, required this.requestId});

  final String requestId;

  @override
  State<ParcelRequestDetailScreen> createState() =>
      _ParcelRequestDetailScreenState();
}

class _ParcelRequestDetailScreenState extends State<ParcelRequestDetailScreen> {
  late final TextEditingController _messageController;
  bool _loading = true;
  String? _error;
  SenderTripRequest? _apiRequest;
  DeliveryRequest? _request;
  int? _matchScore;
  String _tripId = '';

  @override
  void initState() {
    super.initState();
    _messageController = TextEditingController();
    WidgetsBinding.instance.addPostFrameCallback((_) => _load());
  }

  @override
  void dispose() {
    _messageController.dispose();
    super.dispose();
  }

  TripRepository _repo() {
    final auth = context.read<AuthProvider>();
    final demoMode = context.read<DemoModeProvider>();
    return TripRepository(
      apiClient: auth.repository.apiClient,
      demoMode: demoMode,
    );
  }

  void _cacheMatching(SenderTripRequest api, DeliveryRequest request) {
    final tripKey =
        api.tripPublicId.isNotEmpty ? api.tripPublicId : api.tripId;
    StaticData.matchingRequests.removeWhere((m) => m.request.id == api.id);
    StaticData.matchingRequests.add(
      MatchingRequest(
        request: request,
        matchScore: api.matchScore,
        tripId: tripKey,
      ),
    );
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });

    // Prefer live API; fall back to static matching data (browse/demo).
    try {
      final api = await _repo().getSenderRequest(widget.requestId);
      if (!mounted) return;
      final request = api.toDeliveryRequest();
      _cacheMatching(api, request);

      // Keep Accept / Counter buttons accurate after app restart.
      try {
        final offers = await _repo().listCounterOffers();
        if (!mounted) return;
        StaticData.syncTravelerBidsFromApi(offers);
      } catch (_) {
        // Ignore — parcel details can still render.
      }

      setState(() {
        _apiRequest = api;
        _request = request;
        _matchScore = api.matchScore;
        _tripId = api.tripPublicId.isNotEmpty ? api.tripPublicId : api.tripId;
        _loading = false;
      });
      return;
    } catch (_) {
      // Fall through to static.
    }

    final matching = StaticData.matchingRequestById(widget.requestId);
    if (matching != null) {
      if (!mounted) return;
      setState(() {
        _request = matching.request;
        _matchScore = matching.matchScore;
        _tripId = matching.tripId;
        _loading = false;
      });
      return;
    }

    if (!mounted) return;
    setState(() {
      _loading = false;
      _error = 'Unable to load parcel request details.';
    });
  }

  Future<void> _submitBid(double amount) async {
    final request = _request;
    if (request == null) return;

    try {
      final offer = await _repo().sendCounterOffer(
        requestId: widget.requestId,
        amount: amount,
      );
      if (!mounted) return;
      StaticData.upsertTravelerBid(offer);
      FocusScope.of(context).unfocus();
      context.push(
        '/bid-submitted',
        extra: {
          'route': request.route,
          'price': amount,
          'tripId': _tripId,
        },
      );
      return;
    } on ApiException catch (e) {
      if (!mounted) return;
      if (e.code != 'DEMO_MODE') {
        AppToast.error(context, e.message);
        return;
      }
    } catch (_) {
      // Fall through to static demo path.
    }

    final authUser = context.read<AuthProvider>().user;
    final error = StaticData.sendTravelerFinalBudget(
      request: request,
      tripId: _tripId,
      amount: amount,
      authUser: authUser,
      allowAboveMaxBudget: false,
    );
    if (error != null) {
      AppToast.error(context, error);
      return;
    }

    FocusScope.of(context).unfocus();

    if (!mounted) return;
    context.push(
      '/bid-submitted',
      extra: {
        'route': request.route,
        'price': amount,
        'tripId': _tripId,
      },
    );
  }

  Future<void> _acceptOffer() async {
    final request = _request;
    if (request == null) return;
    await _submitBid(request.maxBudget);
  }

  Future<void> _onSendCounterOfferTap() async {
    final sent = await context.push<bool>(
      '/request/${widget.requestId}/counter-offer',
    );
    if (!mounted || sent != true) return;
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final typo = context.typo;

    if (_loading) {
      return const Scaffold(
        backgroundColor: AppColors.background,
        appBar: BackHeader(title: 'Parcel Request Details'),
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

    if (_error != null || _request == null) {
      return Scaffold(
        backgroundColor: AppColors.background,
        appBar: const BackHeader(title: 'Parcel Request Details'),
        body: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                _error ?? 'Request not found.',
                style: typo.sm.copyWith(color: AppColors.textSecondary),
              ),
              TextButton(onPressed: _load, child: const Text('Retry')),
            ],
          ),
        ),
      );
    }

    final request = _request!;
    final matchScore = _matchScore;
    final existingBid = StaticData.travelerBidForRequest(request.id);
    final canAcceptOffer = existingBid == null;
    final canSendCounterOffer =
        existingBid == null || existingBid.status != TravelerBidStatus.accepted;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: const BackHeader(title: 'Parcel Request Details'),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                physics: PlatformUi.scrollPhysics,
                padding: context.pagePaddingWithKeyboard(context.pagePadding),
                child: AppCard(
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
                                  style: typo.h3.copyWith(
                                    fontWeight: FontWeight.w700,
                                    color: AppColors.textPrimary,
                                  ),
                                ),
                                Text(
                                  '★ ${request.senderRating > 0 ? request.senderRating.toStringAsFixed(1) : (_apiRequest?.senderRating?.toStringAsFixed(1) ?? '—')}',
                                  style: typo.sm.copyWith(
                                    color: AppColors.textPrimary,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          if (matchScore != null)
                            AppBadge.success('$matchScore% Match'),
                        ],
                      ),
                      const SizedBox(height: 20),
                      Text(
                        'Parcel details',
                        style: typo.h3.copyWith(
                          fontWeight: FontWeight.w700,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 12),
                      _detailRow(context, 'Route', request.route),
                      _detailRow(
                        context,
                        'Travel / delivery date',
                        DateFormat('MMM d, yyyy').format(request.travelDate),
                      ),
                      _detailRow(
                        context,
                        'Parcel type',
                        request.categoryTypeLabel,
                      ),
                      _detailRow(
                        context,
                        'Parcel weight',
                        '${request.weightKg} kg',
                      ),
                      _detailRow(
                        context,
                        'Meetup location',
                        request.displayMeetupLocation,
                        multiline: request.meetupLocations.length > 1,
                      ),
                      const SizedBox(height: 8),
                      ParcelPhotoViewer(
                        photoUrls: request.photoUrls,
                        title: 'Parcel photos',
                      ),
                      const SizedBox(height: 12),
                      _detailRow(
                        context,
                        'Parcel description',
                        request.displayDescription,
                        multiline: true,
                      ),
                      const SizedBox(height: 8),
                      _detailRow(
                        context,
                        'Sender maximum budget',
                        '\$${request.maxBudget.toStringAsFixed(2)} USD',
                        valueStyle: typo.priceSmall.copyWith(fontSize: 16),
                      ),
                      const SizedBox(height: 16),
                      AppLabeledField(
                        label: 'Message to sender (optional)',
                        labelStyle: typo.inputLabel.copyWith(
                          fontWeight: FontWeight.w600,
                          color: AppColors.textPrimary,
                        ),
                        child: TextField(
                          controller: _messageController,
                          onTap: ensureSoftKeyboardVisible,
                          onTapOutside: dismissKeyboardOnTapOutside,
                          maxLines: 3,
                          style: typo.input,
                          textInputAction: TextInputAction.done,
                          decoration: InputDecoration(
                            hintText:
                                'Add a note for the sender about this delivery…',
                            hintStyle: typo.sm.copyWith(
                              color: AppColors.textSecondary,
                              fontStyle: FontStyle.italic,
                            ),
                          ),
                        ),
                      ),
                      if (existingBid != null) ...[
                        const SizedBox(height: 12),
                        Text(
                          existingBid.isAccepted
                              ? 'This offer was already accepted. Counter offers are closed.'
                              : 'Your offer is ${existingBid.status.label}. You can still send an updated counter offer.',
                          style: typo.sm.copyWith(
                            color: existingBid.isAccepted
                                ? AppColors.danger
                                : AppColors.textSecondary,
                          ),
                        ),
                      ],
                      const SizedBox(height: 16),
                      AppButton(
                        label: 'Accept Offer',
                        onPressed: canAcceptOffer ? _acceptOffer : null,
                      ),
                      const SizedBox(height: AppButton.stackGap),
                      AppButton(
                        label: 'Send Counter Offer',
                        variant: AppButtonVariant.ghost,
                        onPressed:
                            canSendCounterOffer ? _onSendCounterOfferTap : null,
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _detailRow(
    BuildContext context,
    String label,
    String value, {
    TextStyle? valueStyle,
    bool multiline = false,
  }) {
    final typo = context.typo;
    final labelStyle = typo.sm.copyWith(color: AppColors.textSecondary);
    final resolvedValueStyle = valueStyle ??
        typo.body.copyWith(
          color: AppColors.textPrimary,
          fontWeight: FontWeight.w600,
        );

    if (multiline) {
      return Padding(
        padding: const EdgeInsets.only(bottom: 10),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label, style: labelStyle),
            const SizedBox(height: 4),
            Text(
              value,
              style: resolvedValueStyle.copyWith(height: 1.45),
            ),
          ],
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 150,
            child: Text(label, style: labelStyle),
          ),
          Expanded(
            child: Text(value, style: resolvedValueStyle),
          ),
        ],
      ),
    );
  }
}
