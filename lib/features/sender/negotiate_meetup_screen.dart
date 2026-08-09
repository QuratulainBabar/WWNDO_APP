import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../core/config/demo_mode.dart';
import '../../core/layout/responsive.dart';
import '../../core/platform/platform_ui.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_typography.dart';
import '../../core/widgets/app_button.dart';
import '../../core/widgets/app_chip.dart';
import '../../core/widgets/back_header.dart';
import '../../data/models/bid.dart';
import '../../data/services/platform_repository.dart';
import '../../data/static_data.dart';
import '../../providers/auth_provider.dart';

/// Sender proposes a meetup location to negotiate with the traveler.
class NegotiateMeetupScreen extends StatefulWidget {
  const NegotiateMeetupScreen({
    super.key,
    required this.bid,
    this.deliveryPublicId,
  });

  final Bid bid;
  final String? deliveryPublicId;

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
  bool _sending = false;

  String get _deliveryId =>
      widget.deliveryPublicId ?? StaticData.activeShipment.id;

  PlatformRepository _platformRepo() {
    final auth = context.read<AuthProvider>();
    return PlatformRepository(apiClient: auth.repository.apiClient);
  }

  @override
  void initState() {
    super.initState();
    _selected = StaticData.negotiatedMeetupByBidId[widget.bid.id];
    _loadMeetupStatus();
  }

  Future<void> _loadMeetupStatus() async {
    if (context.read<DemoModeProvider>().enabled) return;
    try {
      final status = await _platformRepo().getMeetupStatus(_deliveryId);
      final location = status['location'] as String? ??
          status['meetupLocation'] as String?;
      if (location != null && mounted) {
        setState(() => _selected = location);
      }
    } catch (_) {
      // Non-fatal — user can still propose.
    }
  }

  Future<void> _sendProposal() async {
    if (_selected == null || _sending) return;
    setState(() => _sending = true);
    try {
      final demoMode = context.read<DemoModeProvider>().enabled;
      if (!demoMode) {
        await _platformRepo().proposeMeetup(
          deliveryId: _deliveryId,
          location: _selected!,
        );
      } else {
        StaticData.setNegotiatedMeetup(widget.bid.id, _selected!);
      }
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Meetup proposal sent: $_selected'),
          behavior: SnackBarBehavior.floating,
        ),
      );
      context.pop();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Could not send proposal: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _sending = false);
    }
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
                    (loc) => Padding(
                      padding: const EdgeInsets.only(right: 8, bottom: 8),
                      child: AppChip(
                        label: loc,
                        selected: _selected == loc,
                        onTap: () => setState(() => _selected = loc),
                      ),
                    ),
                  )
                  .toList(),
            ),
            const SizedBox(height: 24),
            AppButton(
              label: _sending ? 'Sending…' : 'Send proposal',
              onPressed: _selected == null || _sending ? null : _sendProposal,
            ),
          ],
        ),
      ),
    );
  }
}
