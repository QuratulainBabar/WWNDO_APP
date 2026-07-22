import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../core/layout/responsive.dart';
import '../../core/platform/platform_ui.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_typography.dart';
import '../../core/widgets/app_button.dart';
import '../../core/widgets/app_chip.dart';
import '../../core/widgets/back_header.dart';
import '../../data/models/bid.dart';
import '../../data/static_data.dart';

/// Sender proposes a meetup location to negotiate with the traveler.
class NegotiateMeetupScreen extends StatefulWidget {
  const NegotiateMeetupScreen({super.key, required this.bid});

  final Bid bid;

  @override
  State<NegotiateMeetupScreen> createState() => _NegotiateMeetupScreenState();
}

class _NegotiateMeetupScreenState extends State<NegotiateMeetupScreen> {
  static const _locations = [
    'Airport',
    'Coffee Shop',
    'Shopping Mall',
    'Bus Station',
    'Train Station',
    'Hotel Lobby',
  ];

  late String? _selected;

  @override
  void initState() {
    super.initState();
    _selected = StaticData.negotiatedMeetupByBidId[widget.bid.id];
  }

  void _sendProposal() {
    if (_selected == null) return;
    StaticData.setNegotiatedMeetup(widget.bid.id, _selected!);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Meetup proposal sent: $_selected'),
        behavior: SnackBarBehavior.floating,
      ),
    );
    context.pop();
  }

  @override
  Widget build(BuildContext context) {
    final typo = context.typo;
    final bid = widget.bid;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: const BackHeader(title: 'Negotiate meetup'),
      body: SingleChildScrollView(
        physics: PlatformUi.scrollPhysics,
        padding: context.pagePadding,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Propose a public meetup location with ${bid.travelerName}.',
              style: typo.body,
            ),
            const SizedBox(height: 8),
            Text(
              'Select one place to suggest. You can finalize details in chat after the bid is accepted.',
              style: typo.sm.copyWith(color: AppColors.textSecondary),
            ),
            const SizedBox(height: 16),
            Wrap(
              children: _locations
                  .map(
                    (location) => AppChip(
                      label: location,
                      selected: _selected == location,
                      onTap: () => setState(() => _selected = location),
                    ),
                  )
                  .toList(),
            ),
            const SizedBox(height: 24),
            AppButton(
              label: 'Send meetup proposal',
              onPressed: _selected == null ? null : _sendProposal,
            ),
          ],
        ),
      ),
    );
  }
}
