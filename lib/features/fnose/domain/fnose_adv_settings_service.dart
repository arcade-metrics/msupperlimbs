import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:msupperlimbs/features/fnose/data/models/fnose_adv_settings_model.dart';
import 'package:msupperlimbs/features/fnose/data/repositories/fnose_adv_settings_repository.dart';

class FNoseAdvSettingsService {
  final FNoseAdvSettingsRepository _repository;

  FNoseAdvSettingsService(this._repository);

  /// Static method to provide default values for the model
  static Map<String, dynamic> getDefaultValues() {
    return {
      'alpha': 0.3,
      'angleBufferSize': 2.0,
      'angleWindowSeconds': 1,
      'elbowFlexionThreshold': 30.0,
      'elbowExtensionThreshold': 160.0,
      'horizontalElbowShoulderDistanceThreshold': 0.25,
      'maxShoulderDistance': 0.3,
      'minAngleChangeForElbowDetection': 4.0,
      'minAngleChangeForShoulderDetection': 4.0,
      'minDistanceToTarget': 0.18,
      'minShoulderDistance': 0.2,
      'movingAverageFrames': 5,
      'noseCenterThreshold': 0.45,
      'noseTouchDistanceThreshold': 0.18,
      'targetNumber': 4,
      'targetScale': 0.45,
      'requiredStableTimeMs': 2500,
      'shoulderYAlignmentThreshold': 0.35,
      'shoulderZAlignmentThreshold': 0.35,
      'stabilityThreshold': 0.5,
      'eventThrottleMs': 50,
      'updateDebounceMs': 50,
      'minAngle': 70.0,
      'maxAngle': 120.0,
      'verticalElbowShoulderDistanceThreshold': 0.2,
      'xTargetPosition': 0.1,
      'yTargetPosition': 0.5,
      'xNoseAlignment': 0.7,
      'yNoseAlignment': 0.3,
      'noseAlignmentThreshold': 0.05,
      'noseAlignmentTargetRadius': 0.07,
      'landmarkBufferSize': 3,
    };
  }

  /// Returns existing settings or creates them with default values
  Future<FNoseAdvSettingsModel> getOrCreateFNoseAdvSettings(
      String userId) async {
    final existingSettings = await _repository.getFNoseAdvSettings(userId);
    return existingSettings ?? await createFNoseAdvSettingsStandard(userId);
  }

  /// Creates settings if they don't exist (idempotent)
  Future<void> createFNoseAdvSettingsIfNotExists(String userId) async {
    final existingSettings = await _repository.getFNoseAdvSettings(userId);
    if (existingSettings == null) {
      final defaultSettings = _fnoseAdvDefaultSettings(userId);
      await _repository.saveFNoseAdvSettings(userId, defaultSettings);
    }
  }

  /// Creates settings with default values (always creates new)
  Future<FNoseAdvSettingsModel> createFNoseAdvSettingsStandard(
      String userId) async {
    final defaultSettings = _fnoseAdvDefaultSettings(userId);
    await _repository.saveFNoseAdvSettings(userId, defaultSettings);
    return defaultSettings;
  }

  /// Restores and returns default settings
  Future<FNoseAdvSettingsModel> restoreFNoseAdvSettingsDefaults(
      String userId) async {
    final defaultSettings = _fnoseAdvDefaultSettings(userId);
    await _repository.saveFNoseAdvSettings(userId, defaultSettings);
    return defaultSettings;
  }

  /// Updates settings with given values
  Future<void> updateFNoseAdvSettings(
      FNoseAdvSettingsModel fnoseAdvSettingsModel) async {
    await _repository.saveFNoseAdvSettings(
        fnoseAdvSettingsModel.userId, fnoseAdvSettingsModel);
  }

  /// Internal: returns default settings instance
  FNoseAdvSettingsModel _fnoseAdvDefaultSettings(String userId) {
    final defaults = getDefaultValues();
    return FNoseAdvSettingsModel(
      // User ID associated with settings
      userId: userId,

      // Smoothing factor for exponential moving average (0–1)
      alpha: defaults['alpha'],

      // Number of angle readings to smooth over (buffer size)
      angleBufferSize: defaults['angleBufferSize'],

      // Time window for analysing joint angles (seconds)
      angleWindowSeconds: defaults['angleWindowSeconds'],

      // Maximum extension angle to consider the elbow fully extended
      elbowExtensionThreshold: defaults['elbowExtensionThreshold'],

      // Minimum flexion angle to consider the elbow bent
      elbowFlexionThreshold: defaults['elbowFlexionThreshold'],

      // Time between accepted events to avoid duplicates (ms)
      eventThrottleMs: defaults['eventThrottleMs'],

      // Horizontal distance threshold between elbow and shoulder (normalised)
      horizontalElbowShoulderDistanceThreshold: defaults['horizontalElbowShoulderDistanceThreshold'],

      // Maximum valid movement angle for the task
      maxAngle: defaults['maxAngle'],

      // Maximum shoulder distance to avoid overly wide posture (normalised)
      maxShoulderDistance: defaults['maxShoulderDistance'],

      // Minimum valid movement angle for the task
      minAngle: defaults['minAngle'],

      // Minimum angular variation to register elbow movement
      minAngleChangeForElbowDetection: defaults['minAngleChangeForElbowDetection'],

      // Minimum angular variation to register shoulder movement
      minAngleChangeForShoulderDetection: defaults['minAngleChangeForShoulderDetection'],

      // Minimum distance required to reach a target (normalised)
      minDistanceToTarget: defaults['minDistanceToTarget'],

      // Minimum shoulder distance to consider arms properly apart (normalised)
      minShoulderDistance: defaults['minShoulderDistance'],

      // Number of frames to average for smoothing (e.g. tremor filtering)
      movingAverageFrames: defaults['movingAverageFrames'],

      // Horizontal distance tolerance to consider the nose centered (normalised)
      noseCenterThreshold: defaults['noseCenterThreshold'],

      // Tolerance for nose alignment validation (normalised)
      noseAlignmentThreshold: defaults['noseAlignmentThreshold'],

      // Visual target radius for nose alignment indicator (normalised)
      noseAlignmentTargetRadius: defaults['noseAlignmentTargetRadius'],

      // Buffer size for landmark smoothing (frames)
      landmarkBufferSize: defaults['landmarkBufferSize'],

      // Max distance allowed to consider the nose was touched (normalised)
      noseTouchDistanceThreshold: defaults['noseTouchDistanceThreshold'],

      // Time in ms the movement must remain stable
      requiredStableTimeMs: defaults['requiredStableTimeMs'],

      // Vertical alignment tolerance between shoulders (normalised)
      shoulderYAlignmentThreshold: defaults['shoulderYAlignmentThreshold'],

      // Depth alignment tolerance between shoulders (normalised)
      shoulderZAlignmentThreshold: defaults['shoulderZAlignmentThreshold'],

      // Minimum stability confidence (0–1) to confirm stable state
      stabilityThreshold: defaults['stabilityThreshold'],

      // Number of default target
      targetNumber: defaults['targetNumber'],

      // Target visual size relative to screen (%)
      targetScale: defaults['targetScale'],

      // Delay after changes before applying update (ms)
      updateDebounceMs: defaults['updateDebounceMs'],

      // Vertical distance threshold between elbow and shoulder (normalised)
      verticalElbowShoulderDistanceThreshold: defaults['verticalElbowShoulderDistanceThreshold'],

      // Target nose alignment position X (normalised, % of screen width)
      xNoseAlignment: defaults['xNoseAlignment'],

      // Target horizontal position (distance from screen edge to target edge, 0 = at edge, 0.5 = at center)
      xTargetPosition: defaults['xTargetPosition'],

      // Target nose alignment position Y (normalised, 0 = top, 1 = bottom)
      yNoseAlignment: defaults['yNoseAlignment'],

      // Target vertical position (normalised, 0 = top, 1 = bottom)
      yTargetPosition: defaults['yTargetPosition'],

      // Timestamp of last update
      updatedAt: DateTime.now().toUtc(),
    );
  }
}
