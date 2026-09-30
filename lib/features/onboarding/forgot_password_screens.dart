import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../core/platform/keyboard_utils.dart';
import '../../core/api/api_exception.dart';
import '../../core/phone/phone_countries.dart';
import '../../core/phone/phone_input_formatters.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_typography.dart';
import '../../core/widgets/app_button.dart';
import '../../core/widgets/app_labeled_field.dart';
import '../../core/widgets/app_toast.dart';
import '../../core/widgets/back_link.dart';
import '../../core/widgets/screen_body.dart';
import '../../core/widgets/otp_channel_picker.dart';
import '../../core/widgets/otp_code_field.dart';
import '../../core/widgets/otp_countdown_timer.dart';
import '../../data/models/otp_channel.dart';
import '../../providers/auth_provider.dart';
import '../../l10n/app_localizations.dart';

/// Passed between forgot-password flow screens.
class ForgotPasswordFlowData {
  const ForgotPasswordFlowData({
    required this.contact,
    required this.channel,
    this.resetToken,
  });

  final String contact;
  final OtpChannel channel;
  final String? resetToken;

  bool get isEmail => channel == OtpChannel.email;

  ForgotPasswordFlowData copyWith({String? resetToken}) {
    return ForgotPasswordFlowData(
      contact: contact,
      channel: channel,
      resetToken: resetToken ?? this.resetToken,
    );
  }

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

class ForgotPasswordScreen extends StatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  State<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen> {
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
    return PhoneCountries.isValidContactPhone(trimmed);
  }

  Future<void> _sendCode() async {
    final contact = _contactController.text.trim();
    if (!_isValidContact(contact)) {
      AppToast.error(
        context,
        _channel == OtpChannel.email
            ? context.tr('Enter a valid email address')
            : context.tr('Enter a valid phone number'),
      );
      return;
    }

    final auth = context.read<AuthProvider>();

    try {
      await auth.sendPasswordResetOtp(contact: contact, channel: _channel);
      if (!mounted) return;

      final flow = ForgotPasswordFlowData(contact: contact, channel: _channel);

      AppToast.success(
        context,
        _channel == OtpChannel.email
            ? context.tr('Code sent to your email')
            : context.tr('Code sent'),
      );
      context.push(
        '/forgot-password/otp',
        extra: flow,
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
      resizeToAvoidBottomInset: true,
      body: ScreenBody(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const BackLink(),
            const SizedBox(height: 12),
            Text(context.tr('Forgot password?'), style: typo.h1),
            const SizedBox(height: 8),
            Text(
              context.tr('Enter your email or phone number and we\'ll send you a verification code.'),
              style: typo.sm.copyWith(height: 1.5),
            ),
            const SizedBox(height: 20),
            Text(
              context.tr('RESET VIA'),
              style: typo.label.copyWith(letterSpacing: 0.5, fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 8),
            OtpChannelPicker(
              selected: _channel,
              onChanged: (c) => setState(() {
                _channel = c;
                _contactController.clear();
              }),
            ),
            const SizedBox(height: 16),
            AppLabeledField(
              label: _channel == OtpChannel.email ? context.tr('Email') : context.tr('Phone number'),
              padding: const EdgeInsets.only(top: AppFieldSpacing.top),
              child: TextField(
                controller: _contactController,
                onTap: ensureSoftKeyboardVisible,
                onTapOutside: dismissKeyboardOnTapOutside,
                keyboardType: _channel == OtpChannel.email
                    ? TextInputType.emailAddress
                    : TextInputType.phone,
                inputFormatters: _channel == OtpChannel.email
                    ? const []
                    : [
                        FilteringTextInputFormatter.allow(RegExp(r'[\d\s+]')),
                        const PhoneDigitLimiter(15, allowPlus: true),
                      ],
                textInputAction: TextInputAction.done,
                onSubmitted: (_) => _sendCode(),
                style: typo.input,
                decoration: InputDecoration(
                  hintText: _channel == OtpChannel.email ? 'you@email.com' : '+33 612 345 678',
                  hintStyle: typo.input.copyWith(color: AppColors.textDisabled),
                ),
              ),
            ),
            const SizedBox(height: 24),
            AppButton(
              label: auth.loading ? context.tr('Sending…') : context.tr('Send verification code'),
              onPressed: auth.loading ? null : _sendCode,
            ),
          ],
        ),
      ),
    );
  }
}

class OtpVerificationScreen extends StatefulWidget {
  const OtpVerificationScreen({super.key, required this.flow});

  final ForgotPasswordFlowData flow;

  @override
  State<OtpVerificationScreen> createState() => _OtpVerificationScreenState();
}

class _OtpVerificationScreenState extends State<OtpVerificationScreen> {
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
      AppToast.error(context, context.tr('Enter the 6-digit code'));
      return;
    }

    final auth = context.read<AuthProvider>();

    try {
      final resetToken = await auth.verifyPasswordResetOtp(
        contact: widget.flow.contact,
        channel: widget.flow.channel,
        code: code,
      );

      if (!mounted) return;

      AppToast.success(context, context.tr('Code verified'));
      context.push(
        '/forgot-password/reset',
        extra: widget.flow.copyWith(resetToken: resetToken),
      );
    } on ApiException catch (e) {
      if (mounted) AppToast.error(context, e.message);
    }
  }

  Future<void> _resendCode() async {
    final auth = context.read<AuthProvider>();

    try {
      await auth.sendPasswordResetOtp(
        contact: widget.flow.contact,
        channel: widget.flow.channel,
      );
      if (mounted) {
        AppToast.success(
          context,
          context.l10n.newCodeSentTo(widget.flow.maskedContact),
        );
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
      resizeToAvoidBottomInset: true,
      body: ScreenBody(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const BackLink(),
            const SizedBox(height: 12),
            Text(context.tr('Verify code'), style: typo.h1),
            const SizedBox(height: 8),
            Text(
              context.l10n.weSentCodeTo(widget.flow.maskedContact),
              style: typo.sm.copyWith(height: 1.5),
            ),
            const SizedBox(height: 16),
            OtpCountdownTimer(key: _timerKey),
            const SizedBox(height: 20),
            AppLabeledField(
              label: context.tr('Verification code'),
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
              label: auth.loading ? context.tr('Verifying…') : context.tr('Verify code'),
              onPressed: auth.loading ? null : _verify,
            ),
            const SizedBox(height: 12),
            Center(
              child: TextButton(
                onPressed: auth.loading ? null : _resendCode,
                child: Text(context.tr('Resend code'), style: typo.linkBold),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class ResetPasswordScreen extends StatefulWidget {
  const ResetPasswordScreen({super.key, required this.flow});

  final ForgotPasswordFlowData flow;

  @override
  State<ResetPasswordScreen> createState() => _ResetPasswordScreenState();
}

class _ResetPasswordScreenState extends State<ResetPasswordScreen> {
  final _passwordController = TextEditingController();
  final _confirmController = TextEditingController();
  bool _obscurePassword = true;
  bool _obscureConfirm = true;

  @override
  void dispose() {
    _passwordController.dispose();
    _confirmController.dispose();
    super.dispose();
  }

  Future<void> _resetPassword() async {
    final password = _passwordController.text;
    final confirm = _confirmController.text;

    if (password.length < 8) {
      AppToast.error(context, context.tr('Password must be at least 8 characters'));
      return;
    }
    if (password != confirm) {
      AppToast.error(context, context.tr('Passwords do not match'));
      return;
    }

    final resetToken = widget.flow.resetToken;
    if (resetToken == null) {
      AppToast.error(context, context.tr('Session expired. Please request a new code.'));
      return;
    }

    final auth = context.read<AuthProvider>();

    try {
      await auth.resetPassword(resetToken: resetToken, password: password);
      if (!mounted) return;
      AppToast.success(context, context.tr('Password reset successfully'));
      context.pushReplacement('/forgot-password/success', extra: widget.flow);
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
      resizeToAvoidBottomInset: true,
      body: ScreenBody(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const BackLink(),
            const SizedBox(height: 12),
            Text(context.tr('Reset password'), style: typo.h1),
            const SizedBox(height: 8),
            Text(
              context.l10n.createNewPasswordFor(widget.flow.maskedContact),
              style: typo.sm.copyWith(height: 1.5),
            ),
            const SizedBox(height: 20),
            AppLabeledField(
              label: context.tr('New password'),
              padding: const EdgeInsets.only(top: AppFieldSpacing.top),
              child: TextField(
                controller: _passwordController,
                onTap: () => ensureSoftKeyboardVisible(retry: true),
                onTapOutside: dismissKeyboardOnTapOutside,
                obscureText: _obscurePassword,
                style: typo.input,
                decoration: InputDecoration(
                  hintText: context.tr('At least 8 characters'),
                  hintStyle: typo.input.copyWith(color: AppColors.textDisabled),
                  suffixIcon: IconButton(
                    icon: Icon(
                      _obscurePassword ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                      color: AppColors.textSecondary,
                    ),
                    onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
                  ),
                ),
              ),
            ),
            AppLabeledField(
              label: context.tr('Confirm password'),
              child: TextField(
                controller: _confirmController,
                onTap: () => ensureSoftKeyboardVisible(retry: true),
                onTapOutside: dismissKeyboardOnTapOutside,
                obscureText: _obscureConfirm,
                textInputAction: TextInputAction.done,
                onSubmitted: (_) => _resetPassword(),
                style: typo.input,
                decoration: InputDecoration(
                  hintText: context.tr('Re-enter your password'),
                  hintStyle: typo.input.copyWith(color: AppColors.textDisabled),
                  suffixIcon: IconButton(
                    icon: Icon(
                      _obscureConfirm ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                      color: AppColors.textSecondary,
                    ),
                    onPressed: () => setState(() => _obscureConfirm = !_obscureConfirm),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 24),
            AppButton(
              label: auth.loading ? context.tr('Updating…') : context.tr('Update password'),
              onPressed: auth.loading ? null : _resetPassword,
            ),
          ],
        ),
      ),
    );
  }
}

class PasswordResetSuccessScreen extends StatelessWidget {
  const PasswordResetSuccessScreen({super.key, required this.flow});

  final ForgotPasswordFlowData flow;

  @override
  Widget build(BuildContext context) {
    final typo = context.typo;

    return Scaffold(
      backgroundColor: AppColors.surface,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  color: AppColors.success.withValues(alpha: 0.12),
                  shape: BoxShape.circle,
                ),
                alignment: Alignment.center,
                child: const Icon(Icons.check, size: 40, color: AppColors.success),
              ),
              const SizedBox(height: 20),
              Text(context.tr('Password updated!'), style: typo.h1, textAlign: TextAlign.center),
              const SizedBox(height: 8),
              Text(
                context.tr('Your password has been reset successfully. You can now log in with your new password.'),
                textAlign: TextAlign.center,
                style: typo.sm.copyWith(height: 1.5),
              ),
              const SizedBox(height: 32),
              AppButton(
                label: context.tr('Back to login'),
                onPressed: () => context.go('/login'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
