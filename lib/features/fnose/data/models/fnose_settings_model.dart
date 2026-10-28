import 'package:cloud_firestore/cloud_firestore.dart';

class FNoseSettingsModel {
  final String userId;
  final String gameMode;
  final bool showInfoVideo;
  final int totalTime;
  final double targetSize;
  final DateTime updatedAt;

  FNoseSettingsModel({
    required this.userId,
    required this.gameMode,
    required this.showInfoVideo,
    required this.totalTime,
    required this.targetSize,
    required this.updatedAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'userId': userId,
      'gameMode': gameMode,
      'showInfoVideo': showInfoVideo,
      'totalTime': totalTime,
      'targetSize': targetSize,
      'updatedAt': Timestamp.fromDate(updatedAt),
    };
  }

  factory FNoseSettingsModel.fromMap(Map<String, dynamic> map) {
    return FNoseSettingsModel(
      userId: map['userId'] as String,
      gameMode: map['gameMode'] as String,
      showInfoVideo: map['showInfoVideo'] as bool,
      totalTime: map['totalTime'] as int,
      targetSize: (map['targetSize'] as num).toDouble(),
      updatedAt: (map['updatedAt'] as Timestamp).toDate(),
    );
  }

  FNoseSettingsModel copyWith({
    String? gameMode,
    bool? showInfoVideo,
    int? totalTime,
    double? targetSize,
    DateTime? updatedAt,
  }) {
    return FNoseSettingsModel(
      userId: userId,
      gameMode: gameMode ?? this.gameMode,
      showInfoVideo: showInfoVideo ?? this.showInfoVideo,
      totalTime: totalTime ?? this.totalTime,
      targetSize: targetSize ?? this.targetSize,
      updatedAt: updatedAt ?? DateTime.now(),
    );
  }
}
