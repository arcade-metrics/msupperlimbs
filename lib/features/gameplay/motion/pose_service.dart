import 'package:flutter/foundation.dart';
import 'package:google_mlkit_pose_detection/google_mlkit_pose_detection.dart';

class PoseService {
  final PoseDetector _poseDetector;
  Pose? lastPose;

  PoseService()
      : _poseDetector = PoseDetector(
          options: PoseDetectorOptions(
            mode: PoseDetectionMode.stream,
            model: PoseDetectionModel.base,
          ),
        );

  Future<void> processImage(InputImage inputImage) async {
    try {
      final poses = await _poseDetector.processImage(inputImage);
      if (poses.isNotEmpty) {
        lastPose = poses.first;
        debugPrint('Pose detectada com ${lastPose!.landmarks.length} landmarks.');
      } else {
        lastPose = null;
      }
    } catch (e) {
      debugPrint('PoseService error: $e');
    }
  }

  Future<void> dispose() async {
    await _poseDetector.close();
  }
}
