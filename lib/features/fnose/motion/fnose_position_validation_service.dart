import 'dart:math';
import 'package:flutter/material.dart';
import 'package:msupperlimbs/features/fnose/data/models/fnose_adv_settings_model.dart';
import 'package:msupperlimbs/features/fnose/motion/utils/pose_frame_data_utils.dart';

class FNosePositionValidationService {
  final FNoseAdvSettingsModel fnoseAdvSettings;

  FNosePositionValidationService(this.fnoseAdvSettings);

  // Message constants - these will be set by the calling widget
  String moveCloserMessage = '';
  String moveFartherMessage = '';
  String faceDeviceMessage = '';
  String alignShouldersMessage = '';
  String moveLeftMessage = '';
  String moveRightMessage = '';
  String moveDownMessage = '';
  String moveUpMessage = '';
  String positionFoundMessage = '';
  String faceAndShouldersNotVisibleMessage = '';
  String noseCloseMessage = '';
  String noseFarMessage = '';

  // Moving average buffers
  List<double> _shoulderDistanceBuffer = [];
  List<double> _shoulderYBuffer = [];
  List<double> _shoulderZBuffer = [];
  List<Offset> _noseOffsetBuffer = [];

  // Validation results
  bool _isShoulderDistanceValid = false;
  bool _isShoulderYAligned = false;
  bool _isShoulderZAligned = false;
  bool _isNoseCentered = false;

  // Messages
  String _currentMessage = '';

  String get currentMessage => _currentMessage;
  bool get isShoulderDistanceValid => _isShoulderDistanceValid;
  bool get isShoulderYAligned => _isShoulderYAligned;
  bool get isShoulderZAligned => _isShoulderZAligned;
  bool get isNoseCentered => _isNoseCentered;

  bool get isPositionValid =>
      _isShoulderDistanceValid &&
      _isShoulderYAligned &&
      _isShoulderZAligned &&
      _isNoseCentered;

  void updatePose(PoseFrameData frameData, Size screenSize, bool isLeftHand) {
    final leftShoulder = frameData.landmarks.leftShoulder;
    final rightShoulder = frameData.landmarks.rightShoulder;
    final nose = frameData.landmarks.nose;
    final leftShoulderOffset = frameData.offsets.leftShoulder;
    final rightShoulderOffset = frameData.offsets.rightShoulder;
    final noseOffset = frameData.offsets.nose;

    if (leftShoulder == null || rightShoulder == null || nose == null ||
        leftShoulderOffset == null || rightShoulderOffset == null || noseOffset == null) {
      _currentMessage = faceAndShouldersNotVisibleMessage;
      return;
    }

    // Calculate shoulder distance using offsets (screen coordinates) for distance validation
    final shoulderDistance = (rightShoulderOffset.dx - leftShoulderOffset.dx).abs();
    final shoulderDistancePercent = shoulderDistance / screenSize.width;

    // Calculate shoulder distance using landmarks (3D coordinates) for normalization
    final shoulderDistanceLandmarks = (rightShoulder.x - leftShoulder.x).abs();

    // Calculate shoulder Y alignment difference using landmarks (3D coordinates)
    final shoulderYDiff = (rightShoulder.y - leftShoulder.y).abs();
    final shoulderYDiffPercent = shoulderYDiff / max(1.0, shoulderDistanceLandmarks);

    // Calculate shoulder Z alignment difference using landmarks (3D coordinates)
    final shoulderZDiff = (rightShoulder.z - leftShoulder.z).abs();
    final shoulderZDiffPercent = shoulderZDiff / max(1.0, shoulderDistanceLandmarks);

    

    // Update moving average buffers
    _updateBuffer(_shoulderDistanceBuffer, shoulderDistancePercent);
    _updateBuffer(_shoulderYBuffer, shoulderYDiffPercent);
    _updateBuffer(_shoulderZBuffer, shoulderZDiffPercent);
    _updateOffsetBuffer(_noseOffsetBuffer, noseOffset);

    // Calculate averages
    final avgShoulderDistance = _calculateAverage(_shoulderDistanceBuffer);
    final avgShoulderYDiff = _calculateAverage(_shoulderYBuffer);
    final avgShoulderZDiff = _calculateAverage(_shoulderZBuffer);
    final avgNoseOffset = _calculateOffsetAverage(_noseOffsetBuffer);

    // Validate conditions in order and show only one message at a time
    debugPrint('Position validation - Shoulder distance: ${avgShoulderDistance.toStringAsFixed(3)}');
    _validateShoulderDistance(avgShoulderDistance);
    debugPrint('Position validation - Shoulder distance valid: $_isShoulderDistanceValid');
    
    if (_isShoulderDistanceValid) {
      _validateShoulderYAlignment(avgShoulderYDiff);      
      if (_isShoulderYAligned) {
        _validateShoulderZAlignment(avgShoulderZDiff);        
        if (_isShoulderZAligned) {
          _validateNosePosition(avgNoseOffset, isLeftHand, screenSize);
          debugPrint('Position validation - Nose centered: $_isNoseCentered');
        } else {
          debugPrint('Position validation - Skipping nose validation (shoulder Z not aligned)');
        }
      } else {
        debugPrint('Position validation - Skipping nose validation (shoulder Y not aligned)');
      }
    } else {
      debugPrint('Position validation - Skipping nose validation (shoulder distance not valid)');
    }
  }

  void _updateBuffer(List<double> buffer, double value) {
    buffer.add(value);
    if (buffer.length > fnoseAdvSettings.movingAverageFrames) {
      buffer.removeAt(0);
    }
  }

  void _updateOffsetBuffer(List<Offset> buffer, Offset value) {
    buffer.add(value);
    if (buffer.length > fnoseAdvSettings.movingAverageFrames) {
      buffer.removeAt(0);
    }
  }

  double _calculateAverage(List<double> buffer) {
    if (buffer.isEmpty) return 0;
    return buffer.reduce((a, b) => a + b) / buffer.length;
  }

  Offset _calculateOffsetAverage(List<Offset> buffer) {
    if (buffer.isEmpty) return Offset.zero;
    final avgX = buffer.map((offset) => offset.dx).reduce((a, b) => a + b) / buffer.length;
    final avgY = buffer.map((offset) => offset.dy).reduce((a, b) => a + b) / buffer.length;
    return Offset(avgX, avgY);
  }

  void _validateShoulderDistance(double distance) {
    if (distance < fnoseAdvSettings.minShoulderDistance) {
      _isShoulderDistanceValid = false;
      _currentMessage = moveCloserMessage;
    } else if (distance > fnoseAdvSettings.maxShoulderDistance) {
      _isShoulderDistanceValid = false;
      _currentMessage = moveFartherMessage;
    } else {
      _isShoulderDistanceValid = true;
      _currentMessage = '';
    }
  }

  void _validateShoulderYAlignment(double yDiff) {
    if (yDiff > fnoseAdvSettings.shoulderYAlignmentThreshold) {
      _isShoulderYAligned = false;
      _currentMessage = faceDeviceMessage;
    } else {
      _isShoulderYAligned = true;
      _currentMessage = '';
    }
  }

  void _validateShoulderZAlignment(double zDiff) {
    if (zDiff > fnoseAdvSettings.shoulderZAlignmentThreshold) {
      _isShoulderZAligned = false;
      _currentMessage = alignShouldersMessage;
    } else {
      _isShoulderZAligned = true;
      _currentMessage = '';
    }
  }

  void _validateNosePosition(Offset currentNosePosition, bool isLeftHand, Size screenSize) {
    final targetX = fnoseAdvSettings.getNoseAlignmentXCoordinate(isLeftHand);
    final targetY = fnoseAdvSettings.yNoseAlignment;
    final threshold = fnoseAdvSettings.noseAlignmentThreshold;
    
    final centerX = targetX * screenSize.width;
    final centerY = targetY * screenSize.height;
    final radius = threshold * screenSize.width;

    final distance = (currentNosePosition - Offset(centerX, centerY)).distance;
    final normalizedDistance = distance / radius;
    
    if (normalizedDistance <= 1.0) {
      // Nose is within the target area
      _isNoseCentered = true;
      _currentMessage = positionFoundMessage;
    } else if (normalizedDistance <= 1.5) {
      // Nose is close to the target area
      _isNoseCentered = false;
      _currentMessage = noseCloseMessage;
    } else {
      // Nose is far from the target area
      _isNoseCentered = false;
      _currentMessage = noseFarMessage;
    }
  }
}
