import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../core/auth/post_auth_navigation.dart';
import '../../core/config/demo_mode.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_typography.dart';
import '../../core/widgets/app_button.dart';
import '../../core/widgets/app_card.dart';
import '../../core/widgets/app_toast.dart';
import '../../core/widgets/back_link.dart';
import '../../data/models/kyc_models.dart';
import '../../providers/auth_provider.dart';
import '../../providers/kyc_provider.dart';
import 'kyc_flow_actions.dart';
import 'kyc_flow_data.dart';

class KycVerificationScreen extends StatefulWidget {
  const KycVerificationScreen({super.key, this.initialFlow});

  final KycFlowData? initialFlow;

  @override
  State<KycVerificationScreen> createState() => _KycVerificationScreenState();
}

class _KycVerificationScreenState extends State<KycVerificationScreen> {
  late KycFlowData _flow;
  bool _demoMode = false;
  String? _notice;

  @override
  void initState() {
    super.initState();
    _flow = widget.initialFlow ?? KycFlowData();
    _demoMode = _flow.isDemoVerification;
    WidgetsBinding.instance.addPostFrameCallback((_) => _loadStatus());
  }

  Future<void> _loadStatus() async {
    if (!mounted) return;
    final demoMode = context.read<DemoModeProvider>().enabled;
    if (demoMode) return;
    try {
      await context.read<KycProvider>().refreshStatus(sync: true, silent: true);
    } catch (_) {}
  }

  void _openIdDocumentFlow() {
    if (_demoMode) {
      setState(() {
        _flow.applyDemoIdDocument();
        _notice = null;
      });
      return;
    }

    context.push('/kyc/id-document', extra: _flow).then((_) {
      if (mounted) setState(() {});
    });
  }

  void _openSelfieFlow() {
    if (!_flow.idDocumentComplete && !_demoMode) {
      setState(() => _notice = 'Complete your ID document step first.');
      return;
    }

    if (_demoMode) {
      if (!_flow.idDocumentComplete) {
        _flow.applyDemoIdDocument();
      }
      setState(() {
        _flow.applyDemoSelfie();
        _notice = null;
      });
      return;
    }

    if (!_flow.idDocumentComplete) {
      setState(() => _notice = 'Complete your ID document step first.');
      return;
    }

    context.push('/kyc/selfie', extra: _flow).then((_) {
      if (mounted) setState(() {});
    });
  }

  Future<void> _verifyIdentity() async {
    final appDemo = context.read<DemoModeProvider>().enabled;

    if (appDemo || _demoMode) {
      if (!_flow.verificationComplete) {
        setState(() => _flow.applyDemoVerification());
      }
      await KycFlowActions.submitForReview(context);
      return;
    }

    setState(() => _notice = null);
    await KycFlowActions.startSumsubVerification(context);
  }

  Future<void> _startLegacyCaptureFlow() async {
    if (!_flow.idDocumentComplete) {
      _openIdDocumentFlow();
      return;
    }
    if (!_flow.selfieComplete) {
      _openSelfieFlow();
      return;
    }
    await KycFlowActions.submitForReview(context);
  }

  Future<void> _completeDemoVerification() async {
    setState(() {
      _demoMode = true;
      _flow.applyDemoVerification();
    });
    await KycFlowActions.submitForReview(context);
  }

  @override
  Widget build(BuildContext context) {
    final typo = context.typo;
    final kyc = context.watch<KycProvider>();
    final authUser = context.watch<AuthProvider>().user;
    final status = kyc.lastStatus?.kycStatus ??
        KycStatusValue.fromString(authUser?.kycStatus);
    final appDemo = context.watch<DemoModeProvider>().enabled;
    final useSumsub = !appDemo && !_demoMode;

    return Scaffold(
      backgroundColor: AppColors.surface,
      body: SafeArea(
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const BackLink(fallbackRoute: '/login'),
                    const SizedBox(height: 12),
                    Text(
                      'Identity Verification',
                      style: typo.headerTitle,
                    ),
                    const SizedBox(height: 2),
                    Text('Powered by Sumsub · your data is secure', style: typo.sm),
                  ],
                ),
              ),
              const Divider(height: 1),
              ColoredBox(
                color: AppColors.kycBackground,
                child: Padding(
                  padding: const EdgeInsets.all(28),
                  child: Column(
                    children: [
                      Container(
                        width: 80,
                        height: 80,
                        decoration: const BoxDecoration(
                          color: AppColors.primary,
                          shape: BoxShape.circle,
                        ),
                        alignment: Alignment.center,
                        child: const Icon(
                          Icons.badge_outlined,
                          size: 44,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 20),
                      Text('Verify your identity', style: typo.h2),
                      const SizedBox(height: 8),
                      Text(
                        useSumsub
                            ? 'Upload a government ID and complete a liveness check securely with Sumsub.'
                            : 'Photograph your government ID and take a quick selfie to unlock all features.',
                        textAlign: TextAlign.center,
                        style: typo.sm.copyWith(height: 1.5),
                      ),
                      const SizedBox(height: 16),
                      _KycStatusChip(status: status),
                      if (useSumsub) ...[
                        const SizedBox(height: 20),
                        AppCard(
                          margin: EdgeInsets.zero,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('What you will do', style: typo.bodyBold),
                              const SizedBox(height: 8),
                              Text(
                                '1. Photograph your passport, ID card, or driving licence\n'
                                '2. Complete a short liveness selfie check\n'
                                '3. Wait for automated review (manual review up to 48 hours)',
                                style: typo.sm.copyWith(height: 1.5),
                              ),
                              if (!kyc.isSdkSupported) ...[
                                const SizedBox(height: 12),
                                Text(
                                  'Sumsub SDK runs on Android and iOS devices only.',
                                  style: typo.sm.copyWith(
                                    color: AppColors.warning,
                                    height: 1.4,
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ),
                      ] else ...[
                        const SizedBox(height: 24),
                        _stepCard(
                          context,
                          emoji: '📷',
                          title: 'Photograph ID document',
                          subtitle: _flow.idDocumentComplete
                              ? (_demoMode && _flow.isDemoVerification
                                  ? 'Demo ${_flow.documentTypeLabel.toLowerCase()} added'
                                  : '${_flow.documentTypeLabel} captured')
                              : _demoMode
                                  ? 'Tap to add demo ID document'
                                  : 'Passport, ID card, or driving licence',
                          completed: _flow.idDocumentComplete,
                          onTap: _openIdDocumentFlow,
                        ),
                        const SizedBox(height: 10),
                        _stepCard(
                          context,
                          emoji: '🤳',
                          title: 'Liveness selfie check',
                          subtitle: _flow.selfieComplete
                              ? (_demoMode && _flow.isDemoVerification
                                  ? 'Demo selfie verified'
                                  : 'Selfie verified')
                              : _demoMode
                                  ? 'Tap to complete demo selfie'
                                  : 'Short video to confirm your identity',
                          completed: _flow.selfieComplete,
                          enabled: _flow.idDocumentComplete || _demoMode,
                          onTap: _openSelfieFlow,
                        ),
                      ],
                      const SizedBox(height: 20),
                      _DemoModeCard(
                        enabled: _demoMode,
                        onChanged: (value) => setState(() => _demoMode = value),
                        onCompleteDemo: _completeDemoVerification,
                      ),
                      const SizedBox(height: 20),
                      if (_notice != null) ...[
                        Text(
                          _notice!,
                          textAlign: TextAlign.center,
                          style: typo.sm.copyWith(color: AppColors.danger, height: 1.5),
                        ),
                        const SizedBox(height: 12),
                      ],
                      if (kyc.error != null && useSumsub) ...[
                        Text(
                          kyc.error!,
                          textAlign: TextAlign.center,
                          style: typo.sm.copyWith(color: AppColors.danger, height: 1.5),
                        ),
                        const SizedBox(height: 12),
                      ],
                      if (kyc.loading)
                        const Padding(
                          padding: EdgeInsets.only(bottom: 16),
                          child: CircularProgressIndicator(),
                        ),
                      AppButton(
                        label: kyc.loading
                            ? 'Opening Sumsub…'
                            : useSumsub
                                ? 'Verify Identity'
                                : (_demoMode
                                    ? 'Start demo verification'
                                    : 'Start verification'),
                        onPressed: kyc.loading
                            ? null
                            : () {
                                if (useSumsub || _demoMode || appDemo) {
                                  _verifyIdentity();
                                } else {
                                  _startLegacyCaptureFlow();
                                }
                              },
                      ),
                      if (useSumsub && status == KycStatusValue.submitted) ...[
                        const SizedBox(height: 12),
                        AppButton(
                          label: 'Refresh status',
                          variant: AppButtonVariant.outline,
                          onPressed: kyc.loading
                              ? null
                              : () async {
                                  try {
                                    await kyc.refreshStatus(sync: true);
                                    if (!context.mounted) return;
                                    AppToast.info(
                                      context,
                                      'Status: ${kyc.statusValue.detailLabel}',
                                    );
                                  } catch (_) {
                                    if (context.mounted) {
                                      AppToast.error(
                                        context,
                                        kyc.error ?? 'Could not refresh KYC status',
                                      );
                                    }
                                  }
                                },
                        ),
                      ],
                      if (appDemo || _demoMode) ...[
                        const SizedBox(height: 12),
                        TextButton(
                          onPressed: () => KycFlowActions.rejectDemo(context),
                          child: Text(
                            'Simulate rejection',
                            style: typo.sm.copyWith(fontWeight: FontWeight.w600),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _stepCard(
    BuildContext context, {
    required String emoji,
    required String title,
    required String subtitle,
    required bool completed,
    bool enabled = true,
    VoidCallback? onTap,
  }) {
    final typo = context.typo;
    final card = AppCard(
      margin: EdgeInsets.zero,
      highlighted: completed,
      child: Row(
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: completed
                  ? AppColors.success.withValues(alpha: 0.12)
                  : AppColors.primary.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            alignment: Alignment.center,
            child: completed
                ? const Icon(Icons.check, size: 16, color: AppColors.success)
                : Text(emoji, style: typo.avatarMd.copyWith(fontWeight: FontWeight.normal)),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: typo.bodyBold.copyWith(fontWeight: FontWeight.w700)),
                Text(
                  subtitle,
                  style: typo.sm.copyWith(
                    color: completed ? AppColors.success : AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          if (enabled)
            Icon(
              completed ? Icons.check_circle : Icons.chevron_right_rounded,
              color: completed ? AppColors.success : AppColors.textSecondary,
            ),
        ],
      ),
    );

    if (onTap == null) {
      return Opacity(
        opacity: enabled ? 1 : 0.55,
        child: card,
      );
    }

    if (!enabled) {
      return Opacity(
        opacity: 0.55,
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: onTap,
            borderRadius: BorderRadius.circular(16),
            child: card,
          ),
        ),
      );
    }

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: card,
      ),
    );
  }
}

class _KycStatusChip extends StatelessWidget {
  const _KycStatusChip({required this.status});

  final KycStatusValue status;

  @override
  Widget build(BuildContext context) {
    final typo = context.typo;
    final (label, color, bg) = switch (status) {
      KycStatusValue.approved => (
          'Approved',
          AppColors.success,
          AppColors.success.withValues(alpha: 0.12),
        ),
      KycStatusValue.rejected => (
          'Rejected',
          AppColors.danger,
          AppColors.danger.withValues(alpha: 0.1),
        ),
      KycStatusValue.submitted => (
          'Pending',
          AppColors.warning,
          AppColors.warning.withValues(alpha: 0.12),
        ),
      KycStatusValue.pending => (
          'Pending',
          AppColors.primary,
          AppColors.primary.withValues(alpha: 0.1),
        ),
    };

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        'Status: $label',
        style: typo.sm.copyWith(color: color, fontWeight: FontWeight.w600),
      ),
    );
  }
}

class _DemoModeCard extends StatelessWidget {
  const _DemoModeCard({
    required this.enabled,
    required this.onChanged,
    required this.onCompleteDemo,
  });

  final bool enabled;
  final ValueChanged<bool> onChanged;
  final VoidCallback onCompleteDemo;

  @override
  Widget build(BuildContext context) {
    final typo = context.typo;

    return AppCard(
      margin: EdgeInsets.zero,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: AppColors.warning.withValues(alpha: 0.12),
                  shape: BoxShape.circle,
                ),
                alignment: Alignment.center,
                child: const Icon(Icons.science_outlined, size: 20, color: AppColors.warning),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Demo mode', style: typo.bodyBold.copyWith(fontWeight: FontWeight.w700)),
                    Text(
                      'Skip camera capture and use sample verification data',
                      style: typo.sm,
                    ),
                  ],
                ),
              ),
              Switch(
                value: enabled,
                onChanged: onChanged,
              ),
            ],
          ),
          if (enabled) ...[
            const SizedBox(height: 12),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.warning.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.warning.withValues(alpha: 0.25)),
              ),
              child: Text(
                'Demo mode is on. Tap each step to fill demo data, or complete everything instantly below.',
                style: typo.sm.copyWith(height: 1.4),
              ),
            ),
            const SizedBox(height: 12),
            AppButton(
              label: 'Complete verification (demo)',
              variant: AppButtonVariant.ghost,
              textStyle: typo.button.copyWith(fontWeight: FontWeight.w700),
              onPressed: onCompleteDemo,
            ),
          ],
        ],
      ),
    );
  }
}

class KycApprovedScreen extends StatelessWidget {
  const KycApprovedScreen({super.key});

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
              Text('Identity verified!', style: typo.h1),
              const SizedBox(height: 8),
              Text(
                'You can now post deliveries and place bids on WWNGO.',
                textAlign: TextAlign.center,
                style: typo.sm.copyWith(height: 1.5),
              ),
              const SizedBox(height: 32),
              AppButton(
                label: 'Continue to app',
                onPressed: () => PostAuthNavigation.continueAfterAuth(
                  context,
                  offerBiometricSetup: false,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class KycRejectedScreen extends StatelessWidget {
  const KycRejectedScreen({super.key});

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
                width: 72,
                height: 72,
                decoration: BoxDecoration(
                  color: AppColors.danger.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                alignment: Alignment.center,
                child: const Icon(Icons.close, size: 34, color: AppColors.danger),
              ),
              const SizedBox(height: 16),
              Text('Verification failed', style: typo.h1),
              const SizedBox(height: 8),
              Text(
                'Your ID could not be verified. Please ensure your document is valid, unexpired, and clearly photographed.',
                textAlign: TextAlign.center,
                style: typo.sm.copyWith(height: 1.5),
              ),
              const SizedBox(height: 20),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.danger.withValues(alpha: 0.06),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: AppColors.danger.withValues(alpha: 0.2)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Possible reasons', style: typo.policyTitle),
                    const SizedBox(height: 6),
                    Text('· Document expired or unreadable', style: typo.sm),
                    Text('· Selfie liveness check failed', style: typo.sm),
                    Text("· Name doesn't match document", style: typo.sm),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              AppButton(
                label: 'Retry verification',
                onPressed: () async {
                  await KycFlowActions.resetForRetry(context);
                  if (context.mounted) context.go('/kyc');
                },
              ),
              const SizedBox(height: 10),
              TextButton(
                onPressed: () => context.push('/contact-support'),
                child: Text('Contact support', style: typo.link),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class KycPendingReviewScreen extends StatefulWidget {
  const KycPendingReviewScreen({super.key});

  @override
  State<KycPendingReviewScreen> createState() => _KycPendingReviewScreenState();
}

class _KycPendingReviewScreenState extends State<KycPendingReviewScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _maybeAutoApproveDemo();
      _refreshLiveStatus();
    });
  }

  Future<void> _refreshLiveStatus() async {
    final demoMode = context.read<DemoModeProvider>().enabled;
    if (demoMode || !mounted) return;
    try {
      final result = await context.read<KycProvider>().refreshStatus(sync: true);
      if (!mounted) return;
      if (result.kycStatus == KycStatusValue.approved) {
        context.go('/kyc-approved');
      } else if (result.kycStatus == KycStatusValue.rejected) {
        context.go('/kyc-rejected');
      }
    } catch (_) {}
  }

  Future<void> _maybeAutoApproveDemo() async {
    final demoMode = context.read<DemoModeProvider>().enabled;
    if (!demoMode || !mounted) return;
    await Future<void>.delayed(const Duration(seconds: 2));
    if (!mounted) return;
    await KycFlowActions.approveDemo(context);
  }

  @override
  Widget build(BuildContext context) {
    final typo = context.typo;
    final demoMode = context.watch<DemoModeProvider>().enabled;
    final kyc = context.watch<KycProvider>();

    return Scaffold(
      backgroundColor: AppColors.surface,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const SizedBox(
                width: 72,
                height: 72,
                child: CircularProgressIndicator(strokeWidth: 3),
              ),
              const SizedBox(height: 24),
              Text('Pending review', style: typo.h1, textAlign: TextAlign.center),
              const SizedBox(height: 8),
              Text(
                'Sumsub is reviewing your documents. Manual review SLA: up to 48 hours.',
                textAlign: TextAlign.center,
                style: typo.sm.copyWith(height: 1.5),
              ),
              if (!demoMode) ...[
                const SizedBox(height: 16),
                Text(
                  'Status: ${kyc.statusValue.label}',
                  textAlign: TextAlign.center,
                  style: typo.smPrimary.copyWith(color: AppColors.primary),
                ),
                const SizedBox(height: 16),
                AppButton(
                  label: kyc.loading ? 'Refreshing…' : 'Refresh status',
                  variant: AppButtonVariant.outline,
                  onPressed: kyc.loading
                      ? null
                      : () => KycFlowActions.refreshAndRoute(context),
                ),
              ],
              if (demoMode) ...[
                const SizedBox(height: 16),
                Text(
                  'Demo mode: auto-approving in a moment…',
                  textAlign: TextAlign.center,
                  style: typo.smPrimary.copyWith(color: AppColors.primary),
                ),
                const SizedBox(height: 16),
                AppButton(
                  label: 'Simulate Sumsub approval',
                  variant: AppButtonVariant.ghost,
                  onPressed: () => KycFlowActions.approveDemo(context),
                ),
              ],
              const SizedBox(height: 24),
              AppButton(
                label: 'I\'ll wait',
                variant: AppButtonVariant.outline,
                onPressed: () => context.go('/role-selection'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class AccountSuspendedScreen extends StatelessWidget {
  const AccountSuspendedScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final typo = context.typo;
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [AppColors.darkNavy, AppColors.darkNavy2],
          ),
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(32),
            child: Column(
              children: [
                Expanded(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        width: 80,
                        height: 80,
                        decoration: BoxDecoration(
                          color: AppColors.danger.withValues(alpha: 0.15),
                          shape: BoxShape.circle,
                          border: Border.all(color: AppColors.danger.withValues(alpha: 0.3), width: 2),
                        ),
                        alignment: Alignment.center,
                        child: Text('🚫', style: typo.avatarLg.copyWith(fontWeight: FontWeight.normal)),
                      ),
                      const SizedBox(height: 20),
                      Text('Account suspended', style: typo.screenTitleDark),
                      const SizedBox(height: 10),
                      Text(
                        "Your account has been permanently\nsuspended due to a violation of\nWWNGO's zero-tolerance fraud policy.",
                        textAlign: TextAlign.center,
                        style: typo.bodyOnDark.copyWith(fontSize: 15),
                      ),
                      const SizedBox(height: 28),
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: AppColors.danger.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(color: AppColors.danger.withValues(alpha: 0.3)),
                        ),
                        child: RichText(
                          textAlign: TextAlign.left,
                          text: TextSpan(
                            style: typo.sm.copyWith(color: Colors.white.withValues(alpha: 0.6), height: 1.5),
                            children: [
                              TextSpan(
                                text: 'WWNGO Zero Tolerance Policy',
                                style: typo.sm.copyWith(
                                  color: AppColors.danger,
                                  fontWeight: FontWeight.w700,
                                  height: 1.5,
                                ),
                              ),
                              const TextSpan(
                                text: '\nOne confirmed fraud violation results in a permanent, irrevocable account ban. Your KYC identity has been flagged.',
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 24),
                      TextButton(
                        onPressed: () => context.push('/contact-support'),
                        child: Text(
                          'If you believe this is a mistake, contact legal@wwngo.com',
                          textAlign: TextAlign.center,
                          style: typo.sm.copyWith(fontSize: 15, color: Colors.white.withValues(alpha: 0.4)),
                        ),
                      ),
                    ],
                  ),
                ),
                AppButton(
                  label: 'Return to welcome',
                  variant: AppButtonVariant.outlineWhite,
                  onPressed: () => context.go('/welcome'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
