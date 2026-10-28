import 'package:cloud_firestore/cloud_firestore.dart';

class FNoseMatchStatsModel {
  final String matchId;
  final String userId;
  final DateTime timestamp;
  final double avgTouchTime;
  final double avgDistance;
  final double avgAngle;
  final double timeCV;
  final double distanceCV;
  final double angleCV;
  final double precisionIndex;
  final double consistencyIndex;

  FNoseMatchStatsModel({
    required this.matchId,
    required this.userId,
    required this.timestamp,
    required this.avgTouchTime,
    required this.avgDistance,
    required this.avgAngle,
    required this.timeCV,
    required this.distanceCV,
    required this.angleCV,
    required this.precisionIndex,
    required this.consistencyIndex,
  });

  Map<String, dynamic> toMap() {
    return {
      'matchId': matchId,
      'userId': userId,
      'timestamp': Timestamp.fromDate(timestamp),
      'avgTouchTime': avgTouchTime,
      'avgDistance': avgDistance,
      'avgAngle': avgAngle,
      'timeCV': timeCV,
      'distanceCV': distanceCV,
      'angleCV': angleCV,
      'precisionIndex': precisionIndex,
      'consistencyIndex': consistencyIndex,
    };
  }

  factory FNoseMatchStatsModel.fromMap(Map<String, dynamic> map) {
    return FNoseMatchStatsModel(
      matchId: map['matchId'] ?? '',
      userId: map['userId'] ?? '',
      timestamp: (map['timestamp'] as Timestamp).toDate(),
      avgTouchTime: (map['avgTouchTime'] as num?)?.toDouble() ?? 0.0,
      avgDistance: (map['avgDistance'] as num?)?.toDouble() ?? 0.0,
      avgAngle: (map['avgAngle'] as num?)?.toDouble() ?? 0.0,
      timeCV: (map['timeCV'] as num?)?.toDouble() ?? 0.0,
      distanceCV: (map['distanceCV'] as num?)?.toDouble() ?? 0.0,
      angleCV: (map['angleCV'] as num?)?.toDouble() ?? 0.0,
      precisionIndex: (map['precisionIndex'] as num?)?.toDouble() ?? 0.0,
      consistencyIndex: (map['consistencyIndex'] as num?)?.toDouble() ?? 0.0,
    );
  }

  FNoseMatchStatsModel copyWith({
    String? matchId,
    String? userId,
    DateTime? timestamp,
    double? avgTouchTime,
    double? avgDistance,
    double? avgAngle,
    double? timeCV,
    double? distanceCV,
    double? angleCV,
    double? precisionIndex,
    double? consistencyIndex,
  }) {
    return FNoseMatchStatsModel(
      matchId: matchId ?? this.matchId,
      userId: userId ?? this.userId,
      timestamp: timestamp ?? this.timestamp,
      avgTouchTime: avgTouchTime ?? this.avgTouchTime,
      avgDistance: avgDistance ?? this.avgDistance,
      avgAngle: avgAngle ?? this.avgAngle,
      timeCV: timeCV ?? this.timeCV,
      distanceCV: distanceCV ?? this.distanceCV,
      angleCV: angleCV ?? this.angleCV,
      precisionIndex: precisionIndex ?? this.precisionIndex,
      consistencyIndex: consistencyIndex ?? this.consistencyIndex,
    );
  }
} 