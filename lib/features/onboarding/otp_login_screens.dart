import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../core/api/api_exception.dart';
import '../../core/auth/post_auth_navigation.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_typography.dart';
import '../../core/widgets/app_button.dart';
import '../../core/widgets/app_labeled_field.dart';
import '../../core/widgets/app_toast.dart';
import '../../core/widgets/back_link.dart';
import '../../core/widgets/otp_channel_picker.dart';
import '../../core/widgets/otp_code_field.dart';
import '../../core/widgets/otp_countdown_timer.dart';
import '../../core/widgets/screen_body.dart';
import '../../data/models/otp_channel.dart';
import '../../providers/auth_provider.dart';

class OtpLoginContactScreen extends StatefulWidget {
  const OtpLoginContactScreen({super.key});

  @override
  State<OtpLoginContactScreen> createState() => _OtpLoginContactScreenState();
}

class _OtpLoginContactScreenState extends State<OtpLoginContactScreen> {
  OtpChannel _channel = OtpChannel.email;
  final _contactController = TextEditingController();

  @override
  void dispose() {
    _contactController.dispose();
    super.dispose();
  }

  bool _isValidContact(String value) {
    final trimmed = value.trim();
    if (_channel == OtpChannel.email) {
      return RegExp(r'^[^@]+@[^@]+\.[^@]+$').hasMatch(trimmed);
    }
    return trimmed.replaceAll(RegExp(r'\s'), '').length >= 8;
  }

  Future<void> _sendCode() async {
    final contact = _contactController.text.trim();
    if (!_isValidContact(contact)) {
      AppToast.error(
        context,
        _channel == OtpChannel.email
            ? 'Enter a valid email address'
            : 'Enter a valid phone number',
      );
      return;
    }

    final auth = context.read<AuthProvider>();

    try {
      await auth.sendLoginOtp(contact: contact, channel: _channel);
      if (!mounted) return;
      context.push(
        '/login/otp',
        extra: OtpLoginFlowData(contact: contact, channel: _channel),
      );
    } on ApiException catch (e) {
      if (mounted) AppToast.error(context, e.message);
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final typo = context.typo;

    return Scaffold(
      backgroundColor: AppColors.surface,
      body: ScreenBody(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const BackLink(fallbackRoute: '/login'),
            const SizedBox(height: 12),
            Text('Log in with OTP', style: typo.h1),
            const SizedBox(height: 8),
            Text(
              'Choose SMS, WhatsApp, or Email. Codes expire in 5 minutes.',
              style: typo.sm.copyWith(height: 1.5),
            ),
            const SizedBox(height: 20),
            Text('DELIVERY CHANNEL', style: typo.label.copyWith(fontWeight: FontWeight.w700)),
            const SizedBox(height: 8),
            OtpChannelPicker(
              selected: _channel,
              onChanged: (c) => setState(() {
                _channel = c;
                _contactController.clear();
              }),
            ),
            const SizedBox(height: 8),
            OtpChannelLegend(channel: _channel),
            const SizedBox(height: 16),
            AppLabeledField(
              label: _channel == OtpChannel.email ? 'Email' : 'Phone number',
              padding: const EdgeInsets.only(top: AppFieldSpacing.top),
              child: TextField(
                controller: _contactController,
                keyboardType: _channel == OtpChannel.email
                    ? TextInputType.emailAddress
                    : TextInputType.phone,
                style: typo.input,
                decoration: InputDecoration(
                  hintText: _channel == OtpChannel.email ? 'you@email.com' : '+33 612 345 678',
                ),
              ),
            ),
            const SizedBox(height: 24),
            AppButton(
              label: auth.loading ? 'Sending…' : 'Send verification code',
              onPressed: auth.loading ? null : _sendCode,
            ),
          ],
        ),
      ),
    );
  }
}

class OtpLoginFlowData {
  const OtpLoginFlowData({required this.contact, required this.channel});

  final String contact;
  final OtpChannel channel;

  String get maskedContact {
    if (channel == OtpChannel.email) {
      final parts = contact.split('@');
      if (parts.length != 2) return contact;
      final name = parts[0];
      final masked = name.length <= 2 ? '**' : '${name.substring(0, 2)}***';
      return '$masked@${parts[1]}';
    }
    if (contact.length < 6) return contact;
    return '${contact.substring(0, contact.length - 4).replaceAll(RegExp(r'.'), '•')}${contact.substring(contact.length - 4)}';
  }
}

class OtpLoginVerifyScreen extends StatefulWidget {
  const OtpLoginVerifyScreen({super.key, required this.flow});

  final OtpLoginFlowData flow;

  @override
  State<OtpLoginVerifyScreen> createState() => _OtpLoginVerifyScreenState();
}

class _OtpLoginVerifyScreenState extends State<OtpLoginVerifyScreen> {
  final _otpController = TextEditingController();
  final _focusNode = FocusNode();
  final _timerKey = GlobalKey<OtpCountdownTimerState>();

  @override
  void dispose() {
    _otpController.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  Future<void> _verify() async {
    final code = _otpController.text.trim();
    if (code.length != 6) {
      AppToast.error(context, 'Enter the 6-digit code');
      return;
    }

    final auth = context.read<AuthProvider>();

    try {
      final user = await auth.verifyLoginOtp(
        contact: widget.flow.contact,
        channel: widget.flow.channel,
        code: code,
      );
      if (!mounted) return;

      if (user.accountStatus == 'suspended') {
        context.go('/account-suspended');
      } else {
        await PostAuthNavigation.continueAfterAuth(
          context,
          requireVerification: false,
        );
      }
    } on ApiException catch (e) {
      if (mounted) AppToast.error(context, e.message);
    }
  }

  Future<void> _resend() async {
    final auth = context.read<AuthProvider>();
    try {
      await auth.sendLoginOtp(contact: widget.flow.contact, channel: widget.flow.channel);
      if (mounted) {
        AppToast.success(context, 'A new code was sent');
        _timerKey.currentState?.restart();
      }
    } on ApiException catch (e) {
      if (mounted) AppToast.error(context, e.message);
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final typo = context.typo;

    return Scaffold(
      backgroundColor: AppColors.surface,
      body: ScreenBody(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const BackLink(fallbackRoute: '/login/otp-contact'),
            const SizedBox(height: 12),
            Text('Enter OTP', style: typo.h1),
            const SizedBox(height: 8),
            Text(
              'Code sent via ${widget.flow.channel.label} to ${widget.flow.maskedContact}',
              style: typo.sm.copyWith(height: 1.5),
            ),
            const SizedBox(height: 16),
            OtpCountdownTimer(key: _timerKey),
            const SizedBox(height: 20),
            AppLabeledField(
              label: 'Verification code',
              padding: const EdgeInsets.only(top: AppFieldSpacing.top),
              child: OtpCodeField(
                controller: _otpController,
                focusNode: _focusNode,
                onChanged: (_) {
                  if (_otpController.text.length == 6) _verify();
                },
              ),
            ),
            const SizedBox(height: 24),
            AppButton(
              label: auth.loading ? 'Verifying…' : 'Verify & log in',
              onPressed: auth.loading ? null : _verify,
            ),
            const SizedBox(height: 12),
            Center(
              child: TextButton(
                onPressed: _resend,
                child: Text('Resend code', style: typo.linkBold),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
