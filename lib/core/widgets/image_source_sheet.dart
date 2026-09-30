import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../../l10n/app_localizations.dart';
import '../theme/app_colors.dart';
import '../theme/app_typography.dart';

/// Returned when the user taps Cancel on [ImageSourceSheet].
class ImageSourceSheetCancel {
  const ImageSourceSheetCancel();
}

class ImageSourceSheet extends StatelessWidget {
  const ImageSourceSheet({
    super.key,
    required this.title,
    this.subtitle,
    this.showCancel = true,
  });

  final String title;
  final String? subtitle;

  /// When true, shows a Cancel button that pops [ImageSourceSheetCancel].
  final bool showCancel;

  @override
  Widget build(BuildContext context) {
    final typo = context.typo;

    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: const EdgeInsets.fromLTRB(24, 12, 24, 32),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: AppColors.border,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 16),
          Text(context.tr(title), style: typo.headerTitle),
          if (subtitle != null) ...[
            const SizedBox(height: 4),
            Text(context.tr(subtitle!), style: typo.sm),
          ],
          const SizedBox(height: 16),
          _ImageSourceOption(
            icon: Icons.photo_camera_outlined,
            label: context.tr('Take photo'),
            onTap: () => Navigator.pop(context, ImageSource.camera),
          ),
          const SizedBox(height: 8),
          _ImageSourceOption(
            icon: Icons.photo_library_outlined,
            label: context.tr('Choose from gallery'),
            onTap: () => Navigator.pop(context, ImageSource.gallery),
          ),
          if (showCancel) ...[
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: Material(
                color: AppColors.background,
                borderRadius: BorderRadius.circular(28),
                child: InkWell(
                  onTap: () =>
                      Navigator.pop(context, const ImageSourceSheetCancel()),
                  borderRadius: BorderRadius.circular(28),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    child: Text(
                      context.tr('Cancel'),
                      textAlign: TextAlign.center,
                      style: typo.body.copyWith(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textPrimary,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _ImageSourceOption extends StatelessWidget {
  const _ImageSourceOption({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final typo = context.typo;

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
                style: typo.body.copyWith(fontSize: 14, fontWeight: FontWeight.w500),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
