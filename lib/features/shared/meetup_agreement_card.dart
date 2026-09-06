import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/config/demo_mode.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_typography.dart';
import '../../core/widgets/app_badge.dart';
import '../../core/widgets/app_button.dart';
import '../../core/widgets/app_card.dart';
import '../../core/widgets/app_chip.dart';
import '../../core/widgets/app_toast.dart';
import '../../data/services/platform_repository.dart';
import '../../data/static_data.dart';
import '../../providers/auth_provider.dart';

/// Shared sender/traveler meetup agreement UI (propose + dual confirm).
class MeetupAgreementCard extends StatefulWidget {
  const MeetupAgreementCard({
    super.key,
    required this.deliveryId,
    this.allowPropose = false,
    this.onUpdated,
  });

  final String deliveryId;
  final bool allowPropose;
  final VoidCallback? onUpdated;

  @override
  State<MeetupAgreementCard> createState() => _MeetupAgreementCardState();
}

class _MeetupAgreementCardState extends State<MeetupAgreementCard> {
  static const _locations = [
    'Airport',
    'Coffee Shop',
    'Shopping Mall',
    'Bus Station',
    'Train Station',
    'Hotel Lobby',
  ];

  bool _loading = true;
  bool _acting = false;
  String? _location;
  bool _agreedBySender = false;
  bool _agreedByTraveler = false;
  bool _fullyAgreed = false;
  String? _selectedProposal;

  @override
  void initState() {
    super.initState();
    _load();
  }

  PlatformRepository _platformRepo() {
    final auth = context.read<AuthProvider>();
    return PlatformRepository(apiClient: auth.repository.apiClient);
  }

  bool get _hasValidChipSelection =>
      _selectedProposal != null && _locations.contains(_selectedProposal);

  /// Once the traveler accepts, sender cannot propose again.
  bool get _proposeLocked => _agreedByTraveler || _fullyAgreed;

  String? _chipSelectionFromLocation(String? location) {
    if (location == null || location.isEmpty) return null;
    return _locations.contains(location) ? location : null;
  }

  Future<void> _load() async {
    if (widget.deliveryId.isEmpty) {
      setState(() => _loading = false);
      return;
    }

    if (context.read<DemoModeProvider>().enabled) {
      setState(() {
        _location = StaticData.thread1ProposedMeetupLocation;
        _agreedBySender = StaticData.senderLocationAgreementAccepted;
        _agreedByTraveler = StaticData.travelerLocationAgreementAccepted;
        _fullyAgreed = StaticData.locationAgreementConfirmed;
        _selectedProposal = _chipSelectionFromLocation(_location);
        _loading = false;
      });
      return;
    }

    setState(() => _loading = true);
    try {
      final status = await _platformRepo().getMeetupStatus(widget.deliveryId);
      if (!mounted) return;
      setState(() {
        _location = status['location'] as String?;
        _agreedBySender = status['agreedBySender'] == true;
        _agreedByTraveler = status['agreedByTraveler'] == true;
        _fullyAgreed = status['fullyAgreed'] == true;
        // Only pre-select when location is one of the 6 venue chips.
        _selectedProposal = _chipSelectionFromLocation(_location);
        _loading = false;
      });
    } catch (_) {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _propose() async {
    if (_acting || _proposeLocked) return;
    final label = _selectedProposal;
    if (!_hasValidChipSelection || label == null) {
      AppToast.info(context, 'Please select a meetup location first.');
      return;
    }
    setState(() => _acting = true);
    try {
      if (context.read<DemoModeProvider>().enabled) {
        StaticData.setNegotiatedMeetup('demo', label);
        StaticData.acceptThread1LocationAgreement(bySender: true);
      } else {
        await _platformRepo().proposeMeetup(
          deliveryId: widget.deliveryId,
          location: label,
        );
      }
      await _load();
      widget.onUpdated?.call();
      if (!mounted) return;
      AppToast.success(context, 'Meetup location proposed.');
    } catch (e) {
      if (mounted) {
        AppToast.error(context, 'Could not propose meetup: $e');
      }
    } finally {
      if (mounted) setState(() => _acting = false);
    }
  }

  Future<void> _agree({required bool asSender}) async {
    if (_acting || _location == null || _location!.isEmpty) return;
    setState(() => _acting = true);
    try {
      if (context.read<DemoModeProvider>().enabled) {
        StaticData.acceptThread1LocationAgreement(bySender: asSender);
      } else {
        final status = await _platformRepo().agreeMeetup(widget.deliveryId);
        if (!mounted) return;
        final fullyAgreed = status['fullyAgreed'] == true;
        await _load();
        widget.onUpdated?.call();
        if (!mounted) return;
        AppToast.success(
          context,
          fullyAgreed
              ? 'Meetup confirmed — ready for NFC handoff.'
              : 'Your confirmation was recorded. Waiting for the other party.',
        );
        return;
      }
      await _load();
      widget.onUpdated?.call();
      if (!mounted) return;
      AppToast.success(
        context,
        _fullyAgreed
            ? 'Meetup confirmed — ready for NFC handoff.'
            : 'Your confirmation was recorded. Waiting for the other party.',
      );
    } catch (e) {
      if (mounted) {
        AppToast.error(context, 'Could not confirm meetup: $e');
      }
    } finally {
      if (mounted) setState(() => _acting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final typo = context.typo;

    if (_loading) {
      return const AppCard(
        margin: EdgeInsets.zero,
        child: Center(
          child: Padding(
            padding: EdgeInsets.all(16),
            child: SizedBox(
              width: 22,
              height: 22,
              child: CircularProgressIndicator(strokeWidth: 2.5),
            ),
          ),
        ),
      );
    }

    final needsSenderConfirm = widget.allowPropose && !_agreedBySender;
    final needsTravelerConfirm = !widget.allowPropose && !_agreedByTraveler;

    return AppCard(
      margin: EdgeInsets.zero,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  'Meetup location',
                  style: typo.h3.copyWith(fontWeight: FontWeight.w700),
                ),
              ),
              if (_fullyAgreed)
                AppBadge.success('Confirmed')
              else
                AppBadge(
                  label: 'Pending',
                  color: AppColors.warning,
                  backgroundColor: AppColors.warning.withValues(alpha: 0.12),
                  semiBold: true,
                ),
            ],
          ),
          const SizedBox(height: 8),
          if (_location != null && _location!.isNotEmpty) ...[
            Text('Location: $_location', style: typo.sm),
            const SizedBox(height: 8),
          ] else
            Text(
              'Choose a public meetup spot both parties can reach.',
              style: typo.sm.copyWith(color: AppColors.textSecondary),
            ),
          const SizedBox(height: 8),
          _partyRow(context, 'Sender', _agreedBySender),
          const SizedBox(height: 4),
          _partyRow(context, 'Traveler', _agreedByTraveler),
          if (widget.allowPropose) ...[
            const SizedBox(height: 12),
            Wrap(
              children: _locations
                  .map(
                    (loc) => Padding(
                      padding: const EdgeInsets.only(right: 8, bottom: 8),
                      child: AppChip(
                        label: loc,
                        selected: _selectedProposal == loc,
                        onTap: _proposeLocked
                            ? null
                            : () => setState(() => _selectedProposal = loc),
                      ),
                    ),
                  )
                  .toList(),
            ),
            const SizedBox(height: 8),
            AppButton(
              label: _acting ? 'Saving…' : 'Propose location',
              small: true,
              // Keep tappable when no chip is selected so we can show a toast.
              // Disable only while saving or after the traveler has accepted.
              onPressed: _acting || _proposeLocked ? null : _propose,
            ),
          ],
          if (!_fullyAgreed && (needsSenderConfirm || needsTravelerConfirm)) ...[
            const SizedBox(height: 12),
            AppButton(
              label: _acting
                  ? 'Confirming…'
                  : widget.allowPropose
                      ? 'Confirm meetup location'
                      : 'Accept meetup location',
              onPressed: _acting || _location == null || _location!.isEmpty
                  ? null
                  : () => _agree(asSender: widget.allowPropose),
            ),
          ],
          if (_fullyAgreed) ...[
            const SizedBox(height: 8),
            Text(
              'Both parties confirmed. You can proceed to NFC handoff.',
              style: typo.sm.copyWith(
                color: AppColors.success,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _partyRow(BuildContext context, String label, bool agreed) {
    final typo = context.typo;
    return Row(
      children: [
        Icon(
          agreed ? Icons.check_circle_rounded : Icons.radio_button_unchecked,
          size: 18,
          color: agreed ? AppColors.success : AppColors.textSecondary,
        ),
        const SizedBox(width: 8),
        Text(
          '$label: ${agreed ? 'Confirmed' : 'Pending'}',
          style: typo.sm.copyWith(
            fontWeight: FontWeight.w600,
            color: agreed ? AppColors.success : AppColors.textSecondary,
          ),
        ),
      ],
    );
  }
}
