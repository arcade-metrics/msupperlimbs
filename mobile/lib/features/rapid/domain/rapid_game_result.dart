import 'package:msupperlimbs/features/motion/domain/motion_data_contract.dart';

class RapidGameResult {
  const RapidGameResult({
    required this.tapCount,
    required this.durationSeconds,
    required this.gameMode,
    required this.visualizationType,
    this.tapEvents = const [],
    this.pulseEvents = const [],
    this.poseSamples = const [],
    this.avgPulseHeight,
    this.maxPulseHeight,
    this.settingsSnapshot,
    this.screenWidth,
    this.screenHeight,
    this.imageWidth,
    this.imageHeight,
    this.startedAtMs,
    this.endedAtMs,
    this.preview,
    this.matchId,
    this.sessionId,
    this.saveError,
  });

  final int tapCount;
  final int durationSeconds;
  final String gameMode;
  final String visualizationType;
  final List<Map<String, dynamic>> tapEvents;
  final List<Map<String, dynamic>> pulseEvents;
  final List<Map<String, dynamic>> poseSamples;
  final double? avgPulseHeight;
  final double? maxPulseHeight;
  final Map<String, dynamic>? settingsSnapshot;
  final int? screenWidth;
  final int? screenHeight;
  final int? imageWidth;
  final int? imageHeight;
  final int? startedAtMs;
  final int? endedAtMs;
  final Map<String, double>? preview;
  final String? matchId;
  final String? sessionId;
  final String? saveError;

  double get tapsPerSecond =>
      durationSeconds <= 0 ? 0 : tapCount / durationSeconds;

  bool get saved => matchId != null && saveError == null;

  RapidGameResult copyWith({
    String? matchId,
    String? sessionId,
    String? saveError,
    bool clearSaveError = false,
  }) {
    return RapidGameResult(
      tapCount: tapCount,
      durationSeconds: durationSeconds,
      gameMode: gameMode,
      visualizationType: visualizationType,
      tapEvents: tapEvents,
      pulseEvents: pulseEvents,
      poseSamples: poseSamples,
      avgPulseHeight: avgPulseHeight,
      maxPulseHeight: maxPulseHeight,
      settingsSnapshot: settingsSnapshot,
      screenWidth: screenWidth,
      screenHeight: screenHeight,
      imageWidth: imageWidth,
      imageHeight: imageHeight,
      startedAtMs: startedAtMs,
      endedAtMs: endedAtMs,
      preview: preview,
      matchId: matchId ?? this.matchId,
      sessionId: sessionId ?? this.sessionId,
      saveError: clearSaveError ? null : (saveError ?? this.saveError),
    );
  }

  Map<String, dynamic> toMatchPayload({String? deviceModel}) {
    return {
      'data_contract_version': MotionDataContract.version,
      if (deviceModel != null) 'device_model': deviceModel,
      'total_time': durationSeconds,
      'game_mode': gameMode,
      'visualization_type': visualizationType,
      'tap_count': tapCount,
      'avg_tap_frequency': tapsPerSecond,
      'avg_pulse_height': avgPulseHeight,
      'max_pulse_height': maxPulseHeight,
      'settings_snapshot': settingsSnapshot,
      'screen_width': screenWidth,
      'screen_height': screenHeight,
      'image_width': imageWidth,
      'image_height': imageHeight,
      'started_at_ms': startedAtMs,
      'ended_at_ms': endedAtMs,
      'preview': preview,
      'is_valid_match': tapCount > 0,
      'tap_events': tapEvents,
      'pulse_events': pulseEvents,
      'pose_samples': poseSamples,
    };
  }
}

class RapidMatchSaveResponse {
  const RapidMatchSaveResponse({
    required this.id,
    required this.sessionId,
    required this.tapCount,
    required this.tapChunkCount,
    required this.pulseChunkCount,
    required this.poseChunkCount,
  });

  final String id;
  final String sessionId;
  final int tapCount;
  final int tapChunkCount;
  final int pulseChunkCount;
  final int poseChunkCount;

  factory RapidMatchSaveResponse.fromJson(Map<String, dynamic> json) {
    return RapidMatchSaveResponse(
      id: json['id'] as String,
      sessionId: json['session_id'] as String,
      tapCount: json['tap_count'] as int? ?? 0,
      tapChunkCount: json['tap_chunk_count'] as int? ?? 0,
      pulseChunkCount: json['pulse_chunk_count'] as int? ?? 0,
      poseChunkCount: json['pose_chunk_count'] as int? ?? 0,
    );
  }
}
