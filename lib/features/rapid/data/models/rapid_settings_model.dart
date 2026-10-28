import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class RapidSettingsModel {
  final String userId;
  final bool showInfoVideo;
  final int totalTime;
  final DateTime updatedAt;
  final String gameMode;
  final String visualizationType; // 'line', 'bar', or 'circle'
  
  // Tap detection settings
  final double? tapSensitivity; // Sensitivity for finger tap detection (lower = more sensitive)
  final int? tapCooldownMs; // Cooldown between taps in milliseconds
  
  // Pulse line controller settings (física do gráfico)
  final int? maxPoints; // Tamanho da janela do gráfico
  final double? minY; // Piso normalizado
  final double? maxY; // Teto normalizado
  final double? baseline; // Nível inicial/base da linha
  final double? gravityPerSecond; // Queda por segundo (↑ = cai mais rápido)
  final double? impulseStrength; // Quanto sobe a cada tap
  final double? floorRestitution; // "Amortecimento" ao bater no piso (0 = sem bounce)
  
  // Pulse line state decay rates
  final double? decayRateIdle; // Taxa de decaimento no estado idle
  final double? decayRateActive; // Taxa de decaimento no estado active
  final double? decayRateUnstable; // Taxa de decaimento no estado unstable
  final double? decayRateFlatline; // Taxa de decaimento no estado flatline
  
  // Pulse line widget appearance
  final Color? lineColor; // Cor da linha
  final double? lineWidth; // Largura da linha
  final bool? glowEnabled; // Se o efeito glow está ativado
  final double? glowBlurSigma; // Intensidade do "glow"
  
  // Global settings
  final bool? useFixedDt; // Usar passo fixo
  final double? fixedDtSeconds; // Passo fixo em segundos (bom para captura a 30 fps)
  
  // Legacy settings
  final double? pulseMaxIntensity; // Max intensity for pulse line (0.0-1.0)
  final double? pulseGravity; // How fast the line falls (Flappy Bird style)
  final double? pulseImpulse; // How much the line rises on each tap

  RapidSettingsModel({
    required this.userId,
    required this.showInfoVideo,
    required this.totalTime,
    required this.updatedAt,
    this.gameMode = 'rightHand',
    this.visualizationType = 'line',
    
    // Tap detection settings
    this.tapSensitivity = 50.0,
    this.tapCooldownMs = 110,
    
    // Pulse line controller settings
    this.maxPoints = 420,
    this.minY = 0.0,
    this.maxY = 1.0,
    this.baseline = 0.25,
    this.gravityPerSecond = 0.35,
    this.impulseStrength = 0.06,
    this.floorRestitution = 0.0,
    
    // Pulse line state decay rates
    this.decayRateIdle = 0.05,
    this.decayRateActive = 0.03,
    this.decayRateUnstable = 0.07,
    this.decayRateFlatline = 0.10,
    
    // Pulse line widget appearance
    this.lineColor,
    this.lineWidth = 3.0,
    this.glowEnabled = true,
    this.glowBlurSigma = 8.0,
    
    // Global settings
    this.useFixedDt = true,
    this.fixedDtSeconds = 1/30,
    
    // Legacy settings
    this.pulseMaxIntensity = 0.6,
    this.pulseGravity = 0.003,
    this.pulseImpulse = 0.16,
  });

  Map<String, dynamic> toMap() {
    return {
      'userId': userId,
      'showInfoVideo': showInfoVideo,
      'totalTime': totalTime,
      'updatedAt': Timestamp.fromDate(updatedAt),
      'gameMode': gameMode,
      'visualizationType': visualizationType,
      
      // Tap detection settings
      'tapSensitivity': tapSensitivity,
      'tapCooldownMs': tapCooldownMs,
      
      // Pulse line controller settings
      'maxPoints': maxPoints,
      'minY': minY,
      'maxY': maxY,
      'baseline': baseline,
      'gravityPerSecond': gravityPerSecond,
      'impulseStrength': impulseStrength,
      'floorRestitution': floorRestitution,
      
      // Pulse line state decay rates
      'decayRateIdle': decayRateIdle,
      'decayRateActive': decayRateActive,
      'decayRateUnstable': decayRateUnstable,
      'decayRateFlatline': decayRateFlatline,
      
      // Pulse line widget appearance
      'lineColor': lineColor?.value,
      'lineWidth': lineWidth,
      'glowEnabled': glowEnabled,
      'glowBlurSigma': glowBlurSigma,
      
      // Global settings
      'useFixedDt': useFixedDt,
      'fixedDtSeconds': fixedDtSeconds,
      
      // Legacy settings
      'pulseMaxIntensity': pulseMaxIntensity,
      'pulseGravity': pulseGravity,
      'pulseImpulse': pulseImpulse,
    };
  }

  factory RapidSettingsModel.fromMap(Map<String, dynamic> map) {
    return RapidSettingsModel(
      userId: map['userId'] as String,
      showInfoVideo: map['showInfoVideo'] as bool,
      totalTime: map['totalTime'] as int,
      updatedAt: (map['updatedAt'] as Timestamp).toDate(),
      gameMode: map['gameMode'] as String? ?? 'rightHand',
      visualizationType: map['visualizationType'] as String? ?? 'line',
      
      // Tap detection settings
      tapSensitivity: map['tapSensitivity'] is double 
          ? map['tapSensitivity'] as double 
          : map['tapSensitivity'] is int 
              ? (map['tapSensitivity'] as int).toDouble() 
              : 50.0,
      tapCooldownMs: map['tapCooldownMs'] as int? ?? 110,
      
      // Pulse line controller settings
      maxPoints: map['maxPoints'] as int? ?? 420,
      minY: _parseDouble(map['minY'], 0.0),
      maxY: _parseDouble(map['maxY'], 1.0),
      baseline: _parseDouble(map['baseline'], 0.25),
      gravityPerSecond: _parseDouble(map['gravityPerSecond'], 0.35),
      impulseStrength: _parseDouble(map['impulseStrength'], 0.06),
      floorRestitution: _parseDouble(map['floorRestitution'], 0.0),
      
      // Pulse line state decay rates
      decayRateIdle: _parseDouble(map['decayRateIdle'], 0.05),
      decayRateActive: _parseDouble(map['decayRateActive'], 0.03),
      decayRateUnstable: _parseDouble(map['decayRateUnstable'], 0.07),
      decayRateFlatline: _parseDouble(map['decayRateFlatline'], 0.10),
      
      // Pulse line widget appearance
      lineColor: map['lineColor'] != null ? Color(map['lineColor'] as int) : null,
      lineWidth: _parseDouble(map['lineWidth'], 3.0),
      glowEnabled: map['glowEnabled'] as bool? ?? true,
      glowBlurSigma: _parseDouble(map['glowBlurSigma'], 8.0),
      
      // Global settings
      useFixedDt: map['useFixedDt'] as bool? ?? true,
      fixedDtSeconds: _parseDouble(map['fixedDtSeconds'], 1/30),
      
      // Legacy settings
      pulseMaxIntensity: _parseDouble(map['pulseMaxIntensity'], 0.6),
      pulseGravity: _parseDouble(map['pulseGravity'], 0.003),
      pulseImpulse: _parseDouble(map['pulseImpulse'], 0.16),
    );
  }
  
  // Helper method to parse double values from the map
  static double _parseDouble(dynamic value, double defaultValue) {
    if (value is double) return value;
    if (value is int) return value.toDouble();
    return defaultValue;
  }

  RapidSettingsModel copyWith({
    bool? showInfoVideo,
    int? totalTime,
    DateTime? updatedAt,
    String? gameMode,
    String? visualizationType,
    
    // Tap detection settings
    double? tapSensitivity,
    int? tapCooldownMs,
    
    // Pulse line controller settings
    int? maxPoints,
    double? minY,
    double? maxY,
    double? baseline,
    double? gravityPerSecond,
    double? impulseStrength,
    double? floorRestitution,
    
    // Pulse line state decay rates
    double? decayRateIdle,
    double? decayRateActive,
    double? decayRateUnstable,
    double? decayRateFlatline,
    
    // Pulse line widget appearance
    Color? lineColor,
    double? lineWidth,
    bool? glowEnabled,
    double? glowBlurSigma,
    
    // Global settings
    bool? useFixedDt,
    double? fixedDtSeconds,
    
    // Legacy settings
    double? pulseMaxIntensity,
    double? pulseGravity,
    double? pulseImpulse,
  }) {
    return RapidSettingsModel(
      userId: userId,
      showInfoVideo: showInfoVideo ?? this.showInfoVideo,
      totalTime: totalTime ?? this.totalTime,
      updatedAt: updatedAt ?? DateTime.now(),
      gameMode: gameMode ?? this.gameMode,
      visualizationType: visualizationType ?? this.visualizationType,
      
      // Tap detection settings
      tapSensitivity: tapSensitivity ?? this.tapSensitivity,
      tapCooldownMs: tapCooldownMs ?? this.tapCooldownMs,
      
      // Pulse line controller settings
      maxPoints: maxPoints ?? this.maxPoints,
      minY: minY ?? this.minY,
      maxY: maxY ?? this.maxY,
      baseline: baseline ?? this.baseline,
      gravityPerSecond: gravityPerSecond ?? this.gravityPerSecond,
      impulseStrength: impulseStrength ?? this.impulseStrength,
      floorRestitution: floorRestitution ?? this.floorRestitution,
      
      // Pulse line state decay rates
      decayRateIdle: decayRateIdle ?? this.decayRateIdle,
      decayRateActive: decayRateActive ?? this.decayRateActive,
      decayRateUnstable: decayRateUnstable ?? this.decayRateUnstable,
      decayRateFlatline: decayRateFlatline ?? this.decayRateFlatline,
      
      // Pulse line widget appearance
      lineColor: lineColor ?? this.lineColor,
      lineWidth: lineWidth ?? this.lineWidth,
      glowEnabled: glowEnabled ?? this.glowEnabled,
      glowBlurSigma: glowBlurSigma ?? this.glowBlurSigma,
      
      // Global settings
      useFixedDt: useFixedDt ?? this.useFixedDt,
      fixedDtSeconds: fixedDtSeconds ?? this.fixedDtSeconds,
      
      // Legacy settings
      pulseMaxIntensity: pulseMaxIntensity ?? this.pulseMaxIntensity,
      pulseGravity: pulseGravity ?? this.pulseGravity,
      pulseImpulse: pulseImpulse ?? this.pulseImpulse,
    );
  }
}


