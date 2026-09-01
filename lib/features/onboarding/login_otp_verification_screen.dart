import 'package:flutter/foundation.dart';
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
import '../../core/widgets/otp_code_field.dart';
import '../../core/widgets/otp_countdown_timer.dart';
import '../../core/widgets/screen_body.dart';
import '../../data/services/otp_service.dart';
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

/// OTP step after password entry. Email is sent in the background; demo OTP
/// (`123456`) always works if the email is delayed or fails.
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
  bool _sending = false;
  bool _expired = false;
  bool _emailFailed = false;
  late bool _sent;

  @override
  void initState() {
    super.initState();
    _sent = widget.flow.alreadySent;
    // Always kick off send from this screen so login can navigate instantly.
    if (!_sent) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _sendCode(isResend: false);
      });
    }
  }

  @override
  void dispose() {
    _otpController.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  bool get _isDemoCode =>
      _otpController.text.trim() == OtpService.demoOtpCode;

  /// User may enter the emailed code or the demo backup code while send runs.
  bool get _canSubmit => !_verifying && (_sent || _emailFailed || _isDemoCode);

  Future<void> _sendCode({required bool isResend}) async {
    if (_sending) return;
    setState(() {
      _sending = true;
      _emailFailed = false;
    });

    final auth = context.read<AuthProvider>();
    try {
      if (kDebugMode) {
        debugPrint(
          'LOGIN OTP → POST /auth/login/password-otp/send '
          '(${widget.flow.maskedContact})',
        );
      }
      // Don't toggle AuthProvider.loading — user can type / use demo OTP meanwhile.
      await auth.sendPasswordLoginOtp(
        email: widget.flow.email,
        password: widget.flow.password,
        trackLoading: false,
      );
      if (!mounted) return;
      if (isResend) _otpController.clear();
      setState(() {
        _sent = true;
        _expired = false;
        _emailFailed = false;
        _sending = false;
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
      if (!mounted) return;

      final invalidCreds = e.code == 'INVALID_CREDENTIALS' ||
          e.code == 'ACCOUNT_SUSPENDED' ||
          e.code == 'ACCOUNT_LOCKED' ||
          e.code == 'CONTACT_MISSING' ||
          e.statusCode == 401;

      if (invalidCreds) {
        setState(() => _sending = false);
        AppToast.error(context, e.message);
        context.go('/login');
        return;
      }

      // Rate limit / SMTP / network: unlock verify with demo OTP backup.
      setState(() {
        _sending = false;
        _sent = true;
        _expired = false;
        _emailFailed = e.code != 'OTP_RATE_LIMITED';
      });
      if (e.code == 'OTP_RATE_LIMITED') {
        AppToast.error(context, e.message);
      } else {
        AppToast.info(
          context,
          'Email is delayed or failed. You can sign in with backup code ${OtpService.demoOtpCode}.',
        );
      }
    } catch (e) {
      if (kDebugMode) debugPrint('LOGIN OTP ← send error: $e');
      if (!mounted) return;
      setState(() {
        _sending = false;
        _sent = true;
        _emailFailed = true;
      });
      AppToast.info(
        context,
        'Email is delayed or failed. You can sign in with backup code ${OtpService.demoOtpCode}.',
      );
    }
  }

  Future<void> _verify() async {
    final code = _otpController.text.trim();
    if (code.length != 6) {
      AppToast.error(context, 'Enter the 6-digit code');
      return;
    }

    final usingDemo = code == OtpService.demoOtpCode;
    if (!_sent && !usingDemo && !_emailFailed) {
      AppToast.error(context, 'Wait for the verification code to be sent');
      return;
    }
    if (_expired && !usingDemo) {
      AppToast.error(context, 'Code expired. Tap Resend code to get a new one.');
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
      if (mounted) {
        AppToast.error(context, 'Could not verify code. Please try again.');
      }
    } finally {
      if (mounted) setState(() => _verifying = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final typo = context.typo;
    final busy = _verifying;

    String subtitle;
    if (_emailFailed) {
      subtitle =
          'We could not deliver email to ${widget.flow.maskedContact} yet. '
          'Enter the email code when it arrives, or use backup code ${OtpService.demoOtpCode}.';
    } else if (_sent) {
      subtitle =
          'We sent a 6-digit code to ${widget.flow.maskedContact}. '
          'If it is delayed, you can use backup code ${OtpService.demoOtpCode}.';
    } else {
      subtitle =
          'Sending a code to ${widget.flow.maskedContact}… '
          'You can keep waiting, or use backup code ${OtpService.demoOtpCode}.';
    }

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
            Text(subtitle, style: typo.sm.copyWith(height: 1.5)),
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
                  setState(() {});
                  if (_otpController.text.length == 6 && _canSubmit) {
                    _verify();
                  }
                },
              ),
            ),
            const SizedBox(height: 24),
            AppButton(
              label: busy
                  ? 'Verifying…'
                  : _sending && !_sent
                      ? 'Sending…'
                      : 'Submit',
              onPressed: busy || !_canSubmit ? null : _verify,
            ),
            const SizedBox(height: 12),
            Center(
              child: TextButton(
                onPressed: busy || _sending
                    ? null
                    : () => _sendCode(isResend: true),
                child: Text(
                  _sending ? 'Sending…' : 'Resend code',
                  style: typo.linkBold,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
