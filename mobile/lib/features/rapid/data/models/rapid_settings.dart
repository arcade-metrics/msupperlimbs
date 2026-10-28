class RapidSettings {
  const RapidSettings({
    required this.userId,
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
    required this.updatedAt,
  });

  final String userId;
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
  final DateTime updatedAt;

  factory RapidSettings.fromJson(Map<String, dynamic> json) {
    return RapidSettings(
      userId: json['user_id'] as String,
      showInfoVideo: json['show_info_video'] as bool,
      totalTime: json['total_time'] as int,
      gameMode: json['game_mode'] as String? ?? 'rightHand',
      visualizationType: json['visualization_type'] as String? ?? 'line',
      tapSensitivity: _asDouble(json['tap_sensitivity'], 0.04),
      tapCooldownMs: json['tap_cooldown_ms'] as int? ?? 110,
      maxPoints: json['max_points'] as int? ?? 420,
      minY: _asDouble(json['min_y'], 0),
      maxY: _asDouble(json['max_y'], 1),
      baseline: _asDouble(json['baseline'], 0.25),
      gravityPerSecond: _asDouble(json['gravity_per_second'], 0.35),
      impulseStrength: _asDouble(json['impulse_strength'], 0.06),
      floorRestitution: _asDouble(json['floor_restitution'], 0),
      decayRateIdle: _asDouble(json['decay_rate_idle'], 0.05),
      decayRateActive: _asDouble(json['decay_rate_active'], 0.03),
      decayRateUnstable: _asDouble(json['decay_rate_unstable'], 0.07),
      decayRateFlatline: _asDouble(json['decay_rate_flatline'], 0.10),
      lineColor: json['line_color'] as int?,
      lineWidth: _asDouble(json['line_width'], 3),
      glowEnabled: json['glow_enabled'] as bool? ?? true,
      glowBlurSigma: _asDouble(json['glow_blur_sigma'], 8),
      useFixedDt: json['use_fixed_dt'] as bool? ?? true,
      fixedDtSeconds: _asDouble(json['fixed_dt_seconds'], 1 / 30),
      pulseMaxIntensity: _asDouble(json['pulse_max_intensity'], 0.6),
      pulseGravity: _asDouble(json['pulse_gravity'], 0.003),
      pulseImpulse: _asDouble(json['pulse_impulse'], 0.16),
      updatedAt: DateTime.parse(json['updated_at'] as String),
    );
  }

  Map<String, dynamic> toUpdateJson() {
    return {
      'show_info_video': showInfoVideo,
      'total_time': totalTime,
      'game_mode': gameMode,
      'visualization_type': visualizationType,
      'tap_sensitivity': tapSensitivity,
      'tap_cooldown_ms': tapCooldownMs,
      'max_points': maxPoints,
      'min_y': minY,
      'max_y': maxY,
      'baseline': baseline,
      'gravity_per_second': gravityPerSecond,
      'impulse_strength': impulseStrength,
      'floor_restitution': floorRestitution,
      'decay_rate_idle': decayRateIdle,
      'decay_rate_active': decayRateActive,
      'decay_rate_unstable': decayRateUnstable,
      'decay_rate_flatline': decayRateFlatline,
      'line_color': lineColor,
      'line_width': lineWidth,
      'glow_enabled': glowEnabled,
      'glow_blur_sigma': glowBlurSigma,
      'use_fixed_dt': useFixedDt,
      'fixed_dt_seconds': fixedDtSeconds,
      'pulse_max_intensity': pulseMaxIntensity,
      'pulse_gravity': pulseGravity,
      'pulse_impulse': pulseImpulse,
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
      userId: userId,
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
