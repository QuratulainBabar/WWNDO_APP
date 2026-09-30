import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../core/api/api_exception.dart';
import '../../core/auth/post_auth_navigation.dart';
import '../../core/config/api_config.dart';
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
import '../../l10n/app_localizations.dart';

/// Weekly email OTP after password entry, or after biometric session restore.
class PasswordLoginOtpFlowData {
  const PasswordLoginOtpFlowData({
    required this.email,
    required this.password,
    this.alreadySent = false,
  }) : sessionMode = false;

  /// Authenticated path (biometric / session restore) — no password needed.
  const PasswordLoginOtpFlowData.session({
    required this.email,
    this.alreadySent = false,
  })  : password = '',
        sessionMode = true;

  final String email;
  final String password;
  final bool alreadySent;

  /// When true, uses `/auth/login-otp/*` instead of password-otp endpoints.
  final bool sessionMode;

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

/// OTP step for the 7-day login email gate (password + biometric paths).
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

  bool get _sessionMode => widget.flow.sessionMode;

  @override
  void initState() {
    super.initState();
    _sent = widget.flow.alreadySent;
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

  bool get _canSubmit => !_verifying && (_sent || _emailFailed || _isDemoCode);

  Future<void> _continueWithoutOtp() async {
    final auth = context.read<AuthProvider>();
    if (_sessionMode) {
      if (!mounted) return;
      await PostAuthNavigation.continueAfterAuth(
        context,
        offerBiometricSetup: false,
        requireVerification: false,
      );
      return;
    }

    try {
      final result = await auth.login(
        email: widget.flow.email,
        password: widget.flow.password,
      );
      if (!mounted) return;
      if (result.requiresLoginOtp) {
        // Race: window just expired — keep user on this screen and resend.
        await _sendCode(isResend: true);
        return;
      }
      final user = result.user;
      if (user == null) {
        AppToast.error(context, context.tr('Could not complete login. Please try again.'));
        context.go('/login');
        return;
      }
      if (user.accountStatus == 'suspended') {
        context.go('/account-suspended');
        return;
      }
      await PostAuthNavigation.continueAfterAuth(
        context,
        offerBiometricSetup: true,
        requireVerification: false,
      );
    } on ApiException catch (e) {
      if (!mounted) return;
      AppToast.error(context, e.message);
      context.go('/login');
    } catch (_) {
      if (!mounted) return;
      AppToast.error(context, context.tr('Could not complete login. Please try again.'));
      context.go('/login');
    }
  }

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
          _sessionMode
              ? 'LOGIN OTP → ${ApiConfig.authBase}/login-otp/send '
                  '(${widget.flow.maskedContact})'
              : 'LOGIN OTP → ${ApiConfig.authBase}/login/password-otp/send '
                  '(${widget.flow.maskedContact})',
        );
      }
      if (_sessionMode) {
        await auth.sendAuthenticatedLoginOtp(trackLoading: false);
      } else {
        await auth.sendPasswordLoginOtp(
          email: widget.flow.email,
          password: widget.flow.password,
          trackLoading: false,
        );
      }
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
            ? context.l10n.newCodeSentTo(widget.flow.maskedContact)
            : context.tr('Verification code sent to your email'),
      );
    } on ApiException catch (e) {
      if (kDebugMode) {
        debugPrint('LOGIN OTP ← send failed: ${e.code} ${e.message}');
      }
      if (!mounted) return;

      if (e.code == 'LOGIN_OTP_NOT_REQUIRED') {
        setState(() => _sending = false);
        await _continueWithoutOtp();
        return;
      }

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
          context.l10n.emailDelayedBackupCode(OtpService.demoOtpCode),
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
        context.l10n.emailDelayedBackupCode(OtpService.demoOtpCode),
      );
    }
  }

  Future<void> _verify() async {
    final code = _otpController.text.trim();
    if (code.length != 6) {
      AppToast.error(context, context.tr('Enter the 6-digit code'));
      return;
    }

    final usingDemo = code == OtpService.demoOtpCode;
    if (!_sent && !usingDemo && !_emailFailed) {
      AppToast.error(context, context.tr('Wait for the verification code to be sent'));
      return;
    }
    if (_expired && !usingDemo) {
      AppToast.error(context, context.tr('Code expired. Tap Resend code to get a new one.'));
      return;
    }

    setState(() => _verifying = true);
    final auth = context.read<AuthProvider>();

    try {
      if (kDebugMode) {
        debugPrint(
          _sessionMode
              ? 'LOGIN OTP → ${ApiConfig.authBase}/login-otp/verify'
              : 'LOGIN OTP → ${ApiConfig.authBase}/login/password-otp/verify',
        );
      }

      final user = _sessionMode
          ? await auth.verifyAuthenticatedLoginOtp(code: code)
          : await auth.completePasswordLoginOtp(
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
          offerBiometricSetup: !_sessionMode,
          requireVerification: false,
        );
      }
    } on ApiException catch (e) {
      if (kDebugMode) {
        debugPrint('LOGIN OTP ← verify failed: ${e.code} ${e.message}');
      }
      if (!mounted) return;
      if (e.code == 'LOGIN_OTP_NOT_REQUIRED') {
        await _continueWithoutOtp();
        return;
      }
      AppToast.error(context, e.message);
    } catch (e) {
      if (kDebugMode) debugPrint('LOGIN OTP ← verify error: $e');
      if (mounted) {
        AppToast.error(context, context.tr('Could not verify code. Please try again.'));
      }
    } finally {
      if (mounted) setState(() => _verifying = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final typo = context.typo;
    final busy = _verifying;
    final backRoute = _sessionMode ? '/biometric/login' : '/login';

    final l10n = context.l10n;
    final contact = widget.flow.maskedContact;
    final backupCode = OtpService.demoOtpCode;
    String subtitle;
    if (_emailFailed) {
      subtitle = l10n.otpSubtitleFailed(contact, backupCode);
    } else if (_sent) {
      subtitle = l10n.otpSubtitleSent(contact, backupCode);
    } else {
      subtitle = l10n.otpSubtitleSending(contact, backupCode);
    }

    return Scaffold(
      backgroundColor: AppColors.surface,
      resizeToAvoidBottomInset: true,
      body: ScreenBody(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            BackLink(fallbackRoute: backRoute),
            const SizedBox(height: 12),
            Text(context.tr('Verify code'), style: typo.h1),
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
              label: context.tr('Verification code'),
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
                  ? context.tr('Verifying…')
                  : _sending && !_sent
                      ? context.tr('Sending…')
                      : context.tr('Submit'),
              onPressed: busy || !_canSubmit ? null : _verify,
            ),
            const SizedBox(height: 12),
            Center(
              child: TextButton(
                onPressed: busy || _sending
                    ? null
                    : () => _sendCode(isResend: true),
                child: Text(
                  _sending ? context.tr('Sending…') : context.tr('Resend code'),
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
