import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../../../core/config/api_config.dart';
import '../../../core/platform/platform_ui.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/widgets/app_labeled_field.dart';
import '../../../core/widgets/app_toast.dart';
import '../../../core/widgets/captured_image_preview.dart';
import '../../../core/widgets/image_source_sheet.dart';
import '../../../l10n/app_localizations.dart';

class ParcelPhotosSection extends StatefulWidget {
  const ParcelPhotosSection({
    super.key,
    required this.photoPaths,
    required this.onChanged,
    this.errorText,
    this.existingPhotos = const [],
    this.onExistingPhotoRemoved,
  });

  final List<String> photoPaths;
  final ValueChanged<List<String>> onChanged;
  final String? errorText;
  final List<({String id, String url})> existingPhotos;
  final ValueChanged<String>? onExistingPhotoRemoved;

  @override
  State<ParcelPhotosSection> createState() => _ParcelPhotosSectionState();
}

class _ParcelPhotosSectionState extends State<ParcelPhotosSection> {
  static const _maxPhotos = 3;
  static const _maxBytes = 10 * 1024 * 1024;

  final ImagePicker _imagePicker = ImagePicker();

  Future<void> _showPhotoSourceSheet() async {
    final remaining = _maxPhotos - widget.existingPhotos.length - widget.photoPaths.length;
    if (remaining <= 0) return;

    FocusScope.of(context).unfocus();
    final result = await PlatformUi.showAppBottomSheet<Object>(
      context,
      child: ImageSourceSheet(
        title: context.l10n.addParcelPhoto,
        subtitle: context.l10n.uploadParcelPhotosShort,
        showCancel: false,
      ),
    );
    if (!mounted || result is! ImageSource) return;

    if (result == ImageSource.gallery) {
      await _pickFromGallery(remaining);
    } else {
      await _pickFromCamera();
    }
  }

  bool _isWithinSizeLimit(String path) {
    try {
      final bytes = File(path).lengthSync();
      return bytes <= _maxBytes;
    } catch (_) {
      return true;
    }
  }

  Future<void> _pickFromGallery(int remaining) async {
    try {
      final images = await _imagePicker.pickMultiImage(
        imageQuality: 85,
        maxWidth: 1920,
        limit: remaining,
      );
      if (!mounted || images.isEmpty) return;

      final next = [...widget.photoPaths];
      for (final image in images.take(remaining)) {
        if (!_isWithinSizeLimit(image.path)) {
          _showSizeError();
          continue;
        }
        next.add(image.path);
      }
      widget.onChanged(next);
    } catch (_) {}
  }

  Future<void> _pickFromCamera() async {
    try {
      final image = await _imagePicker.pickImage(
        source: ImageSource.camera,
        imageQuality: 85,
        maxWidth: 1920,
        preferredCameraDevice: CameraDevice.rear,
      );
      if (!mounted || image == null) return;
      if (!_isWithinSizeLimit(image.path)) {
        _showSizeError();
        return;
      }

      widget.onChanged([...widget.photoPaths, image.path]);
    } catch (_) {}
  }

  void _showSizeError() {
    AppToast.error(context, 'Each image must be 10 MB or smaller.');
  }

  void _removePhoto(int index) {
    final next = [...widget.photoPaths]..removeAt(index);
    widget.onChanged(next);
  }

  @override
  Widget build(BuildContext context) {
    final typo = context.typo;
    final l10n = context.l10n;
    final totalCount = widget.existingPhotos.length + widget.photoPaths.length;
    final canAddMore = totalCount < _maxPhotos;

    return AppLabeledField(
      label: l10n.parcelPhotos,
      labelStyle: typo.inputLabel.copyWith(fontWeight: FontWeight.w600),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            l10n.uploadParcelPhotosHint,
            style: typo.sm.copyWith(color: AppColors.textSecondary),
          ),
          const SizedBox(height: 8),
          Material(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(12),
            child: InkWell(
              onTap: canAddMore ? _showPhotoSourceSheet : null,
              borderRadius: BorderRadius.circular(12),
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 20),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: widget.errorText != null
                        ? AppColors.danger
                        : canAddMore
                            ? AppColors.border
                            : AppColors.textDisabled,
                    width: 1.5,
                  ),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.photo_library_outlined,
                      size: 28,
                      color: canAddMore ? AppColors.primary : AppColors.textDisabled,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      l10n.uploadPhotos,
                      style: typo.body.copyWith(
                        fontWeight: FontWeight.w600,
                        color: canAddMore ? AppColors.textPrimary : AppColors.textDisabled,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(height: 8),
          if (widget.existingPhotos.isEmpty && widget.photoPaths.isEmpty)
            _EmptyPhotosPlaceholder(typo: typo)
          else
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (final photo in widget.existingPhotos)
                  _RemotePhotoThumbnail(
                    url: photo.url,
                    onRemove: widget.onExistingPhotoRemoved == null
                        ? null
                        : () => widget.onExistingPhotoRemoved!(photo.id),
                  ),
                for (var i = 0; i < widget.photoPaths.length; i++)
                  _PhotoThumbnail(
                    path: widget.photoPaths[i],
                    onRemove: () => _removePhoto(i),
                  ),
              ],
            ),
          const SizedBox(height: 8),
          Text(
            'Maximum file size: 10 MB per image.',
            style: typo.sm.copyWith(color: AppColors.textSecondary),
          ),
          if (widget.errorText != null) ...[
            const SizedBox(height: 8),
            Text(widget.errorText!, style: typo.sm.copyWith(color: AppColors.danger)),
          ],
        ],
      ),
    );
  }
}

class _EmptyPhotosPlaceholder extends StatelessWidget {
  const _EmptyPhotosPlaceholder({required this.typo});

  final AppTypography typo;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 18, horizontal: 16),
      decoration: BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border, width: 1.5),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.image_outlined, size: 20, color: AppColors.textSecondary),
          const SizedBox(width: 8),
          Text(
            context.l10n.noPhotosSelectedYet,
            style: typo.sm.copyWith(color: AppColors.textSecondary),
          ),
        ],
      ),
    );
  }
}

class _RemotePhotoThumbnail extends StatelessWidget {
  const _RemotePhotoThumbnail({
    required this.url,
    this.onRemove,
  });

  final String url;
  final VoidCallback? onRemove;

  @override
  Widget build(BuildContext context) {
    final resolved = ApiConfig.resolveUploadUrl(url);
    return Stack(
      clipBehavior: Clip.none,
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: Image.network(
            resolved,
            width: 88,
            height: 88,
            fit: BoxFit.cover,
            errorBuilder: (_, __, ___) => Container(
              width: 88,
              height: 88,
              color: AppColors.background,
              alignment: Alignment.center,
              child: Icon(Icons.image_outlined, color: AppColors.textSecondary),
            ),
          ),
        ),
        if (onRemove != null)
          Positioned(
            top: -6,
            right: -6,
            child: Material(
              color: AppColors.surface,
              shape: CircleBorder(side: BorderSide(color: AppColors.border)),
              child: InkWell(
                onTap: onRemove,
                customBorder: const CircleBorder(),
                child: Padding(
                  padding: EdgeInsets.all(4),
                  child: Icon(Icons.close, size: 16, color: AppColors.textSecondary),
                ),
              ),
            ),
          ),
      ],
    );
  }
}

class _PhotoThumbnail extends StatelessWidget {
  const _PhotoThumbnail({
    required this.path,
    required this.onRemove,
  });

  final String path;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) {
    return Stack(
      clipBehavior: Clip.none,
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: CapturedImagePreview(
            path: path,
            width: 88,
            height: 88,
            fit: BoxFit.cover,
          ),
        ),
        Positioned(
          top: -6,
          right: -6,
          child: Material(
            color: AppColors.surface,
            shape: CircleBorder(side: BorderSide(color: AppColors.border)),
            child: InkWell(
              onTap: onRemove,
              customBorder: const CircleBorder(),
              child: Padding(
                padding: EdgeInsets.all(4),
                child: Icon(Icons.close, size: 16, color: AppColors.textSecondary),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
