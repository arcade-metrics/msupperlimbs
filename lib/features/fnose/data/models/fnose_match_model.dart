class FNoseMatchModel {
  final String matchId;
  final String sessionId;
  final String userId;
  final int totalTime;
  final String gameMode;
  final int? totalLeftSparks;
  final int? totalRightSparks;
  final int? totalSparks;
  final int imageWidth;
  final int imageHeight;
  final int screenWidth;
  final int screenHeight;
  final Map<String, double>? targetCalibrationOffset;
  final DateTime createdAt;
  final Map<String, dynamic>? advSettingsData;

  // Performance metrics
  final double? avgTouchTime;
  final double? avgDistance;
  final double? avgAngle;
  final double? timeCV;
  final double? distanceCV;
  final double? angleCV;
  final double? precisionIndex;
  final double? consistencyIndex;

  // Validation
  final bool? isValidMatch;
  final int? minTouchesRequired;
  final int? minTimeRequired;

  FNoseMatchModel({
    required this.matchId,
    required this.sessionId,
    required this.userId,
    required this.totalTime,
    required this.gameMode,
    this.totalLeftSparks,
    this.totalRightSparks,
    this.totalSparks,
    required this.imageWidth,
    required this.imageHeight,
    required this.screenWidth,
    required this.screenHeight,
    this.targetCalibrationOffset,
    required this.createdAt,
    this.advSettingsData,
    this.avgTouchTime,
    this.avgDistance,
    this.avgAngle,
    this.timeCV,
    this.distanceCV,
    this.angleCV,
    this.precisionIndex,
    this.consistencyIndex,
    this.isValidMatch,
    this.minTouchesRequired,
    this.minTimeRequired,
  });

  Map<String, dynamic> toMap() {
    return {
      'matchId': matchId,
      'sessionId': sessionId,
      'userId': userId,
      'totalTime': totalTime,
      'gameMode': gameMode,
      'totalLeftSparks': totalLeftSparks,
      'totalRightSparks': totalRightSparks,
      'totalSparks': totalSparks,
      'imageWidth': imageWidth,
      'imageHeight': imageHeight,
      'screenWidth': screenWidth,
      'screenHeight': screenHeight,
      'targetCalibrationOffset': targetCalibrationOffset,
      'createdAt': createdAt.toIso8601String(),
      'advSettingsData': advSettingsData,
      'avgTouchTime': avgTouchTime,
      'avgDistance': avgDistance,
      'avgAngle': avgAngle,
      'timeCV': timeCV,
      'distanceCV': distanceCV,
      'angleCV': angleCV,
      'precisionIndex': precisionIndex,
      'consistencyIndex': consistencyIndex,
      'isValidMatch': isValidMatch,
      'minTouchesRequired': minTouchesRequired,
      'minTimeRequired': minTimeRequired,
    };
  }

  factory FNoseMatchModel.fromMap(Map<String, dynamic> map) {
    return FNoseMatchModel(
      matchId: map['matchId'],
      sessionId: map['sessionId'],
      userId: map['userId'],
      totalTime: map['totalTime'],
      gameMode: map['gameMode'],
      totalLeftSparks: map['totalLeftSparks'],
      totalRightSparks: map['totalRightSparks'],
      totalSparks: map['totalSparks'],
      imageWidth: map['imageWidth'],
      imageHeight: map['imageHeight'],
      screenWidth: map['screenWidth'],
      screenHeight: map['screenHeight'],
      targetCalibrationOffset: map['targetCalibrationOffset'] != null
          ? Map<String, double>.from(map['targetCalibrationOffset'])
          : null,
      createdAt: DateTime.parse(map['createdAt']),
      advSettingsData: map['advSettingsData'] as Map<String, dynamic>?,
      avgTouchTime: (map['avgTouchTime'] as num?)?.toDouble(),
      avgDistance: (map['avgDistance'] as num?)?.toDouble(),
      avgAngle: (map['avgAngle'] as num?)?.toDouble(),
      timeCV: (map['timeCV'] as num?)?.toDouble(),
      distanceCV: (map['distanceCV'] as num?)?.toDouble(),
      angleCV: (map['angleCV'] as num?)?.toDouble(),
      precisionIndex: (map['precisionIndex'] as num?)?.toDouble(),
      consistencyIndex: (map['consistencyIndex'] as num?)?.toDouble(),
      isValidMatch: map['isValidMatch'] as bool?,
      minTouchesRequired: map['minTouchesRequired'] as int?,
      minTimeRequired: map['minTimeRequired'] as int?,
    );
  }

  FNoseMatchModel copyWith({
    String? matchId,
    String? sessionId,
    String? userId,
    int? totalTime,
    int? totalLeftSparks,
    int? totalRightSparks,
    int? totalSparks,
    String? gameMode,
    int? imageWidth,
    int? imageHeight,
    int? screenWidth,
    int? screenHeight,
    Map<String, double>? targetCalibrationOffset,
    DateTime? createdAt,
    Map<String, dynamic>? advSettingsData,
    double? avgTouchTime,
    double? avgDistance,
    double? avgAngle,
    double? timeCV,
    double? distanceCV,
    double? angleCV,
    double? precisionIndex,
    double? consistencyIndex,
    bool? isValidMatch,
    int? minTouchesRequired,
    int? minTimeRequired,
  }) {
    return FNoseMatchModel(
      matchId: matchId ?? this.matchId,
      sessionId: sessionId ?? this.sessionId,
      userId: userId ?? this.userId,
      totalTime: totalTime ?? this.totalTime,
      totalLeftSparks: totalLeftSparks ?? this.totalLeftSparks,
      totalRightSparks: totalRightSparks ?? this.totalRightSparks,
      totalSparks: totalSparks ?? this.totalSparks,
      gameMode: gameMode ?? this.gameMode,
      imageWidth: imageWidth ?? this.imageWidth,
      imageHeight: imageHeight ?? this.imageHeight,
      screenWidth: screenWidth ?? this.screenWidth,
      screenHeight: screenHeight ?? this.screenHeight,
      targetCalibrationOffset:
          targetCalibrationOffset ?? this.targetCalibrationOffset,
      createdAt: createdAt ?? this.createdAt,
      advSettingsData: advSettingsData ?? this.advSettingsData,
      avgTouchTime: avgTouchTime ?? this.avgTouchTime,
      avgDistance: avgDistance ?? this.avgDistance,
      avgAngle: avgAngle ?? this.avgAngle,
      timeCV: timeCV ?? this.timeCV,
      distanceCV: distanceCV ?? this.distanceCV,
      angleCV: angleCV ?? this.angleCV,
      precisionIndex: precisionIndex ?? this.precisionIndex,
      consistencyIndex: consistencyIndex ?? this.consistencyIndex,
      isValidMatch: isValidMatch ?? this.isValidMatch,
      minTouchesRequired: minTouchesRequired ?? this.minTouchesRequired,
      minTimeRequired: minTimeRequired ?? this.minTimeRequired,
    );
  }
}
