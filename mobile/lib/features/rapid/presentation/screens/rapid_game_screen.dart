import 'dart:async';

import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:msupperlimbs/core/network/api_error_messages.dart';
import 'package:msupperlimbs/features/auth/application/auth_notifier.dart';
import 'package:msupperlimbs/features/match/application/match_providers.dart';
import 'package:msupperlimbs/features/match/application/match_uploader.dart';
import 'package:msupperlimbs/features/match/domain/match_context.dart';
import 'package:msupperlimbs/features/motion/data/camera_frame_converter.dart';
import 'package:msupperlimbs/features/motion/data/mediapipe_service.dart';
import 'package:msupperlimbs/features/motion/domain/landmark_point.dart';
import 'package:msupperlimbs/features/motion/domain/screen_mapper.dart';
import 'package:msupperlimbs/features/motion/domain/session_clock.dart';
import 'package:msupperlimbs/features/motion/presentation/widgets/landmark_debug_painter.dart';
import 'package:msupperlimbs/features/rapid/application/rapid_match_flow.dart';
import 'package:msupperlimbs/features/rapid/application/rapid_settings_providers.dart';
import 'package:msupperlimbs/features/rapid/data/models/rapid_settings.dart';
import 'package:msupperlimbs/features/rapid/domain/rapid_game_engine.dart';
import 'package:msupperlimbs/features/rapid/domain/rapid_game_phase.dart';
import 'package:msupperlimbs/features/rapid/presentation/widgets/pulse_visualization.dart';
import 'package:msupperlimbs/features/rapid/presentation/widgets/rapid_countdown_overlay.dart';
import 'package:msupperlimbs/features/rapid/presentation/widgets/rapid_pregame_overlay.dart';
import 'package:msupperlimbs/l10n/generated/app_localizations.dart';
import 'package:permission_handler/permission_handler.dart';

class RapidGameScreen extends ConsumerStatefulWidget {
  const RapidGameScreen({super.key});

  @override
  ConsumerState<RapidGameScreen> createState() => _RapidGameScreenState();
}

class _RapidGameScreenState extends ConsumerState<RapidGameScreen> {
  final _mediaPipe = MediaPipeService();
  final _clock = SessionClock();
  final _previewKey = GlobalKey();
  late final RapidMatchFlow _flow;
  CameraController? _controller;
  RapidGameEngine? _engine;
  Timer? _secondTimer;
  Timer? _physicsTimer;

  bool _busy = true;
  bool _processing = false;
  bool _saving = false;
  String? _error;
  List<LandmarkPoint> _hands = const [];
  var _navigatedToFeedback = false;

  static const _maxInferSide = 288;

  @override
  void initState() {
    super.initState();
    final auth = ref.read(authProvider.notifier);
    _flow = RapidMatchFlow(
      ref.read(matchApiProvider),
      () => auth.accessToken,
      userId: () => auth.userId,
      queue: ref.read(pendingUploadsProvider),
    );
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
    SystemChrome.setPreferredOrientations(const [
      DeviceOrientation.landscapeLeft,
      DeviceOrientation.landscapeRight,
    ]);
    WidgetsBinding.instance.addPostFrameCallback((_) => _bootstrap());
  }

  Future<void> _bootstrap() async {
    try {
      final settings = await ref.read(rapidSettingsProvider.future);
      if (!mounted) return;
      setState(() {
        _engine = RapidGameEngine(
          settings: settings,
          clock: _clock,
          onChanged: () {
            if (!mounted) return;
            setState(() {});
            _maybeFinish();
          },
        );
      });
      await _startCamera();
    } catch (e, st) {
      logCameraError(e, st);
      if (!mounted) return;
      setState(() {
        _busy = false;
        _error = e.toString();
      });
    }
  }

  Future<void> _startCamera() async {
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      final status = await Permission.camera.request();
      if (!status.isGranted) {
        throw Exception('Permissão de câmera negada');
      }

      await _mediaPipe.initialize(mode: 'hands');
      final cameras = await availableCameras();
      if (cameras.isEmpty) throw Exception('Nenhuma câmera disponível');
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

  Rect? _measurePreviewRect() {
    final box = _previewKey.currentContext?.findRenderObject() as RenderBox?;
    if (box == null || !box.hasSize) return null;
    return Rect.fromPoints(
      box.localToGlobal(Offset.zero),
      box.localToGlobal(box.size.bottomRight(Offset.zero)),
    );
  }

  Future<void> _onFrame(CameraImage image) async {
    final engine = _engine;
    if (_processing || _controller == null || engine == null) return;
    final frameAt = _clock.now();
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

      final result = await _mediaPipe.detectFrame(
        image: scaled.bytes,
        width: scaled.width,
        height: scaled.height,
        rotation: rotation,
        mirrorHorizontal: isFront,
        mirrorVertical: false,
        pose: false,
        hands: true,
      );

      if (!mounted) return;
      final screen = MediaQuery.sizeOf(context);
      final previewRect = _measurePreviewRect();
      engine
        ..screenWidth = screen.width.round()
        ..screenHeight = screen.height.round()
        ..imageWidth = scaled.width
        ..imageHeight = scaled.height
        ..preview = previewRect == null
            ? null
            : ScreenMapper(
                screenSize: screen,
                previewRect: previewRect,
              ).normalizedPreview
        ..onHands(result.hands, frameAt);
      setState(() => _hands = result.hands);
    } catch (e, st) {
      logCameraError(e, st);
    } finally {
      _processing = false;
    }
  }

  void _onCountdownFinished() {
    final engine = _engine;
    if (engine == null) return;
    engine.onCountdownFinished();
    _flow.start(_matchContext(engine));
    _secondTimer?.cancel();
    _physicsTimer?.cancel();
    _secondTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      engine.onSecondElapsed();
    });
    _physicsTimer = Timer.periodic(const Duration(milliseconds: 33), (_) {
      engine.tickPhysics(_clock.now());
    });
  }

  void _maybeFinish() {
    final engine = _engine;
    if (engine == null || engine.phase != RapidGamePhase.finished) return;
    if (_navigatedToFeedback || _saving) return;
    _saving = true;
    _secondTimer?.cancel();
    _physicsTimer?.cancel();
    unawaited(_saveAndGo(engine));
  }

  Future<void> _saveAndGo(RapidGameEngine engine) async {
    if (!mounted) return;
    setState(() {});

    final size = MediaQuery.sizeOf(context);
    engine.screenWidth = size.width.round();
    engine.screenHeight = size.height.round();

    final l10n = AppLocalizations.of(context);
    var result = engine.result;
    try {
      result = await _flow.complete(result, _matchContext(engine));
    } catch (e) {
      result = result.copyWith(
        saveError: apiErrorMessage(l10n, e),
        queued: e is UploadQueuedException,
      );
    }

    if (!mounted) return;
    _navigatedToFeedback = true;
    context.go('/rapid-feedback', extra: result);
  }

  Map<String, dynamic> _matchContext(RapidGameEngine engine) =>
      buildMatchContext(
        screenWidth: engine.screenWidth,
        screenHeight: engine.screenHeight,
        imageWidth: engine.imageWidth,
        imageHeight: engine.imageHeight,
        cameraLens: _controller?.description.lensDirection.name,
        preview: engine.preview,
      );

  @override
  void dispose() {
    final engine = _engine;
    if (engine != null && engine.phase == RapidGamePhase.playing) {
      unawaited(
        _flow.cancel(score: engine.tapCount, durationMs: engine.playedMs),
      );
    }
    _secondTimer?.cancel();
    _physicsTimer?.cancel();
    final controller = _controller;
    _controller = null;
    controller?.dispose();
    _mediaPipe.dispose();
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    SystemChrome.setPreferredOrientations(DeviceOrientation.values);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final engine = _engine;
    final settings = engine?.settings;

    return Scaffold(
      backgroundColor: Colors.black,
      body: _buildBody(engine, settings),
    );
  }

  Widget _buildBody(RapidGameEngine? engine, RapidSettings? settings) {
    if (_busy && engine == null) {
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
                onPressed: _bootstrap,
                child: const Text('Tentar de novo'),
              ),
              TextButton(
                onPressed: () => context.go('/rapid-intro'),
                child: const Text('Voltar'),
              ),
            ],
          ),
        ),
      );
    }

    final controller = _controller;
    if (controller == null ||
        !controller.value.isInitialized ||
        engine == null) {
      return const Center(child: CircularProgressIndicator());
    }

    return Stack(
      fit: StackFit.expand,
      children: [
        _buildCoverPreview(controller),
        SafeArea(
          child: Align(
            alignment: Alignment.topLeft,
            child: IconButton(
              onPressed: () => context.go('/rapid-intro'),
              icon: const Icon(Icons.close, color: Colors.white),
            ),
          ),
        ),
        if (engine.phase == RapidGamePhase.playing ||
            engine.phase == RapidGamePhase.finished)
          SafeArea(
            child: Align(
              alignment: Alignment.topCenter,
              child: _Hud(
                seconds: engine.remainingSeconds,
                taps: engine.tapCount,
              ),
            ),
          ),
        if (engine.phase == RapidGamePhase.playing)
          SafeArea(
            child: Align(
              alignment: Alignment.bottomCenter,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
                child: PulseVisualization(
                  controller: engine.pulse,
                  type: settings?.visualizationType ?? 'line',
                ),
              ),
            ),
          ),
        RapidPregameOverlay(
          phase: engine.phase,
          holdProgress: engine.holdProgress,
          handPresent: engine.handPresent,
        ),
        if (engine.phase == RapidGamePhase.countdown)
          RapidCountdownOverlay(onFinished: _onCountdownFinished),
        if (_saving)
          const ColoredBox(
            color: Color(0x99000000),
            child: Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  CircularProgressIndicator(),
                  SizedBox(height: 16),
                  Text(
                    'A guardar partida…',
                    style: TextStyle(color: Colors.white, fontSize: 18),
                  ),
                ],
              ),
            ),
          ),
      ],
    );
  }

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
                key: _previewKey,
                painter: LandmarkDebugPainter(
                  pose: const [],
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

class _Hud extends StatelessWidget {
  const _Hud({required this.seconds, required this.taps});

  final int seconds;
  final int taps;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 8),
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: Colors.black54,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                '${seconds}s',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(width: 24),
              Text(
                '$taps taps',
                style: const TextStyle(
                  color: Colors.lightGreenAccent,
                  fontSize: 22,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
