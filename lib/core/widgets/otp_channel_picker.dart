import 'package:flutter/material.dart';

import '../../data/models/otp_channel.dart';
import '../theme/app_colors.dart';
import '../theme/app_typography.dart';
import 'app_chip.dart';

class OtpChannelPicker extends StatelessWidget {
  const OtpChannelPicker({
    super.key,
    required this.selected,
    required this.onChanged,
    this.allowed = const [
      OtpChannel.email,
      OtpChannel.sms,
      OtpChannel.whatsapp,
    ],
  });

  final OtpChannel selected;
  final ValueChanged<OtpChannel> onChanged;
  final List<OtpChannel> allowed;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        for (final channel in allowed)
          AppChip(
            label: channel.label,
            selected: selected == channel,
            onTap: () => onChanged(channel),
          ),
      ],
    );
  }
}

class OtpChannelLegend extends StatelessWidget {
  const OtpChannelLegend({super.key, required this.channel});

  final OtpChannel channel;

  @override
  Widget build(BuildContext context) {
    final typo = context.typo;
    final detail = switch (channel) {
      OtpChannel.email => 'Code will be sent to your email inbox.',
      OtpChannel.sms => 'Code will be sent via SMS to your phone.',
      OtpChannel.whatsapp => 'Code will be sent on WhatsApp.',
    };
    return Text(detail, style: typo.sm.copyWith(color: AppColors.textSecondary));
  }
}
