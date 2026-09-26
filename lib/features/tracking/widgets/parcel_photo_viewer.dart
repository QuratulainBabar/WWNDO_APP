import 'package:flutter/material.dart';

import '../../../core/config/api_config.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';

/// Parcel photo thumbnails with full-screen viewer.
class ParcelPhotoViewer extends StatelessWidget {
  const ParcelPhotoViewer({
    super.key,
    this.photoUrls = const [],
    this.title = 'Parcel photos',
  });

  final List<String> photoUrls;
  final String title;

  List<String> get _resolvedUrls {
    if (photoUrls.isNotEmpty) {
      return photoUrls
          .map(ApiConfig.resolveUploadUrl)
          .where((u) => u.isNotEmpty)
          .toList();
    }
    return const [];
  }

  @override
  Widget build(BuildContext context) {
    final typo = context.typo;
    final urls = _resolvedUrls;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (title.trim().isNotEmpty) ...[
          Text(title, style: typo.h3.copyWith(fontWeight: FontWeight.w700)),
          const SizedBox(height: 12),
        ],
        if (urls.isEmpty)
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
                Icon(Icons.image_outlined, size: 20, color: AppColors.textSecondary),
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
              for (var i = 0; i < urls.length; i++)
                GestureDetector(
                  onTap: () => _openViewer(context, urls: urls, initialIndex: i),
                  child: _NetworkThumbnail(url: urls[i], index: i + 1),
                ),
            ],
          ),
      ],
    );
  }

  void _openViewer(
    BuildContext context, {
    required List<String> urls,
    required int initialIndex,
  }) {
    showDialog<void>(
      context: context,
      barrierColor: Colors.black87,
      builder: (context) => _ParcelPhotoViewerDialog(
        urls: urls,
        initialIndex: initialIndex,
      ),
    );
  }
}

class _NetworkThumbnail extends StatelessWidget {
  const _NetworkThumbnail({required this.url, required this.index});

  final String url;
  final int index;

  @override
  Widget build(BuildContext context) {
    final typo = context.typo;
    return ClipRRect(
      borderRadius: BorderRadius.circular(12),
      child: Container(
        width: 96,
        height: 96,
        decoration: BoxDecoration(
          color: AppColors.primary.withValues(alpha: 0.08),
          border: Border.all(color: AppColors.border, width: 1.5),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Stack(
          fit: StackFit.expand,
          children: [
            Image.network(
              url,
              fit: BoxFit.cover,
              errorBuilder: (context, error, stackTrace) => Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.broken_image_outlined, size: 28, color: AppColors.textSecondary),
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
              loadingBuilder: (context, child, progress) {
                if (progress == null) return child;
                return const Center(
                  child: SizedBox(
                    width: 22,
                    height: 22,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}

class _ParcelPhotoViewerDialog extends StatefulWidget {
  const _ParcelPhotoViewerDialog({
    required this.urls,
    required this.initialIndex,
  });

  final List<String> urls;
  final int initialIndex;

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
                itemCount: widget.urls.length,
                onPageChanged: (i) => setState(() => _index = i),
                itemBuilder: (context, i) {
                  return Center(
                    child: Container(
                      margin: const EdgeInsets.symmetric(horizontal: 24),
                      constraints: const BoxConstraints(maxHeight: 420),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(16),
                        child: Image.network(
                          widget.urls[i],
                          fit: BoxFit.contain,
                          errorBuilder: (context, error, stackTrace) => Container(
                            color: Colors.white12,
                            alignment: Alignment.center,
                            child: Text(
                              'Could not load photo ${i + 1}',
                              style: typo.body.copyWith(color: Colors.white70),
                            ),
                          ),
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(16),
              child: Text(
                'Photo ${_index + 1} of ${widget.urls.length}',
                style: typo.body.copyWith(color: Colors.white, fontWeight: FontWeight.w600),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
