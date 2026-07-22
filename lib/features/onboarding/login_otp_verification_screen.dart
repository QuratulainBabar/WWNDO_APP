import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../core/api/api_exception.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_typography.dart';
import '../../core/widgets/app_button.dart';
import '../../core/widgets/app_labeled_field.dart';
import '../../core/widgets/app_toast.dart';
import '../../core/widgets/back_link.dart';
import '../../core/widgets/otp_code_field.dart';
import '../../core/widgets/otp_countdown_timer.dart';
import '../../core/widgets/screen_body.dart';
import '../../data/static_data.dart';
import '../../providers/auth_provider.dart';

/// Credentials held until OTP is verified on the password login path.
class PasswordLoginOtpFlowData {
  const PasswordLoginOtpFlowData({
    required this.email,
    required this.password,
  });

  final String email;
  final String password;

  String get maskedContact {
    final contact = email.trim();
    if (contact.contains('@')) {
      final parts = contact.split('@');
      if (parts.length != 2) return contact;
      final name = parts[0];
      final masked = name.length <= 2 ? '**' : '${name.substring(0, 2)}***';
      return '$masked@${parts[1]}';
    }
    if (contact.length < 6) return contact;
    return '${contact.substring(0, contact.length - 4).replaceAll(RegExp(r'.'), '•')}'
        '${contact.substring(contact.length - 4)}';
  }
}

/// Frontend-only OTP step after password entry. Auth completes only on success.
class LoginOtpVerificationScreen extends StatefulWidget {
  const LoginOtpVerificationScreen({super.key, required this.flow});

  final PasswordLoginOtpFlowData flow;

  @override
  State<LoginOtpVerificationScreen> createState() =>
      _LoginOtpVerificationScreenState();
}

class _LoginOtpVerificationScreenState extends State<LoginOtpVerificationScreen> {
  final _otpController = TextEditingController();
  final _focusNode = FocusNode();
  final _timerKey = GlobalKey<OtpCountdownTimerState>();
  bool _verifying = false;

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

    // Frontend-only demo OTP — no backend OTP call.
    if (code != StaticData.demoOtpCode) {
      AppToast.error(context, 'Invalid verification code');
      return;
    }

    setState(() => _verifying = true);
    final auth = context.read<AuthProvider>();

    try {
      final user = await auth.login(
        email: widget.flow.email,
        password: widget.flow.password,
      );

      if (!mounted) return;

      if (user.accountStatus == 'suspended') {
        context.go('/account-suspended');
      } else {
        context.go('/role-selection');
      }
    } on ApiException catch (e) {
      if (mounted) AppToast.error(context, e.message);
    } finally {
      if (mounted) setState(() => _verifying = false);
    }
  }

  void _resend() {
    AppToast.success(
      context,
      'A new code was sent. Use ${StaticData.demoOtpCode} to verify.',
    );
    _timerKey.currentState?.restart();
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final typo = context.typo;
    final busy = _verifying || auth.loading;

    return Scaffold(
      backgroundColor: AppColors.surface,
      resizeToAvoidBottomInset: true,
      body: ScreenBody(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const BackLink(fallbackRoute: '/login'),
            const SizedBox(height: 12),
            Text('Verify code', style: typo.h1),
            const SizedBox(height: 8),
            Text(
              'We sent a 6-digit code to ${widget.flow.maskedContact}',
              style: typo.sm.copyWith(height: 1.5),
            ),
            const SizedBox(height: 8),
            Text(
              'Demo mode: use code ${StaticData.demoOtpCode}',
              style: typo.smPrimary.copyWith(color: AppColors.primary),
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
              label: busy ? 'Verifying…' : 'Verify',
              onPressed: busy ? null : _verify,
            ),
            const SizedBox(height: 12),
            Center(
              child: TextButton(
                onPressed: busy ? null : _resend,
                child: Text('Resend code', style: typo.linkBold),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
