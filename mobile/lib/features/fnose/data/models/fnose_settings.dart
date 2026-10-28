class FnoseSettings {
  const FnoseSettings({
    required this.userId,
    required this.gameMode,
    required this.showInfoVideo,
    required this.totalTime,
    required this.targetSize,
    required this.updatedAt,
  });

  final String userId;
  final String gameMode;
  final bool showInfoVideo;
  final int totalTime;
  final double targetSize;
  final DateTime updatedAt;

  factory FnoseSettings.fromJson(Map<String, dynamic> json) {
    return FnoseSettings(
      userId: json['user_id'] as String,
      gameMode: json['game_mode'] as String? ?? 'leftHand',
      showInfoVideo: json['show_info_video'] as bool? ?? true,
      totalTime: json['total_time'] as int? ?? 60,
      targetSize: (json['target_size'] as num?)?.toDouble() ?? 1.0,
      updatedAt: DateTime.parse(json['updated_at'] as String),
    );
  }

  Map<String, dynamic> toUpdateJson() => {
    'game_mode': gameMode,
    'show_info_video': showInfoVideo,
    'total_time': totalTime,
    'target_size': targetSize,
  };

  FnoseSettings copyWith({
    String? gameMode,
    bool? showInfoVideo,
    int? totalTime,
    double? targetSize,
  }) {
    return FnoseSettings(
      userId: userId,
      gameMode: gameMode ?? this.gameMode,
      showInfoVideo: showInfoVideo ?? this.showInfoVideo,
      totalTime: totalTime ?? this.totalTime,
      targetSize: targetSize ?? this.targetSize,
      updatedAt: DateTime.now().toUtc(),
    );
  }
}

class FnoseAdvSettings {
  const FnoseAdvSettings({
    required this.userId,
    required this.data,
    required this.updatedAt,
  });

  final String userId;
  final Map<String, dynamic> data;
  final DateTime updatedAt;

  factory FnoseAdvSettings.fromJson(Map<String, dynamic> json) {
    return FnoseAdvSettings(
      userId: json['user_id'] as String,
      data: Map<String, dynamic>.from(json['data'] as Map? ?? {}),
      updatedAt: DateTime.parse(json['updated_at'] as String),
    );
  }

  double d(String key, double fallback) =>
      (data[key] as num?)?.toDouble() ?? fallback;

  int i(String key, int fallback) => (data[key] as num?)?.toInt() ?? fallback;

  FnoseAdvSettings copyWithData(Map<String, dynamic> data) {
    return FnoseAdvSettings(
      userId: userId,
      data: Map<String, dynamic>.from(data),
      updatedAt: DateTime.now().toUtc(),
    );
  }

  FnoseAdvSettings withValue(String key, num value) {
    final next = Map<String, dynamic>.from(data);
    next[key] = value;
    return copyWithData(next);
  }
}
