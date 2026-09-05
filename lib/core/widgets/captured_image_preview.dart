import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../theme/app_colors.dart';

/// Displays a camera/gallery capture reliably on Android (including content URIs).
class CapturedImagePreview extends StatefulWidget {
  const CapturedImagePreview({
    super.key,
    required this.path,
    this.fit = BoxFit.cover,
    this.width,
    this.height,
    this.borderRadius,
    this.clipOval = false,
  });

  final String path;
  final BoxFit fit;
  final double? width;
  final double? height;
  final BorderRadius? borderRadius;
  final bool clipOval;

  @override
  State<CapturedImagePreview> createState() => _CapturedImagePreviewState();
}

class _CapturedImagePreviewState extends State<CapturedImagePreview> {
  late Future<Uint8List?> _bytesFuture;

  @override
  void initState() {
    super.initState();
    _bytesFuture = _loadBytes();
  }

  @override
  void didUpdateWidget(covariant CapturedImagePreview oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.path != widget.path) {
      _bytesFuture = _loadBytes();
    }
  }

  Future<Uint8List?> _loadBytes() async {
    try {
      return await XFile(widget.path).readAsBytes();
    } catch (_) {
      return null;
    }
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<Uint8List?>(
      future: _bytesFuture,
      builder: (context, snapshot) {
        Widget image;

        if (snapshot.connectionState != ConnectionState.done) {
          image = Container(
            color: AppColors.background,
            alignment: Alignment.center,
            child: const SizedBox(
              width: 28,
              height: 28,
              child: CircularProgressIndicator(strokeWidth: 2.5),
            ),
          );
        } else if (snapshot.hasData && snapshot.data!.isNotEmpty) {
          image = Image.memory(
            snapshot.data!,
            fit: widget.fit,
            width: widget.width,
            height: widget.height,
            gaplessPlayback: true,
          );
        } else {
          image = Container(
            color: AppColors.background,
            alignment: Alignment.center,
            child: const Icon(Icons.broken_image_outlined, color: AppColors.textSecondary),
          );
        }

        if (widget.clipOval) {
          image = ClipOval(child: image);
        } else if (widget.borderRadius != null) {
          image = ClipRRect(borderRadius: widget.borderRadius!, child: image);
        }

        if (widget.width != null || widget.height != null) {
          image = SizedBox(width: widget.width, height: widget.height, child: image);
        }

        return image;
      },
    );
  }
}
