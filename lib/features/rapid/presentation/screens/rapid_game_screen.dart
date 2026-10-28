import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:msupperlimbs/core/utils/screen_orientation.dart';
import 'package:msupperlimbs/features/gameplay/application/device_stability_service_provider.dart';
import 'package:msupperlimbs/features/gameplay/application/session_state.dart';
import 'package:msupperlimbs/features/rapid/application/rapid_camera_provider.dart';
import 'package:msupperlimbs/features/rapid/application/rapid_match_state.dart';
import 'package:msupperlimbs/features/rapid/application/rapid_settings_state.dart';
import 'package:msupperlimbs/features/rapid/motion/rapid_camera_service.dart';
import 'package:msupperlimbs/features/rapid/motion/rapid_hand_detector.dart';
import 'package:msupperlimbs/features/rapid/presentation/widgets/hand_landmarks_debug_painter.dart';
import 'package:msupperlimbs/features/rapid/presentation/widgets/hand_position_detector.dart';
import 'package:msupperlimbs/features/rapid/presentation/widgets/pulse_line_widget.dart';
import 'package:msupperlimbs/features/rapid/presentation/widgets/rapid_saving_overlay.dart';
import 'package:msupperlimbs/features/rapid/presentation/widgets/pulse_bar_widget.dart';
import 'package:msupperlimbs/features/rapid/presentation/widgets/pulse_circle_widget.dart';
import 'package:msupperlimbs/features/rapid/controllers/pulse_line_controller.dart';
import 'package:msupperlimbs/features/rapid/motion/utils/hand_frame_data_utils.dart';

class RapidGameScreen extends ConsumerStatefulWidget {
  const RapidGameScreen({super.key});

  @override
  ConsumerState<RapidGameScreen> createState() => _RapidGameScreenState();
}

class _RapidGameScreenState extends ConsumerState<RapidGameScreen> {
  // Game state
  int _remainingTime = 30;
  bool _isGameRunning = false;
  bool _isGameEnded = false;
  bool _isEndingGame = false;
  bool _isSaving = false;
  bool _hideGameUI = false;
  SavingPhase _currentSavingPhase = SavingPhase.savingPoseData;
  double _savingProgress = 0.0;
  Timer? _gameTimer;
  Timer? _physicsTimer;
  List<Map<String, dynamic>> _poseData = [];
  String _detectedHand = 'Nenhuma mão detectada';
  
  // Detecção de mão
  bool _isLeftHandDetected = false;
  bool _isRightHandDetected = false;
  
  // Hand detection
  String _nativeResponse = 'No response yet';
  List<Map<String, dynamic>> _handLandmarks = [];
  Size _imageSize = const Size(640, 480);
  
  // Pulse line
  late PulseLineController _pulseLineController;
  Map<String, Offset?> _previousOffsets = {};
  
  // Finger tapping detection
  int _tapCount = 0;
  bool _isFingerTapping = false;
  int _lastTapTime = 0;
  int _tapCooldownMs = 110; // Cooldown between taps in milliseconds, updated from settings
  
  // Tapping sensitivity - lower value = more sensitive (smaller distance required)
  double _tapSensitivity = 50.0; // Default value, will be updated from settings
  
  // Simplified pulse line parameters
  double _currentPulseHeight = 0.5; // Current height (0-1), starts at 0.5
  double _pulseImpulse = 0.16;      // How much each tap increases height
  double _pulseGravity = 0.01;      // How much gravity reduces height per period
  
  // Logging data
  List<Map<String, dynamic>> _tapLogs = [];
  List<Map<String, dynamic>> _pulseStateLogs = [];
  
  // Método para carregar configurações e inicializar o controlador
  void _initializeSettings() {
    final settings = ref.read(rapidSettingsStateProvider);
    
    // Configure tap detection
    _tapSensitivity = settings?.tapSensitivity ?? 50.0;
    _tapCooldownMs = settings?.tapCooldownMs ?? 110;
    
    // Configure pulse physics
    _pulseGravity = settings?.gravityPerSecond ?? 0.35;
    _pulseImpulse = settings?.impulseStrength ?? 0.06;
    
    // Initialize pulse line controller with settings
    _pulseLineController = PulseLineController(
      // Pulse line controller settings
      maxPoints: settings?.maxPoints ?? 420,
      minY: settings?.minY ?? 0.0,
      maxY: settings?.maxY ?? 1.0,
      baseline: settings?.baseline ?? 0.25,
      gravityPerSecond: settings?.gravityPerSecond ?? 0.35,
      impulseStrength: settings?.impulseStrength ?? 0.06,
      floorRestitution: settings?.floorRestitution ?? 0.0,
      
      // Decay rates
      decayRateIdle: settings?.decayRateIdle ?? 0.05,
      decayRateActive: settings?.decayRateActive ?? 0.03,
      decayRateUnstable: settings?.decayRateUnstable ?? 0.07,
      decayRateFlatline: settings?.decayRateFlatline ?? 0.10,
    );
    
    // Set up pulse line controller callbacks for logging
    _pulseLineController.onStateChange = (height, state, eventType) {
      if (_isGameRunning) {
        _pulseStateLogs.add({
          'timestamp': DateTime.now().millisecondsSinceEpoch,
          'pulseHeight': height,
          'pulseState': state.name,
          'eventType': eventType,
        });
      }
    };
    
    _pulseLineController.onImpulse = (heightBefore, heightAfter, impulseStrength) {
      if (_isGameRunning) {
        debugPrint('[PULSE_LOG] Impulse: $heightBefore -> $heightAfter (strength: $impulseStrength)');
        _pulseStateLogs.add({
          'timestamp': DateTime.now().millisecondsSinceEpoch,
          'pulseHeight': heightAfter,
          'pulseState': _pulseLineController.state.name,
          'eventType': 'impulse',
          'additionalData': {
            'heightBefore': heightBefore,
            'heightAfter': heightAfter,
            'impulseStrength': impulseStrength,
          },
        });
      }
    };
  }

  @override
  void initState() {
    super.initState();
    lockToLandscape();
    
    // Inicializa a altura da linha no meio (0.5)
    _currentPulseHeight = 0.5;
    
    // Carrega as configurações e inicializa o controlador
    _initializeSettings();
    
    // Inicializa o serviço de estabilidade do dispositivo
    final stabilityService = ref.read(deviceStabilityServiceProvider);
    stabilityService.startStabilityCheck();
    
    // Configura a detecção de mão
    _setupHandDetection();
    // Game will be started after hand detection is complete
  }

  Future<void> _setupHandDetection() async {
    // Get services from providers
    final cameraService = ref.read(rapidCameraServiceProvider);
    final handDetector = ref.read(rapidHandDetectorProvider);
    
    // Test native connection
    final testResult = await handDetector.testNativeConnection();
    setState(() {
      _nativeResponse = testResult;
    });
    
    // Set up callback for landmarks
    handDetector.onLandmarksDetected = (landmarks) {
      // Determine which hand is detected based on landmarks
      String detectedHand = 'No hand detected';
      bool isLeftHandDetected = false;
      bool isRightHandDetected = false;
      
      if (landmarks.isNotEmpty) {
        // Check each landmark to determine which hand is present
        for (final landmark in landmarks) {
          final handType = landmark['type'] as String? ?? 'unknown';
          if (handType.toLowerCase().contains('left')) {
            isLeftHandDetected = true;
          } else if (handType.toLowerCase().contains('right')) {
            isRightHandDetected = true;
          }
        }
        
        // Update detection text
        if (isLeftHandDetected && isRightHandDetected) {
          detectedHand = 'Both hands detected';
        } else if (isLeftHandDetected) {
          detectedHand = 'Left hand detected';
        } else if (isRightHandDetected) {
          detectedHand = 'Right hand detected';
        }
        
        // Calculate movement intensity for pulse line
        _updatePulseLineFromLandmarks(landmarks);
      }
      
      setState(() {
        _handLandmarks = landmarks;
        _detectedHand = detectedHand;
        _isLeftHandDetected = isLeftHandDetected;
        _isRightHandDetected = isRightHandDetected;
      });
      
      // Record landmarks data with timestamp if game is running
      if (_isGameRunning && landmarks.isNotEmpty) {
        final settings = ref.read(rapidSettingsStateProvider);
        final selectedHand = settings?.gameMode ?? 'rightHand';
        
        // Filter landmarks by selected hand
        final filteredLandmarks = _filterLandmarksByHand(landmarks, selectedHand);
        
        if (filteredLandmarks.isNotEmpty) {
          _poseData.add({
            'timestamp': DateTime.now().millisecondsSinceEpoch,
            'landmarks': filteredLandmarks,
            'selectedHand': selectedHand,
          });
        }
      }
    };
    
    // Set up callback for camera frames
    cameraService.onFrameAvailable = (imageBytes, imageSize) {
      setState(() {
        _imageSize = imageSize;
      });
      
      // Process frame for hand detection
      handDetector.processFrame(imageBytes, imageSize);
    };
    
    // Initialize camera
    await cameraService.initialize();
    
    // Load settings
    _loadSettings();
  }
  
  void _loadSettings() {
    final session = ref.read(sessionProvider);
    if (session != null) {
      ref.read(rapidSettingsProvider(session.userId)).whenData((settings) {
        setState(() {
          _remainingTime = settings.totalTime;
          _tapSensitivity = settings.tapSensitivity ?? 50.0;
          _pulseGravity = settings.gravityPerSecond ?? 0.35; // Usar nova configuração de gravidade
          _pulseImpulse = settings.pulseImpulse ?? 0.16;
          _currentPulseHeight = 0.5; // Sempre começa no meio
        });
        
        // Store settings in state provider for easy access
        ref.read(rapidSettingsStateProvider.notifier).state = settings;
      });
    }
  }

  @override
  void dispose() {
    // Clean up timers first
    _gameTimer?.cancel();
    _physicsTimer?.cancel();
    
    // Dispose of the pulse line controller
    _pulseLineController.dispose();
    
    // Clear all memory resources
    _clearMemoryResources();
    
    // Reset screen orientation
    lockToPortrait();
    
    super.dispose();
  }
  
  void _startGame() async {
    debugPrint('[RAPID GAME] _startGame() called');
    final session = ref.read(sessionProvider);
    final settings = ref.read(rapidSettingsStateProvider);
    if (session == null || settings == null) {
      debugPrint('[ERROR] Missing session or settings - session: $session, settings: $settings');
      return;
    }
    
    // Clear previous data
    _poseData.clear();
    _tapLogs.clear();
    _pulseStateLogs.clear();
    debugPrint('[RAPID GAME] Data cleared - pose: ${_poseData.length}, taps: ${_tapLogs.length}, pulse: ${_pulseStateLogs.length}');
    
    // Create new match in Firebase
    debugPrint('[RAPID GAME] Creating match for user: ${session.userId}, session: ${session.sessionId}');
    debugPrint('[RAPID GAME] Settings: gameMode=${settings.gameMode}, totalTime=${settings.totalTime}, visualizationType=${settings.visualizationType}');
    
    try {
      await ref.read(rapidMatchStateProvider.notifier).startMatch(
        userId: session.userId,
        sessionId: session.sessionId,
        gameMode: settings.gameMode,
        totalTime: settings.totalTime,
        imageWidth: _imageSize.width.toInt(),
        imageHeight: _imageSize.height.toInt(),
        screenWidth: MediaQuery.of(context).size.width.toInt(),
        screenHeight: MediaQuery.of(context).size.height.toInt(),
        selectedHand: settings.gameMode, // Use gameMode as selectedHand
        visualizationType: settings.visualizationType,
        settingsData: settings.toMap(),
      );
      debugPrint('[RAPID GAME] Match created successfully');
    } catch (e, stack) {
      debugPrint('[ERROR] Failed to create match: $e');
      debugPrint(stack.toString());
    }
    
    // Start the game timer
    if (mounted) {
      setState(() {
        _isGameRunning = true;
        _remainingTime = settings.totalTime;
        _tapCount = 0; // Reset tap count when game starts
        _lastTapTime = 0;
        _isFingerTapping = false;
      });
    }
    
    _gameTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (mounted) {
        setState(() {
          _remainingTime--;
          if (_remainingTime <= 0) {
            _endGame();
          }
        });
      }
    });
    
    // Garante que a linha começa no meio
    _currentPulseHeight = 0.5;
    _pulseLineController.update(_currentPulseHeight);
    
    // Não precisamos mais do physics timer, pois o controlador já tem sua própria física
    // O widget PulseLineWidget já chama o método tick() do controlador a cada frame
    _physicsTimer?.cancel(); // Cancela qualquer timer existente
    
    // Debug print ocasional
    _physicsTimer = Timer.periodic(const Duration(milliseconds: 500), (timer) {
      // Debug print a cada 0.5 segundos
      debugPrint('[PHYSICS_TIMER] Current Y: ${(_pulseLineController.currentY * 100).toStringAsFixed(1)}%');
    });
    
    // Force garbage collection for validation widgets
    // This helps ensure they're not consuming memory after game starts
    Future.microtask(() {
      // Give a little time for state to update before forcing GC
      _clearMemoryResources();
    });
  }
  
  void _endGame() async {
    if (!_isGameRunning) return;
    
    setState(() {
      _isEndingGame = true;
      _isSaving = true;
      _hideGameUI = true;
    });
    
    // Cancel timers
    _gameTimer?.cancel();
    _physicsTimer?.cancel();
    
    // Capture refs before changing state
    final cameraService = ref.read(rapidCameraServiceProvider);
    final handDetector = ref.read(rapidHandDetectorProvider);
    final settings = ref.read(rapidSettingsStateProvider);
    final matchNotifier = ref.read(rapidMatchStateProvider.notifier);
    
    if (mounted) {
      setState(() {
        _isGameRunning = false;
        _isGameEnded = true;
      });
    }
    
    // Remove callbacks to prevent further processing
    handDetector.onLandmarksDetected = null;
    cameraService.onFrameAvailable = null;
    
    // Stop image stream and dispose camera
    await cameraService.stopImageStream();
    await cameraService.dispose();
    
    // Clear only navigation data, NOT the logs we need to save!
    _previousOffsets.clear();
    _handLandmarks = [];
    
    // Save match data
    final totalTime = settings?.totalTime ?? 30;
    
    // CRITICAL DEBUG: Check data BEFORE any async operations
    debugPrint('[RAPID GAME] ========== PRE-FINALIZATION DATA CHECK ==========');
    debugPrint('[RAPID GAME] _tapLogs is null? ${_tapLogs == null}');
    debugPrint('[RAPID GAME] _tapLogs length: ${_tapLogs.length}');
    debugPrint('[RAPID GAME] _pulseStateLogs is null? ${_pulseStateLogs == null}');
    debugPrint('[RAPID GAME] _pulseStateLogs length: ${_pulseStateLogs.length}');
    debugPrint('[RAPID GAME] _poseData length: ${_poseData.length}');
    debugPrint('[RAPID GAME] Tap count variable: $_tapCount');
    
    // Create copies to prevent modification
    final tapLogsCopy = List<Map<String, dynamic>>.from(_tapLogs);
    final pulseStateLogsCopy = List<Map<String, dynamic>>.from(_pulseStateLogs);
    final poseDataCopy = List<Map<String, dynamic>>.from(_poseData);
    
    debugPrint('[RAPID GAME] Copies created:');
    debugPrint('  - tapLogsCopy: ${tapLogsCopy.length}');
    debugPrint('  - pulseStateLogsCopy: ${pulseStateLogsCopy.length}');
    debugPrint('  - poseDataCopy: ${poseDataCopy.length}');
    debugPrint('[RAPID GAME] =====================================================');
    
    try {
      await matchNotifier.finalizeMatch(
        poseData: poseDataCopy,
        tapLogs: tapLogsCopy,
        pulseStateLogs: pulseStateLogsCopy,
        onProgress: (phase, progress) {
          setState(() {
            _currentSavingPhase = phase;
            _savingProgress = progress;
          });
        },
        additionalData: {
          'tapCount': _tapCount,
          'totalTime': totalTime,
          'tapsPerSecond': _tapCount / totalTime,
        },
      );
      debugPrint('[RAPID GAME] Match finalization completed successfully');
    } catch (e, stack) {
      debugPrint('[ERROR] Failed to finalize match: $e');
      debugPrint(stack.toString());
    }
    
    // NOW we can safely clear the memory resources after saving
    _clearMemoryResources();
    
    // Navigate to feedback screen with safety check
    // Small delay to ensure widget tree is stable before navigation
    if (mounted && context.mounted) {
      try {
        await Future.delayed(const Duration(milliseconds: 100));
        if (mounted && context.mounted) {
          context.go('/rapid-feedback');
        }
      } catch (e) {
        debugPrint('[ERROR] Navigation failed: $e');
      }
    }
  }
  
  /// Clears memory resources to prevent memory leaks
  void _clearMemoryResources() {
    // Clear large data structures
    _poseData = [];
    _handLandmarks = [];
    _previousOffsets = {};
    _tapLogs = [];
    _pulseStateLogs = [];
    
    // Force a garbage collection cycle (indirectly)
    // This is a hint to the system that we've cleared large data
    // and it's a good time to run garbage collection
    setState(() {});
  }
  
  
  /// Updates the pulse line controller with simplified pulse logic
  void _updatePulseLineFromLandmarks(List<Map<String, dynamic>> landmarks) {
    if (landmarks.isEmpty) return;
    
    // Convert native landmarks to HandLandmarkOffsets
    final handOffsets = _convertNativeLandmarksToOffsets(landmarks);
    
    // Detect finger tapping - if tap detected, apply impulse
    final tapDetected = _detectFingerTappingFromOffsets(handOffsets);
    
    if (tapDetected) {
      // Apply impulse when tap is detected (increase height directly)
      // Gravity is applied continuously by the physics timer
      _pulseLineController.impulse();
    }
  }
  
  /// Este método não é mais necessário, pois estamos usando a física do controller
  /// Mantido apenas para compatibilidade com código existente
  void _applySimplePulseLogic(bool tapDetected) {
    // Não faz nada - a física é gerenciada pelo PulseLineController
    if (tapDetected) {
      debugPrint('[PULSE_DEBUG] 📈 Tap detectado - impulso gerenciado pelo controller');
    }
  }
  
  /// Converts native landmarks to HandLandmarkOffsets structure
  HandLandmarkOffsets _convertNativeLandmarksToOffsets(List<Map<String, dynamic>> landmarks) {
    Map<String, Offset> landmarkMap = {};
    
    // Get screen size for coordinate transformation
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;
    
    debugPrint('[PULSE_DEBUG] Processing ${landmarks.length} landmarks');
    
    // Native detector returns landmarks in sequential order (0-20 for each hand)
    // For 1 hand: 21 landmarks (indices 0-20)
    // For 2 hands: 42 landmarks (first hand 0-20, second hand 21-41)
    
    if (landmarks.length >= 21) {
      // Process first hand (assume left for now - we'll need handedness info later)
      for (int i = 0; i < 21; i++) {
        final landmark = landmarks[i];
        final x = (landmark['x'] is num) ? (landmark['x'] as num).toDouble() : null;
        final y = (landmark['y'] is num) ? (landmark['y'] as num).toDouble() : null;
        
        if (x != null && y != null) {
          // Transform normalized coordinates (0-1) to screen coordinates
          // Apply mirror effect like HandLandmarksDebugPainter does
          final screenX = (1.0 - x) * screenWidth;
          final screenY = y * screenHeight;
          
          // Use left hand IDs for first 21 landmarks
          final id = 'left_$i';
          landmarkMap[id] = Offset(screenX, screenY);
          _previousOffsets[id] = Offset(screenX, screenY);
          
          // Debug: log finger tips only
          if (i == 4 || i == 8 || i == 12 || i == 16 || i == 20) {
            debugPrint('[PULSE_DEBUG] Finger tip $id: normalized($x, $y) -> screen($screenX, $screenY)');
          }
        }
      }
    }
    
    // Process second hand if present
    if (landmarks.length >= 42) {
      for (int i = 21; i < 42; i++) {
        final landmark = landmarks[i];
        final x = (landmark['x'] is num) ? (landmark['x'] as num).toDouble() : null;
        final y = (landmark['y'] is num) ? (landmark['y'] as num).toDouble() : null;
        
        if (x != null && y != null) {
          final screenX = (1.0 - x) * screenWidth;
          final screenY = y * screenHeight;
          
          // Use right hand IDs for second 21 landmarks
          final landmarkIndex = i - 21;
          final id = 'right_$landmarkIndex';
          landmarkMap[id] = Offset(screenX, screenY);
          _previousOffsets[id] = Offset(screenX, screenY);
          
          if (landmarkIndex == 4 || landmarkIndex == 8 || landmarkIndex == 12 || 
              landmarkIndex == 16 || landmarkIndex == 20) {
            debugPrint('[PULSE_DEBUG] Finger tip $id: normalized($x, $y) -> screen($screenX, $screenY)');
          }
        }
      }
    }
    
    debugPrint('[PULSE_DEBUG] Converted ${landmarkMap.length} landmarks');
    
    // Create HandLandmarkOffsets from the landmark map
    return HandLandmarkOffsets.fromNativeLandmarks(landmarkMap);
  }
  
  /// Detects finger tapping (finger tip to thumb tip)
  double _detectFingerTapping(Map<String, Offset> fingerTips) {
    // Default intensity if no tapping detected
    double tapIntensity = 0.01;
    bool tapDetected = false;
    String? tappedFinger;
    double detectedDistance = 0.0;
    
    // Get thumb tip positions
    Offset? leftThumbTip = fingerTips['left_4'];
    Offset? rightThumbTip = fingerTips['right_4'];
    
    // Check for tapping on left hand
    if (leftThumbTip != null) {
      // Get closest finger to thumb
      Map<String, double> fingerDistances = _getFingerDistances(
        fingerTips, 
        leftThumbTip, 
        ['left_8', 'left_12', 'left_16', 'left_20']
      );
      
      // Find the closest finger
      String? closestFinger;
      double minDistance = double.infinity;
      
      fingerDistances.forEach((finger, distance) {
        if (distance < minDistance) {
          minDistance = distance;
          closestFinger = finger;
        }
      });
      
      // If any finger is close to thumb, consider it a tap
      if (minDistance < _tapSensitivity && closestFinger != null) {
        // Calculate intensity based on how close the fingers are
        tapIntensity = 1.0 - (minDistance / _tapSensitivity).clamp(0.0, 1.0);
        tapDetected = true;
        tappedFinger = closestFinger;
        detectedDistance = minDistance;
        debugPrint('Left hand tap detected! Finger: $closestFinger, Distance: $minDistance, Intensity: $tapIntensity');
      }
    }
    
    // Check for tapping on right hand
    if (rightThumbTip != null && !tapDetected) { // Only check right if left not detected
      // Get closest finger to thumb
      Map<String, double> fingerDistances = _getFingerDistances(
        fingerTips, 
        rightThumbTip, 
        ['right_8', 'right_12', 'right_16', 'right_20']
      );
      
      // Find the closest finger
      String? closestFinger;
      double minDistance = double.infinity;
      
      fingerDistances.forEach((finger, distance) {
        if (distance < minDistance) {
          minDistance = distance;
          closestFinger = finger;
        }
      });
      
      // If any finger is close to thumb, consider it a tap
      if (minDistance < _tapSensitivity && closestFinger != null) {
        // Calculate intensity based on how close the fingers are
        tapIntensity = 1.0 - (minDistance / _tapSensitivity).clamp(0.0, 1.0);
        tapDetected = true;
        tappedFinger = closestFinger;
        detectedDistance = minDistance;
        debugPrint('Right hand tap detected! Finger: $closestFinger, Distance: $minDistance, Intensity: $tapIntensity');
      }
    }
    
    // Count taps with cooldown to avoid multiple counts for the same tap
    final currentTime = DateTime.now().millisecondsSinceEpoch;
    
    if (tapDetected) {
      // Only register a new tap if:
      // 1. We weren't already in a tapping state, or
      // 2. Enough time has passed since the last tap
      if (!_isFingerTapping || (currentTime - _lastTapTime > _tapCooldownMs)) {
        if (_isGameRunning) {
          setState(() {
            _tapCount++;
            _lastTapTime = currentTime;
            
            // Log detailed tap information
            debugPrint('TAP #$_tapCount: Finger $tappedFinger touched thumb at distance $detectedDistance (threshold: $_tapSensitivity)');
          });
        }
      }
      _isFingerTapping = true;
    } else {
      _isFingerTapping = false;
    }
    
    return tapIntensity;
  }
  
  /// Detects finger tapping using HandLandmarkOffsets
  /// Returns true if tap detected, false otherwise
  bool _detectFingerTappingFromOffsets(HandLandmarkOffsets offsets) {
    bool tapDetected = false;
    String? tappedFinger;
    double detectedDistance = 0.0;
    
    // Check left hand tapping
    if (offsets.leftThumbTip != null) {
      final thumbTip = offsets.leftThumbTip!;
      double minDistance = double.infinity;
      String? closestFinger;
      
      debugPrint('[PULSE_DEBUG] Left thumb at: $thumbTip');
      
      // Check each finger tip against thumb
      final fingerTips = [
        ('left_8', offsets.leftIndexTip),
        ('left_12', offsets.leftMiddleTip),
        ('left_16', offsets.leftRingTip),
        ('left_20', offsets.leftPinkyTip),
      ];
      
      for (final (fingerId, fingerTip) in fingerTips) {
        if (fingerTip != null) {
          final distance = (thumbTip - fingerTip).distance;
          debugPrint('[PULSE_DEBUG] Distance $fingerId to thumb: $distance (threshold: $_tapSensitivity)');
          if (distance < minDistance) {
            minDistance = distance;
            closestFinger = fingerId;
          }
        }
      }
      
      if (minDistance < _tapSensitivity && closestFinger != null) {
        tapDetected = true;
        tappedFinger = closestFinger;
        detectedDistance = minDistance;
        debugPrint('[PULSE_DEBUG] ✓ LEFT TAP DETECTED! Finger: $closestFinger, Distance: $minDistance');
      }
    }
    
    // Check right hand tapping (only if left not detected)
    if (!tapDetected && offsets.rightThumbTip != null) {
      final thumbTip = offsets.rightThumbTip!;
      double minDistance = double.infinity;
      String? closestFinger;
      
      debugPrint('[PULSE_DEBUG] Right thumb at: $thumbTip');
      
      final fingerTips = [
        ('right_8', offsets.rightIndexTip),
        ('right_12', offsets.rightMiddleTip),
        ('right_16', offsets.rightRingTip),
        ('right_20', offsets.rightPinkyTip),
      ];
      
      for (final (fingerId, fingerTip) in fingerTips) {
        if (fingerTip != null) {
          final distance = (thumbTip - fingerTip).distance;
          debugPrint('[PULSE_DEBUG] Distance $fingerId to thumb: $distance (threshold: $_tapSensitivity)');
          if (distance < minDistance) {
            minDistance = distance;
            closestFinger = fingerId;
          }
        }
      }
      
      if (minDistance < _tapSensitivity && closestFinger != null) {
        tapDetected = true;
        tappedFinger = closestFinger;
        detectedDistance = minDistance;
        debugPrint('[PULSE_DEBUG] ✓ RIGHT TAP DETECTED! Finger: $closestFinger, Distance: $minDistance');
      }
    }
    
    // Count taps with cooldown
    final currentTime = DateTime.now().millisecondsSinceEpoch;
    
    if (tapDetected) {
      if (!_isFingerTapping || (currentTime - _lastTapTime > _tapCooldownMs)) {
          if (_isGameRunning && mounted) {
          final pulseHeightBefore = _pulseLineController.currentY;
          
          setState(() {
            _tapCount++;
            _lastTapTime = currentTime;
          });
          
          // Trigger pulse line impulse
          _pulseLineController.impulse();
          
          // Log detailed tap event
          final tapEvent = {
            'timestamp': currentTime,
            'tappedFinger': tappedFinger ?? 'unknown',
            'distance': detectedDistance,
            'intensity': 1.0, // Will be calculated based on distance
            'pulseHeightBefore': pulseHeightBefore,
            'pulseHeightAfter': _pulseLineController.currentY,
            'handType': tappedFinger?.startsWith('left') == true ? 'left' : 'right',
            'tapSensitivity': _tapSensitivity,
          };
          
          _tapLogs.add(tapEvent);
          debugPrint('[TAP_LOG] 🎯 TAP COUNT: $_tapCount, Total tap logs: ${_tapLogs.length}');
        }
      }
      _isFingerTapping = true;
    } else {
      _isFingerTapping = false;
    }
    
    return tapDetected;
  }
  
  /// Filters landmarks to only include the selected hand
  List<Map<String, dynamic>> _filterLandmarksByHand(
    List<Map<String, dynamic>> landmarks, 
    String selectedHand
  ) {
    if (selectedHand == 'both') {
      return landmarks; // Return all landmarks if both hands selected
    }
    
    // For rapid game, we need to filter based on hand detection
    // Since landmarks come as sequential arrays, we need to determine which hand is which
    List<Map<String, dynamic>> filteredLandmarks = [];
    
    // Simple filtering: if we have 21 landmarks, assume it's one hand
    // If we have 42 landmarks, first 21 are left, next 21 are right
    if (landmarks.length == 21) {
      // Single hand detected - assume it's the correct one
      filteredLandmarks = landmarks;
    } else if (landmarks.length == 42) {
      // Two hands detected - filter by selected hand
      if (selectedHand == 'leftHand') {
        filteredLandmarks = landmarks.sublist(0, 21);
      } else if (selectedHand == 'rightHand') {
        filteredLandmarks = landmarks.sublist(21, 42);
      }
    }
    
    return filteredLandmarks;
  }
  
  /// Gets distances between thumb tip and all other finger tips
  Map<String, double> _getFingerDistances(
    Map<String, Offset> fingerTips, 
    Offset thumbTip, 
    List<String> fingerTipIds
  ) {
    Map<String, double> distances = {};
    
    for (String fingerId in fingerTipIds) {
      Offset? fingerTip = fingerTips[fingerId];
      if (fingerTip != null) {
        double distance = (thumbTip - fingerTip).distance;
        distances[fingerId] = distance;
      }
    }
    
    return distances;
  }
  
  /// Checks the minimum distance between thumb tip and other finger tips
  double _checkFingerToThumbDistance(
    Map<String, Offset> fingerTips, 
    Offset thumbTip, 
    List<String> fingerTipIds
  ) {
    double minDistance = 1000.0; // Large initial value
    
    for (String fingerId in fingerTipIds) {
      Offset? fingerTip = fingerTips[fingerId];
      if (fingerTip != null) {
        double distance = (thumbTip - fingerTip).distance;
        if (distance < minDistance) {
          minDistance = distance;
        }
      }
    }
    
    return minDistance;
  }

  /// Builds the appropriate visualization widget based on settings
  Widget _buildVisualizationWidget() {
    final settings = ref.read(rapidSettingsStateProvider);
    final visualizationType = settings?.visualizationType ?? 'line';
    
    switch (visualizationType) {
      case 'bar':
        return Center(
          child: PulseBarWidget(
            controller: _pulseLineController,
            height: 200,
            backgroundColor: Colors.black,
            barOpacity: 0.6,
          ),
        );
      case 'circle':
        return Center(
          child: PulseCircleWidget(
            controller: _pulseLineController,
            size: 200,
            backgroundColor: Colors.black,
            circleOpacity: 0.6,
            showTargetRings: true,
            showParticles: true,
          ),
        );
      case 'line':
      default:
        return SizedBox(
          width: MediaQuery.of(context).size.width / 2.5,
          child: PulseLineWidget(
            controller: _pulseLineController,
            height: 120,
            backgroundColor: Colors.black,
            backgroundOpacity: 0.65,
            lineColor: settings?.lineColor,
            lineWidth: settings?.lineWidth,
            glowEnabled: settings?.glowEnabled,
            glowBlurSigma: settings?.glowBlurSigma,
            useFixedDt: settings?.useFixedDt,
            fixedDtSeconds: settings?.fixedDtSeconds,
          ),
        );
    }
  }

  @override
  Widget build(BuildContext context) {
    final cameraService = ref.read(rapidCameraServiceProvider);
    final cameraWidget = cameraService.getCameraPreview();
    
    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: Stack(
          children: [
            // Camera preview with proper fitting (always visible)
            Positioned.fill(
              child: FittedBox(
                fit: BoxFit.cover,
                child: SizedBox(
                  width: _imageSize.width,
                  height: _imageSize.height,
                  child: Transform(
                    alignment: Alignment.center,
                    // Fix orientation for landscape mode with front camera
                    transform: Matrix4.diagonal3Values(
                      1.0,  // No horizontal mirroring in landscape
                      1.0,  // No vertical mirroring
                      1.0,
                    ),
                    child: cameraWidget,
                  ),
                ),
              ),
            ),
            
            // Semi-transparent overlay for better UI visibility
            Positioned.fill(
              child: Container(
                color: Colors.black.withOpacity(0.3),
              ),
            ),
            
            // Hand landmarks overlay (visual feedback)
            if (_handLandmarks.isNotEmpty)
              Positioned.fill(
                child: CustomPaint(
                  painter: HandLandmarksDebugPainter(
                    landmarks: _handLandmarks,
                    imageSize: _imageSize,
                  ),
                ),
              ),
            
            // Hand position detector overlay when game is not running and not ended
            if (!_isGameRunning && !_isGameEnded)
              Positioned.fill(
                child: HandPositionDetector(
                  onDetectionComplete: _startGame,
                  handLandmarks: _handLandmarks,
                ),
              ),
              
            // Game UI elements only visible when game is running
            if (_isGameRunning) ...[
              // Status indicators
              Positioned(
                top: 20,
                left: 20,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Game mode indicator
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      margin: const EdgeInsets.only(bottom: 8),
                      decoration: BoxDecoration(
                        color: Colors.black54,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        'Mode: ${ref.watch(rapidSettingsStateProvider)?.gameMode ?? 'Standard'}',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    // Timer display
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      decoration: BoxDecoration(
                        color: Colors.black54,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        'Time: $_remainingTime s',
                        style: TextStyle(
                          color: _remainingTime <= 10 ? Colors.red : 
                                 _remainingTime <= 20 ? Colors.orange : Colors.white,
                          fontSize: 28,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              
              
              
              // Pulse visualization display
              if (!_hideGameUI)
                Positioned(
                  bottom: 100,
                  left: 20,
                  right: 20,
                  child: _buildVisualizationWidget(),
                ),
              
              // Saving overlay
              if (_isEndingGame)
                RapidSavingOverlay(
                  currentPhase: _currentSavingPhase,
                  progress: _savingProgress,
                ),
            ],
            
            // Exit button (always visible)
            Positioned(
              top: 16,
              right: 16,
              child: IconButton(
                icon: const Icon(Icons.close, color: Colors.white, size: 32),
                onPressed: () => context.go('/rapid-intro'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}


