import 'dart:async';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_typography.dart';
import '../../core/widgets/app_button.dart';
import '../../core/widgets/back_header.dart';
import '../../core/widgets/captured_image_preview.dart';
import '../../core/widgets/front_camera_preview.dart';
import '../../core/widgets/scrollable_form_screen.dart';
import 'kyc_flow_actions.dart';
import 'kyc_flow_data.dart';

class KycSelfieIntroScreen extends StatelessWidget {
  const KycSelfieIntroScreen({super.key, required this.flow});

  final KycFlowData flow;

  @override
  Widget build(BuildContext context) {
    final typo = context.typo;

    return Scaffold(
      backgroundColor: AppColors.surface,
      appBar: const BackHeader(title: 'Selfie check'),
      body: ScrollableFormScreen(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Liveness selfie check', style: typo.h2),
            const SizedBox(height: 8),
            Text(
              'We will guide you through a short liveness check, then ask for a clear selfie to match your ID.',
              style: typo.sm.copyWith(height: 1.5),
            ),
            const SizedBox(height: 24),
            _IntroTip(icon: Icons.wb_sunny_outlined, text: 'Find a well-lit place without strong backlight'),
            const SizedBox(height: 10),
            _IntroTip(icon: Icons.face_retouching_off_outlined, text: 'Remove hats, sunglasses, or face coverings'),
            const SizedBox(height: 10),
            _IntroTip(icon: Icons.center_focus_strong_outlined, text: 'Keep your face centered in the frame'),
            const SizedBox(height: 10),
            _IntroTip(icon: Icons.timelapse_outlined, text: 'The liveness check takes about 15 seconds'),
          ],
        ),
        actions: [
          AppButton(
            label: 'Start liveness check',
            onPressed: () => context.push('/kyc/selfie/liveness', extra: flow),
          ),
        ],
      ),
    );
  }
}

class _IntroTip extends StatelessWidget {
  const _IntroTip({required this.icon, required this.text});

  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.kycBackground,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: [
          Icon(icon, color: AppColors.primary, size: 22),
          const SizedBox(width: 12),
          Expanded(child: Text(text, style: context.typo.sm)),
        ],
      ),
    );
  }
}

class _LivenessStep {
  const _LivenessStep({required this.instruction, required this.hint});

  final String instruction;
  final String hint;
}

class KycLivenessCheckScreen extends StatefulWidget {
  const KycLivenessCheckScreen({super.key, required this.flow});

  final KycFlowData flow;

  @override
  State<KycLivenessCheckScreen> createState() => _KycLivenessCheckScreenState();
}

class _KycLivenessCheckScreenState extends State<KycLivenessCheckScreen> {
  static const _steps = [
    _LivenessStep(instruction: 'Position your face in the circle', hint: 'Hold your phone at eye level'),
    _LivenessStep(instruction: 'Look straight ahead', hint: 'Keep your eyes open and still'),
    _LivenessStep(instruction: 'Slowly turn your head left', hint: 'Move smoothly, not too fast'),
    _LivenessStep(instruction: 'Slowly turn your head right', hint: 'Return to center when done'),
    _LivenessStep(instruction: 'Blink once naturally', hint: 'Almost finished'),
  ];

  int _stepIndex = 0;
  double _stepProgress = 0;
  bool _stepComplete = false;
  bool _allComplete = false;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _startStepTimer();
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void _startStepTimer() {
    _timer?.cancel();
    _stepProgress = 0;
    _stepComplete = false;

    const tick = Duration(milliseconds: 50);
    const stepDuration = Duration(seconds: 2);
    final ticks = stepDuration.inMilliseconds / tick.inMilliseconds;
    var elapsed = 0.0;

    _timer = Timer.periodic(tick, (timer) {
      elapsed += 1;
      final progress = (elapsed / ticks).clamp(0.0, 1.0);
      if (!mounted) return;
      setState(() => _stepProgress = progress);

      if (progress >= 1) {
        timer.cancel();
        setState(() => _stepComplete = true);
      }
    });
  }

  void _nextStep() {
    if (!_stepComplete) return;

    if (_stepIndex >= _steps.length - 1) {
      widget.flow.livenessCheckPassed = true;
      setState(() => _allComplete = true);
      return;
    }

    setState(() => _stepIndex += 1);
    _startStepTimer();
  }

  void _continueToCapture() {
    context.push('/kyc/selfie/capture', extra: widget.flow);
  }

  @override
  Widget build(BuildContext context) {
    final typo = context.typo;
    final step = _steps[_stepIndex];

    return Scaffold(
      backgroundColor: AppColors.nfcGradientStart,
      appBar: BackHeader(
        title: 'Liveness check',
        fallbackRoute: '/kyc/selfie',
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 16, 24, 24),
          child: Column(
            children: [
              Text(
                _allComplete ? 'Liveness check passed' : step.instruction,
                style: typo.h2.copyWith(color: Colors.white),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Text(
                _allComplete
                    ? 'Great job. Now take a selfie so we can match it to your ID.'
                    : step.hint,
                textAlign: TextAlign.center,
                style: typo.sm.copyWith(color: Colors.white.withValues(alpha: 0.75), height: 1.5),
              ),
              const SizedBox(height: 8),
              Text(
                _allComplete ? 'Complete' : 'Step ${_stepIndex + 1} of ${_steps.length}',
                style: typo.label.copyWith(color: AppColors.secondary),
              ),
              const SizedBox(height: 24),
              Expanded(
                child: Center(
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      SizedBox(
                        width: 256,
                        height: 256,
                        child: CircularProgressIndicator(
                          value: _allComplete ? 1 : _stepProgress,
                          strokeWidth: 4,
                          color: _allComplete ? AppColors.success : AppColors.secondary,
                          backgroundColor: Colors.white.withValues(alpha: 0.15),
                        ),
                      ),
                      ClipOval(
                        child: SizedBox(
                          width: 240,
                          height: 240,
                          child: _allComplete
                              ? ColoredBox(
                                  color: Colors.black,
                                  child: Center(
                                    child: Icon(
                                      Icons.check_rounded,
                                      size: 72,
                                      color: AppColors.success,
                                    ),
                                  ),
                                )
                              : const FrontCameraPreview(),
                        ),
                      ),
                      Container(
                        width: 240,
                        height: 240,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: _allComplete
                                ? AppColors.success
                                : Colors.white.withValues(alpha: 0.85),
                            width: 2.5,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              if (!_allComplete) ...[
                LinearProgressIndicator(
                  value: (_stepIndex + _stepProgress) / _steps.length,
                  minHeight: 6,
                  borderRadius: BorderRadius.circular(99),
                  color: AppColors.secondary,
                  backgroundColor: Colors.white.withValues(alpha: 0.15),
                ),
                const SizedBox(height: 20),
                AppButton(
                  label: _stepComplete ? 'Next step' : 'Hold still…',
                  onPressed: _stepComplete ? _nextStep : null,
                ),
              ] else ...[
                AppButton(label: 'Take selfie', onPressed: _continueToCapture),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class KycSelfieCaptureScreen extends StatefulWidget {
  const KycSelfieCaptureScreen({super.key, required this.flow});

  final KycFlowData flow;

  @override
  State<KycSelfieCaptureScreen> createState() => _KycSelfieCaptureScreenState();
}

class _KycSelfieCaptureScreenState extends State<KycSelfieCaptureScreen> {
  final _imagePicker = ImagePicker();
  bool _picking = false;

  Future<void> _captureSelfie() async {
    if (_picking) return;

    setState(() => _picking = true);
    try {
      final file = await _imagePicker.pickImage(
        source: ImageSource.camera,
        imageQuality: 90,
        maxWidth: 1600,
        preferredCameraDevice: CameraDevice.front,
      );
      if (!mounted || file == null) return;

      context.push(
        '/kyc/selfie/preview',
        extra: KycSelfiePreviewRouteArgs(flow: widget.flow, imagePath: file.path),
      );
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Could not open camera: $error')),
      );
    } finally {
      if (mounted) setState(() => _picking = false);
    }
  }

  Future<void> _pickFromGallery() async {
    if (_picking) return;

    setState(() => _picking = true);
    try {
      final file = await _imagePicker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 90,
        maxWidth: 1600,
      );
      if (!mounted || file == null) return;

      context.push(
        '/kyc/selfie/preview',
        extra: KycSelfiePreviewRouteArgs(flow: widget.flow, imagePath: file.path),
      );
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Could not pick image: $error')),
      );
    } finally {
      if (mounted) setState(() => _picking = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final typo = context.typo;

    return Scaffold(
      backgroundColor: AppColors.nfcGradientStart,
      appBar: BackHeader(
        title: 'Take selfie',
        fallbackRoute: '/kyc/selfie/liveness',
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 16, 24, 24),
          child: Column(
            children: [
              Text(
                'Take a clear selfie',
                style: typo.h2.copyWith(color: Colors.white),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Text(
                'Center your face in the oval. We will compare this photo with your ID document.',
                textAlign: TextAlign.center,
                style: typo.sm.copyWith(color: Colors.white.withValues(alpha: 0.75), height: 1.5),
              ),
              const SizedBox(height: 24),
              Expanded(
                child: Center(
                  child: Container(
                    width: 220,
                    height: 280,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white.withValues(alpha: 0.85), width: 2.5),
                    ),
                    child: Center(
                      child: Icon(
                        Icons.face_rounded,
                        size: 72,
                        color: Colors.white.withValues(alpha: 0.35),
                      ),
                    ),
                  ),
                ),
              ),
              AppButton(
                label: _picking ? 'Opening camera…' : 'Take selfie',
                onPressed: _picking ? null : _captureSelfie,
              ),
              const SizedBox(height: AppButton.stackGap),
              AppButton(
                label: 'Choose from gallery',
                variant: AppButtonVariant.outlineWhite,
                onPressed: _picking ? null : _pickFromGallery,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class KycSelfiePreviewScreen extends StatelessWidget {
  const KycSelfiePreviewScreen({
    super.key,
    required this.flow,
    required this.imagePath,
  });

  final KycFlowData flow;
  final String imagePath;

  void _confirm(BuildContext context) {
    flow.selfieImagePath = imagePath;
    context.push('/kyc/selfie/processing', extra: flow);
  }

  @override
  Widget build(BuildContext context) {
    final typo = context.typo;

    return Scaffold(
      backgroundColor: AppColors.surface,
      appBar: const BackHeader(title: 'Review selfie'),
      body: ScrollableFormScreen(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Does this look like you?', style: typo.h2),
            const SizedBox(height: 8),
            Text(
              'Make sure your full face is visible and matches the photo on your ID.',
              style: typo.sm.copyWith(height: 1.5),
            ),
            const SizedBox(height: 20),
            Center(
              child: CapturedImagePreview(
                path: imagePath,
                fit: BoxFit.cover,
                width: 220,
                height: 220,
                clipOval: true,
              ),
            ),
            const SizedBox(height: 20),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: AppColors.kycBackground,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: AppColors.border),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Before you submit', style: typo.bodyBold),
                  const SizedBox(height: 6),
                  Text('· Your whole face is in frame', style: typo.sm),
                  Text('· Lighting is even on both sides', style: typo.sm),
                  Text('· No filters or heavy editing', style: typo.sm),
                ],
              ),
            ),
          ],
        ),
        actions: [
          AppButton(label: 'Submit selfie', onPressed: () => _confirm(context)),
          AppButton(
            label: 'Retake selfie',
            variant: AppButtonVariant.outline,
            onPressed: () => context.pop(),
          ),
        ],
      ),
    );
  }
}

class KycSelfieProcessingScreen extends StatefulWidget {
  const KycSelfieProcessingScreen({super.key, required this.flow});

  final KycFlowData flow;

  @override
  State<KycSelfieProcessingScreen> createState() => _KycSelfieProcessingScreenState();
}

class _KycSelfieProcessingScreenState extends State<KycSelfieProcessingScreen> {
  static const _messages = [
    'Analyzing liveness signals…',
    'Matching selfie to ID photo…',
    'Verifying identity…',
  ];

  int _messageIndex = 0;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _timer = Timer.periodic(const Duration(milliseconds: 900), (timer) {
      if (!mounted) return;
      if (_messageIndex >= _messages.length - 1) {
        timer.cancel();
        Future.delayed(const Duration(milliseconds: 600), () {
          if (!mounted) return;
          context.pushReplacement('/kyc/selfie/complete', extra: widget.flow);
        });
        return;
      }
      setState(() => _messageIndex += 1);
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final typo = context.typo;

    return Scaffold(
      backgroundColor: AppColors.surface,
      body: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 32),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                const SizedBox(
                  width: 56,
                  height: 56,
                  child: CircularProgressIndicator(strokeWidth: 4),
                ),
                const SizedBox(height: 24),
                Text('Verifying your identity', style: typo.h2, textAlign: TextAlign.center),
                const SizedBox(height: 8),
                Text(
                  _messages[_messageIndex],
                  textAlign: TextAlign.center,
                  style: typo.sm.copyWith(height: 1.5),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class KycSelfieCompleteScreen extends StatelessWidget {
  const KycSelfieCompleteScreen({super.key, required this.flow});

  final KycFlowData flow;

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
              Text('Selfie check complete', style: typo.h1, textAlign: TextAlign.center),
              const SizedBox(height: 8),
              Text(
                'Your liveness check and selfie have been submitted successfully.',
                textAlign: TextAlign.center,
                style: typo.sm.copyWith(height: 1.5),
              ),
              const SizedBox(height: 32),
              AppButton(
                label: 'Finish verification',
                onPressed: () => KycFlowActions.submitForReview(context),
              ),
              const SizedBox(height: AppButton.stackGap),
              AppButton(
                label: 'Back to verification',
                variant: AppButtonVariant.outline,
                onPressed: () => context.go('/kyc', extra: flow),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
