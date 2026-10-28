import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:msupperlimbs/core/models/camera_image_config.dart';
import 'package:msupperlimbs/core/services/camera_config_service.dart';
import 'package:msupperlimbs/features/gameplay/motion/mediapipe_types.dart';
import 'package:msupperlimbs/features/gameplay/application/camera_service_provider.dart';
import 'package:msupperlimbs/features/fnose/data/models/enums/fnose_game_mode_enum.dart';
import 'package:msupperlimbs/features/fnose/presentation/widgets/fnose_camera_with_landmarks.dart';
import 'package:camera/camera.dart';

/// Manual camera configuration widget with two phases:
/// 1. INPUT phase: Find config that makes MediaPipe detect landmarks
/// 2. OUTPUT phase: Adjust config to align landmarks on screen
class ManualCameraConfigWidget extends ConsumerStatefulWidget {
  final FNoseGameMode gameMode;
  final VoidCallback onConfigurationComplete;
  final VoidCallback onConfigurationFailed;

  const ManualCameraConfigWidget({
    super.key,
    required this.gameMode,
    required this.onConfigurationComplete,
    required this.onConfigurationFailed,
  });

  @override
  ConsumerState<ManualCameraConfigWidget> createState() =>
      _ManualCameraConfigWidgetState();
}

class _ManualCameraConfigWidgetState
    extends ConsumerState<ManualCameraConfigWidget> {
  
  // Phase control
  bool _isInputPhase = true;
  int _selectedInputConfig = 0;
  int _selectedOutputConfig = 0;
  
  // Landmark detection state
  bool _landmarksDetected = false;
  Size _imageSize = const Size(640, 480);
  CustomPainter? _landmarksPainter;
  
  // Current applied configs
  CameraImageConfig? _currentInputConfig;
  CameraImageConfig? _currentOutputConfig;
  
  // Device info
  String _deviceModel = '';

  @override
  void initState() {
    super.initState();
    _initializeManualConfig();
  }

  @override
  void dispose() {
    // Clean up callback
    final cameraService = ref.read(cameraServiceProvider);
    cameraService.onMpPoseDetected = null;
    super.dispose();
  }

  Future<void> _initializeManualConfig() async {
    // Get device model
    _deviceModel = await CameraConfigService.instance.getActualDeviceModel();
    debugPrint('📱 Manual config for device: $_deviceModel');
    
    // Start with config 0 (0°, no mirrors)
    await _applyInputConfig(0);
    
    // Set up pose detection callback
    _setupPoseCallback();
  }

  void _setupPoseCallback() {
    final cameraService = ref.read(cameraServiceProvider);
    
    cameraService.onMpPoseDetected = (pose, imageSize, rotationDegrees, lensDirection) {
      if (!mounted) return;
      
      setState(() {
        _imageSize = imageSize;
        _landmarksDetected = pose.landmarks.isNotEmpty && _hasValidLandmarks(pose);
        
        if (_landmarksDetected) {
          // Show landmarks overlay
          _landmarksPainter = _createLandmarksPainter(pose, imageSize);
        } else {
          _landmarksPainter = null;
        }
      });
    };
  }

  bool _hasValidLandmarks(MediaPipePose pose) {
    // Check if we have essential landmarks with good visibility
    int validLandmarks = 0;
    for (final landmark in pose.landmarks) {
      if (landmark.visibility > 0.5) {
        validLandmarks++;
      }
    }
    return validLandmarks >= 5; // At least 5 visible landmarks
  }

  CustomPainter? _createLandmarksPainter(MediaPipePose pose, Size imageSize) {
    // Create a simple painter to show landmarks are detected
    return _LandmarkDetectionPainter(
      pose: pose,
      imageSize: imageSize,
    );
  }

  /// Generate config from index (0-15)
  /// Index mapping: rotation (0-3) * 4 + mirror_combo (0-3)
  /// Mirror combos: 0=none, 1=H, 2=V, 3=HV
  CameraImageConfig _configFromIndex(int index, bool isInput) {
    final rotationIndex = index ~/ 4; // 0, 1, 2, 3
    final mirrorIndex = index % 4;    // 0, 1, 2, 3
    
    final rotation = [0, 90, 180, 270][rotationIndex];
    final mirrorH = mirrorIndex == 1 || mirrorIndex == 3;
    final mirrorV = mirrorIndex == 2 || mirrorIndex == 3;
    
    if (isInput) {
      return CameraImageConfig(
        deviceModel: _deviceModel,
        inputRotationDegrees: rotation,
        inputMirrorHorizontal: mirrorH,
        inputMirrorVertical: mirrorV,
        // Start with output same as input
        outputRotationDegrees: rotation,
        outputMirrorHorizontal: mirrorH,
        outputMirrorVertical: mirrorV,
      );
    } else {
      // Output config: keep input settings, change output settings
      return CameraImageConfig(
        deviceModel: _deviceModel,
        inputRotationDegrees: _currentInputConfig!.inputRotationDegrees,
        inputMirrorHorizontal: _currentInputConfig!.inputMirrorHorizontal,
        inputMirrorVertical: _currentInputConfig!.inputMirrorVertical,
        outputRotationDegrees: rotation,
        outputMirrorHorizontal: mirrorH,
        outputMirrorVertical: mirrorV,
      );
    }
  }

  Future<void> _applyInputConfig(int index) async {
    final config = _configFromIndex(index, true);
    _currentInputConfig = config;
    _selectedInputConfig = index;
    
    debugPrint('🔧 Testing INPUT config $index: rot=${config.inputRotationDegrees}°, mirror=[H:${config.inputMirrorHorizontal},V:${config.inputMirrorVertical}]');
    
    await CameraConfigService.instance.setTemporaryConfig(config);
    
    setState(() {
      _landmarksDetected = false;
      _landmarksPainter = null;
    });
  }

  Future<void> _applyOutputConfig(int index) async {
    final config = _configFromIndex(index, false);
    _currentOutputConfig = config;
    _selectedOutputConfig = index;
    
    debugPrint('🔧 Testing OUTPUT config $index: rot=${config.outputRotationDegrees}°, mirror=[H:${config.outputMirrorHorizontal},V:${config.outputMirrorVertical}]');
    
    await CameraConfigService.instance.setTemporaryConfig(config);
    
    setState(() {
      // Keep landmarks detection from input phase
    });
  }

  void _goToOutputPhase() {
    setState(() {
      _isInputPhase = false;
      _selectedOutputConfig = _selectedInputConfig; // Start with same config
    });
    
    // Apply the same config as output starting point
    _applyOutputConfig(_selectedInputConfig);
  }

  Future<void> _saveAndProceed() async {
    if (_currentOutputConfig == null) return;
    
    debugPrint('💾 Saving manual config: ${_currentOutputConfig!}');
    
    try {
      await CameraConfigService.instance.saveDeviceConfig(_currentOutputConfig!);
      debugPrint('✅ Manual config saved successfully');
      
      widget.onConfigurationComplete();
    } catch (e) {
      debugPrint('❌ Failed to save manual config: $e');
      widget.onConfigurationFailed();
    }
  }

  String _getConfigDescription(int index) {
    final rotationIndex = index ~/ 4;
    final mirrorIndex = index % 4;
    
    final rotation = ['0°', '90°', '180°', '270°'][rotationIndex];
    final mirror = ['', 'H', 'V', 'HV'][mirrorIndex];
    
    return mirror.isEmpty ? rotation : '$rotation $mirror';
  }

  @override
  Widget build(BuildContext context) {
    final cameraService = ref.read(cameraServiceProvider);
    final cameraWidget = cameraService.getCameraPreview();
    
    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: Column(
          children: [
            // Phase indicator
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              color: _isInputPhase ? Colors.blue.withOpacity(0.2) : Colors.green.withOpacity(0.2),
              child: Text(
                _isInputPhase 
                    ? 'INPUT CONFIG (Get Landmarks)' 
                    : 'OUTPUT CONFIG (Align Display)',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
            ),
            
            // Camera preview with landmarks
            Expanded(
              flex: 3,
              child: Container(
                margin: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.white24),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      if (cameraService.controller?.value.isInitialized == true)
                        cameraWidget,
                      
                      // Landmarks overlay
                      if (_landmarksPainter != null)
                        CustomPaint(painter: _landmarksPainter),
                      
                      // Status overlay
                      Positioned(
                        top: 8,
                        left: 8,
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                          decoration: BoxDecoration(
                            color: _landmarksDetected ? Colors.green : Colors.red,
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: Text(
                            _landmarksDetected ? '✓ Landmarks detected!' : '✗ No landmarks',
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            
            // Config selection grid
            Expanded(
              flex: 2,
              child: Container(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    Text(
                      _isInputPhase 
                          ? 'Select INPUT configuration:' 
                          : 'Select OUTPUT configuration:',
                      style: const TextStyle(color: Colors.white, fontSize: 16),
                    ),
                    const SizedBox(height: 8),
                    
                    Expanded(
                      child: GridView.count(
                        crossAxisCount: 4,
                        mainAxisSpacing: 8,
                        crossAxisSpacing: 8,
                        children: List.generate(16, (index) {
                          final isSelected = _isInputPhase 
                              ? index == _selectedInputConfig
                              : index == _selectedOutputConfig;
                          
                          return ElevatedButton(
                            onPressed: () {
                              if (_isInputPhase) {
                                _applyInputConfig(index);
                              } else {
                                _applyOutputConfig(index);
                              }
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: isSelected 
                                  ? (_isInputPhase ? Colors.blue : Colors.green)
                                  : Colors.grey[800],
                              foregroundColor: Colors.white,
                            ),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text(
                                  '${index + 1}',
                                  style: const TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                Text(
                                  _getConfigDescription(index),
                                  style: const TextStyle(fontSize: 10),
                                  textAlign: TextAlign.center,
                                ),
                              ],
                            ),
                          );
                        }),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            
            // Action buttons
            Container(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  if (!_isInputPhase)
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () {
                          setState(() {
                            _isInputPhase = true;
                          });
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.grey[700],
                        ),
                        child: const Text('← Back to Input'),
                      ),
                    ),
                  
                  if (!_isInputPhase)
                    const SizedBox(width: 16),
                  
                  Expanded(
                    child: ElevatedButton(
                      onPressed: _isInputPhase
                          ? (_landmarksDetected ? _goToOutputPhase : null)
                          : _saveAndProceed,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: _isInputPhase
                            ? (_landmarksDetected ? Colors.blue : Colors.grey)
                            : Colors.green,
                      ),
                      child: Text(
                        _isInputPhase
                            ? 'Continue to Output Config →'
                            : 'Save & Continue',
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Simple painter to show that landmarks are detected
class _LandmarkDetectionPainter extends CustomPainter {
  final MediaPipePose pose;
  final Size imageSize;

  _LandmarkDetectionPainter({
    required this.pose,
    required this.imageSize,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.green
      ..strokeWidth = 2
      ..style = PaintingStyle.fill;

    // Draw simple dots for detected landmarks
    for (final landmark in pose.landmarks) {
      if (landmark.visibility > 0.5) {
        final x = landmark.x * size.width;
        final y = landmark.y * size.height;
        canvas.drawCircle(Offset(x, y), 3, paint);
      }
    }
  }

  @override
  bool shouldRepaint(covariant _LandmarkDetectionPainter oldDelegate) {
    return oldDelegate.pose != pose || oldDelegate.imageSize != imageSize;
  }
}


