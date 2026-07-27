import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../core/platform/keyboard_utils.dart';
import '../../core/api/api_exception.dart';
import '../../core/auth/post_auth_navigation.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_typography.dart';
import '../../core/widgets/app_button.dart';
import '../../core/widgets/app_card.dart';
import '../../core/widgets/app_labeled_field.dart';
import '../../core/widgets/back_link.dart';
import '../../core/widgets/otp_code_field.dart';
import '../../core/widgets/otp_countdown_timer.dart';
import '../../core/widgets/screen_body.dart';
import '../../core/widgets/scrollable_form_screen.dart';
import '../../core/widgets/app_toast.dart';
import '../../data/models/otp_channel.dart';
import '../../providers/auth_provider.dart';

class AccountVerificationScreen extends StatelessWidget {
  const AccountVerificationScreen({super.key});

  Future<void> _verifyEmail(BuildContext context) async {
    if (!context.mounted) return;
    context.push(
      '/verify-account/otp',
      extra: const CrossVerificationOtpFlow(channel: OtpChannel.email),
    );
  }

  Future<void> _verifyPhone(BuildContext context) async {
    final auth = context.read<AuthProvider>();
    final user = auth.user;
    if (user == null) return;

    if (user.phone.replaceAll(' ', '').isEmpty) {
      final phone = await _promptForPhone(context);
      if (phone == null || !context.mounted) return;
      await auth.updateLinkedPhone(phone);
    }

    if (!context.mounted) return;
    context.push(
      '/verify-account/otp',
      extra: const CrossVerificationOtpFlow(channel: OtpChannel.sms),
    );
  }

  Future<String?> _promptForPhone(BuildContext context) async {
    final controller = TextEditingController();
    final typo = context.typo;

    return showDialog<String>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text('Add phone number', style: typo.h3),
        content: AppLabeledField(
          label: 'Phone',
          child: TextField(
            controller: controller,
            onTapOutside: dismissKeyboardOnTapOutside,
            keyboardType: TextInputType.phone,
            decoration: const InputDecoration(hintText: '+33 612 345 678'),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              final value = controller.text.trim();
              if (value.replaceAll(' ', '').length < 8) return;
              Navigator.of(dialogContext).pop(value);
            },
            child: const Text('Continue'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final typo = context.typo;
    final user = context.watch<AuthProvider>().user;

    if (user == null) {
      return const Scaffold(body: Center(child: Text('Please log in')));
    }

    return Scaffold(
      backgroundColor: AppColors.background,
      body: ScrollableFormScreen(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const BackLink(),
            const SizedBox(height: 40),
            Text('Verify your account', style: typo.h1),
            const SizedBox(height: 8),
            Text(
              'WWNGO requires both email and phone to be verified before you can transact.',
              style: typo.sm.copyWith(height: 1.5),
            ),
            const SizedBox(height: 8),
            Text(
              'Status: ${user.verificationState}',
              style: typo.sm.copyWith(
                color: user.isFullyCrossVerified ? AppColors.success : AppColors.primary,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 20),
            _VerificationCard(
              title: 'Email',
              value: user.email,
              verified: user.emailVerified,
              unverifiedIcon: Icons.mark_email_unread_outlined,
              onVerify: user.emailVerified ? null : () => _verifyEmail(context),
              margin: const EdgeInsets.only(bottom: 14),
            ),
            _VerificationCard(
              title: 'Phone',
              value: user.phone.isEmpty ? 'Not linked yet' : user.phone,
              verified: user.phoneVerified,
              unverifiedIcon: Icons.phone_android_outlined,
              onVerify: user.phoneVerified ? null : () => _verifyPhone(context),
            ),
          ],
        ),
        actions: [
          if (user.isFullyCrossVerified)
            AppButton(
              label: 'Continue',
              onPressed: () => PostAuthNavigation.continueAfterAuth(
                context,
                offerBiometricSetup: true,
                requireVerification: false,
              ),
            )
          else
            AppButton(
              label: 'Sign up',
              onPressed: () => context.push('/register'),
            ),
        ],
      ),
    );
  }
}

class _VerificationCard extends StatelessWidget {
  const _VerificationCard({
    required this.title,
    required this.value,
    required this.verified,
    required this.unverifiedIcon,
    this.onVerify,
    this.margin,
  });

  final String title;
  final String value;
  final bool verified;
  final IconData unverifiedIcon;
  final VoidCallback? onVerify;
  final EdgeInsets? margin;

  @override
  Widget build(BuildContext context) {
    final typo = context.typo;
    return AppCard(
      margin: margin,
      child: Row(
        children: [
          Icon(
            verified ? Icons.verified_rounded : unverifiedIcon,
            color: verified ? AppColors.success : AppColors.primary,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: typo.bodyBold.copyWith(fontWeight: FontWeight.w700)),
                Text(value, style: typo.sm),
              ],
            ),
          ),
          if (!verified && onVerify != null)
            TextButton(onPressed: onVerify, child: const Text('Verify'))
          else if (verified)
            Text('✓', style: typo.h3.copyWith(color: AppColors.success)),
        ],
      ),
    );
  }
}

class CrossVerificationOtpScreen extends StatefulWidget {
  const CrossVerificationOtpScreen({super.key, required this.flow});

  final CrossVerificationOtpFlow flow;

  OtpChannel get channel => flow.channel;

  @override
  State<CrossVerificationOtpScreen> createState() => _CrossVerificationOtpScreenState();
}

class _CrossVerificationOtpScreenState extends State<CrossVerificationOtpScreen> {
  final _otpController = TextEditingController();
  final _focusNode = FocusNode();
  final _timerKey = GlobalKey<OtpCountdownTimerState>();
  bool _sent = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _sendOtp());
  }

  @override
  void dispose() {
    _otpController.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  Future<void> _sendOtp() async {
    final auth = context.read<AuthProvider>();
    try {
      await auth.sendCrossVerificationOtp(channel: widget.channel);
      if (mounted) setState(() => _sent = true);
      _timerKey.currentState?.restart();
    } on ApiException catch (e) {
      if (mounted) AppToast.error(context, e.message);
    }
  }

  Future<void> _navigateAfterSuccess(AuthProvider auth) async {
    if (!mounted) return;

    // After verifying email/phone, continue into the app when fully verified
    // (or when this flow was opened to finish onboarding) — don't bounce back
    // to the Verify Account hub unless more steps remain.
    final user = auth.user;
    if (widget.flow.continueToHomeOnSuccess ||
        (user != null && user.isFullyCrossVerified)) {
      await PostAuthNavigation.continueAfterAuth(
        context,
        offerBiometricSetup: true,
        requireVerification: false,
      );
      return;
    }

    context.go(widget.flow.returnRoute);
  }

  Future<void> _verify() async {
    final code = _otpController.text.trim();
    if (code.length != 6) {
      AppToast.error(context, 'Enter the 6-digit code');
      return;
    }

    final auth = context.read<AuthProvider>();
    try {
      await auth.verifyCrossVerificationOtp(channel: widget.channel, code: code);
      if (!mounted) return;
      AppToast.success(
        context,
        widget.channel == OtpChannel.email
            ? 'Email verified successfully'
            : 'Phone verified successfully',
      );
      await _navigateAfterSuccess(auth);
    } on ApiException catch (e) {
      if (mounted) AppToast.error(context, e.message);
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final typo = context.typo;
    final user = auth.user;
    final contact = widget.channel == OtpChannel.email ? user?.email : user?.phone;

    return Scaffold(
      backgroundColor: AppColors.surface,
      body: ScreenBody(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            BackLink(fallbackRoute: widget.flow.returnRoute),
            const SizedBox(height: 12),
            Text('Verify ${widget.channel.label}', style: typo.h1),
            const SizedBox(height: 8),
            Text(
              _sent
                  ? 'Enter the code sent to $contact'
                  : 'Sending verification code…',
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
              label: auth.loading ? 'Verifying…' : 'Confirm verification',
              onPressed: auth.loading ? null : _verify,
            ),
            const SizedBox(height: 12),
            Center(
              child: TextButton(
                onPressed: _sendOtp,
                child: Text('Resend code', style: typo.linkBold),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
