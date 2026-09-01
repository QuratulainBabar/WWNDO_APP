import 'package:flutter/material.dart';

import '../../core/layout/responsive.dart';
import '../../core/platform/platform_ui.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_typography.dart';
import '../../core/widgets/back_header.dart';
import '../../data/models/bid.dart';
import '../../data/static_data.dart';
import '../shared/meetup_agreement_card.dart';

/// Sender proposes and confirms meetup location with the selected traveler.
class NegotiateMeetupScreen extends StatelessWidget {
  const NegotiateMeetupScreen({
    super.key,
    required this.bid,
    this.deliveryPublicId,
  });

  final Bid bid;
  final String? deliveryPublicId;

  String get _deliveryId =>
      deliveryPublicId ?? StaticData.activeShipment.id;

  @override
  Widget build(BuildContext context) {
    final typo = context.typo;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: const BackHeader(title: 'Meetup location'),
      body: SingleChildScrollView(
        physics: PlatformUi.scrollPhysics,
        padding: context.pagePadding,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Agree on a public meetup spot with ${bid.travelerName}.',
              style: typo.body,
            ),
            const SizedBox(height: 8),
            Text(
              'Both sender and traveler must confirm before NFC handoff.',
              style: typo.sm.copyWith(color: AppColors.textSecondary),
            ),
            const SizedBox(height: 16),
            MeetupAgreementCard(
              deliveryId: _deliveryId,
              allowPropose: true,
              onUpdated: () {},
            ),
          ],
        ),
      ),
    );
  }
}
