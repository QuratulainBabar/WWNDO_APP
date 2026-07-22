import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';

/// Parcel photo thumbnails with full-screen viewer (static demo placeholders).
class ParcelPhotoViewer extends StatelessWidget {
  const ParcelPhotoViewer({
    super.key,
    required this.photoCount,
    this.title = 'Parcel photos',
  });

  final int photoCount;
  final String title;

  static const _tints = [
    AppColors.primary,
    AppColors.success,
    AppColors.warning,
    AppColors.transit,
  ];

  @override
  Widget build(BuildContext context) {
    final typo = context.typo;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: typo.h3.copyWith(fontWeight: FontWeight.w700)),
        const SizedBox(height: 12),
        if (photoCount == 0)
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
            decoration: BoxDecoration(
              color: AppColors.background,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.border, width: 1.5),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.image_outlined, size: 20, color: AppColors.textSecondary),
                const SizedBox(width: 8),
                Text(
                  'No photos uploaded yet',
                  style: typo.sm.copyWith(color: AppColors.textSecondary),
                ),
              ],
            ),
          )
        else
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: [
              for (var i = 0; i < photoCount; i++)
                GestureDetector(
                  onTap: () => _openViewer(context, initialIndex: i),
                  child: _Thumbnail(index: i + 1, tint: _tints[i % _tints.length]),
                ),
            ],
          ),
      ],
    );
  }

  void _openViewer(BuildContext context, {required int initialIndex}) {
    showDialog<void>(
      context: context,
      barrierColor: Colors.black87,
      builder: (context) => _ParcelPhotoViewerDialog(
        photoCount: photoCount,
        initialIndex: initialIndex,
        tints: _tints,
      ),
    );
  }
}

class _Thumbnail extends StatelessWidget {
  const _Thumbnail({required this.index, required this.tint});

  final int index;
  final Color tint;

  @override
  Widget build(BuildContext context) {
    final typo = context.typo;
    return Container(
      width: 96,
      height: 96,
      decoration: BoxDecoration(
        color: tint.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border, width: 1.5),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.photo_outlined, size: 30, color: tint),
          const SizedBox(height: 4),
          Text(
            'Photo $index',
            style: typo.caption.copyWith(
              fontWeight: FontWeight.w600,
              color: AppColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }
}

class _ParcelPhotoViewerDialog extends StatefulWidget {
  const _ParcelPhotoViewerDialog({
    required this.photoCount,
    required this.initialIndex,
    required this.tints,
  });

  final int photoCount;
  final int initialIndex;
  final List<Color> tints;

  @override
  State<_ParcelPhotoViewerDialog> createState() => _ParcelPhotoViewerDialogState();
}

class _ParcelPhotoViewerDialogState extends State<_ParcelPhotoViewerDialog> {
  late final PageController _controller;
  late int _index;

  @override
  void initState() {
    super.initState();
    _index = widget.initialIndex;
    _controller = PageController(initialPage: widget.initialIndex);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final typo = context.typo;
    return Material(
      color: Colors.transparent,
      child: SafeArea(
        child: Column(
          children: [
            Align(
              alignment: Alignment.topRight,
              child: IconButton(
                onPressed: () => Navigator.of(context).pop(),
                icon: const Icon(Icons.close_rounded, color: Colors.white, size: 28),
              ),
            ),
            Expanded(
              child: PageView.builder(
                controller: _controller,
                itemCount: widget.photoCount,
                onPageChanged: (i) => setState(() => _index = i),
                itemBuilder: (context, i) {
                  final tint = widget.tints[i % widget.tints.length];
                  return Center(
                    child: Container(
                      margin: const EdgeInsets.symmetric(horizontal: 24),
                      width: double.infinity,
                      constraints: const BoxConstraints(maxHeight: 360),
                      decoration: BoxDecoration(
                        color: tint.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: Colors.white24),
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.inventory_2_outlined, size: 72, color: tint),
                          const SizedBox(height: 16),
                          Text(
                            'Parcel photo ${i + 1}',
                            style: typo.h3.copyWith(color: Colors.white),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Demo placeholder — uploaded by sender',
                            style: typo.sm.copyWith(color: Colors.white70),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(16),
              child: Text(
                'Photo ${_index + 1} of ${widget.photoCount}',
                style: typo.body.copyWith(color: Colors.white, fontWeight: FontWeight.w600),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
