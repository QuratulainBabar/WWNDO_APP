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

enum _ParcelOfferAction { none, accepted, countered }

class _ParcelRequestDetailScreenState extends State<ParcelRequestDetailScreen> {
  late final TextEditingController _messageController;
  bool _loading = true;
  bool _busy = false;
  String? _error;
  SenderTripRequest? _apiRequest;
  DeliveryRequest? _request;
  int? _matchScore;
  String _tripId = '';
  _ParcelOfferAction _completedAction = _ParcelOfferAction.none;

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

    // Always sync offers first so Accept / Counter button states survive reloads
    // even when the sender-request endpoint is temporarily unavailable.
    try {
      final offers = await _repo().listCounterOffers();
      if (!mounted) return;
      StaticData.syncTravelerBidsFromApi(offers);
    } catch (_) {
      // Ignore — parcel details can still render.
    }

    // Prefer live API; fall back to static matching data (browse/demo).
    try {
      final api = await _repo().getSenderRequest(widget.requestId);
      if (!mounted) return;
      final request = api.toDeliveryRequest();
      _cacheMatching(api, request);

      setState(() {
        _apiRequest = api;
        _request = request;
        _matchScore = api.matchScore;
        _tripId = api.tripPublicId.isNotEmpty ? api.tripPublicId : api.tripId;
        _completedAction = _actionFromLoadedState(api, request);
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
        _completedAction =
            _actionFromLoadedState(null, matching.request);
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

  _ParcelOfferAction _actionFromLoadedState(
    SenderTripRequest? api,
    DeliveryRequest request,
  ) {
    if (_completedAction != _ParcelOfferAction.none) return _completedAction;
    if ((api?.status ?? '').trim().toLowerCase() == 'accepted') {
      return _ParcelOfferAction.accepted;
    }
    final bid = StaticData.travelerBidForRequest(request.id) ??
        StaticData.travelerBidForRequest(widget.requestId);
    if (bid == null) return _ParcelOfferAction.none;

    // Accept Offer creates a pending counter-offer row at the sender max budget.
    // A revised offer is marked "updated" and is always a counter-offer path.
    if (bid.status == TravelerBidStatus.updated) {
      return _ParcelOfferAction.countered;
    }
    final acceptedAtMaxBudget =
        (bid.amount - request.maxBudget).abs() < 0.005 &&
            bid.status == TravelerBidStatus.pending;
    if (acceptedAtMaxBudget) {
      return _ParcelOfferAction.accepted;
    }
    return _ParcelOfferAction.countered;
  }

  TravelerBid? _existingBid() {
    final request = _request;
    if (request == null) return null;
    return StaticData.travelerBidForRequest(request.id) ??
        StaticData.travelerBidForRequest(widget.requestId);
  }

  Future<void> _submitBid(double amount, {bool acceptedOffer = false}) async {
    final request = _request;
    if (request == null || _busy) return;

    setState(() => _busy = true);

    try {
      final offer = acceptedOffer
          ? await _repo().acceptSenderRequest(widget.requestId)
          : await _repo().sendCounterOffer(
              requestId: widget.requestId,
              amount: amount,
            );
      if (!mounted) return;
      StaticData.upsertTravelerBid(offer);
      _markActionComplete(acceptedOffer);
      FocusScope.of(context).unfocus();
      await context.push(
        '/bid-submitted',
        extra: {
          'route': request.route,
          'price': amount,
          'tripId': _tripId,
        },
      );
      if (mounted) setState(() => _busy = false);
      return;
    } on ApiException catch (e) {
      if (!mounted) return;
      if (e.code != 'DEMO_MODE') {
        setState(() => _busy = false);
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
      acceptedOffer: acceptedOffer,
    );
    if (!mounted) return;
    if (error != null) {
      setState(() => _busy = false);
      AppToast.error(context, error);
      return;
    }

    _markActionComplete(acceptedOffer);
    FocusScope.of(context).unfocus();
    await context.push(
      '/bid-submitted',
      extra: {
        'route': request.route,
        'price': amount,
        'tripId': _tripId,
      },
    );
    if (mounted) setState(() => _busy = false);
  }

  void _markActionComplete(bool acceptedOffer) {
    setState(() {
      _busy = false;
      _completedAction = acceptedOffer
          ? _ParcelOfferAction.accepted
          : _ParcelOfferAction.countered;
    });
  }

  Future<void> _acceptOffer() async {
    final request = _request;
    if (request == null) return;
    if (_busy || _completedAction != _ParcelOfferAction.none) return;
    await _submitBid(request.maxBudget, acceptedOffer: true);
  }

  Future<void> _onSendCounterOfferTap() async {
    if (_busy || _completedAction == _ParcelOfferAction.accepted) return;
    final sent = await context.push<bool>(
      '/request/${widget.requestId}/counter-offer',
    );
    if (!mounted || sent != true) return;
    setState(() => _completedAction = _ParcelOfferAction.countered);
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
    final existingBid = _existingBid();
    final acceptedOffer = _completedAction == _ParcelOfferAction.accepted;
    final sentCounter = _completedAction == _ParcelOfferAction.countered;
    // Mutual exclusivity: Accept disables Counter; Counter disables Accept.
    final canAcceptOffer =
        !_busy && _completedAction == _ParcelOfferAction.none;
    final canSendCounterOffer = !_busy && !acceptedOffer;

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
                      if (acceptedOffer || sentCounter || existingBid != null) ...[
                        const SizedBox(height: 12),
                        Text(
                          acceptedOffer
                              ? 'You accepted this offer. Send Counter Offer is disabled.'
                              : sentCounter
                                  ? 'Your counter offer was sent. Accept Offer is disabled.'
                                  : existingBid!.isAccepted
                                      ? 'This offer was already accepted. Counter offers are closed.'
                                      : 'Your offer is ${existingBid.status.label}. You can still send an updated counter offer.',
                          style: typo.sm.copyWith(
                            color: acceptedOffer ||
                                    sentCounter ||
                                    existingBid?.isAccepted == true
                                ? AppColors.danger
                                : AppColors.textSecondary,
                          ),
                        ),
                      ],
                      const SizedBox(height: 16),
                      AppButton(
                        label: acceptedOffer ? 'Offer Accepted' : 'Accept Offer',
                        onPressed: canAcceptOffer ? _acceptOffer : null,
                      ),
                      const SizedBox(height: AppButton.stackGap),
                      AppButton(
                        label: acceptedOffer
                            ? 'Send Counter Offer'
                            : sentCounter
                                ? 'Update Counter Offer'
                                : 'Send Counter Offer',
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
