import 'package:flutter/foundation.dart';
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
import '../../core/auth/post_auth_navigation.dart';
import '../../providers/auth_provider.dart';

/// Credentials held until OTP is verified on the password login path.
class PasswordLoginOtpFlowData {
  const PasswordLoginOtpFlowData({
    required this.email,
    required this.password,
    this.alreadySent = false,
  });

  final String email;
  final String password;

  /// True when Login already called `/auth/login/password-otp/send` successfully.
  final bool alreadySent;

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

/// OTP step after password entry. Uses the same backend email OTP APIs as signup.
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
  bool _expired = false;
  late bool _sent;

  @override
  void initState() {
    super.initState();
    _sent = widget.flow.alreadySent;
    // Safety net: if Login did not send (e.g. stale hot reload), send here.
    if (!_sent) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _sendCode(isResend: false));
    }
  }

  @override
  void dispose() {
    _otpController.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  Future<void> _sendCode({required bool isResend}) async {
    final auth = context.read<AuthProvider>();
    try {
      if (kDebugMode) {
        debugPrint(
          'LOGIN OTP → POST /auth/login/password-otp/send '
          '(${widget.flow.maskedContact})',
        );
      }
      await auth.sendPasswordLoginOtp(
        email: widget.flow.email,
        password: widget.flow.password,
      );
      if (!mounted) return;
      _otpController.clear();
      setState(() {
        _sent = true;
        _expired = false;
      });
      _timerKey.currentState?.restart();
      AppToast.success(
        context,
        isResend
            ? 'A new code was sent to ${widget.flow.maskedContact}'
            : 'Verification code sent to your email',
      );
    } on ApiException catch (e) {
      if (kDebugMode) {
        debugPrint('LOGIN OTP ← send failed: ${e.code} ${e.message}');
      }
      if (mounted) AppToast.error(context, e.message);
    } catch (e) {
      if (kDebugMode) debugPrint('LOGIN OTP ← send error: $e');
      if (mounted) {
        AppToast.error(context, 'Unable to send verification email. Please try again.');
      }
    }
  }

  Future<void> _verify() async {
    if (!_sent) {
      AppToast.error(context, 'Wait for the verification code to be sent');
      return;
    }
    if (_expired) {
      AppToast.error(context, 'Code expired. Tap Resend code to get a new one.');
      return;
    }

    final code = _otpController.text.trim();
    if (code.length != 6) {
      AppToast.error(context, 'Enter the 6-digit code');
      return;
    }

    setState(() => _verifying = true);
    final auth = context.read<AuthProvider>();

    try {
      if (kDebugMode) {
        debugPrint('LOGIN OTP → POST /auth/login/password-otp/verify');
      }
      final user = await auth.completePasswordLoginOtp(
        email: widget.flow.email,
        password: widget.flow.password,
        code: code,
      );

      if (!mounted) return;

      if (user.accountStatus == 'suspended') {
        context.go('/account-suspended');
      } else {
        // Login email OTP already proved identity — skip Verify Account screen.
        await PostAuthNavigation.continueAfterAuth(
          context,
          offerBiometricSetup: true,
          requireVerification: false,
        );
      }
    } on ApiException catch (e) {
      if (kDebugMode) {
        debugPrint('LOGIN OTP ← verify failed: ${e.code} ${e.message}');
      }
      if (mounted) AppToast.error(context, e.message);
    } catch (e) {
      if (kDebugMode) debugPrint('LOGIN OTP ← verify error: $e');
      if (mounted) AppToast.error(context, 'Could not verify code. Please try again.');
    } finally {
      if (mounted) setState(() => _verifying = false);
    }
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
              _sent
                  ? 'We sent a 6-digit code to ${widget.flow.maskedContact}'
                  : 'Sending verification code…',
              style: typo.sm.copyWith(height: 1.5),
            ),
            const SizedBox(height: 16),
            if (_sent)
              OtpCountdownTimer(
                key: _timerKey,
                onExpired: () {
                  if (!mounted) return;
                  setState(() => _expired = true);
                  _otpController.clear();
                },
              ),
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
              label: busy ? 'Verifying…' : 'Submit',
              onPressed: busy || !_sent ? null : _verify,
            ),
            const SizedBox(height: 12),
            Center(
              child: TextButton(
                onPressed: busy ? null : () => _sendCode(isResend: true),
                child: Text('Resend code', style: typo.linkBold),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
