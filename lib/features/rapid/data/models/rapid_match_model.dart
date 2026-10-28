class RapidMatchModel {
  final String matchId;
  final String sessionId;
  final String userId;
  final int totalTime;
  final String gameMode;
  final int imageWidth;
  final int imageHeight;
  final int screenWidth;
  final int screenHeight;
  final DateTime createdAt;
  final Map<String, dynamic>? advSettingsData;
  final Map<String, dynamic>? handLandmarksData;
  
  // Game-specific data
  final int? tapCount;
  final String? selectedHand; // 'left', 'right', or 'both'
  final String? visualizationType; // 'line', 'bar', 'circle'
  final Map<String, dynamic>? settingsData; // Complete settings used during match
  
  // Performance metrics
  final double? avgTapFrequency; // taps per second
  final double? maxTapFrequency;
  final double? minTapFrequency;
  final double? tapFrequencyCV; // coefficient of variation
  final double? avgPulseHeight;
  final double? maxPulseHeight;
  final double? timeInActiveState; // seconds spent in active pulse state
  final double? timeInIdleState;
  final double? timeInUnstableState;
  final double? timeInFlatlineState;
  
  // Validation
  final bool? isValidMatch;
  final int? minTapsRequired;
  final int? minTimeRequired;

  RapidMatchModel({
    required this.matchId,
    required this.sessionId,
    required this.userId,
    required this.totalTime,
    required this.gameMode,
    required this.imageWidth,
    required this.imageHeight,
    required this.screenWidth,
    required this.screenHeight,
    required this.createdAt,
    this.advSettingsData,
    this.handLandmarksData,
    this.tapCount,
    this.selectedHand,
    this.visualizationType,
    this.settingsData,
    this.avgTapFrequency,
    this.maxTapFrequency,
    this.minTapFrequency,
    this.tapFrequencyCV,
    this.avgPulseHeight,
    this.maxPulseHeight,
    this.timeInActiveState,
    this.timeInIdleState,
    this.timeInUnstableState,
    this.timeInFlatlineState,
    this.isValidMatch,
    this.minTapsRequired,
    this.minTimeRequired,
  });

  Map<String, dynamic> toMap() {
    return {
      'matchId': matchId,
      'sessionId': sessionId,
      'userId': userId,
      'totalTime': totalTime,
      'gameMode': gameMode,
      'imageWidth': imageWidth,
      'imageHeight': imageHeight,
      'screenWidth': screenWidth,
      'screenHeight': screenHeight,
      'createdAt': createdAt.toIso8601String(),
      'advSettingsData': advSettingsData,
      'handLandmarksData': handLandmarksData,
      'tapCount': tapCount,
      'selectedHand': selectedHand,
      'visualizationType': visualizationType,
      'settingsData': settingsData,
      'avgTapFrequency': avgTapFrequency,
      'maxTapFrequency': maxTapFrequency,
      'minTapFrequency': minTapFrequency,
      'tapFrequencyCV': tapFrequencyCV,
      'avgPulseHeight': avgPulseHeight,
      'maxPulseHeight': maxPulseHeight,
      'timeInActiveState': timeInActiveState,
      'timeInIdleState': timeInIdleState,
      'timeInUnstableState': timeInUnstableState,
      'timeInFlatlineState': timeInFlatlineState,
      'isValidMatch': isValidMatch,
      'minTapsRequired': minTapsRequired,
      'minTimeRequired': minTimeRequired,
    };
  }

  factory RapidMatchModel.fromMap(Map<String, dynamic> map) {
    return RapidMatchModel(
      matchId: map['matchId'],
      sessionId: map['sessionId'],
      userId: map['userId'],
      totalTime: map['totalTime'],
      gameMode: map['gameMode'],
      imageWidth: map['imageWidth'],
      imageHeight: map['imageHeight'],
      screenWidth: map['screenWidth'],
      screenHeight: map['screenHeight'],
      createdAt: DateTime.parse(map['createdAt']),
      advSettingsData: map['advSettingsData'] as Map<String, dynamic>?,
      handLandmarksData: map['handLandmarksData'] as Map<String, dynamic>?,
      tapCount: map['tapCount'] as int?,
      selectedHand: map['selectedHand'] as String?,
      visualizationType: map['visualizationType'] as String?,
      settingsData: map['settingsData'] as Map<String, dynamic>?,
      avgTapFrequency: (map['avgTapFrequency'] as num?)?.toDouble(),
      maxTapFrequency: (map['maxTapFrequency'] as num?)?.toDouble(),
      minTapFrequency: (map['minTapFrequency'] as num?)?.toDouble(),
      tapFrequencyCV: (map['tapFrequencyCV'] as num?)?.toDouble(),
      avgPulseHeight: (map['avgPulseHeight'] as num?)?.toDouble(),
      maxPulseHeight: (map['maxPulseHeight'] as num?)?.toDouble(),
      timeInActiveState: (map['timeInActiveState'] as num?)?.toDouble(),
      timeInIdleState: (map['timeInIdleState'] as num?)?.toDouble(),
      timeInUnstableState: (map['timeInUnstableState'] as num?)?.toDouble(),
      timeInFlatlineState: (map['timeInFlatlineState'] as num?)?.toDouble(),
      isValidMatch: map['isValidMatch'] as bool?,
      minTapsRequired: map['minTapsRequired'] as int?,
      minTimeRequired: map['minTimeRequired'] as int?,
    );
  }

  RapidMatchModel copyWith({
    String? matchId,
    String? sessionId,
    String? userId,
    int? totalTime,
    String? gameMode,
    int? imageWidth,
    int? imageHeight,
    int? screenWidth,
    int? screenHeight,
    DateTime? createdAt,
    Map<String, dynamic>? advSettingsData,
    Map<String, dynamic>? handLandmarksData,
    int? tapCount,
    String? selectedHand,
    String? visualizationType,
    Map<String, dynamic>? settingsData,
    double? avgTapFrequency,
    double? maxTapFrequency,
    double? minTapFrequency,
    double? tapFrequencyCV,
    double? avgPulseHeight,
    double? maxPulseHeight,
    double? timeInActiveState,
    double? timeInIdleState,
    double? timeInUnstableState,
    double? timeInFlatlineState,
    bool? isValidMatch,
    int? minTapsRequired,
    int? minTimeRequired,
  }) {
    return RapidMatchModel(
      matchId: matchId ?? this.matchId,
      sessionId: sessionId ?? this.sessionId,
      userId: userId ?? this.userId,
      totalTime: totalTime ?? this.totalTime,
      gameMode: gameMode ?? this.gameMode,
      imageWidth: imageWidth ?? this.imageWidth,
      imageHeight: imageHeight ?? this.imageHeight,
      screenWidth: screenWidth ?? this.screenWidth,
      screenHeight: screenHeight ?? this.screenHeight,
      createdAt: createdAt ?? this.createdAt,
      advSettingsData: advSettingsData ?? this.advSettingsData,
      handLandmarksData: handLandmarksData ?? this.handLandmarksData,
      tapCount: tapCount ?? this.tapCount,
      selectedHand: selectedHand ?? this.selectedHand,
      visualizationType: visualizationType ?? this.visualizationType,
      settingsData: settingsData ?? this.settingsData,
      avgTapFrequency: avgTapFrequency ?? this.avgTapFrequency,
      maxTapFrequency: maxTapFrequency ?? this.maxTapFrequency,
      minTapFrequency: minTapFrequency ?? this.minTapFrequency,
      tapFrequencyCV: tapFrequencyCV ?? this.tapFrequencyCV,
      avgPulseHeight: avgPulseHeight ?? this.avgPulseHeight,
      maxPulseHeight: maxPulseHeight ?? this.maxPulseHeight,
      timeInActiveState: timeInActiveState ?? this.timeInActiveState,
      timeInIdleState: timeInIdleState ?? this.timeInIdleState,
      timeInUnstableState: timeInUnstableState ?? this.timeInUnstableState,
      timeInFlatlineState: timeInFlatlineState ?? this.timeInFlatlineState,
      isValidMatch: isValidMatch ?? this.isValidMatch,
      minTapsRequired: minTapsRequired ?? this.minTapsRequired,
      minTimeRequired: minTimeRequired ?? this.minTimeRequired,
    );
  }
}
