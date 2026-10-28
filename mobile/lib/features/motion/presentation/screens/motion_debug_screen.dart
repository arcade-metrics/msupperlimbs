import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:msupperlimbs/features/motion/data/camera_frame_converter.dart';
import 'package:msupperlimbs/features/motion/data/mediapipe_service.dart';
import 'package:msupperlimbs/features/motion/domain/landmark_point.dart';
import 'package:msupperlimbs/features/motion/presentation/widgets/landmark_debug_painter.dart';
import 'package:permission_handler/permission_handler.dart';

class MotionDebugScreen extends StatefulWidget {
  const MotionDebugScreen({super.key});

  @override
  State<MotionDebugScreen> createState() => _MotionDebugScreenState();
}

class _MotionDebugScreenState extends State<MotionDebugScreen> {
  final _mediaPipe = MediaPipeService();
  CameraController? _controller;
  bool _busy = false;
  bool _processing = false;
  String? _error;
  List<LandmarkPoint> _pose = const [];
  List<LandmarkPoint> _hands = const [];
  int _frameCount = 0;
  int _lastRotation = 0;
  int _skipCounter = 0;

  static const _processEveryNth = 1;
  static const _maxInferSide = 288;

  @override
  void initState() {
    super.initState();
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
    _start();
  }

  Future<void> _start() async {
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      final status = await Permission.camera.request();
      if (!status.isGranted) {
        throw Exception('Permissão de câmera negada');
      }

      await _mediaPipe.initialize(mode: 'both');
      final cameras = await availableCameras();
      if (cameras.isEmpty) {
        throw Exception('Nenhuma câmera disponível');
      }
      final camera = cameras.firstWhere(
        (c) => c.lensDirection == CameraLensDirection.front,
        orElse: () => cameras.first,
      );

      final controller = CameraController(
        camera,
        ResolutionPreset.low,
        enableAudio: false,
        imageFormatGroup: ImageFormatGroup.yuv420,
      );
      await controller.initialize();
      await controller.startImageStream(_onFrame);
      if (!mounted) return;
      setState(() {
        _controller = controller;
        _busy = false;
      });
    } catch (e, st) {
      logCameraError(e, st);
      if (!mounted) return;
      setState(() {
        _busy = false;
        _error = e.toString();
      });
    }
  }

  DeviceOrientation get _deviceOrientation {
    final fromCamera = _controller?.value.deviceOrientation;
    if (fromCamera != null) return fromCamera;
    return MediaQuery.maybeOf(context)?.orientation == Orientation.landscape
        ? DeviceOrientation.landscapeLeft
        : DeviceOrientation.portraitUp;
  }

  Future<void> _onFrame(CameraImage image) async {
    if (_processing || _controller == null) return;
    _skipCounter++;
    if (_skipCounter % _processEveryNth != 0) return;

    _processing = true;
    try {
      final yBytes = CameraFrameConverter.yPlaneBytes(image);
      if (yBytes == null) return;

      final scaled = CameraFrameConverter.downsampleY(
        yBytes,
        image.width,
        image.height,
        maxSide: _maxInferSide,
      );

      final isFront =
          _controller!.description.lensDirection == CameraLensDirection.front;
      final rotation = CameraFrameConverter.rotationForPreview(
        camera: _controller!.description,
        deviceOrientation: _deviceOrientation,
      );
      _lastRotation = rotation;

      // Hands every other processed frame to cut latency further.
      final wantHands = _frameCount.isEven;

      final result = await _mediaPipe.detectFrame(
        image: scaled.bytes,
        width: scaled.width,
        height: scaled.height,
        rotation: rotation,
        mirrorHorizontal: isFront,
        mirrorVertical: false,
        pose: true,
        hands: wantHands,
      );

      if (!mounted) return;
      setState(() {
        _pose = result.pose;
        if (wantHands) _hands = result.hands;
        _frameCount++;
      });
    } catch (e, st) {
      logCameraError(e, st);
    } finally {
      _processing = false;
    }
  }

  @override
  void dispose() {
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    final controller = _controller;
    _controller = null;
    controller?.dispose();
    _mediaPipe.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(backgroundColor: Colors.black, body: _buildBody());
  }

  Widget _buildBody() {
    if (_busy) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_error != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                _error!,
                textAlign: TextAlign.center,
                style: const TextStyle(color: Colors.white),
              ),
              const SizedBox(height: 16),
              FilledButton(
                onPressed: _start,
                child: const Text('Tentar de novo'),
              ),
            ],
          ),
        ),
      );
    }

    final controller = _controller;
    if (controller == null || !controller.value.isInitialized) {
      return const Center(child: Text('Câmera não inicializada'));
    }

    return Stack(
      fit: StackFit.expand,
      children: [
        _buildCoverPreview(controller),
        SafeArea(
          child: Align(
            alignment: Alignment.topLeft,
            child: IconButton(
              onPressed: () => Navigator.of(context).maybePop(),
              icon: const Icon(Icons.arrow_back, color: Colors.white),
            ),
          ),
        ),
        Positioned(
          left: 12,
          bottom: 12,
          child: SafeArea(
            child: DecoratedBox(
              decoration: BoxDecoration(
                color: Colors.black54,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Padding(
                padding: const EdgeInsets.all(8),
                child: Text(
                  'frames: $_frameCount  rot: $_lastRotation°  '
                  '${_deviceOrientation.name}',
                  style: const TextStyle(color: Colors.white, fontSize: 12),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  /// Full-bleed cover: crop edges, never stretch. Landmarks stay as preview child.
  Widget _buildCoverPreview(CameraController controller) {
    final size = MediaQuery.sizeOf(context);
    var scale = size.aspectRatio * controller.value.aspectRatio;
    if (scale < 1) scale = 1 / scale;

    return ClipRect(
      child: Transform.scale(
        scale: scale,
        alignment: Alignment.center,
        child: Center(
          child: AspectRatio(
            aspectRatio: controller.value.aspectRatio,
            child: CameraPreview(
              controller,
              child: CustomPaint(
                painter: LandmarkDebugPainter(
                  pose: _pose,
                  hands: _hands,
                  mirrorHorizontal: false,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
