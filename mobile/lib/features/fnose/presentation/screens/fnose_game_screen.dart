import 'dart:async';

import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:msupperlimbs/features/auth/application/auth_notifier.dart';
import 'package:msupperlimbs/features/calibration/application/calibration_providers.dart';
import 'package:msupperlimbs/core/network/api_error_messages.dart';
import 'package:msupperlimbs/features/fnose/application/fnose_calibration_flow.dart';
import 'package:msupperlimbs/features/fnose/application/fnose_match_flow.dart';
import 'package:msupperlimbs/features/fnose/application/fnose_settings_providers.dart';
import 'package:msupperlimbs/features/fnose/domain/fnose_calibration.dart';
import 'package:msupperlimbs/features/fnose/domain/fnose_game_engine.dart';
import 'package:msupperlimbs/features/fnose/domain/fnose_types.dart';
import 'package:msupperlimbs/features/fnose/domain/pregame_sensor_sampler.dart';
import 'package:msupperlimbs/features/fnose/presentation/widgets/fnose_pregame_overlay.dart';
import 'package:msupperlimbs/features/fnose/presentation/widgets/fnose_nose_alignment_overlay.dart';
import 'package:msupperlimbs/features/fnose/presentation/widgets/fnose_target_overlay.dart';
import 'package:msupperlimbs/features/match/application/match_providers.dart';
import 'package:msupperlimbs/features/match/domain/match_context.dart';
import 'package:msupperlimbs/features/motion/data/camera_frame_converter.dart';
import 'package:msupperlimbs/features/motion/data/mediapipe_service.dart';
import 'package:msupperlimbs/features/motion/domain/landmark_point.dart';
import 'package:msupperlimbs/features/motion/domain/session_clock.dart';
import 'package:msupperlimbs/features/motion/presentation/widgets/landmark_debug_painter.dart';
import 'package:msupperlimbs/features/rapid/presentation/widgets/rapid_countdown_overlay.dart';
import 'package:msupperlimbs/l10n/generated/app_localizations.dart';
import 'package:permission_handler/permission_handler.dart';

class FnoseGameScreen extends ConsumerStatefulWidget {
  const FnoseGameScreen({super.key});

  @override
  ConsumerState<FnoseGameScreen> createState() => _FnoseGameScreenState();
}

class _FnoseGameScreenState extends ConsumerState<FnoseGameScreen> {
  final _mediaPipe = MediaPipeService();
  final _clock = SessionClock();
  late final FnoseCalibrationFlow _calibration;
  late final FnoseMatchFlow _match;
  CameraController? _controller;
  FnoseGameEngine? _engine;
  PregameSensorSampler? _sensors;
  Timer? _secondTimer;

  final _previewKey = GlobalKey();

  bool _busy = true;
  bool _processing = false;
  bool _saving = false;
  bool _alive = true;
  String? _error;
  List<LandmarkPoint> _pose = const [];
  var _navigatedToFeedback = false;

  static const _maxInferSide = 288;

  @override
  void initState() {
    super.initState();
    final auth = ref.read(authProvider.notifier);
    final matches = ref.read(matchApiProvider);
    _calibration = FnoseCalibrationFlow(
      matches,
      ref.read(calibrationApiProvider),
      () => auth.accessToken,
    );
    _match = FnoseMatchFlow(matches, () => auth.accessToken);
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
    SystemChrome.setPreferredOrientations(const [
      DeviceOrientation.landscapeLeft,
      DeviceOrientation.landscapeRight,
    ]);
    WidgetsBinding.instance.addPostFrameCallback((_) => _bootstrap());
  }

  Future<void> _bootstrap() async {
    try {
      final settings = await ref.read(fnoseSettingsProvider.future);
      final adv = await ref.read(fnoseAdvSettingsProvider.future);
      if (!mounted) return;
      setState(() {
        _engine = FnoseGameEngine(
          settings: settings,
          adv: adv,
          clock: _clock,
          onChanged: () {
            if (!_alive || !mounted) return;
            setState(() {});
            _maybeFinish();
          },
        );
        _sensors = PregameSensorSampler(
          _engine!.telemetry,
          settings: adv,
          clock: _clock,
          orientation: () => _deviceOrientation,
          onTick:
              ({required still, required pitch, required roll, required now}) {
                _engine?.onSensorStatus(
                  still: still,
                  pitch: pitch,
                  roll: roll,
                  now: now,
                );
              },
        )..start();
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
      final l10n = AppLocalizations.of(context);
      final status = await Permission.camera.request();
      if (!status.isGranted) {
        throw Exception(l10n.camera_permissionDenied);
      }

      await _mediaPipe.initialize(mode: 'pose');
      final cameras = await availableCameras();
      if (cameras.isEmpty) throw Exception(l10n.camera_noneAvailable);
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

  /// Área ocupada pela imagem depois do recorte `cover`, em coordenadas do
  /// ecrã. Medida no layout porque o `Transform.scale` da pré-visualização não
  /// é dedutível apenas do rácio da câmara.
  Rect? _measurePreviewRect() {
    final box = _previewKey.currentContext?.findRenderObject() as RenderBox?;
    if (box == null || !box.hasSize) return null;
    return Rect.fromPoints(
      box.localToGlobal(Offset.zero),
      box.localToGlobal(box.size.bottomRight(Offset.zero)),
    );
  }

  DeviceOrientation get _deviceOrientation {
    final fromCamera = _controller?.value.deviceOrientation;
    if (fromCamera != null) return fromCamera;
    return MediaQuery.maybeOf(context)?.orientation == Orientation.landscape
        ? DeviceOrientation.landscapeLeft
        : DeviceOrientation.portraitUp;
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
        pose: true,
        hands: false,
      );

      if (!mounted || !_alive) return;
      final size = MediaQuery.sizeOf(context);
      engine.screenWidth = size.width.round();
      engine.screenHeight = size.height.round();
      engine.imageWidth = scaled.width;
      engine.imageHeight = scaled.height;
      engine.previewRect = _measurePreviewRect();
      engine.onPose(result.pose, frameAt);
      setState(() => _pose = result.pose);
    } catch (e, st) {
      logCameraError(e, st);
    } finally {
      _processing = false;
    }
  }

  Future<void> _onCountdownFinished() async {
    final engine = _engine;
    if (engine == null) return;

    final run = engine.closeCalibration(completed: true);
    _sensors?.stop();
    final calibrationRunId = run == null
        ? null
        : _uploadCalibration(run).then((id) => engine.calibrationRunId = id);

    engine.onCountdownFinished();
    _match.start(_matchContext(engine), calibrationRunId: calibrationRunId);
    _secondTimer?.cancel();
    _secondTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      engine.onSecondElapsed();
    });
  }

  /// Never throws: the match can still be played and saved without a run.
  Future<String?> _uploadCalibration(FnoseCalibrationRun run) async {
    try {
      return await _calibration.upload(run);
    } catch (e, st) {
      debugPrint('FNose calibration upload failed: $e\n$st');
      return null;
    }
  }

  void _maybeFinish() {
    final engine = _engine;
    if (engine == null || engine.phase != FnoseGamePhase.finished) return;
    if (_navigatedToFeedback || _saving) return;
    _saving = true;
    _secondTimer?.cancel();
    unawaited(_saveAndGo(engine));
  }

  Future<void> _saveAndGo(FnoseGameEngine engine) async {
    if (!mounted || !_alive) return;
    _sensors?.stop();
    setState(() {});

    final size = MediaQuery.sizeOf(context);
    engine.screenWidth = size.width.round();
    engine.screenHeight = size.height.round();

    final l10n = AppLocalizations.of(context);
    var result = engine.result;
    try {
      result = await _match.complete(result, _matchContext(engine));
    } catch (e) {
      result = result.copyWith(saveError: apiErrorMessage(l10n, e));
    }

    if (!mounted) return;
    _navigatedToFeedback = true;
    context.go('/fnose-feedback', extra: result);
  }

  Map<String, dynamic> _matchContext(FnoseGameEngine engine) =>
      buildMatchContext(
        screenWidth: engine.screenWidth,
        screenHeight: engine.screenHeight,
        imageWidth: engine.imageWidth,
        imageHeight: engine.imageHeight,
        cameraLens: _controller?.description.lensDirection.name,
        preview: engine.result.preview,
      );

  @override
  void dispose() {
    _alive = false;
    _secondTimer?.cancel();
    _sensors?.stop();
    _sensors = null;
    final engine = _engine;
    _engine = null;
    if (engine != null && engine.phase == FnoseGamePhase.playing) {
      unawaited(
        _match.cancel(score: engine.totalSparks, durationMs: engine.playedMs),
      );
    }
    final abandoned = engine?.closeCalibration(completed: false);
    if (abandoned != null) unawaited(_uploadCalibration(abandoned));
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
    return Scaffold(backgroundColor: Colors.black, body: _buildBody(engine));
  }

  Widget _buildBody(FnoseGameEngine? engine) {
    if (_busy && engine == null) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_error != null) {
      final l10n = AppLocalizations.of(context);
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
                child: Text(l10n.common_retry),
              ),
              TextButton(
                onPressed: () => context.go('/fnose-intro'),
                child: Text(l10n.common_back),
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

    final mode = engine.settings.gameMode;
    final showLeft = mode != 'rightHand';
    final showRight = mode == 'rightHand';
    final targetScale =
        engine.adv.d('target_scale', 0.45) *
        engine.settings.targetSize.clamp(0.5, 2.0);

    return Stack(
      fit: StackFit.expand,
      children: [
        _buildCoverPreview(controller),
        if (engine.phase == FnoseGamePhase.playing ||
            engine.phase == FnoseGamePhase.finished)
          FnoseTargetOverlay(
            xTargetPosition: engine.adv.d('x_target_position', 0.1),
            yTargetPosition: engine.adv.d('y_target_position', 0.5),
            targetScale: targetScale,
            showLeft: showLeft,
            showRight: showRight,
            leftSpark: engine.leftSpark,
            rightSpark: engine.rightSpark,
            tracked: engine.fingerPosition,
          ),
        SafeArea(
          child: Align(
            alignment: Alignment.topLeft,
            child: IconButton(
              onPressed: () => context.go('/fnose-intro'),
              icon: const Icon(Icons.close, color: Colors.white),
            ),
          ),
        ),
        if (engine.phase == FnoseGamePhase.playing ||
            engine.phase == FnoseGamePhase.finished)
          SafeArea(
            child: Align(
              alignment: Alignment.topCenter,
              child: _Hud(
                seconds: engine.remainingSeconds,
                left: engine.leftSparks,
                right: engine.rightSparks,
                leftSpark: engine.leftSpark,
                rightSpark: engine.rightSpark,
              ),
            ),
          ),
        FnosePregameOverlay(
          phase: engine.phase,
          holdProgress: engine.holdProgress,
          pitch: engine.pitch,
          roll: engine.roll,
          pitchMin: engine.adv.d('pitch_min_deg', -12),
          pitchMax: engine.adv.d('pitch_max_deg', 12),
          rollMin: engine.adv.d('roll_min_deg', -8),
          rollMax: engine.adv.d('roll_max_deg', 8),
        ),
        // Marcas depois do HUD para ficarem sempre visíveis por cima dele.
        if (engine.phase == FnoseGamePhase.calibrateFinger)
          FnoseTargetOverlay(
            xTargetPosition: engine.adv.d('x_target_position', 0.1),
            yTargetPosition: engine.adv.d('y_target_position', 0.5),
            targetScale: targetScale,
            showLeft: showLeft,
            showRight: showRight,
            leftSpark: engine.fingerInside
                ? FnoseSparkState.fire
                : FnoseSparkState.aiming,
            rightSpark: engine.fingerInside
                ? FnoseSparkState.fire
                : FnoseSparkState.aiming,
            tracked: engine.fingerPosition,
          ),
        if (engine.phase == FnoseGamePhase.alignNose)
          FnoseNoseAlignmentOverlay(
            center: engine.noseTargetCenter,
            radius: engine.noseTargetRadius,
            inside: engine.noseInside,
            detected: engine.nosePosition,
          ),
        if (engine.phase == FnoseGamePhase.countdown)
          RapidCountdownOverlay(
            onFinished: () {
              unawaited(_onCountdownFinished());
            },
          ),
        if (_saving)
          ColoredBox(
            color: const Color(0x99000000),
            child: Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const CircularProgressIndicator(),
                  const SizedBox(height: 16),
                  Text(
                    AppLocalizations.of(context).fnose_game_saving,
                    style: const TextStyle(color: Colors.white, fontSize: 18),
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
                  pose: _pose,
                  hands: const [],
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
  const _Hud({
    required this.seconds,
    required this.left,
    required this.right,
    required this.leftSpark,
    required this.rightSpark,
  });

  final int seconds;
  final int left;
  final int right;
  final FnoseSparkState leftSpark;
  final FnoseSparkState rightSpark;

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
              const SizedBox(width: 20),
              Text(
                'L $left (${leftSpark.name})',
                style: const TextStyle(
                  color: Colors.lightBlueAccent,
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(width: 12),
              Text(
                'R $right (${rightSpark.name})',
                style: const TextStyle(
                  color: Colors.orangeAccent,
                  fontSize: 16,
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
