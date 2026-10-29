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

  /// Phase, tap and pulse_tick events on one timeline, ordered by
  /// `offsetMs` (events at the same offset keep their order).
  List<Map<String, dynamic>> get events {
    final all = [...phaseEvents, ...tapEvents, ...pulseEvents];
    int offset(int i) => all[i]['offsetMs'] as int;
    final order = List<int>.generate(all.length, (i) => i)
      ..sort((a, b) {
        final byOffset = offset(a).compareTo(offset(b));
        return byOffset != 0 ? byOffset : a.compareTo(b);
      });
    return [for (final i in order) all[i]];
  }

  /// Body of `POST /msupperlimbs-rapid/matches/{id}/metrics`.
  Map<String, dynamic> toMetricsJson() => {
    'tapCount': tapCount,
    'avgTapFrequency': tapsPerSecond,
    'avgPulseHeight': ?avgPulseHeight,
    'maxPulseHeight': ?maxPulseHeight,
    'isValidMatch': tapCount > 0,
  };
}
