import 'dart:io';
import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'package:google_mlkit_pose_detection/google_mlkit_pose_detection.dart';
import 'package:msupperlimbs/features/gameplay/motion/coordinates_translator.dart';

class HandLandmarkSet {
  // Mão esquerda - 21 landmarks
  final PoseLandmark? leftWrist; // 0
  final PoseLandmark? leftThumbCMC; // 1
  final PoseLandmark? leftThumbMCP; // 2
  final PoseLandmark? leftThumbIP; // 3
  final PoseLandmark? leftThumbTip; // 4
  final PoseLandmark? leftIndexMCP; // 5
  final PoseLandmark? leftIndexPIP; // 6
  final PoseLandmark? leftIndexDIP; // 7
  final PoseLandmark? leftIndexTip; // 8
  final PoseLandmark? leftMiddleMCP; // 9
  final PoseLandmark? leftMiddlePIP; // 10
  final PoseLandmark? leftMiddleDIP; // 11
  final PoseLandmark? leftMiddleTip; // 12
  final PoseLandmark? leftRingMCP; // 13
  final PoseLandmark? leftRingPIP; // 14
  final PoseLandmark? leftRingDIP; // 15
  final PoseLandmark? leftRingTip; // 16
  final PoseLandmark? leftPinkyMCP; // 17
  final PoseLandmark? leftPinkyPIP; // 18
  final PoseLandmark? leftPinkyDIP; // 19
  final PoseLandmark? leftPinkyTip; // 20
  
  // Mão direita - 21 landmarks
  final PoseLandmark? rightWrist; // 0
  final PoseLandmark? rightThumbCMC; // 1
  final PoseLandmark? rightThumbMCP; // 2
  final PoseLandmark? rightThumbIP; // 3
  final PoseLandmark? rightThumbTip; // 4
  final PoseLandmark? rightIndexMCP; // 5
  final PoseLandmark? rightIndexPIP; // 6
  final PoseLandmark? rightIndexDIP; // 7
  final PoseLandmark? rightIndexTip; // 8
  final PoseLandmark? rightMiddleMCP; // 9
  final PoseLandmark? rightMiddlePIP; // 10
  final PoseLandmark? rightMiddleDIP; // 11
  final PoseLandmark? rightMiddleTip; // 12
  final PoseLandmark? rightRingMCP; // 13
  final PoseLandmark? rightRingPIP; // 14
  final PoseLandmark? rightRingDIP; // 15
  final PoseLandmark? rightRingTip; // 16
  final PoseLandmark? rightPinkyMCP; // 17
  final PoseLandmark? rightPinkyPIP; // 18
  final PoseLandmark? rightPinkyDIP; // 19
  final PoseLandmark? rightPinkyTip; // 20

  HandLandmarkSet._({
    this.leftWrist,
    this.leftThumbCMC,
    this.leftThumbMCP,
    this.leftThumbIP,
    this.leftThumbTip,
    this.leftIndexMCP,
    this.leftIndexPIP,
    this.leftIndexDIP,
    this.leftIndexTip,
    this.leftMiddleMCP,
    this.leftMiddlePIP,
    this.leftMiddleDIP,
    this.leftMiddleTip,
    this.leftRingMCP,
    this.leftRingPIP,
    this.leftRingDIP,
    this.leftRingTip,
    this.leftPinkyMCP,
    this.leftPinkyPIP,
    this.leftPinkyDIP,
    this.leftPinkyTip,
    this.rightWrist,
    this.rightThumbCMC,
    this.rightThumbMCP,
    this.rightThumbIP,
    this.rightThumbTip,
    this.rightIndexMCP,
    this.rightIndexPIP,
    this.rightIndexDIP,
    this.rightIndexTip,
    this.rightMiddleMCP,
    this.rightMiddlePIP,
    this.rightMiddleDIP,
    this.rightMiddleTip,
    this.rightRingMCP,
    this.rightRingPIP,
    this.rightRingDIP,
    this.rightRingTip,
    this.rightPinkyMCP,
    this.rightPinkyPIP,
    this.rightPinkyDIP,
    this.rightPinkyTip,
  });

  factory HandLandmarkSet.fromPose(Pose pose) {
    PoseLandmark? get(PoseLandmarkType type) => pose.landmarks[type];
    
    // Nota: O MLKit Pose Detection não tem todos os landmarks das mãos que precisamos
    // Estamos usando os landmarks disponíveis e marcando o resto como null
    // Posteriormente, esses landmarks serão preenchidos pelo detector de mãos específico
    
    return HandLandmarkSet._(
      // Mão esquerda
      leftWrist: get(PoseLandmarkType.leftWrist),
      leftThumbCMC: null, // Não disponível no MLKit Pose
      leftThumbMCP: null,
      leftThumbIP: null,
      leftThumbTip: get(PoseLandmarkType.leftThumb), // Aproximação
      leftIndexMCP: null,
      leftIndexPIP: null,
      leftIndexDIP: null,
      leftIndexTip: get(PoseLandmarkType.leftIndex), // Aproximação
      leftMiddleMCP: null,
      leftMiddlePIP: null,
      leftMiddleDIP: null,
      leftMiddleTip: null,
      leftRingMCP: null,
      leftRingPIP: null,
      leftRingDIP: null,
      leftRingTip: null,
      leftPinkyMCP: null,
      leftPinkyPIP: null,
      leftPinkyDIP: null,
      leftPinkyTip: get(PoseLandmarkType.leftPinky), // Aproximação
      
      // Mão direita
      rightWrist: get(PoseLandmarkType.rightWrist),
      rightThumbCMC: null, // Não disponível no MLKit Pose
      rightThumbMCP: null,
      rightThumbIP: null,
      rightThumbTip: get(PoseLandmarkType.rightThumb), // Aproximação
      rightIndexMCP: null,
      rightIndexPIP: null,
      rightIndexDIP: null,
      rightIndexTip: get(PoseLandmarkType.rightIndex), // Aproximação
      rightMiddleMCP: null,
      rightMiddlePIP: null,
      rightMiddleDIP: null,
      rightMiddleTip: null,
      rightRingMCP: null,
      rightRingPIP: null,
      rightRingDIP: null,
      rightRingTip: null,
      rightPinkyMCP: null,
      rightPinkyPIP: null,
      rightPinkyDIP: null,
      rightPinkyTip: get(PoseLandmarkType.rightPinky), // Aproximação
    );
  }
}

class HandLandmarkOffsets {
  // Mão esquerda - 21 landmarks
  final Offset? leftWrist; // 0
  final Offset? leftThumbCMC; // 1
  final Offset? leftThumbMCP; // 2
  final Offset? leftThumbIP; // 3
  final Offset? leftThumbTip; // 4
  final Offset? leftIndexMCP; // 5
  final Offset? leftIndexPIP; // 6
  final Offset? leftIndexDIP; // 7
  final Offset? leftIndexTip; // 8
  final Offset? leftMiddleMCP; // 9
  final Offset? leftMiddlePIP; // 10
  final Offset? leftMiddleDIP; // 11
  final Offset? leftMiddleTip; // 12
  final Offset? leftRingMCP; // 13
  final Offset? leftRingPIP; // 14
  final Offset? leftRingDIP; // 15
  final Offset? leftRingTip; // 16
  final Offset? leftPinkyMCP; // 17
  final Offset? leftPinkyPIP; // 18
  final Offset? leftPinkyDIP; // 19
  final Offset? leftPinkyTip; // 20
  
  // Mão direita - 21 landmarks
  final Offset? rightWrist; // 0
  final Offset? rightThumbCMC; // 1
  final Offset? rightThumbMCP; // 2
  final Offset? rightThumbIP; // 3
  final Offset? rightThumbTip; // 4
  final Offset? rightIndexMCP; // 5
  final Offset? rightIndexPIP; // 6
  final Offset? rightIndexDIP; // 7
  final Offset? rightIndexTip; // 8
  final Offset? rightMiddleMCP; // 9
  final Offset? rightMiddlePIP; // 10
  final Offset? rightMiddleDIP; // 11
  final Offset? rightMiddleTip; // 12
  final Offset? rightRingMCP; // 13
  final Offset? rightRingPIP; // 14
  final Offset? rightRingDIP; // 15
  final Offset? rightRingTip; // 16
  final Offset? rightPinkyMCP; // 17
  final Offset? rightPinkyPIP; // 18
  final Offset? rightPinkyDIP; // 19
  final Offset? rightPinkyTip; // 20

  HandLandmarkOffsets._({
    this.leftWrist,
    this.leftThumbCMC,
    this.leftThumbMCP,
    this.leftThumbIP,
    this.leftThumbTip,
    this.leftIndexMCP,
    this.leftIndexPIP,
    this.leftIndexDIP,
    this.leftIndexTip,
    this.leftMiddleMCP,
    this.leftMiddlePIP,
    this.leftMiddleDIP,
    this.leftMiddleTip,
    this.leftRingMCP,
    this.leftRingPIP,
    this.leftRingDIP,
    this.leftRingTip,
    this.leftPinkyMCP,
    this.leftPinkyPIP,
    this.leftPinkyDIP,
    this.leftPinkyTip,
    this.rightWrist,
    this.rightThumbCMC,
    this.rightThumbMCP,
    this.rightThumbIP,
    this.rightThumbTip,
    this.rightIndexMCP,
    this.rightIndexPIP,
    this.rightIndexDIP,
    this.rightIndexTip,
    this.rightMiddleMCP,
    this.rightMiddlePIP,
    this.rightMiddleDIP,
    this.rightMiddleTip,
    this.rightRingMCP,
    this.rightRingPIP,
    this.rightRingDIP,
    this.rightRingTip,
    this.rightPinkyMCP,
    this.rightPinkyPIP,
    this.rightPinkyDIP,
    this.rightPinkyTip,
  });

  /// Creates HandLandmarkOffsets from native landmarks map
  factory HandLandmarkOffsets.fromNativeLandmarks(Map<String, Offset> landmarks) {
    return HandLandmarkOffsets._(
      // Left hand landmarks
      leftWrist: landmarks['left_0'],
      leftThumbCMC: landmarks['left_1'],
      leftThumbMCP: landmarks['left_2'],
      leftThumbIP: landmarks['left_3'],
      leftThumbTip: landmarks['left_4'],
      leftIndexMCP: landmarks['left_5'],
      leftIndexPIP: landmarks['left_6'],
      leftIndexDIP: landmarks['left_7'],
      leftIndexTip: landmarks['left_8'],
      leftMiddleMCP: landmarks['left_9'],
      leftMiddlePIP: landmarks['left_10'],
      leftMiddleDIP: landmarks['left_11'],
      leftMiddleTip: landmarks['left_12'],
      leftRingMCP: landmarks['left_13'],
      leftRingPIP: landmarks['left_14'],
      leftRingDIP: landmarks['left_15'],
      leftRingTip: landmarks['left_16'],
      leftPinkyMCP: landmarks['left_17'],
      leftPinkyPIP: landmarks['left_18'],
      leftPinkyDIP: landmarks['left_19'],
      leftPinkyTip: landmarks['left_20'],
      
      // Right hand landmarks
      rightWrist: landmarks['right_0'],
      rightThumbCMC: landmarks['right_1'],
      rightThumbMCP: landmarks['right_2'],
      rightThumbIP: landmarks['right_3'],
      rightThumbTip: landmarks['right_4'],
      rightIndexMCP: landmarks['right_5'],
      rightIndexPIP: landmarks['right_6'],
      rightIndexDIP: landmarks['right_7'],
      rightIndexTip: landmarks['right_8'],
      rightMiddleMCP: landmarks['right_9'],
      rightMiddlePIP: landmarks['right_10'],
      rightMiddleDIP: landmarks['right_11'],
      rightMiddleTip: landmarks['right_12'],
      rightRingMCP: landmarks['right_13'],
      rightRingPIP: landmarks['right_14'],
      rightRingDIP: landmarks['right_15'],
      rightRingTip: landmarks['right_16'],
      rightPinkyMCP: landmarks['right_17'],
      rightPinkyPIP: landmarks['right_18'],
      rightPinkyDIP: landmarks['right_19'],
      rightPinkyTip: landmarks['right_20'],
    );
  }

  factory HandLandmarkOffsets.fromPose({
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
            
        // Ajuste para iOS
        final aspectImage = imageSize.width / imageSize.height;
        final aspectScreen = screenSize.width / screenSize.height;
        final scale = aspectScreen / aspectImage;
        x = x * scale;
        
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

    final handLandmarkSet = HandLandmarkSet.fromPose(pose);

    return HandLandmarkOffsets._(
      // Mão esquerda
      leftWrist: project(handLandmarkSet.leftWrist),
      leftThumbCMC: project(handLandmarkSet.leftThumbCMC),
      leftThumbMCP: project(handLandmarkSet.leftThumbMCP),
      leftThumbIP: project(handLandmarkSet.leftThumbIP),
      leftThumbTip: project(handLandmarkSet.leftThumbTip),
      leftIndexMCP: project(handLandmarkSet.leftIndexMCP),
      leftIndexPIP: project(handLandmarkSet.leftIndexPIP),
      leftIndexDIP: project(handLandmarkSet.leftIndexDIP),
      leftIndexTip: project(handLandmarkSet.leftIndexTip),
      leftMiddleMCP: project(handLandmarkSet.leftMiddleMCP),
      leftMiddlePIP: project(handLandmarkSet.leftMiddlePIP),
      leftMiddleDIP: project(handLandmarkSet.leftMiddleDIP),
      leftMiddleTip: project(handLandmarkSet.leftMiddleTip),
      leftRingMCP: project(handLandmarkSet.leftRingMCP),
      leftRingPIP: project(handLandmarkSet.leftRingPIP),
      leftRingDIP: project(handLandmarkSet.leftRingDIP),
      leftRingTip: project(handLandmarkSet.leftRingTip),
      leftPinkyMCP: project(handLandmarkSet.leftPinkyMCP),
      leftPinkyPIP: project(handLandmarkSet.leftPinkyPIP),
      leftPinkyDIP: project(handLandmarkSet.leftPinkyDIP),
      leftPinkyTip: project(handLandmarkSet.leftPinkyTip),
      
      // Mão direita
      rightWrist: project(handLandmarkSet.rightWrist),
      rightThumbCMC: project(handLandmarkSet.rightThumbCMC),
      rightThumbMCP: project(handLandmarkSet.rightThumbMCP),
      rightThumbIP: project(handLandmarkSet.rightThumbIP),
      rightThumbTip: project(handLandmarkSet.rightThumbTip),
      rightIndexMCP: project(handLandmarkSet.rightIndexMCP),
      rightIndexPIP: project(handLandmarkSet.rightIndexPIP),
      rightIndexDIP: project(handLandmarkSet.rightIndexDIP),
      rightIndexTip: project(handLandmarkSet.rightIndexTip),
      rightMiddleMCP: project(handLandmarkSet.rightMiddleMCP),
      rightMiddlePIP: project(handLandmarkSet.rightMiddlePIP),
      rightMiddleDIP: project(handLandmarkSet.rightMiddleDIP),
      rightMiddleTip: project(handLandmarkSet.rightMiddleTip),
      rightRingMCP: project(handLandmarkSet.rightRingMCP),
      rightRingPIP: project(handLandmarkSet.rightRingPIP),
      rightRingDIP: project(handLandmarkSet.rightRingDIP),
      rightRingTip: project(handLandmarkSet.rightRingTip),
      rightPinkyMCP: project(handLandmarkSet.rightPinkyMCP),
      rightPinkyPIP: project(handLandmarkSet.rightPinkyPIP),
      rightPinkyDIP: project(handLandmarkSet.rightPinkyDIP),
      rightPinkyTip: project(handLandmarkSet.rightPinkyTip),
    );
  }
}

class HandFrameData {
  final HandLandmarkSet landmarks;
  final HandLandmarkOffsets offsets;

  HandFrameData({
    required this.landmarks,
    required this.offsets,
  });

  factory HandFrameData.fromPose({
    required Pose pose,
    required Size screenSize,
    required Size imageSize,
    required InputImageRotation rotation,
    required CameraLensDirection lensDirection,
  }) {
    final landmarks = HandLandmarkSet.fromPose(pose);
    final offsets = HandLandmarkOffsets.fromPose(
      pose: pose,
      screenSize: screenSize,
      imageSize: imageSize,
      rotation: rotation,
      lensDirection: lensDirection,
    );
    return HandFrameData(
      landmarks: landmarks,
      offsets: offsets,
    );
  }
}
