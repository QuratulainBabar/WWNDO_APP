import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

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
import '../../data/models/traveler_bid.dart';
import '../../data/static_data.dart';
import '../../providers/auth_provider.dart';

class ParcelRequestDetailScreen extends StatefulWidget {
  const ParcelRequestDetailScreen({super.key, required this.requestId});

  final String requestId;

  @override
  State<ParcelRequestDetailScreen> createState() =>
      _ParcelRequestDetailScreenState();
}

class _ParcelRequestDetailScreenState extends State<ParcelRequestDetailScreen> {
  late final TextEditingController _messageController;

  DeliveryRequest get _request {
    final matching = StaticData.matchingRequestById(widget.requestId);
    return matching?.request ?? StaticData.matchingRequests.first.request;
  }

  int? get _matchScore =>
      StaticData.matchingRequestById(widget.requestId)?.matchScore;

  String get _tripId =>
      StaticData.matchingRequestById(widget.requestId)?.tripId ?? '';

  @override
  void initState() {
    super.initState();
    _messageController = TextEditingController();
  }

  @override
  void dispose() {
    _messageController.dispose();
    super.dispose();
  }

  Future<void> _submitBid(double amount) async {
    final request = _request;
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
    await _submitBid(_request.maxBudget);
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
    final request = _request;
    final matchScore = _matchScore;
    final existingBid = StaticData.travelerBidForRequest(request.id);
    final canAcceptOffer = existingBid == null;
    // Counter-offer stays available so travelers can open the budget screen
    // even when a pending/seed bid already exists. Only block after acceptance.
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
                                  '★ ${request.senderRating}',
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
                      _photoSection(context, request.photoCount),
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
                              : 'You already sent a budget for this request. You can still send a counter offer.',
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

  Widget _photoSection(BuildContext context, int photoCount) {
    final typo = context.typo;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Parcel photos',
          style: typo.sm.copyWith(color: AppColors.textSecondary),
        ),
        const SizedBox(height: 8),
        if (photoCount == 0)
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 18, horizontal: 16),
            decoration: BoxDecoration(
              color: AppColors.background,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.border, width: 1.5),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(
                  Icons.image_outlined,
                  size: 20,
                  color: AppColors.textSecondary,
                ),
                const SizedBox(width: 8),
                Text(
                  'No photos provided',
                  style: typo.sm.copyWith(color: AppColors.textSecondary),
                ),
              ],
            ),
          )
        else
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (var i = 0; i < photoCount; i++)
                _StaticPhotoThumbnail(index: i + 1),
            ],
          ),
      ],
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

class _StaticPhotoThumbnail extends StatelessWidget {
  const _StaticPhotoThumbnail({required this.index});

  final int index;

  static const _tints = [
    AppColors.primary,
    AppColors.success,
    AppColors.warning,
  ];

  @override
  Widget build(BuildContext context) {
    final typo = context.typo;
    final tint = _tints[(index - 1) % _tints.length];

    return Container(
      width: 88,
      height: 88,
      decoration: BoxDecoration(
        color: tint.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border, width: 1.5),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.photo_outlined, size: 28, color: tint),
          const SizedBox(height: 4),
          Text(
            'Photo $index',
            style: typo.sm.copyWith(
              fontSize: 11,
              color: AppColors.textSecondary,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}
