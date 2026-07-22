import 'package:camera/camera.dart';
import 'package:flutter/material.dart';

/// Live front-camera preview for selfie / liveness flows.
class FrontCameraPreview extends StatefulWidget {
  const FrontCameraPreview({super.key});

  @override
  State<FrontCameraPreview> createState() => _FrontCameraPreviewState();
}

class _FrontCameraPreviewState extends State<FrontCameraPreview> {
  CameraController? _controller;
  bool _initializing = true;

  @override
  void initState() {
    super.initState();
    _initCamera();
  }

  Future<void> _initCamera() async {
    try {
      final cameras = await availableCameras();
      if (cameras.isEmpty) {
        if (mounted) setState(() => _initializing = false);
        return;
      }

      final frontCamera = cameras.firstWhere(
        (camera) => camera.lensDirection == CameraLensDirection.front,
        orElse: () => cameras.first,
      );

      final controller = CameraController(
        frontCamera,
        ResolutionPreset.medium,
        enableAudio: false,
        imageFormatGroup: ImageFormatGroup.jpeg,
      );

      await controller.initialize();
      if (!mounted) {
        await controller.dispose();
        return;
      }

      setState(() {
        _controller = controller;
        _initializing = false;
      });
    } catch (_) {
      if (mounted) setState(() => _initializing = false);
    }
  }

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final controller = _controller;

    if (_initializing) {
      return const ColoredBox(
        color: Colors.black,
        child: Center(
          child: CircularProgressIndicator(
            strokeWidth: 2.5,
            color: Colors.white54,
          ),
        ),
      );
    }

    if (controller == null || !controller.value.isInitialized) {
      return _placeholder();
    }

    final previewSize = controller.value.previewSize;
    if (previewSize == null) {
      return _placeholder();
    }

    return ColoredBox(
      color: Colors.black,
      child: FittedBox(
        fit: BoxFit.cover,
        child: SizedBox(
          width: previewSize.height,
          height: previewSize.width,
          child: CameraPreview(controller),
        ),
      ),
    );
  }

  Widget _placeholder() {
    return ColoredBox(
      color: Colors.black,
      child: Center(
        child: Icon(
          Icons.face_rounded,
          size: 72,
          color: Colors.white.withValues(alpha: 0.45),
        ),
      ),
    );
  }
}
