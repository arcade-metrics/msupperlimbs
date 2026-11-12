/// Rapid player settings (`/msupperlimbs-rapid/players/{id}/settings`).
class RapidSettings {
  const RapidSettings({
    this.presetId,
    required this.showInfoVideo,
    required this.totalTime,
    required this.gameMode,
    required this.visualizationType,
    required this.tapSensitivity,
    required this.tapCooldownMs,
    required this.maxPoints,
    required this.minY,
    required this.maxY,
    required this.baseline,
    required this.gravityPerSecond,
    required this.impulseStrength,
    required this.floorRestitution,
    required this.decayRateIdle,
    required this.decayRateActive,
    required this.decayRateUnstable,
    required this.decayRateFlatline,
    required this.lineColor,
    required this.lineWidth,
    required this.glowEnabled,
    required this.glowBlurSigma,
    required this.useFixedDt,
    required this.fixedDtSeconds,
    required this.pulseMaxIntensity,
    required this.pulseGravity,
    required this.pulseImpulse,
    this.updatedAt,
  });

  /// Preset the settings were seeded from.
  final String? presetId;
  final bool showInfoVideo;
  final int totalTime;
  final String gameMode;
  final String visualizationType;
  final double tapSensitivity;
  final int tapCooldownMs;
  final int maxPoints;
  final double minY;
  final double maxY;
  final double baseline;
  final double gravityPerSecond;
  final double impulseStrength;
  final double floorRestitution;
  final double decayRateIdle;
  final double decayRateActive;
  final double decayRateUnstable;
  final double decayRateFlatline;
  final int? lineColor;
  final double lineWidth;
  final bool glowEnabled;
  final double glowBlurSigma;
  final bool useFixedDt;
  final double fixedDtSeconds;
  final double pulseMaxIntensity;
  final double pulseGravity;
  final double pulseImpulse;
  final DateTime? updatedAt;

  /// Parses the API envelope `{presetId, updatedAt, settings: {…}}`.
  factory RapidSettings.fromApi(Map<String, dynamic> envelope) {
    final json = envelope['settings'] as Map<String, dynamic>;
    final updatedAt = envelope['updatedAt'] as String?;
    return RapidSettings(
      presetId: envelope['presetId'] as String?,
      showInfoVideo: json['showInfoVideo'] as bool? ?? true,
      totalTime: json['totalTime'] as int? ?? 30,
      gameMode: json['gameMode'] as String? ?? 'rightHand',
      visualizationType: json['visualizationType'] as String? ?? 'line',
      tapSensitivity: _asDouble(json['tapSensitivity'], 0.04),
      tapCooldownMs: json['tapCooldownMs'] as int? ?? 110,
      maxPoints: json['maxPoints'] as int? ?? 420,
      minY: _asDouble(json['minY'], 0),
      maxY: _asDouble(json['maxY'], 1),
      baseline: _asDouble(json['baseline'], 0.25),
      gravityPerSecond: _asDouble(json['gravityPerSecond'], 0.35),
      impulseStrength: _asDouble(json['impulseStrength'], 0.06),
      floorRestitution: _asDouble(json['floorRestitution'], 0),
      decayRateIdle: _asDouble(json['decayRateIdle'], 0.05),
      decayRateActive: _asDouble(json['decayRateActive'], 0.03),
      decayRateUnstable: _asDouble(json['decayRateUnstable'], 0.07),
      decayRateFlatline: _asDouble(json['decayRateFlatline'], 0.10),
      lineColor: json['lineColor'] as int?,
      lineWidth: _asDouble(json['lineWidth'], 3),
      glowEnabled: json['glowEnabled'] as bool? ?? true,
      glowBlurSigma: _asDouble(json['glowBlurSigma'], 8),
      useFixedDt: json['useFixedDt'] as bool? ?? true,
      fixedDtSeconds: _asDouble(json['fixedDtSeconds'], 1 / 30),
      pulseMaxIntensity: _asDouble(json['pulseMaxIntensity'], 0.6),
      pulseGravity: _asDouble(json['pulseGravity'], 0.003),
      pulseImpulse: _asDouble(json['pulseImpulse'], 0.16),
      updatedAt: updatedAt == null ? null : DateTime.parse(updatedAt),
    );
  }

  /// Every field, camelCase, as `PATCH …/settings` accepts it.
  Map<String, dynamic> toUpdateJson() {
    return {
      'showInfoVideo': showInfoVideo,
      'totalTime': totalTime,
      'gameMode': gameMode,
      'visualizationType': visualizationType,
      'tapSensitivity': tapSensitivity,
      'tapCooldownMs': tapCooldownMs,
      'maxPoints': maxPoints,
      'minY': minY,
      'maxY': maxY,
      'baseline': baseline,
      'gravityPerSecond': gravityPerSecond,
      'impulseStrength': impulseStrength,
      'floorRestitution': floorRestitution,
      'decayRateIdle': decayRateIdle,
      'decayRateActive': decayRateActive,
      'decayRateUnstable': decayRateUnstable,
      'decayRateFlatline': decayRateFlatline,
      'lineColor': lineColor,
      'lineWidth': lineWidth,
      'glowEnabled': glowEnabled,
      'glowBlurSigma': glowBlurSigma,
      'useFixedDt': useFixedDt,
      'fixedDtSeconds': fixedDtSeconds,
      'pulseMaxIntensity': pulseMaxIntensity,
      'pulseGravity': pulseGravity,
      'pulseImpulse': pulseImpulse,
    };
  }

  RapidSettings copyWith({
    bool? showInfoVideo,
    int? totalTime,
    String? gameMode,
    String? visualizationType,
    double? tapSensitivity,
    int? tapCooldownMs,
    int? maxPoints,
    double? minY,
    double? maxY,
    double? baseline,
    double? gravityPerSecond,
    double? impulseStrength,
    double? floorRestitution,
    double? decayRateIdle,
    double? decayRateActive,
    double? decayRateUnstable,
    double? decayRateFlatline,
    int? lineColor,
    double? lineWidth,
    bool? glowEnabled,
    double? glowBlurSigma,
    bool? useFixedDt,
    double? fixedDtSeconds,
    double? pulseMaxIntensity,
    double? pulseGravity,
    double? pulseImpulse,
  }) {
    return RapidSettings(
      presetId: presetId,
      showInfoVideo: showInfoVideo ?? this.showInfoVideo,
      totalTime: totalTime ?? this.totalTime,
      gameMode: gameMode ?? this.gameMode,
      visualizationType: visualizationType ?? this.visualizationType,
      tapSensitivity: tapSensitivity ?? this.tapSensitivity,
      tapCooldownMs: tapCooldownMs ?? this.tapCooldownMs,
      maxPoints: maxPoints ?? this.maxPoints,
      minY: minY ?? this.minY,
      maxY: maxY ?? this.maxY,
      baseline: baseline ?? this.baseline,
      gravityPerSecond: gravityPerSecond ?? this.gravityPerSecond,
      impulseStrength: impulseStrength ?? this.impulseStrength,
      floorRestitution: floorRestitution ?? this.floorRestitution,
      decayRateIdle: decayRateIdle ?? this.decayRateIdle,
      decayRateActive: decayRateActive ?? this.decayRateActive,
      decayRateUnstable: decayRateUnstable ?? this.decayRateUnstable,
      decayRateFlatline: decayRateFlatline ?? this.decayRateFlatline,
      lineColor: lineColor ?? this.lineColor,
      lineWidth: lineWidth ?? this.lineWidth,
      glowEnabled: glowEnabled ?? this.glowEnabled,
      glowBlurSigma: glowBlurSigma ?? this.glowBlurSigma,
      useFixedDt: useFixedDt ?? this.useFixedDt,
      fixedDtSeconds: fixedDtSeconds ?? this.fixedDtSeconds,
      pulseMaxIntensity: pulseMaxIntensity ?? this.pulseMaxIntensity,
      pulseGravity: pulseGravity ?? this.pulseGravity,
      pulseImpulse: pulseImpulse ?? this.pulseImpulse,
      updatedAt: DateTime.now().toUtc(),
    );
  }

  static double _asDouble(dynamic value, double fallback) {
    if (value is double) return value;
    if (value is int) return value.toDouble();
    if (value is num) return value.toDouble();
    return fallback;
  }
}
