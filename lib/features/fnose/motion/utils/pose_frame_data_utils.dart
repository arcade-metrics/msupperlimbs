import 'dart:io';
import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'package:google_mlkit_pose_detection/google_mlkit_pose_detection.dart';
import 'package:msupperlimbs/features/gameplay/motion/mediapipe_types.dart';
import 'package:msupperlimbs/features/gameplay/motion/coordinates_translator.dart';

final double scaleFactorX = 0.5;
final double scaleFactorY = 0.5;
final double scaleFactorZ = 0.5;

PoseLandmark? projectFingerTipLandmark(
  PoseLandmark index,
  PoseLandmark wrist,
  double scaleFactorX,
  double scaleFactorY,
  double scaleFactorZ,
) {
  final dx = index.x + scaleFactorX * (index.x - wrist.x);
  final dy = index.y + scaleFactorY * (index.y - wrist.y);
  final dz = index.z + scaleFactorZ * (index.z - wrist.z);

  return PoseLandmark(
    type: index.type,
    x: dx,
    y: dy,
    z: dz,
    likelihood: index.likelihood,
  );
}

class LandmarkSet {
  final PoseLandmark? nose;
  final PoseLandmark? leftShoulder;
  final PoseLandmark? rightShoulder;
  final PoseLandmark? leftElbow;
  final PoseLandmark? rightElbow;
  final PoseLandmark? leftWrist;
  final PoseLandmark? rightWrist;
  final PoseLandmark? leftIndex;
  final PoseLandmark? rightIndex;
  final PoseLandmark? leftIndexTip;
  final PoseLandmark? rightIndexTip;

  LandmarkSet._({
    this.nose,
    this.leftShoulder,
    this.rightShoulder,
    this.leftElbow,
    this.rightElbow,
    this.leftWrist,
    this.rightWrist,
    this.leftIndex,
    this.rightIndex,
    this.leftIndexTip,
    this.rightIndexTip,
  });

  factory LandmarkSet.fromPose(Pose pose) {
    PoseLandmark? get(PoseLandmarkType type) => pose.landmarks[type];

    final leftIndex = get(PoseLandmarkType.leftIndex);
    final leftWrist = get(PoseLandmarkType.leftWrist);
    final rightIndex = get(PoseLandmarkType.rightIndex);
    final rightWrist = get(PoseLandmarkType.rightWrist);

    return LandmarkSet._(
      nose: get(PoseLandmarkType.nose),
      leftShoulder: get(PoseLandmarkType.leftShoulder),
      rightShoulder: get(PoseLandmarkType.rightShoulder),
      leftElbow: get(PoseLandmarkType.leftElbow),
      rightElbow: get(PoseLandmarkType.rightElbow),
      leftWrist: leftWrist,
      rightWrist: rightWrist,
      leftIndex: leftIndex,
      rightIndex: rightIndex,
      leftIndexTip: (leftIndex != null && leftWrist != null)
          ? projectFingerTipLandmark(
              leftIndex, leftWrist, scaleFactorX, scaleFactorY, scaleFactorZ)
          : null,
      rightIndexTip: (rightIndex != null && rightWrist != null)
          ? projectFingerTipLandmark(
              rightIndex, rightWrist, scaleFactorX, scaleFactorY, scaleFactorZ)
          : null,
    );
  }

  factory LandmarkSet.fromMediaPipe(
    List<MediaPipePoseLandmark> lms,
  ) {
    PoseLandmark? lm(int idx, PoseLandmarkType type) {
      try {
        final m = lms.firstWhere((l) => l.index == idx);
        return PoseLandmark(
          type: type,
          x: m.x,
          y: m.y,
          z: m.z,
          likelihood: m.visibility,
        );
      } catch (e) {
        return null; // landmark not found in filtered list
      }
    }

    final leftIndex = lm(19, PoseLandmarkType.leftIndex);
    final leftWrist = lm(15, PoseLandmarkType.leftWrist);
    final rightIndex = lm(20, PoseLandmarkType.rightIndex);
    final rightWrist = lm(16, PoseLandmarkType.rightWrist);

    return LandmarkSet._(
      nose: lm(0, PoseLandmarkType.nose),
      leftShoulder: lm(11, PoseLandmarkType.leftShoulder),
      rightShoulder: lm(12, PoseLandmarkType.rightShoulder),
      leftElbow: lm(13, PoseLandmarkType.leftElbow),
      rightElbow: lm(14, PoseLandmarkType.rightElbow),
      leftWrist: leftWrist,
      rightWrist: rightWrist,
      leftIndex: leftIndex,
      rightIndex: rightIndex,
      leftIndexTip: (leftIndex != null && leftWrist != null)
          ? projectFingerTipLandmark(
              leftIndex, leftWrist, scaleFactorX, scaleFactorY, scaleFactorZ)
          : null,
      rightIndexTip: (rightIndex != null && rightWrist != null)
          ? projectFingerTipLandmark(
              rightIndex, rightWrist, scaleFactorX, scaleFactorY, scaleFactorZ)
          : null,
    );
  }
}

class LandmarkOffsets {
  final Offset? nose;
  final Offset? leftShoulder;
  final Offset? rightShoulder;
  final Offset? leftElbow;
  final Offset? rightElbow;
  final Offset? leftWrist;
  final Offset? rightWrist;
  final Offset? leftIndex;
  final Offset? rightIndex;
  final Offset? leftIndexTip;
  final Offset? rightIndexTip;

  LandmarkOffsets._({
    this.nose,
    this.leftShoulder,
    this.rightShoulder,
    this.leftElbow,
    this.rightElbow,
    this.leftWrist,
    this.rightWrist,
    this.leftIndex,
    this.rightIndex,
    this.leftIndexTip,
    this.rightIndexTip,
  });

  factory LandmarkOffsets.fromPose({
    required Pose pose,
    required Size screenSize,
    required Size imageSize,
    required InputImageRotation rotation,
    required CameraLensDirection lensDirection,
  }) {
    Offset? project(PoseLandmark? landmark) {
      if (landmark == null) return null;

      Offset point;
      
      if (Platform.isIOS) {
        double x = translateX(
            landmark.x, screenSize, imageSize, rotation, lensDirection);
        double y = translateY(
            landmark.y, screenSize, imageSize, rotation, lensDirection);
            
        // 🔹 Ajuste hardcode para iOS (corrigir deslocamento X sem alterar rotação/espelho)
        final aspectImage = imageSize.width / imageSize.height;
        final aspectScreen = screenSize.width / screenSize.height;
        final scale = aspectScreen / aspectImage;
        x = x * scale; // aplica correção proporcional
        
        point = Offset(x, y);
      } else {
        // Android: usa a nova função translateLandmark que rotaciona 90° anti-horário
        point = translateLandmark(
          x: landmark.x,
          y: landmark.y,
          canvasSize: screenSize,
          imageSize: imageSize,
          rotation: rotation,
          cameraLensDirection: lensDirection,
        );
      }

      return point;
    }

    final landmarkSet = LandmarkSet.fromPose(pose);

    return LandmarkOffsets._(
      nose: project(landmarkSet.nose),
      leftShoulder: project(landmarkSet.leftShoulder),
      rightShoulder: project(landmarkSet.rightShoulder),
      leftElbow: project(landmarkSet.leftElbow),
      rightElbow: project(landmarkSet.rightElbow),
      leftWrist: project(landmarkSet.leftWrist),
      rightWrist: project(landmarkSet.rightWrist),
      leftIndex: project(landmarkSet.leftIndex),
      rightIndex: project(landmarkSet.rightIndex),
      leftIndexTip: project(landmarkSet.leftIndexTip),
      rightIndexTip: project(landmarkSet.rightIndexTip),
    );
  }

  factory LandmarkOffsets.fromMediaPipe({
    required List<MediaPipePoseLandmark> lms,
    required Size screenSize,
    required Size imageSize,
    required bool isFrontCamera,
    int rotationDegrees = 0, // Backward compatibility
    int outputRotationDegrees = 0, // New: OUTPUT rotation for display
    bool outputMirrorHorizontal = false, // New: OUTPUT mirror for display
    bool outputMirrorVertical = false, // New: OUTPUT mirror for display
  }) {
    Offset? projectIndex(int idx) {
      try {
        final m = lms.firstWhere((l) => l.index == idx);
        return translateNormalizedLive(
          nx: m.x,
          ny: m.y,
          imageSize: imageSize,
          canvasSize: screenSize,
          isFrontCamera: isFrontCamera,
          rotationDegrees: rotationDegrees, // Backward compatibility
          outputRotationDegrees: outputRotationDegrees,
          outputMirrorHorizontal: outputMirrorHorizontal,
          outputMirrorVertical: outputMirrorVertical,
        );
      } catch (e) {
        return null; // landmark not found in filtered list
      }
    }

    final leftIndex = projectIndex(19);
    final leftWrist = projectIndex(15);
    final rightIndex = projectIndex(20);
    final rightWrist = projectIndex(16);

    // Project fingertip similarly to MLKit path
    Offset? projectTip(Offset? index, Offset? wrist) {
      if (index == null || wrist == null) return null;
      final dx = index.dx + scaleFactorX * (index.dx - wrist.dx);
      final dy = index.dy + scaleFactorY * (index.dy - wrist.dy);
      return Offset(dx, dy);
    }

    return LandmarkOffsets._(
      nose: projectIndex(0),
      leftShoulder: projectIndex(11),
      rightShoulder: projectIndex(12),
      leftElbow: projectIndex(13),
      rightElbow: projectIndex(14),
      leftWrist: leftWrist,
      rightWrist: rightWrist,
      leftIndex: leftIndex,
      rightIndex: rightIndex,
      leftIndexTip: projectTip(leftIndex, leftWrist),
      rightIndexTip: projectTip(rightIndex, rightWrist),
    );
  }
}

class PoseFrameData {
  final LandmarkSet landmarks;
  final LandmarkOffsets offsets;

  PoseFrameData({
    required this.landmarks,
    required this.offsets,
  });

  factory PoseFrameData.fromPose({
    required Pose pose,
    required Size screenSize,
    required Size imageSize,
    required InputImageRotation rotation,
    required CameraLensDirection lensDirection,
  }) {
    final landmarks = LandmarkSet.fromPose(pose);
    final offsets = LandmarkOffsets.fromPose(
      pose: pose,
      screenSize: screenSize,
      imageSize: imageSize,
      rotation: rotation,
      lensDirection: lensDirection,
    );
    return PoseFrameData(
      landmarks: landmarks,
      offsets: offsets,
    );
  }
}
