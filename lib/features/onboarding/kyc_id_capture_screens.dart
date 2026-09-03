import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import '../../core/platform/platform_ui.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_typography.dart';
import '../../core/widgets/app_button.dart';
import '../../core/widgets/app_card.dart';
import '../../core/widgets/app_toast.dart';
import '../../core/widgets/back_header.dart';
import '../../core/widgets/captured_image_preview.dart';
import '../../core/widgets/scrollable_form_screen.dart';
import '../../core/widgets/screen_body.dart';
import 'kyc_flow_data.dart';

class KycDocumentTypeScreen extends StatelessWidget {
  const KycDocumentTypeScreen({super.key, required this.flow});

  final KycFlowData flow;

  void _selectType(BuildContext context, KycDocumentType type) {
    flow
      ..documentType = type
      ..frontImagePath = null
      ..backImagePath = null;
    context.push('/kyc/id-capture', extra: KycCaptureRouteArgs(flow: flow, side: KycCaptureSide.front));
  }

  @override
  Widget build(BuildContext context) {
    final typo = context.typo;

    return Scaffold(
      backgroundColor: AppColors.surface,
      appBar: const BackHeader(title: 'ID document'),
      body: ScreenBody(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Choose your document', style: typo.h2),
            const SizedBox(height: 8),
            Text(
              'Select the government-issued ID you want to verify. Make sure it is valid and not expired.',
              style: typo.sm.copyWith(height: 1.5),
            ),
            const SizedBox(height: 24),
            _DocumentTypeOption(
              emoji: '🛂',
              title: 'Passport',
              subtitle: 'Photo page with your picture and details',
              onTap: () => _selectType(context, KycDocumentType.passport),
            ),
            _DocumentTypeOption(
              emoji: '🪪',
              title: 'National ID card',
              subtitle: 'Front and back required',
              onTap: () => _selectType(context, KycDocumentType.idCard),
            ),
            _DocumentTypeOption(
              emoji: '🚗',
              title: 'Driving licence',
              subtitle: 'Front and back required',
              onTap: () => _selectType(context, KycDocumentType.drivingLicence),
            ),
          ],
        ),
      ),
    );
  }
}

class _DocumentTypeOption extends StatelessWidget {
  const _DocumentTypeOption({
    required this.emoji,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  final String emoji;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final typo = context.typo;

    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(16),
          child: AppCard(
            margin: EdgeInsets.zero,
            child: Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.1),
                    shape: BoxShape.circle,
                  ),
                  alignment: Alignment.center,
                  child: Text(emoji, style: typo.avatarMd.copyWith(fontWeight: FontWeight.normal)),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(title, style: typo.bodyBold.copyWith(fontWeight: FontWeight.w700)),
                      Text(subtitle, style: typo.sm),
                    ],
                  ),
                ),
                const Icon(Icons.chevron_right_rounded, color: AppColors.textSecondary),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class KycDocumentCaptureScreen extends StatefulWidget {
  const KycDocumentCaptureScreen({super.key, required this.flow, required this.side});

  final KycFlowData flow;
  final KycCaptureSide side;

  @override
  State<KycDocumentCaptureScreen> createState() => _KycDocumentCaptureScreenState();
}

class _KycDocumentCaptureScreenState extends State<KycDocumentCaptureScreen> {
  final _imagePicker = ImagePicker();
  bool _picking = false;

  Future<void> _openPicker() async {
    if (_picking) return;

    FocusScope.of(context).unfocus();
    final source = await PlatformUi.showAppBottomSheet<ImageSource>(
      context,
      child: const _CaptureSourceSheet(),
    );
    if (!mounted || source == null) return;

    setState(() => _picking = true);
    try {
      final file = await _imagePicker.pickImage(
        source: source,
        imageQuality: 90,
        maxWidth: 2200,
        preferredCameraDevice: CameraDevice.rear,
      );
      if (!mounted || file == null) return;

      context.push(
        '/kyc/id-preview',
        extra: KycPreviewRouteArgs(
          flow: widget.flow,
          side: widget.side,
          imagePath: file.path,
        ),
      );
    } catch (error) {
      if (!mounted) return;
      AppToast.error(context, 'Could not capture image: $error');
    } finally {
      if (mounted) setState(() => _picking = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final typo = context.typo;
    final flow = widget.flow;
    final side = widget.side;

    return Scaffold(
      backgroundColor: AppColors.nfcGradientStart,
      appBar: BackHeader(
        title: flow.documentTypeLabel,
        fallbackRoute: '/kyc/id-document',
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 16, 24, 24),
          child: Column(
            children: [
              Text(
                flow.sideLabel(side),
                style: typo.h2.copyWith(color: Colors.white),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Text(
                'Place your ${flow.documentTypeLabel.toLowerCase()} inside the frame. Avoid glare and keep all corners visible.',
                textAlign: TextAlign.center,
                style: typo.sm.copyWith(color: Colors.white.withValues(alpha: 0.75), height: 1.5),
              ),
              const SizedBox(height: 24),
              Expanded(
                child: Center(
                  child: AspectRatio(
                    aspectRatio: 1.55,
                    child: Container(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(18),
                        border: Border.all(color: Colors.white.withValues(alpha: 0.85), width: 2),
                      ),
                      child: Stack(
                        children: [
                          Positioned.fill(
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(16),
                              child: ColoredBox(color: Colors.black.withValues(alpha: 0.25)),
                            ),
                          ),
                          ..._cornerGuides(),
                          Center(
                            child: Icon(
                              Icons.document_scanner_outlined,
                              size: 56,
                              color: Colors.white.withValues(alpha: 0.35),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              _TipRow(text: 'Use a plain, well-lit surface'),
              const SizedBox(height: 8),
              _TipRow(text: 'Hold your phone parallel to the document'),
              const SizedBox(height: 8),
              _TipRow(text: 'Make sure text is sharp and readable'),
              const SizedBox(height: 24),
              AppButton(
                label: _picking ? 'Opening camera…' : 'Take photo',
                onPressed: _picking ? null : _openPicker,
              ),
            ],
          ),
        ),
      ),
    );
  }

  List<Widget> _cornerGuides() {
    Widget corner(Alignment alignment) {
      return Align(
        alignment: alignment,
        child: Container(
          width: 28,
          height: 28,
          margin: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            border: Border(
              top: alignment.y < 0 ? const BorderSide(color: AppColors.secondary, width: 3) : BorderSide.none,
              bottom: alignment.y > 0 ? const BorderSide(color: AppColors.secondary, width: 3) : BorderSide.none,
              left: alignment.x < 0 ? const BorderSide(color: AppColors.secondary, width: 3) : BorderSide.none,
              right: alignment.x > 0 ? const BorderSide(color: AppColors.secondary, width: 3) : BorderSide.none,
            ),
          ),
        ),
      );
    }

    return [
      corner(Alignment.topLeft),
      corner(Alignment.topRight),
      corner(Alignment.bottomLeft),
      corner(Alignment.bottomRight),
    ];
  }
}

class _TipRow extends StatelessWidget {
  const _TipRow({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(Icons.check_circle_outline, size: 16, color: Colors.white.withValues(alpha: 0.7)),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            text,
            style: context.typo.sm.copyWith(color: Colors.white.withValues(alpha: 0.75)),
          ),
        ),
      ],
    );
  }
}

class _CaptureSourceSheet extends StatelessWidget {
  const _CaptureSourceSheet();

  @override
  Widget build(BuildContext context) {
    final typo = context.typo;

    return Container(
      decoration: const BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: AppColors.border,
              borderRadius: BorderRadius.circular(99),
            ),
          ),
          const SizedBox(height: 16),
          Text('Capture document', style: typo.h3),
          const SizedBox(height: 16),
          _SourceTile(
            icon: Icons.photo_camera_outlined,
            label: 'Take photo',
            onTap: () => Navigator.pop(context, ImageSource.camera),
          ),
          const SizedBox(height: 8),
          _SourceTile(
            icon: Icons.photo_library_outlined,
            label: 'Choose from gallery',
            onTap: () => Navigator.pop(context, ImageSource.gallery),
          ),
        ],
      ),
    );
  }
}

class _SourceTile extends StatelessWidget {
  const _SourceTile({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.background,
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          child: Row(
            children: [
              Icon(icon, color: AppColors.primary),
              const SizedBox(width: 12),
              Text(
                label,
                style: context.typo.bodyBold.copyWith(fontWeight: FontWeight.w600),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class KycDocumentPreviewScreen extends StatelessWidget {
  const KycDocumentPreviewScreen({
    super.key,
    required this.flow,
    required this.side,
    required this.imagePath,
  });

  final KycFlowData flow;
  final KycCaptureSide side;
  final String imagePath;

  void _retake(BuildContext context) => context.pop();

  void _confirm(BuildContext context) {
    flow.setImagePath(side, imagePath);

    final nextSide = flow.nextCaptureSide;
    if (nextSide != null && nextSide != side) {
      context.pushReplacement(
        '/kyc/id-capture',
        extra: KycCaptureRouteArgs(flow: flow, side: nextSide),
      );
      return;
    }

    context.push('/kyc/id-complete', extra: flow);
  }

  @override
  Widget build(BuildContext context) {
    final typo = context.typo;

    return Scaffold(
      backgroundColor: AppColors.surface,
      appBar: const BackHeader(title: 'Review photo'),
      body: ScrollableFormScreen(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Does this look clear?', style: typo.h2),
            const SizedBox(height: 8),
            Text(
              'Check that your ${flow.documentTypeLabel.toLowerCase()} is fully visible and easy to read.',
              style: typo.sm.copyWith(height: 1.5),
            ),
            const SizedBox(height: 20),
            AspectRatio(
              aspectRatio: 1.55,
              child: CapturedImagePreview(
                path: imagePath,
                fit: BoxFit.cover,
                borderRadius: BorderRadius.circular(16),
              ),
            ),
            const SizedBox(height: 16),
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
                  Text('Before you continue', style: typo.bodyBold),
                  const SizedBox(height: 6),
                  Text('· All four corners are visible', style: typo.sm),
                  Text('· No glare or heavy shadows', style: typo.sm),
                  Text('· Name and document number are readable', style: typo.sm),
                ],
              ),
            ),
          ],
        ),
        actions: [
          AppButton(label: 'Use this photo', onPressed: () => _confirm(context)),
          AppButton(
            label: 'Retake photo',
            variant: AppButtonVariant.outline,
            onPressed: () => _retake(context),
          ),
        ],
      ),
    );
  }
}

class KycIdCompleteScreen extends StatelessWidget {
  const KycIdCompleteScreen({super.key, required this.flow});

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
              Text('ID document captured', style: typo.h1, textAlign: TextAlign.center),
              const SizedBox(height: 8),
              Text(
                'Your ${flow.documentTypeLabel.toLowerCase()} has been saved. Continue verification with a quick selfie check.',
                textAlign: TextAlign.center,
                style: typo.sm.copyWith(height: 1.5),
              ),
              const SizedBox(height: 32),
              AppButton(
                label: 'Continue to selfie check',
                onPressed: () => context.push('/kyc/selfie', extra: flow),
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
