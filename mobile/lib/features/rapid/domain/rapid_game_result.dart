import 'package:msupperlimbs/features/motion/domain/motion_data_contract.dart';

class RapidGameResult {
  const RapidGameResult({
    required this.tapCount,
    required this.durationSeconds,
    this.durationMs = 0,
    required this.gameMode,
    required this.visualizationType,
    this.phaseEvents = const [],
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
    this.preview,
    this.matchId,
    this.sessionId,
    this.saveError,
  });

  final int tapCount;
  final int durationSeconds;

  /// Tempo jogado medido (fase `playing` → `finished`), em ms.
  final int durationMs;
  final String gameMode;
  final String visualizationType;
  final List<Map<String, dynamic>> phaseEvents;
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
      durationMs: durationMs,
      gameMode: gameMode,
      visualizationType: visualizationType,
      phaseEvents: phaseEvents,
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
      'duration_ms': durationMs,
      'preview': preview,
      'is_valid_match': tapCount > 0,
      'phase_events': phaseEvents,
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
