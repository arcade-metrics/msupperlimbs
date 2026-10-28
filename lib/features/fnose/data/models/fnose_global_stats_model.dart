import 'package:cloud_firestore/cloud_firestore.dart';

class FNoseGlobalStatsModel {
  final int totalMatches;
  final int validMatches;
  final double avgTouchTime;
  final double avgDistance;
  final double avgAngle;
  final double avgTimeCV;
  final double avgDistanceCV;
  final double avgAngleCV;
  final double avgPrecisionIndex;
  final double avgConsistencyIndex;
  final DateTime lastUpdated;
  final String lastMatchId;

  FNoseGlobalStatsModel({
    required this.totalMatches,
    required this.validMatches,
    required this.avgTouchTime,
    required this.avgDistance,
    required this.avgAngle,
    required this.avgTimeCV,
    required this.avgDistanceCV,
    required this.avgAngleCV,
    required this.avgPrecisionIndex,
    required this.avgConsistencyIndex,
    required this.lastUpdated,
    required this.lastMatchId,
  });

  Map<String, dynamic> toMap() {
    return {
      'totalMatches': totalMatches,
      'validMatches': validMatches,
      'avgTouchTime': avgTouchTime,
      'avgDistance': avgDistance,
      'avgAngle': avgAngle,
      'avgTimeCV': avgTimeCV,
      'avgDistanceCV': avgDistanceCV,
      'avgAngleCV': avgAngleCV,
      'avgPrecisionIndex': avgPrecisionIndex,
      'avgConsistencyIndex': avgConsistencyIndex,
      'lastUpdated': Timestamp.fromDate(lastUpdated),
      'lastMatchId': lastMatchId,
    };
  }

  factory FNoseGlobalStatsModel.fromMap(Map<String, dynamic> map) {
    return FNoseGlobalStatsModel(
      totalMatches: map['totalMatches'] ?? 0,
      validMatches: map['validMatches'] ?? 0,
      avgTouchTime: (map['avgTouchTime'] as num?)?.toDouble() ?? 0.0,
      avgDistance: (map['avgDistance'] as num?)?.toDouble() ?? 0.0,
      avgAngle: (map['avgAngle'] as num?)?.toDouble() ?? 0.0,
      avgTimeCV: (map['avgTimeCV'] as num?)?.toDouble() ?? 0.0,
      avgDistanceCV: (map['avgDistanceCV'] as num?)?.toDouble() ?? 0.0,
      avgAngleCV: (map['avgAngleCV'] as num?)?.toDouble() ?? 0.0,
      avgPrecisionIndex: (map['avgPrecisionIndex'] as num?)?.toDouble() ?? 0.0,
      avgConsistencyIndex: (map['avgConsistencyIndex'] as num?)?.toDouble() ?? 0.0,
      lastUpdated: (map['lastUpdated'] as Timestamp).toDate(),
      lastMatchId: map['lastMatchId'] ?? '',
    );
  }

  FNoseGlobalStatsModel copyWith({
    int? totalMatches,
    int? validMatches,
    double? avgTouchTime,
    double? avgDistance,
    double? avgAngle,
    double? avgTimeCV,
    double? avgDistanceCV,
    double? avgAngleCV,
    double? avgPrecisionIndex,
    double? avgConsistencyIndex,
    DateTime? lastUpdated,
    String? lastMatchId,
  }) {
    return FNoseGlobalStatsModel(
      totalMatches: totalMatches ?? this.totalMatches,
      validMatches: validMatches ?? this.validMatches,
      avgTouchTime: avgTouchTime ?? this.avgTouchTime,
      avgDistance: avgDistance ?? this.avgDistance,
      avgAngle: avgAngle ?? this.avgAngle,
      avgTimeCV: avgTimeCV ?? this.avgTimeCV,
      avgDistanceCV: avgDistanceCV ?? this.avgDistanceCV,
      avgAngleCV: avgAngleCV ?? this.avgAngleCV,
      avgPrecisionIndex: avgPrecisionIndex ?? this.avgPrecisionIndex,
      avgConsistencyIndex: avgConsistencyIndex ?? this.avgConsistencyIndex,
      lastUpdated: lastUpdated ?? this.lastUpdated,
      lastMatchId: lastMatchId ?? this.lastMatchId,
    );
  }
} 