import 'dart:async';

import 'package:flutter/material.dart';

import '../../l10n/app_localizations.dart';
import '../theme/app_colors.dart';
import '../theme/app_typography.dart';

/// Five-minute OTP validity countdown (Section I).
class OtpCountdownTimer extends StatefulWidget {
  const OtpCountdownTimer({
    super.key,
    this.duration = const Duration(minutes: 5),
    this.onExpired,
  });

  final Duration duration;
  final VoidCallback? onExpired;

  @override
  State<OtpCountdownTimer> createState() => OtpCountdownTimerState();
}

class OtpCountdownTimerState extends State<OtpCountdownTimer> {
  Timer? _timer;
  late Duration _remaining;

  @override
  void initState() {
    super.initState();
    restart();
  }

  void restart() {
    _timer?.cancel();
    _remaining = widget.duration;
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (!mounted) return;
      if (_remaining.inSeconds <= 1) {
        setState(() => _remaining = Duration.zero);
        _timer?.cancel();
        widget.onExpired?.call();
      } else {
        setState(() => _remaining -= const Duration(seconds: 1));
      }
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  bool get isExpired => _remaining == Duration.zero;

  @override
  Widget build(BuildContext context) {
    final typo = context.typo;
    final minutes = _remaining.inMinutes.remainder(60).toString().padLeft(2, '0');
    final seconds = (_remaining.inSeconds % 60).toString().padLeft(2, '0');
    final color = isExpired ? AppColors.danger : AppColors.primary;

    return Row(
      children: [
        Icon(Icons.timer_outlined, size: 18, color: color),
        const SizedBox(width: 6),
        Text(
          isExpired
              ? context.l10n.codeExpired
              : context.l10n.codeExpiresIn('$minutes:$seconds'),
          style: typo.sm.copyWith(color: color, fontWeight: FontWeight.w700),
        ),
      ],
    );
  }
}
