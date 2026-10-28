import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:msupperlimbs/features/rapid/motion/rapid_camera_service.dart';
import 'package:msupperlimbs/features/rapid/motion/rapid_hand_detector.dart';

/// Provider for Rapid Camera Service
final rapidCameraServiceProvider = Provider<RapidCameraService>((ref) {
  return RapidCameraService();
});

/// Provider for Rapid Hand Detector
final rapidHandDetectorProvider = Provider<RapidHandDetector>((ref) {
  return RapidHandDetector();
});
