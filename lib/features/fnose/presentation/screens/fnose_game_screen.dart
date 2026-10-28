import 'dart:async';
import 'dart:math';
import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:msupperlimbs/gen_l10n/app_localizations.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:msupperlimbs/core/utils/mirror_device_util.dart';
import 'package:msupperlimbs/core/utils/screen_orientation.dart';
import 'package:msupperlimbs/core/services/camera_config_service.dart';
import 'package:msupperlimbs/core/models/camera_image_config.dart';
import 'package:msupperlimbs/features/fnose/application/fnose-game-controller.dart';
import 'package:msupperlimbs/features/fnose/application/fnose_adv_settings_state.dart';
import 'package:msupperlimbs/features/fnose/application/fnose_match_state.dart';
import 'package:msupperlimbs/features/fnose/application/fnose_position_validation_service_provider.dart';
import 'package:msupperlimbs/features/fnose/application/fnose_settings_state.dart';
import 'package:msupperlimbs/features/fnose/application/fnose_spark_controller_provider.dart';
import 'package:msupperlimbs/features/fnose/data/models/enums/fnose_game_mode_enum.dart';
import 'package:msupperlimbs/features/fnose/data/models/enums/spark_state_enum.dart';
import 'package:msupperlimbs/features/fnose/data/models/fnose_adv_settings_model.dart';
import 'package:msupperlimbs/features/fnose/motion/fnose_position_validation_service.dart';
import 'package:msupperlimbs/features/fnose/motion/utils/arm_movement_tracking_utils.dart';
import 'package:msupperlimbs/features/fnose/motion/utils/game_pose_logger_utils.dart';
import 'package:msupperlimbs/features/fnose/motion/utils/pose_frame_data_utils.dart';
import 'package:msupperlimbs/features/fnose/motion/utils/touch_logger_utils.dart';
import 'package:msupperlimbs/features/fnose/presentation/widgets/fnose_adjust_position_banner.dart';
import 'package:msupperlimbs/features/fnose/presentation/widgets/fnose_camera_with_landmarks.dart';
import 'package:msupperlimbs/features/fnose/presentation/widgets/fnose_saving_overlay.dart';
import 'package:msupperlimbs/features/fnose/presentation/widgets/validation_stability_checker_overlay.dart';
import 'package:msupperlimbs/features/fnose/presentation/widgets/validation_target_calibration_widget.dart';
import 'package:msupperlimbs/features/fnose/presentation/widgets/validation_timer_pre_game.dart';
import 'package:msupperlimbs/features/fnose/presentation/widgets/validation_position_checker_overlay.dart';
import 'package:msupperlimbs/features/fnose/presentation/widgets/target_spark_aura_widget.dart';
import 'package:msupperlimbs/features/fnose/presentation/widgets/target_spark_fire_marker_widget.dart';
import 'package:msupperlimbs/features/fnose/presentation/widgets/target_spark_score_widget.dart';
import 'package:msupperlimbs/features/fnose/presentation/widgets/target_hit_area_debug_circle.dart';
import 'package:msupperlimbs/features/fnose/presentation/widgets/target_touch_explosion_widget.dart';
import 'package:rxdart/rxdart.dart';
import 'package:msupperlimbs/features/fnose/presentation/widgets/target_touch_marks_widget.dart';
import 'package:msupperlimbs/features/fnose/presentation/widgets/nose_alignment_indicator_widget.dart';
import 'package:msupperlimbs/features/fnose/presentation/widgets/fnose_saving_overlay.dart';
import 'package:msupperlimbs/features/gameplay/application/camera_service_provider.dart';
import 'package:msupperlimbs/features/gameplay/application/device_stability_service_provider.dart';
import 'package:msupperlimbs/features/gameplay/application/session_state.dart';
import 'package:msupperlimbs/features/gameplay/presentation/widgets/countdown_widget.dart';
import 'package:msupperlimbs/features/gameplay/presentation/widgets/target_widget.dart';
import 'package:msupperlimbs/features/gameplay/presentation/widgets/manual_camera_config_widget.dart';
import 'package:msupperlimbs/features/gameplay/motion/mlkit_pose_adapter.dart';
import 'package:msupperlimbs/features/gameplay/motion/mediapipe_pose_painter.dart';
import 'package:msupperlimbs/features/gameplay/motion/image_rotation.dart';

// Enum to track the current game state
enum GameState {
  notStarted,
  touchNose,
  touchTarget,
  targetTouched,
}

class FNoseGameScreen extends ConsumerStatefulWidget {
  const FNoseGameScreen({super.key});

  @override
  ConsumerState<FNoseGameScreen> createState() => _FNoseGameScreenState();
}

class _FNoseGameScreenState extends ConsumerState<FNoseGameScreen> {
  // == Manual camera configuration ==
  bool _showManualConfig = false; // Only show after stability
  bool _configurationComplete = false;
  bool _configurationFailed = false;
  bool _isConfigurationActive = false;
  CameraImageConfig? _cameraConfig; // Cached config - loaded once

  // == Pre-game stability, position validation and target calibration==
  bool isPreGame = false;
  Timer? _stabilityTimer;
  StreamSubscription<MapEntry<bool, double>>? _stabilitySubscription;
  bool _hasStartedCountdown = false;
  bool _showValidationUI = false;
  bool _showTimerPreGame = false;
  bool _isTargetCalibrated = false;
  Offset _targetCalibrationOffset = Offset.zero;

  // == Game state control ==
  GameState _gameState = GameState.notStarted;
  int _remainingTime = 0;
  Timer? _gameTimer;
  bool _isEndingGame = false;
  late int _gameStartTimestamp;
  late int _timestamp;
  bool _isSaving = false;
  bool _hideGameUI = false;
  SavingPhase _currentSavingPhase = SavingPhase.savingPoseData;
  double _savingProgress = 0.0;

  // == Pose detection and visualisation ==
  CustomPainter? _landmarksPainter; // optional visual overlay
  Size _imageSize = const Size(640, 480); // fallback if no image metadata

  // == Landmark processing ==
  LandmarkSet? _landmarkSet; // raw PoseLandmarks (nose, wrist, etc.)
  LandmarkOffsets? _landmarkOffsets; // screen-projected Offsets for UI use

  // == Arm tracking ==
  ArmMovementTracker? _leftArmTracker;
  ArmMovementTracker? _rightArmTracker;

  // == Game mode (left, right or both hands) ==
  FNoseGameMode _currentGameMode = FNoseGameMode.leftHand;
  late final FNoseAdvSettingsModel _advSettings;

  // == Game interaction tracking ==
  int _leftSparkCount = 0;
  int _rightSparkCount = 0;
  double _maxLeftExtensionAngle = 0;
  double _maxRightExtensionAngle = 0;
  Offset? _bestLeftIndexTipPosition;
  Offset? _bestRightIndexTipPosition;
  double? _leftFingerNoseDistance;
  double? _rightFingerNoseDistance;
  bool _wasLastLeftTouchValid = false;
  bool _wasLastRightTouchValid = false;

  // == Touch feedback and gameplay logs ==
  final List<TargetTouchMark> _touchMarks = [];
  final List<Widget> _explosions = [];
  final List<TouchLog> _touchLogs = [];
  bool _showLandmarks = true;

  // == Pose logging ==
  List<Map<String, dynamic>> _poseLog = []; // frame-to-frame logs

  // == Position validation service ==
  FNosePositionValidationService? _positionValidationService;
  bool _isPositionValidated = false;

  // == MediaPipe adapter ==
  MLKitPoseAdapter? _mpAdapter;

  // == Utility ==
  String generateId() {
    final now = DateTime.now().toUtc();
    final formatted = DateFormat('yyyyMMddHHmmss').format(now);
    return 'fnose_${formatted}_${now.millisecondsSinceEpoch}';
  }

  @override
  void initState() {
    super.initState();
    lockToLandscape();
    _positionValidationService =
        ref.read(fnosePositionValidationServiceProvider);
    _currentGameMode = FNoseGameModeX.fromString(
          ref.read(fnoseSettingsStateProvider)?.gameMode ?? '',
        ) ??
        FNoseGameMode.leftHand;

    _advSettings = ref.read(fnoseAdvSettingsStateProvider.notifier).state!;
    if (_advSettings == null) {
      debugPrint('[WARN] AdvSettings not loaded before initState');
      return;
    }

    _initCameraAndStream();
    _initStabilityCheck();

    if (_currentGameMode == FNoseGameMode.leftHand ||
        _currentGameMode == FNoseGameMode.bothHands) {
      _leftArmTracker = ArmMovementTracker(
        bufferSize: _advSettings.angleBufferSize.toInt(),
        flexionThreshold: _advSettings.elbowFlexionThreshold,
        extensionThreshold: _advSettings.elbowExtensionThreshold,
        noseTouchDistanceThreshold: 0.55,
        minAngleChangeForDetection:
            _advSettings.minAngleChangeForElbowDetection,
      );
    }

    if (_currentGameMode == FNoseGameMode.rightHand ||
        _currentGameMode == FNoseGameMode.bothHands) {
      _rightArmTracker = ArmMovementTracker(
        bufferSize: _advSettings.angleBufferSize.toInt(),
        flexionThreshold: _advSettings.elbowFlexionThreshold,
        extensionThreshold: _advSettings.elbowExtensionThreshold,
        noseTouchDistanceThreshold: 0.55,
        minAngleChangeForDetection:
            _advSettings.minAngleChangeForElbowDetection,
      );
    }
  }

  void _initStabilityCheck() {
    final stabilityService = ref.read(deviceStabilityServiceProvider);
    stabilityService.startStabilityCheck();

    // Subscribe to both stability and angle streams
    _stabilitySubscription = Rx.combineLatest2(
      stabilityService.stabilityStream,
      stabilityService.angleStream,
      (bool isStable, double angle) => MapEntry(isStable, angle),
    ).listen((MapEntry<bool, double> state) {
      if (!mounted || _isEndingGame) return;

      final isStable = state.key;
      final angle = state.value;
      final isCorrectAngle = angle >= 70 && angle <= 120;
      final isPositionValid =
          _positionValidationService?.isPositionValid ?? false;

      debugPrint('📱 Device stability check: stable=$isStable, angle=$angle°, correctAngle=$isCorrectAngle');

      // Check if device is stable and angle is correct (but don't start countdown yet)
      final deviceReady = isStable && isCorrectAngle;

      if (deviceReady) {
        // Skip manual configuration - always use default config
        debugPrint('📊 Configuration status: complete=$_configurationComplete (validation disabled)');
        if (_configurationComplete) {
          debugPrint('⏭️ Using default configuration - skipping manual setup');
        }
        
        // Only set the device as ready but wait for position validation
        // before starting the countdown
        setState(() {
          isPreGame = false; // Keep in validation mode
        });

        // Add a delay before showing the validation UI
        if (!_showValidationUI && _configurationComplete) {
          Future.delayed(const Duration(milliseconds: 200), () {
            if (mounted && isStable && isCorrectAngle) {
              setState(() {
                _showValidationUI = true;
              });
            }
          });
        }
      } else {
        // Device is not stable or angle is incorrect, reset validation UI flag
        setState(() {
          _showValidationUI = false;
        });

        if (_hasStartedCountdown) {
          setState(() {
            _hasStartedCountdown = false;
            isPreGame = false;
            _isPositionValidated = false;
          });
        }
        _stabilityTimer?.cancel();
      }
    });
  }

  @override
  void dispose() {
    _stabilityTimer?.cancel();
    _stabilitySubscription?.cancel();
    _gameTimer?.cancel();

    final stabilityService = ref.read(deviceStabilityServiceProvider);
    stabilityService.stopStabilityCheck();

    ref.read(cameraServiceProvider).onMpPoseDetected = null;
    ref.read(leftSparkControllerProvider.notifier).reset();
    ref.read(rightSparkControllerProvider.notifier).reset();
    ref.read(cameraServiceProvider).stopImageStream();

    super.dispose();
  }

  Future<void> _startGame() async {
    debugPrint('🚀 Game starting now!');
    final session = ref.read(sessionProvider);
    final settings = ref.read(fnoseSettingsStateProvider);
    if (session == null || settings == null) {
      debugPrint('❌ Cannot start game: session or settings null');
      return;
    }

    debugPrint('⏱️ Game duration: ${settings.totalTime} seconds');

    await ref.read(fnoseMatchStateProvider.notifier).startMatch(
          userId: session.userId,
          sessionId: session.sessionId,
          gameMode: _currentGameMode,
          totalTime: settings.totalTime,
          imageWidth: _imageSize.width.toInt(),
          imageHeight: _imageSize.height.toInt(),
          screenWidth: MediaQuery.of(context).size.width.toInt(),
          screenHeight: MediaQuery.of(context).size.height.toInt(),
          advSettings: _advSettings,
        );

    setState(() {
      _gameState = GameState.touchNose;
      _remainingTime = settings.totalTime;
    });

    // Start game timer
    _gameStartTimestamp = DateTime.now().millisecondsSinceEpoch;

    _gameTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      setState(() {
        _remainingTime--;
      });

      if (_remainingTime <= 0) {
        _endGame();
      }
    });
  }

  void _endGame() async {
    setState(() {
      _isEndingGame = true;
      _isSaving = true;
      _hideGameUI = true;
    });

    ref.read(cameraServiceProvider).onMpPoseDetected = null;

    _gameTimer?.cancel();
    _stabilitySubscription?.cancel();

    final cameraService = ref.read(cameraServiceProvider);
    await cameraService.stopImageStream();

    final session = ref.read(sessionProvider);
    final matchNotifier = ref.read(fnoseMatchStateProvider.notifier);
    if (session == null) return;

    final touchJson = _touchLogs.map((e) => e.toJson()).toList();
    
    debugPrint('[DEBUG] Sending to Firebase:');
    debugPrint('[DEBUG] - touchLogs: ${_touchLogs.length}');
    debugPrint('[DEBUG] - poseLog: ${_poseLog.length} frames');
    if (_poseLog.isNotEmpty) {
      debugPrint('[DEBUG] - First pose frame keys: ${_poseLog.first.keys}');
      debugPrint('[DEBUG] - First pose has landmarks: ${_poseLog.first.containsKey('landmarks')}');
      debugPrint('[DEBUG] - First pose has offsets: ${_poseLog.first.containsKey('offsets')}');
    }

    await matchNotifier.finalizeMatch(
      poseLog: _poseLog,
      leftCount: _leftSparkCount,
      rightCount: _rightSparkCount,
      calibrationOffset: _targetCalibrationOffset,
      touchLogs: touchJson,
      onProgress: (phase, progress) {
        setState(() {
          _currentSavingPhase = phase;
          _savingProgress = progress;
        });
      },
    );

    debugPrint('[END] Finalize complete — navigating to feedback.');

    _touchLogs.clear();
    _poseLog.clear();
    _leftSparkCount = 0;
    _rightSparkCount = 0;

    ref.read(leftSparkControllerProvider.notifier).reset();
    ref.read(rightSparkControllerProvider.notifier).reset();

    if (mounted) {
      context.go('/fnose-feedback');
    }
  }

  // Modified method to check all validations and start game if all are valid
  void _checkValidations() {
    if (_landmarkSet == null || _landmarkOffsets == null || _isEndingGame) {
      if (_landmarkSet == null) debugPrint('⚠️ Validation: No landmarks available');
      return;
    }

    debugPrint('🔍 Checking validations...');
    final screenSize = MediaQuery.of(context).size;

    // Update position validation
    final isLeftHand = _currentGameMode == FNoseGameMode.leftHand;
    final frameData = PoseFrameData(
      landmarks: _landmarkSet!,
      offsets: _landmarkOffsets!,
    );
    _positionValidationService?.updatePose(frameData, screenSize, isLeftHand);

    // Check if device is stable and position is validated
    final stabilityService = ref.read(deviceStabilityServiceProvider);
    final isStable = stabilityService.isStable;

    final isPositionValid =
        _positionValidationService?.isPositionValid ?? false;

    debugPrint('📊 Validation status:');
    debugPrint('  - Device stable: $isStable');
    debugPrint('  - Position valid: $isPositionValid');
    debugPrint('  - Shoulder distance: ${_positionValidationService?.isShoulderDistanceValid}');
    debugPrint('  - Shoulder Y aligned: ${_positionValidationService?.isShoulderYAligned}');
    debugPrint('  - Shoulder Z aligned: ${_positionValidationService?.isShoulderZAligned}');
    debugPrint('  - Nose centered: ${_positionValidationService?.isNoseCentered}');
    debugPrint('  - Has started countdown: $_hasStartedCountdown');

    // All conditions must be met to start the game
    if (isStable && isPositionValid && !_hasStartedCountdown) {
      debugPrint('✅ All validations passed! Starting countdown...');
      _hasStartedCountdown = true;
      _stabilityTimer?.cancel();
      _stabilityTimer = Timer(const Duration(milliseconds: 2000), () {
        if (mounted) {
          // Double check all conditions before starting the game
          final isStillStable = stabilityService.isStable;

          final isStillPositionValid =
              _positionValidationService?.isPositionValid ?? false;

          if (isStillStable && isStillPositionValid) {
            debugPrint('🎮 Position validated! Moving to pre-game...');
            setState(() {
              isPreGame = true;
              _isPositionValidated = true;
              _isTargetCalibrated = false;
            });
          } else {
            debugPrint('❌ Validation lost during countdown. Resetting...');
            _hasStartedCountdown = false;
          }
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final settings = ref.watch(fnoseSettingsStateProvider);
    final advSettings = ref.watch(fnoseAdvSettingsStateProvider);
    final countdownTime = settings!.totalTime;
    final cameraService = ref.read(cameraServiceProvider);
    final cameraWidget = cameraService.getCameraPreview();
    final stabilityAsync = ref.watch(deviceStabilityProvider);
    final l10n = AppLocalizations.of(context)!;

    // Initialize position validation service with localized messages
    if (_positionValidationService != null) {
      _positionValidationService!.moveCloserMessage = l10n.position_moveCloser;
      _positionValidationService!.moveFartherMessage =
          l10n.position_moveFarther;
      _positionValidationService!.faceDeviceMessage = l10n.position_faceDevice;
      _positionValidationService!.alignShouldersMessage =
          l10n.position_alignShoulders;
      _positionValidationService!.moveLeftMessage = l10n.position_moveLeft;
      _positionValidationService!.moveRightMessage = l10n.position_moveRight;
      _positionValidationService!.moveDownMessage = l10n.position_moveDown;
      _positionValidationService!.moveUpMessage = l10n.position_moveUp;
      _positionValidationService!.positionFoundMessage =
          l10n.position_positionFound;
      _positionValidationService!.faceAndShouldersNotVisibleMessage =
          l10n.position_faceAndShouldersNotVisible;
      _positionValidationService!.noseCloseMessage = l10n.position_noseClose;
      _positionValidationService!.noseFarMessage = l10n.position_noseFar;
    }

    final session = ref.watch(sessionProvider);
    final orientation =
        MediaQuery.of(context).orientation == Orientation.landscape
            ? DeviceOrientation.landscapeLeft
            : DeviceOrientation.portraitUp;
    final (mirrorX, mirrorY) = session != null
        ? MirrorDeviceUtil.shouldMirrorCamera(session.deviceModel, orientation)
        : (false, false);

    if (advSettings == null) {
      return const SizedBox.shrink();
    }

    // Only run position validation AFTER configuration is complete
    if (_gameState == GameState.notStarted && 
        !_isEndingGame && 
        _configurationComplete && 
        !_showManualConfig) {
      _checkValidations();
    }

    // Pose logging now handled in _initCameraAndStream callback with MediaPipe raw data

    final screenSize = MediaQuery.of(context).size;
    final imageSize = screenSize.shortestSide * advSettings.targetScale;
    final isLeftHand = _currentGameMode == FNoseGameMode.leftHand;
    final xPos = isLeftHand
        ? screenSize.width * advSettings.xTargetPosition +
            (imageSize / 2) // Borda esquerda do alvo
        : screenSize.width * (1 - advSettings.xTargetPosition) -
            (imageSize / 2); // Borda direita do alvo
    final yPos = screenSize.height * advSettings.yTargetPosition;
    final targetCenterOffset = Offset(xPos, yPos);

    return PopScope(
      // PopScope with canPop == false Prevents the Android back button from closing the screen before _endGame()      canPop: false,
      canPop: false,
      child: Scaffold(
        body: ColoredBox(
          color: Colors.black,
          child: Stack(
            fit: StackFit.expand,
            children: [
              // Só renderiza preview quando a câmera estiver pronta
              if (!_hideGameUI && 
                  cameraService.controller?.value.isInitialized == true)
                FNoseCameraWithLandmarks(
                  cameraPreview: cameraWidget,
                  landmarksOverlay: _landmarksPainter != null
                      ? CustomPaint(painter: _landmarksPainter)
                      : null,
                  imageSize: _imageSize,
                  cameraLensDirection: CameraLensDirection.front,
                  rotation: ImageRotation.rotation0deg,
                  mirrorHorizontal: mirrorX,
                  mirrorVertical: mirrorY,
                  showLandmarks: _showLandmarks,
                  noseOffset: _landmarkOffsets?.nose,
                  leftIndex: _landmarkOffsets?.leftIndexTip,
                  rightIndex: _landmarkOffsets?.rightIndexTip,
                  leftSparkState: ref.watch(leftSparkControllerProvider),
                  rightSparkState: ref.watch(rightSparkControllerProvider),
                ),

              if (_gameState != GameState.notStarted && !_hideGameUI) ...[
                // Blue background
                Positioned.fill(
                  child: Container(
                    margin: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.blue.withAlpha((0.2 * 255).round()),
                      borderRadius: BorderRadius.circular(20),
                    ),
                  ),
                ),

                if (_currentGameMode != FNoseGameMode.rightHand &&
                    ref.watch(leftSparkControllerProvider) ==
                        SparkState.fired &&
                    _landmarkOffsets?.leftIndexTip != null)
                  SparkFireMarker(position: _bestLeftIndexTipPosition!),

                if (_currentGameMode != FNoseGameMode.leftHand &&
                    ref.watch(rightSparkControllerProvider) ==
                        SparkState.fired &&
                    _landmarkOffsets?.rightIndexTip != null)
                  SparkFireMarker(position: _bestRightIndexTipPosition!),

                TargetTouchMarksWidget(marks: _touchMarks),

                TargetWidget(
                  gameMode: _currentGameMode,
                  targetNumber: advSettings.targetNumber,
                  xPercent: advSettings.xTargetPosition,
                  yPercent: advSettings.yTargetPosition,
                  scale: advSettings.targetScale,
                ),

                CustomPaint(
                  painter: TargetHitboxPainter(
                    center: targetCenterOffset,
                    targetScale: advSettings.targetScale,
                  ),
                ),

                ..._explosions,

                CountdownWidget(
                  initialTime: _remainingTime,
                  gameMode: _currentGameMode,
                  showHands: true,
                  onCountdownFinished: _endGame,
                ),

                if (_currentGameMode != FNoseGameMode.rightHand)
                  SparkScoreWidget(
                    count: _leftSparkCount,
                    gameMode: _currentGameMode,
                    color: Colors.lightBlueAccent,
                  ),

                if (_currentGameMode != FNoseGameMode.leftHand)
                  SparkScoreWidget(
                    count: _rightSparkCount,
                    gameMode: _currentGameMode,
                    color: Colors.deepOrangeAccent,
                  ),

                if (_currentGameMode != FNoseGameMode.rightHand &&
                    _landmarkOffsets?.leftIndexTip != null)
                  SparkAuraWidget(
                    position: _landmarkOffsets?.leftIndexTip,
                    sparkState: ref.watch(leftSparkControllerProvider),
                  ),

                if (_currentGameMode != FNoseGameMode.leftHand &&
                    _landmarkOffsets?.rightIndexTip != null)
                  SparkAuraWidget(
                    position: _landmarkOffsets?.rightIndexTip,
                    sparkState: ref.watch(rightSparkControllerProvider),
                  ),
              ],

              // Overlay visible saving even with _hideGameUI
              if (_isEndingGame)
                FNoseSavingOverlay(
                  currentPhase: _currentSavingPhase,
                  progress: _savingProgress,
                ),

              // Validation UI Pre game
              if (!isPreGame && !_isEndingGame)
                FNoseStabilityCheckerOverlay(
                  stabilityAsync: stabilityAsync,
                  showValidationUI: _showValidationUI,
                ),

              if (!_isPositionValidated && _showValidationUI && !_isEndingGame) ...[
                FNoseValidationOverlay(
                  show: _showValidationUI,
                  isDistanceValid:
                      _positionValidationService?.isShoulderDistanceValid ??
                          false,
                  isYAligned:
                      _positionValidationService?.isShoulderYAligned ?? false,
                  isZAligned:
                      _positionValidationService?.isShoulderZAligned ?? false,
                  isNoseCentered:
                      _positionValidationService?.isNoseCentered ?? false,
                  isLeftHand: _currentGameMode == FNoseGameMode.leftHand,
                  currentValidationMessage:
                      _positionValidationService?.currentMessage,
                ),
                NoseAlignmentIndicatorWidget(
                  advSettings: advSettings,
                  gameMode: _currentGameMode,
                  screenSize: MediaQuery.of(context).size,
                  currentNosePosition: _landmarkOffsets?.nose,
                ),
              ],

              if (_isPositionValidated && !_isTargetCalibrated)
                FNoseTargetCalibrationWidget(
                  gameMode: _currentGameMode,
                  xPercent: advSettings.xTargetPosition,
                  yPercent: advSettings.yTargetPosition,
                  scale: advSettings.targetScale,
                  indexTipPosition: _currentGameMode == FNoseGameMode.leftHand
                      ? _landmarkOffsets?.leftIndexTip
                      : _landmarkOffsets?.rightIndexTip,
                  onCalibrated: (offset) {
                    setState(() {
                      _targetCalibrationOffset = offset;
                      _isTargetCalibrated = true;
                      _showTimerPreGame = true;
                    });
                  },
                ),

              if (_showTimerPreGame)
                Positioned.fill(
                  child: FNoseTimerPreGameWidget(
                    onFinished: () {
                      setState(() {
                        _showTimerPreGame = false;
                      });
                      _startGame();
                    },
                  ),
                ),

              // Manual camera configuration overlay
              if (_showManualConfig && !_configurationComplete)
                Positioned.fill(
                  child: ManualCameraConfigWidget(
                    gameMode: _currentGameMode,
                    onConfigurationComplete: () async {
                      // Configuration saved successfully
                      final cameraService = ref.read(cameraServiceProvider);
                      cameraService.onMpPoseDetected = null;
                      
                      setState(() {
                        _showManualConfig = false;
                        _configurationComplete = true;
                        _isConfigurationActive = false;
                      });
                      debugPrint('✅ Manual configuration completed - services stopped');
                      
                      // Small delay to ensure Firebase/cache save is complete
                      await Future.delayed(const Duration(milliseconds: 200));
                      
                      // Reload config from Firebase (now saved)
                      await CameraConfigService.instance.reload();
                      debugPrint('🔄 Config reloaded from Firebase');
                      
                      // Re-establish game callback after configuration
                      _setupPoseCallback();
                    },
                    onConfigurationFailed: () {
                      // Configuration failed
                      final cameraService = ref.read(cameraServiceProvider);
                      cameraService.onMpPoseDetected = null;
                      
                      setState(() {
                        _configurationFailed = true;
                        _isConfigurationActive = false;
                      });
                      // Show error and go back
                      Future.delayed(const Duration(seconds: 3), () {
                        if (mounted) {
                          context.go('/home');
                        }
                      });
                    },
                  ),
                ),

              // Conditional Exibition of lines and landmarks
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _initCameraAndStream() async {
    final cameraService = ref.read(cameraServiceProvider);

    debugPrint('🎬 Initializing camera and stream for FNose game...');

    // Attach MLKit adapter to camera (mantém interface MediaPipe)
    _mpAdapter = MLKitPoseAdapter();
    await _mpAdapter!.initialize();
    cameraService.mpAdapter = _mpAdapter;

    // Obter câmeras disponíveis
    final cameras = await availableCameras();
    
    // Encontrar câmera frontal
    final frontCamera = cameras.firstWhere(
      (camera) => camera.lensDirection == CameraLensDirection.front,
      orElse: () => cameras.first,
    );
    
    await cameraService.initializeCamera(frontCamera);

    // Skip camera validation - use default config directly
    _cameraConfig = await CameraConfigService.instance.getConfig();
    final actualDeviceModel = await CameraConfigService.instance.getActualDeviceModel();
    
    debugPrint('📱 Device: $actualDeviceModel');
    debugPrint('📸 Using default config (validation disabled): ${_cameraConfig!.deviceModel} [rot=${_cameraConfig!.rotationDegrees}°, mirror=[H:${_cameraConfig!.mirrorHorizontal},V:${_cameraConfig!.mirrorVertical}]]');
    
    setState(() {
      _configurationComplete = true; // Always complete - skip validation
    });
    
    // Always setup pose callback immediately
    debugPrint('✅ Using default configuration (validation skipped)');
    _setupPoseCallback();

    debugPrint('📹 Camera initialized successfully');
  }

  void _setupPoseCallback() {
    final cameraService = ref.read(cameraServiceProvider);
    
    cameraService.onMpPoseDetected = (mpPose, imgSize, rotationDeg, lensDir) {
      if (!mounted || _isSaving || _isEndingGame) {
        // debugPrint('⚠️ Skipping pose: mounted=$mounted, saving=$_isSaving, ending=$_isEndingGame');
        return;
      }
      // Aceita poses parciais — lógica abaixo valida landmarks necessários
      final screenSize = MediaQuery.of(context).size;
      final imageSize = imgSize;
      
      // Initialize timestamp relative to game start (only after game started)
      if (_gameState != GameState.notStarted) {
        _timestamp = DateTime.now().millisecondsSinceEpoch - _gameStartTimestamp;
      } else {
        _timestamp = 0; // Use 0 before game starts
      }

      // debugPrint('📐 Image size: $imageSize, screen: $screenSize');

      // Dual-path: raw para logs, smoothed para UI
      final mpRaw = _mpAdapter?.lastPoseRaw;
      final mpSmoothed = _mpAdapter?.lastPoseSmoothed;

      // Use cached config (já carregado na inicialização)
      final config = _cameraConfig ?? CameraImageConfig.globalAndroid;

      setState(() {
        _imageSize = imageSize;
        // UI usa pose suavizada
        _landmarksPainter = mpSmoothed != null
            ? MediaPipePosePainter(
                pose: mpSmoothed,
                imageSize: _imageSize,
                cameraLensDirection: CameraLensDirection.front,
                rotationDegrees: rotationDeg, // Backward compatibility
                outputRotationDegrees: config.outputRotationDegrees,
                outputMirrorHorizontal: config.outputMirrorHorizontal,
                outputMirrorVertical: config.outputMirrorVertical,
              )
            : null;
      });

      // Logs biométricos usam pose raw (sem buffer, todos os frames)
      // TODO: integrar lastPoseRaw aos logs do Firebase em vez de mpPose
      if (mpRaw != null) {
        _landmarkSet = LandmarkSet.fromMediaPipe(mpRaw.landmarks);
      }

      // UI usa pose suavizada
      if (mpSmoothed != null) {
        _landmarkOffsets = LandmarkOffsets.fromMediaPipe(
          lms: mpSmoothed.landmarks,
          screenSize: screenSize,
          imageSize: imageSize,
          isFrontCamera: true,
          rotationDegrees: rotationDeg, // Backward compatibility
          outputRotationDegrees: config.outputRotationDegrees,
          outputMirrorHorizontal: config.outputMirrorHorizontal,
          outputMirrorVertical: config.outputMirrorVertical,
        );
      }

      // debugPrint('🎯 Landmarks - Nose: ${_landmarkOffsets?.nose}, '
      //     'Left Index: ${_landmarkOffsets?.leftIndexTip}, '
      //     'Right Index: ${_landmarkOffsets?.rightIndexTip}');

      // Log pose data during game (only after game started)
      if (_gameState != GameState.notStarted && mpRaw != null && _landmarkSet != null) {
        final frameData = <String, dynamic>{
          'timestamp': _timestamp,
          'landmarks': <String, dynamic>{},
          'offsets': <String, dynamic>{},
        };

        // Add raw landmarks (normalized coordinates)
        void addLandmark(String name, int index) {
          try {
            final lm = mpRaw!.landmarks.firstWhere((l) => l.index == index);
            (frameData['landmarks'] as Map<String, dynamic>)[name] = {
              'x': lm.x,
              'y': lm.y,
              'z': lm.z,
              'visibility': lm.visibility,
            };
          } catch (e) {
            // Landmark not found, skip
          }
        }

        // Add required landmarks: nose(0), shoulders(11,12), elbows(13,14), wrists(15,16), index(19,20)
        addLandmark('nose', 0);
        addLandmark('leftShoulder', 11);
        addLandmark('rightShoulder', 12);
        addLandmark('leftElbow', 13);
        addLandmark('rightElbow', 14);
        addLandmark('leftWrist', 15);
        addLandmark('rightWrist', 16);
        addLandmark('leftIndex', 19);
        addLandmark('rightIndex', 20);

        // Add projected offsets (screen coordinates) - dedos projetados
        if (_landmarkOffsets != null) {
          void addOffset(String name, Offset? offset) {
            if (offset != null) {
              (frameData['offsets'] as Map<String, dynamic>)[name] = {
                'x': offset.dx,
                'y': offset.dy,
              };
            }
          }

          addOffset('nose', _landmarkOffsets!.nose);
          addOffset('leftShoulder', _landmarkOffsets!.leftShoulder);
          addOffset('rightShoulder', _landmarkOffsets!.rightShoulder);
          addOffset('leftElbow', _landmarkOffsets!.leftElbow);
          addOffset('rightElbow', _landmarkOffsets!.rightElbow);
          addOffset('leftWrist', _landmarkOffsets!.leftWrist);
          addOffset('rightWrist', _landmarkOffsets!.rightWrist);
          addOffset('leftIndex', _landmarkOffsets!.leftIndex);
          addOffset('rightIndex', _landmarkOffsets!.rightIndex);
          addOffset('leftIndexTip', _landmarkOffsets!.leftIndexTip);
          addOffset('rightIndexTip', _landmarkOffsets!.rightIndexTip);
        }

        _poseLog.add(frameData);
      }

      // Existing gameplay logic remains unchanged...
      final leftSparkController =
          ref.read(leftSparkControllerProvider.notifier);
      final currentLeftSparkState = ref.read(leftSparkControllerProvider);
      final rightSparkController =
          ref.read(rightSparkControllerProvider.notifier);
      final currentRightSparkState = ref.read(rightSparkControllerProvider);

      // === LEFT HAND ===
      final ls = _landmarkSet;
      final leftLandmarksReady = ls?.leftShoulder != null &&
          ls?.leftElbow != null &&
          ls?.leftWrist != null &&
          ls?.leftIndexTip != null &&
          ls?.nose != null;

      if (leftLandmarksReady && _leftArmTracker != null) {
        _leftArmTracker!.updateFromLandmarks(
          shoulder: ls!.leftShoulder!,
          elbow: ls.leftElbow!,
          wrist: ls.leftWrist!,
          index: ls.leftIndexTip!,
          nose: ls.nose!,
          imageSize: _imageSize,
        );
      } else {
        // debugPrint('Missing landmarks for left arm tracking');
      }

      final isLeftActive = _currentGameMode == FNoseGameMode.leftHand ||
          _currentGameMode == FNoseGameMode.bothHands;

      if (isLeftActive && _leftArmTracker != null) {
        final tracker = _leftArmTracker!;
        final sparkState = currentLeftSparkState;

        if (sparkState == SparkState.idle && tracker.isNoseTouch()) {
          leftSparkController.goArmed();
          // debugPrint('LEFT: Armed after nose touch');
        } else if (sparkState == SparkState.armed && tracker.isExtending()) {
          leftSparkController.goAiming();
          // debugPrint('LEFT: Aiming after arm extension');
        } else if (sparkState == SparkState.aiming) {
          final angle = tracker.latestAngle;

          if (_landmarkOffsets?.leftIndexTip != null &&
              angle > _maxLeftExtensionAngle) {
            final tip = _landmarkOffsets!.leftIndexTip!;
            _maxLeftExtensionAngle = angle;
            _bestLeftIndexTipPosition = tip;
            // debugPrint('LEFT: New max extension: ${angle.toStringAsFixed(1)}°');

            if (tracker.isTargetTouch()) {
              final isInside = FNoseGameController.isTouchInsideTarget(
                mark: tip - _targetCalibrationOffset,
                isLeft: true,
                screenSize: MediaQuery.of(context).size,
                xTargetPosition: _advSettings.xTargetPosition,
                yTargetPosition: _advSettings.yTargetPosition,
                targetScale: _advSettings.targetScale,
              );

              if (isInside) {
                setState(() {
                  _touchMarks.add(TargetTouchMark(
                    position: tip - _targetCalibrationOffset,
                    isLeftHand: true,
                    angle: angle,
                  ));
                  _addExplosion(tip - _targetCalibrationOffset);
                });

                _wasLastLeftTouchValid = true;

                _touchLogs.add(
                  FNoseGameController.buildTouchLog(
                    mark: tip - _targetCalibrationOffset,
                    nose: _landmarkOffsets!.nose!,
                    isLeft: true,
                    screenSize: MediaQuery.of(context).size,
                    xTargetPosition: _advSettings.xTargetPosition,
                    yTargetPosition: _advSettings.yTargetPosition,
                    targetScale: _advSettings.targetScale,
                    timestamp: _timestamp,
                    gameMode: _currentGameMode,
                  ),
                );

                // debugPrint('LEFT: Target touched at $tip');
              } else {
                _addExplosion(tip, isError: true);
                _wasLastLeftTouchValid = false;
                // debugPrint('LEFT: Touch rejected — outside target');
              }
            }
          }

          if (tracker.isFlexioning()) {
            leftSparkController.goFire();
            leftSparkController.reset();
            debugPrint(
                'LEFT: Fired! Max extension: ${_maxLeftExtensionAngle.toStringAsFixed(1)}°');

            if (_wasLastLeftTouchValid) {
              setState(() {
                _leftSparkCount++;
              });
            }

            _maxLeftExtensionAngle = 0;
            _wasLastLeftTouchValid = false;
          }
        }
      } else {
        _leftArmTracker?.reset();
        leftSparkController.reset();
      }

      // === RIGHT HAND ===
      final rs = _landmarkSet;
      final rightLandmarksReady = rs?.rightShoulder != null &&
          rs?.rightElbow != null &&
          rs?.rightWrist != null &&
          rs?.rightIndexTip != null &&
          rs?.nose != null;

      if (rightLandmarksReady && _rightArmTracker != null) {
        _rightArmTracker!.updateFromLandmarks(
          shoulder: rs!.rightShoulder!,
          elbow: rs.rightElbow!,
          wrist: rs.rightWrist!,
          index: rs.rightIndexTip!,
          nose: rs.nose!,
          imageSize: _imageSize,
        );
      } else {
        // debugPrint('Missing landmarks for right arm tracking');
      }

      final isRightActive = _currentGameMode == FNoseGameMode.rightHand ||
          _currentGameMode == FNoseGameMode.bothHands;

      if (isRightActive && _rightArmTracker != null) {
        final tracker = _rightArmTracker!;
        final sparkState = currentRightSparkState;

        if (sparkState == SparkState.idle && tracker.isNoseTouch()) {
          rightSparkController.goArmed();
          // debugPrint('RIGHT: Armed after nose touch');
        } else if (sparkState == SparkState.armed && tracker.isExtending()) {
          rightSparkController.goAiming();
          // debugPrint('RIGHT: Aiming after arm extension');
        } else if (sparkState == SparkState.aiming) {
          final angle = tracker.latestAngle;

          if (_landmarkOffsets?.rightIndexTip != null &&
              angle > _maxRightExtensionAngle) {
            final tip = _landmarkOffsets!.rightIndexTip!;
            _maxRightExtensionAngle = angle;
            _bestRightIndexTipPosition = tip;
            debugPrint(
                'RIGHT: New max extension: ${_maxRightExtensionAngle.toStringAsFixed(1)}°');

            if (tracker.isTargetTouch()) {
              final isInside = FNoseGameController.isTouchInsideTarget(
                mark: tip - _targetCalibrationOffset,
                isLeft: false,
                screenSize: MediaQuery.of(context).size,
                xTargetPosition: _advSettings.xTargetPosition,
                yTargetPosition: _advSettings.yTargetPosition,
                targetScale: _advSettings.targetScale,
              );

              if (isInside) {
                setState(() {
                  _touchMarks.add(TargetTouchMark(
                    position: tip - _targetCalibrationOffset,
                    isLeftHand: false,
                    angle: angle,
                  ));
                  _addExplosion(tip - _targetCalibrationOffset);
                });

                _wasLastRightTouchValid = true;

                _touchLogs.add(
                  FNoseGameController.buildTouchLog(
                    mark: tip - _targetCalibrationOffset,
                    nose: _landmarkOffsets!.nose!,
                    isLeft: false,
                    screenSize: MediaQuery.of(context).size,
                    xTargetPosition: _advSettings.xTargetPosition,
                    yTargetPosition: _advSettings.yTargetPosition,
                    targetScale: _advSettings.targetScale,
                    timestamp: _timestamp,
                    gameMode: _currentGameMode,
                  ),
                );

                // debugPrint('RIGHT: Target touched at $tip');
              } else {
                _addExplosion(tip, isError: true);
                _wasLastRightTouchValid = false;
                // debugPrint('RIGHT: Touch rejected — outside target');
              }
            }
          }

          if (tracker.isFlexioning()) {
            rightSparkController.goFire();
            rightSparkController.reset();
            debugPrint(
                'RIGHT: Fired! Max extension: ${_maxRightExtensionAngle.toStringAsFixed(1)}°');

            if (_wasLastRightTouchValid) {
              setState(() {
                _rightSparkCount++;
              });
            }

            _maxRightExtensionAngle = 0;
            _wasLastRightTouchValid = false;
          }
        }
      } else {
        _rightArmTracker?.reset();
        rightSparkController.reset();
      }
    };
  }

  void _addExplosion(Offset position, {bool isError = false}) {
    if (isError && _gameState == GameState.notStarted) {
      return;
    }
    
    setState(() {
      _explosions.add(
        TouchExplosion(
          position: position,
          color: isError ? Colors.redAccent : Colors.yellowAccent,
          onComplete: () {
            setState(() {
              if (_explosions.isNotEmpty) {
                _explosions.removeAt(0);
              }
            });
          },
        ),
      );
    });
  }
}
