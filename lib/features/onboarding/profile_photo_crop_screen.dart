import 'dart:math' as math;
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_typography.dart';

/// Result of the WhatsApp-style profile photo crop / adjust flow.
class ProfilePhotoCropResult {
  const ProfilePhotoCropResult({required this.bytes});

  final Uint8List bytes;
}

/// Full-screen circular crop: pinch to zoom, drag to reposition, then save.
class ProfilePhotoCropScreen extends StatefulWidget {
  const ProfilePhotoCropScreen({
    super.key,
    required this.imageBytes,
  });

  final Uint8List imageBytes;

  @override
  State<ProfilePhotoCropScreen> createState() => _ProfilePhotoCropScreenState();
}

class _ProfilePhotoCropScreenState extends State<ProfilePhotoCropScreen> {
  final TransformationController _transform = TransformationController();
  final GlobalKey _viewportKey = GlobalKey();

  ui.Image? _decoded;
  bool _saving = false;
  double _minScale = 1;
  Size? _imageLayoutSize;

  @override
  void initState() {
    super.initState();
    _decodeImage();
  }

  @override
  void dispose() {
    _transform.dispose();
    _decoded?.dispose();
    super.dispose();
  }

  Future<void> _decodeImage() async {
    final codec = await ui.instantiateImageCodec(widget.imageBytes);
    final frame = await codec.getNextFrame();
    if (!mounted) {
      frame.image.dispose();
      return;
    }
    setState(() => _decoded = frame.image);
  }

  void _ensureCoverScale(Size viewport, double hole) {
    final image = _decoded;
    if (image == null) return;

    final imgW = image.width.toDouble();
    final imgH = image.height.toDouble();
    // Scale so the image fully covers the circular hole (BoxFit.cover).
    final cover = math.max(hole / imgW, hole / imgH);
    final layoutW = imgW * cover;
    final layoutH = imgH * cover;
    _imageLayoutSize = Size(layoutW, layoutH);
    _minScale = 1;

    // Center the image in the viewport at cover scale.
    final dx = (viewport.width - layoutW) / 2;
    final dy = (viewport.height - layoutH) / 2;
    _transform.value = Matrix4.identity()
      ..translateByDouble(dx, dy, 0, 1);
  }

  Future<void> _onDone() async {
    if (_saving || _decoded == null || _imageLayoutSize == null) return;
    setState(() => _saving = true);
    try {
      final bytes = await _exportCroppedPng();
      if (!mounted) return;
      if (bytes == null || bytes.isEmpty) {
        setState(() => _saving = false);
        return;
      }
      Navigator.of(context).pop(ProfilePhotoCropResult(bytes: bytes));
    } catch (_) {
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<Uint8List?> _exportCroppedPng() async {
    final image = _decoded;
    final layout = _imageLayoutSize;
    final box = _viewportKey.currentContext?.findRenderObject() as RenderBox?;
    if (image == null || layout == null || box == null || !box.hasSize) {
      return null;
    }

    const outSize = 512;
    final hole = math.min(box.size.width, box.size.height) * 0.78;
    final viewCenter = Offset(box.size.width / 2, box.size.height / 2);
    final matrix = _transform.value.clone();
    final inverse = Matrix4.tryInvert(matrix);
    if (inverse == null) return null;

    // Map crop-hole corners from viewport space into the laid-out image space.
    final topLeft = MatrixUtils.transformPoint(
      inverse,
      viewCenter - Offset(hole / 2, hole / 2),
    );
    final bottomRight = MatrixUtils.transformPoint(
      inverse,
      viewCenter + Offset(hole / 2, hole / 2),
    );

    final srcX = (topLeft.dx / layout.width) * image.width;
    final srcY = (topLeft.dy / layout.height) * image.height;
    final srcW = ((bottomRight.dx - topLeft.dx) / layout.width) * image.width;
    final srcH = ((bottomRight.dy - topLeft.dy) / layout.height) * image.height;

    final recorder = ui.PictureRecorder();
    final canvas = Canvas(recorder);
    final dest = Rect.fromLTWH(0, 0, outSize.toDouble(), outSize.toDouble());
    canvas.drawImageRect(
      image,
      Rect.fromLTWH(srcX, srcY, srcW, srcH),
      dest,
      Paint()..filterQuality = FilterQuality.high,
    );

    final picture = recorder.endRecording();
    final outImage = await picture.toImage(outSize, outSize);
    final byteData = await outImage.toByteData(format: ui.ImageByteFormat.png);
    outImage.dispose();
    picture.dispose();
    return byteData?.buffer.asUint8List();
  }

  @override
  Widget build(BuildContext context) {
    final typo = context.typo;
    final image = _decoded;

    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(8, 4, 8, 8),
              child: Row(
                children: [
                  TextButton(
                    onPressed: _saving ? null : () => Navigator.of(context).pop(),
                    child: Text(
                      'Cancel',
                      style: typo.buttonSm.copyWith(color: Colors.white),
                    ),
                  ),
                  const Spacer(),
                  Text(
                    'Move and scale',
                    style: typo.sm.copyWith(
                      color: Colors.white.withValues(alpha: 0.9),
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const Spacer(),
                  TextButton(
                    onPressed: _saving ? null : _onDone,
                    child: _saving
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : Text(
                            'Done',
                            style: typo.buttonSm.copyWith(
                              color: AppColors.primary,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: LayoutBuilder(
                builder: (context, constraints) {
                  final viewport = Size(constraints.maxWidth, constraints.maxHeight);
                  final hole = math.min(viewport.width, viewport.height) * 0.78;

                  if (image != null && _imageLayoutSize == null) {
                    WidgetsBinding.instance.addPostFrameCallback((_) {
                      if (!mounted || _imageLayoutSize != null) return;
                      setState(() => _ensureCoverScale(viewport, hole));
                    });
                  }

                  final layout = _imageLayoutSize;

                  return Stack(
                    key: _viewportKey,
                    fit: StackFit.expand,
                    children: [
                      if (image == null || layout == null)
                        const Center(
                          child: CircularProgressIndicator(color: Colors.white),
                        )
                      else
                        InteractiveViewer(
                          transformationController: _transform,
                          minScale: _minScale,
                          maxScale: 4,
                          constrained: false,
                          boundaryMargin: const EdgeInsets.all(2000),
                          child: SizedBox(
                            width: layout.width,
                            height: layout.height,
                            child: RawImage(
                              image: image,
                              fit: BoxFit.fill,
                              width: layout.width,
                              height: layout.height,
                            ),
                          ),
                        ),
                      IgnorePointer(
                        child: CustomPaint(
                          painter: _CircleCropOverlayPainter(holeSize: hole),
                          child: const SizedBox.expand(),
                        ),
                      ),
                    ],
                  );
                },
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 12, 24, 20),
              child: Text(
                'Drag to reposition · Pinch to zoom',
                textAlign: TextAlign.center,
                style: typo.sm.copyWith(
                  color: Colors.white.withValues(alpha: 0.65),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _CircleCropOverlayPainter extends CustomPainter {
  _CircleCropOverlayPainter({required this.holeSize});

  final double holeSize;

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = holeSize / 2;
    final overlay = Path()..addRect(Offset.zero & size);
    final hole = Path()
      ..addOval(Rect.fromCircle(center: center, radius: radius));
    final masked = Path.combine(PathOperation.difference, overlay, hole);

    canvas.drawPath(
      masked,
      Paint()..color = Colors.black.withValues(alpha: 0.55),
    );

    canvas.drawCircle(
      center,
      radius,
      Paint()
        ..color = Colors.white.withValues(alpha: 0.9)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2,
    );

    // Subtle WhatsApp-style grid inside the circle.
    final gridPaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.25)
      ..strokeWidth = 1;
    canvas.drawLine(
      Offset(center.dx - radius, center.dy),
      Offset(center.dx + radius, center.dy),
      gridPaint,
    );
    canvas.drawLine(
      Offset(center.dx, center.dy - radius),
      Offset(center.dx, center.dy + radius),
      gridPaint,
    );
  }

  @override
  bool shouldRepaint(covariant _CircleCropOverlayPainter oldDelegate) {
    return oldDelegate.holeSize != holeSize;
  }
}
