import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:msupperlimbs/features/fnose/domain/fnose_adv_settings_service.dart';

class FNoseAdvSettingsModel {
  final String userId;

  // Arm Tracking
  final double elbowFlexionThreshold;
  final double elbowExtensionThreshold;
  final double horizontalElbowShoulderDistanceThreshold;
  final double verticalElbowShoulderDistanceThreshold;
  final double noseTouchDistanceThreshold;
  final double minAngleChangeForElbowDetection;
  final double minAngleChangeForShoulderDetection;
  final double angleBufferSize;
  final double minDistanceToTarget;

  // Target Settings
  final int targetNumber;
  final double xTargetPosition;
  final double yTargetPosition;
  final double targetScale;

  // Pose validation
  final double minShoulderDistance;
  final double maxShoulderDistance;
  final double shoulderYAlignmentThreshold;
  final double shoulderZAlignmentThreshold;
  final double noseCenterThreshold;
  final double xNoseAlignment;
  final double yNoseAlignment;
  final double noseAlignmentThreshold;
  final double noseAlignmentTargetRadius;
  final int landmarkBufferSize;
  final int movingAverageFrames;

  // Device stability validation
  final double stabilityThreshold;
  final int requiredStableTimeMs;
  final int eventThrottleMs;
  final int updateDebounceMs;
  final int angleWindowSeconds;
  final double minAngle;
  final double maxAngle;
  final double alpha;

  final DateTime updatedAt;

  FNoseAdvSettingsModel({
    required this.elbowFlexionThreshold,
    required this.elbowExtensionThreshold,
    required this.horizontalElbowShoulderDistanceThreshold,
    required this.verticalElbowShoulderDistanceThreshold,
    required this.noseTouchDistanceThreshold,
    required this.minAngleChangeForElbowDetection,
    required this.minAngleChangeForShoulderDetection,
    required this.angleBufferSize,
    required this.minDistanceToTarget,
    required this.targetNumber,
    required this.xTargetPosition,
    required this.yTargetPosition,
    required this.targetScale,
    required this.userId,
    required this.minShoulderDistance,
    required this.maxShoulderDistance,
    required this.shoulderYAlignmentThreshold,
    required this.shoulderZAlignmentThreshold,
    required this.noseCenterThreshold,
    required this.xNoseAlignment,
    required this.yNoseAlignment,
    required this.noseAlignmentThreshold,
    required this.noseAlignmentTargetRadius,
    required this.landmarkBufferSize,
    required this.movingAverageFrames,
    required this.stabilityThreshold,
    required this.requiredStableTimeMs,
    required this.eventThrottleMs,
    required this.updateDebounceMs,
    required this.angleWindowSeconds,
    required this.minAngle,
    required this.maxAngle,
    required this.alpha,
    required this.updatedAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'elbowFlexionThreshold': elbowFlexionThreshold,
      'elbowExtensionThreshold': elbowExtensionThreshold,
      'horizontalElbowShoulderDistanceThreshold':
          horizontalElbowShoulderDistanceThreshold,
      'verticalElbowShoulderDistanceThreshold':
          verticalElbowShoulderDistanceThreshold,
      'noseTouchDistanceThreshold': noseTouchDistanceThreshold,
      'minAngleChangeForElbowDetection': minAngleChangeForElbowDetection,
      'minAngleChangeForShoulderDetection': minAngleChangeForShoulderDetection,
      'angleBufferSize': angleBufferSize,
      'minDistanceToTarget': minDistanceToTarget,
      'targetNumber': targetNumber,
      'xTargetPosition': xTargetPosition,
      'yTargetPosition': yTargetPosition,
      'targetScale': targetScale,
      'userId': userId,
      'minShoulderDistance': minShoulderDistance,
      'maxShoulderDistance': maxShoulderDistance,
      'shoulderYAlignmentThreshold': shoulderYAlignmentThreshold,
      'shoulderZAlignmentThreshold': shoulderZAlignmentThreshold,
      'noseCenterThreshold': noseCenterThreshold,
      'xNoseAlignment': xNoseAlignment,
      'yNoseAlignment': yNoseAlignment,
      'noseAlignmentThreshold': noseAlignmentThreshold,
      'noseAlignmentTargetRadius': noseAlignmentTargetRadius,
      'landmarkBufferSize': landmarkBufferSize,
      'movingAverageFrames': movingAverageFrames,
      'stabilityThreshold': stabilityThreshold,
      'requiredStableTimeMs': requiredStableTimeMs,
      'eventThrottleMs': eventThrottleMs,
      'updateDebounceMs': updateDebounceMs,
      'angleWindowSeconds': angleWindowSeconds,
      'minAngle': minAngle,
      'maxAngle': maxAngle,
      'alpha': alpha,
      'updatedAt': Timestamp.fromDate(updatedAt),
    };
  }

  factory FNoseAdvSettingsModel.fromMap(Map<String, dynamic> map) {
    final defaults = FNoseAdvSettingsService.getDefaultValues();
    
    return FNoseAdvSettingsModel(
      alpha: ((map['alpha'] ?? defaults['alpha']) as num).toDouble(),
      angleBufferSize: ((map['angleBufferSize'] ?? defaults['angleBufferSize']) as num).toDouble(),
      angleWindowSeconds: ((map['angleWindowSeconds'] ?? defaults['angleWindowSeconds']) as num).toInt(),
      elbowFlexionThreshold:
          ((map['elbowFlexionThreshold'] ?? defaults['elbowFlexionThreshold']) as num).toDouble(),
      elbowExtensionThreshold:
          ((map['elbowExtensionThreshold'] ?? defaults['elbowExtensionThreshold']) as num).toDouble(),
      horizontalElbowShoulderDistanceThreshold:
          ((map['horizontalElbowShoulderDistanceThreshold'] ?? defaults['horizontalElbowShoulderDistanceThreshold']) as num)
              .toDouble(),
      maxShoulderDistance:
          ((map['maxShoulderDistance'] ?? defaults['maxShoulderDistance']) as num).toDouble(),
      minAngleChangeForElbowDetection:
          ((map['minAngleChangeForElbowDetection'] ?? defaults['minAngleChangeForElbowDetection']) as num).toDouble(),
      minAngleChangeForShoulderDetection:
          ((map['minAngleChangeForShoulderDetection'] ?? defaults['minAngleChangeForShoulderDetection']) as num)
              .toDouble(),
      minDistanceToTarget:
          ((map['minDistanceToTarget'] ?? defaults['minDistanceToTarget']) as num).toDouble(),
      minShoulderDistance:
          ((map['minShoulderDistance'] ?? defaults['minShoulderDistance']) as num).toDouble(),
      movingAverageFrames: ((map['movingAverageFrames'] ?? defaults['movingAverageFrames']) as num).toInt(),
      noseCenterThreshold:
          ((map['noseCenterThreshold'] ?? defaults['noseCenterThreshold']) as num).toDouble(),
      noseTouchDistanceThreshold:
          ((map['noseTouchDistanceThreshold'] ?? defaults['noseTouchDistanceThreshold']) as num).toDouble(),
      targetNumber: ((map['targetNumber'] ?? defaults['targetNumber']) as num).toInt(),
      targetScale: ((map['targetScale'] ?? defaults['targetScale']) as num).toDouble(),
      requiredStableTimeMs:
          ((map['requiredStableTimeMs'] ?? defaults['requiredStableTimeMs']) as num).toInt(),
      shoulderYAlignmentThreshold:
          ((map['shoulderYAlignmentThreshold'] ?? defaults['shoulderYAlignmentThreshold']) as num).toDouble(),
      shoulderZAlignmentThreshold:
          ((map['shoulderZAlignmentThreshold'] ?? defaults['shoulderZAlignmentThreshold']) as num).toDouble(),
      stabilityThreshold:
          ((map['stabilityThreshold'] ?? defaults['stabilityThreshold']) as num).toDouble(),
      eventThrottleMs: ((map['eventThrottleMs'] ?? defaults['eventThrottleMs']) as num).toInt(),
      updateDebounceMs: ((map['updateDebounceMs'] ?? defaults['updateDebounceMs']) as num).toInt(),
      minAngle: ((map['minAngle'] ?? defaults['minAngle']) as num).toDouble(),
      maxAngle: ((map['maxAngle'] ?? defaults['maxAngle']) as num).toDouble(),
      updatedAt:
          (map['updatedAt'] as Timestamp?)?.toDate() ?? DateTime.now().toUtc(),
      userId: map['userId'] as String,
      verticalElbowShoulderDistanceThreshold:
          ((map['verticalElbowShoulderDistanceThreshold'] ?? defaults['verticalElbowShoulderDistanceThreshold']) as num)
              .toDouble(),
      xTargetPosition: ((map['xTargetPosition'] ?? defaults['xTargetPosition']) as num).toDouble(),
      yTargetPosition: ((map['yTargetPosition'] ?? defaults['yTargetPosition']) as num).toDouble(),
      xNoseAlignment: ((map['xNoseAlignment'] ?? defaults['xNoseAlignment']) as num).toDouble(),
      yNoseAlignment: ((map['yNoseAlignment'] ?? defaults['yNoseAlignment']) as num).toDouble(),
      noseAlignmentThreshold:
          ((map['noseAlignmentThreshold'] ?? defaults['noseAlignmentThreshold']) as num).toDouble(),
      noseAlignmentTargetRadius:
          ((map['noseAlignmentTargetRadius'] ?? defaults['noseAlignmentTargetRadius']) as num).toDouble(),
      landmarkBufferSize: ((map['landmarkBufferSize'] ?? defaults['landmarkBufferSize']) as num).toInt(),
    );
  }

  FNoseAdvSettingsModel copyWith({
    double? elbowFlexionThreshold,
    double? elbowExtensionThreshold,
    double? horizontalElbowShoulderDistanceThreshold,
    double? verticalElbowShoulderDistanceThreshold,
    double? noseTouchDistanceThreshold,
    double? minAngleChangeForElbowDetection,
    double? minAngleChangeForShoulderDetection,
    double? angleBufferSize,
    double? minDistanceToTarget,
    int? targetNumber,
    double? xTargetPosition,
    double? yTargetPosition,
    double? targetScale,
    double? minShoulderDistance,
    double? maxShoulderDistance,
    double? shoulderYAlignmentThreshold,
    double? shoulderZAlignmentThreshold,
    double? noseCenterThreshold,
    double? xNoseAlignment,
    double? yNoseAlignment,
    double? noseAlignmentThreshold,
    double? noseAlignmentTargetRadius,
    int? landmarkBufferSize,
    int? movingAverageFrames,
    double? stabilityThreshold,
    int? requiredStableTimeMs,
    int? eventThrottleMs,
    int? updateDebounceMs,
    int? angleWindowSeconds,
    double? minAngle,
    double? maxAngle,
    double? alpha,
    DateTime? updatedAt,
  }) {
    return FNoseAdvSettingsModel(
      elbowFlexionThreshold:
          elbowFlexionThreshold ?? this.elbowFlexionThreshold,
      elbowExtensionThreshold:
          elbowExtensionThreshold ?? this.elbowExtensionThreshold,
      horizontalElbowShoulderDistanceThreshold:
          horizontalElbowShoulderDistanceThreshold ??
              this.horizontalElbowShoulderDistanceThreshold,
      verticalElbowShoulderDistanceThreshold:
          verticalElbowShoulderDistanceThreshold ??
              this.verticalElbowShoulderDistanceThreshold,
      noseTouchDistanceThreshold:
          noseTouchDistanceThreshold ?? this.noseTouchDistanceThreshold,
      minAngleChangeForElbowDetection: minAngleChangeForElbowDetection ??
          this.minAngleChangeForElbowDetection,
      minAngleChangeForShoulderDetection: minAngleChangeForShoulderDetection ??
          this.minAngleChangeForShoulderDetection,
      angleBufferSize: angleBufferSize ?? this.angleBufferSize,
      minDistanceToTarget: minDistanceToTarget ?? this.minDistanceToTarget,
      targetNumber: targetNumber ?? this.targetNumber,
      xTargetPosition: xTargetPosition ?? this.xTargetPosition,
      yTargetPosition: yTargetPosition ?? this.yTargetPosition,
      targetScale: targetScale ?? this.targetScale,
      userId: userId,
      minShoulderDistance: minShoulderDistance ?? this.minShoulderDistance,
      maxShoulderDistance: maxShoulderDistance ?? this.maxShoulderDistance,
      shoulderYAlignmentThreshold:
          shoulderYAlignmentThreshold ?? this.shoulderYAlignmentThreshold,
      shoulderZAlignmentThreshold:
          shoulderZAlignmentThreshold ?? this.shoulderZAlignmentThreshold,
      noseCenterThreshold: noseCenterThreshold ?? this.noseCenterThreshold,
      xNoseAlignment: xNoseAlignment ?? this.xNoseAlignment,
      yNoseAlignment: yNoseAlignment ?? this.yNoseAlignment,
      noseAlignmentThreshold: noseAlignmentThreshold ?? this.noseAlignmentThreshold,
      noseAlignmentTargetRadius: noseAlignmentTargetRadius ?? this.noseAlignmentTargetRadius,
      landmarkBufferSize: landmarkBufferSize ?? this.landmarkBufferSize,
      movingAverageFrames: movingAverageFrames ?? this.movingAverageFrames,
      stabilityThreshold: stabilityThreshold ?? this.stabilityThreshold,
      requiredStableTimeMs: requiredStableTimeMs ?? this.requiredStableTimeMs,
      eventThrottleMs: eventThrottleMs ?? this.eventThrottleMs,
      updateDebounceMs: updateDebounceMs ?? this.updateDebounceMs,
      angleWindowSeconds: angleWindowSeconds ?? this.angleWindowSeconds,
      minAngle: minAngle ?? this.minAngle,
      maxAngle: maxAngle ?? this.maxAngle,
      alpha: alpha ?? this.alpha,
      updatedAt: updatedAt ?? DateTime.now(),
    );
  }

  double getNoseAlignmentXCoordinate(bool isLeftHand) {
    return isLeftHand ? xNoseAlignment : (1.0 - xNoseAlignment);
  }

  /// @deprecated Use getNoseAlignmentXCoordinate instead
  double getNoseAlignmentX(bool isLeftHand) {
    return getNoseAlignmentXCoordinate(isLeftHand);
  }
}
