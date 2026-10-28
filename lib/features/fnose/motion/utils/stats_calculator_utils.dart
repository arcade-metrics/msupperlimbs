import 'dart:math';
import 'package:msupperlimbs/features/fnose/data/models/fnose_global_stats_model.dart';
import 'package:msupperlimbs/features/fnose/data/models/fnose_match_stats_model.dart';
import 'package:msupperlimbs/features/fnose/motion/utils/touch_logger_utils.dart';

class StatsCalculator {
  /// Calculate statistics for a single match from touch logs
  static FNoseMatchStatsModel calculateMatchStats({
    required List<TouchLog> touchLogs,
    required String matchId,
    required String userId,
    required DateTime timestamp,
  }) {
    if (touchLogs.length < 2) {
      // Return default stats for invalid matches
      return FNoseMatchStatsModel(
        matchId: matchId,
        userId: userId,
        timestamp: timestamp,
        avgTouchTime: 0.0,
        avgDistance: 0.0,
        avgAngle: 0.0,
        timeCV: 0.0,
        distanceCV: 0.0,
        angleCV: 0.0,
        precisionIndex: 0.0,
        consistencyIndex: 0.0,
      );
    }

    // Sort by timestamp
    final sortedTouches = [...touchLogs]
      ..sort((a, b) => a.timestamp.compareTo(b.timestamp));

    // Calculate time intervals between consecutive touches
    final timeIntervals = <int>[];
    for (int i = 1; i < sortedTouches.length; i++) {
      timeIntervals.add(sortedTouches[i].timestamp - sortedTouches[i - 1].timestamp);
    }

    // Calculate distances and angles
    final distances = <double>[];
    final angles = <double>[];

    for (final touch in sortedTouches) {
      distances.add(touch.distanceToTarget);
      
      // Calculate angle between mark position and target center
      // Using the distance and position to calculate error angle
      final dx = touch.markPosition.x - touch.targetCenter.x;
      final dy = touch.markPosition.y - touch.targetCenter.y;
      final angle = atan2(dy, dx) * 180 / pi;
      angles.add(angle.abs()); // Use absolute value for error angle
    }

    // Calculate averages
    final avgTouchTime = timeIntervals.isNotEmpty 
        ? timeIntervals.reduce((a, b) => a + b) / timeIntervals.length / 1000.0 // Convert to seconds
        : 0.0;
    final avgDistance = distances.isNotEmpty 
        ? distances.reduce((a, b) => a + b) / distances.length
        : 0.0;
    final avgAngle = angles.isNotEmpty 
        ? angles.reduce((a, b) => a + b) / angles.length
        : 0.0;

    // Calculate standard deviations
    final timeStdDev = timeIntervals.isNotEmpty 
        ? _calculateStandardDeviation(timeIntervals.map((t) => t / 1000.0).toList())
        : 0.0;
    final distanceStdDev = distances.isNotEmpty 
        ? _calculateStandardDeviation(distances)
        : 0.0;
    final angleStdDev = angles.isNotEmpty 
        ? _calculateStandardDeviation(angles)
        : 0.0;

    // Calculate coefficients of variation (CV)
    final timeCV = avgTouchTime > 0 ? timeStdDev / avgTouchTime : 0.0;
    final distanceCV = avgDistance > 0 ? distanceStdDev / avgDistance : 0.0;
    final angleCV = avgAngle > 0 ? angleStdDev / avgAngle : 0.0;

    // Calculate composite indices
    final precisionIndex = (distanceCV + angleCV) > 0 
        ? 1.0 / (1.0 + distanceCV + angleCV)
        : 1.0; // Perfect precision if no variation
    final consistencyIndex = timeCV > 0 
        ? 1.0 / (1.0 + timeCV)
        : 1.0; // Perfect consistency if no variation

    return FNoseMatchStatsModel(
      matchId: matchId,
      userId: userId,
      timestamp: timestamp,
      avgTouchTime: avgTouchTime,
      avgDistance: avgDistance,
      avgAngle: avgAngle,
      timeCV: timeCV,
      distanceCV: distanceCV,
      angleCV: angleCV,
      precisionIndex: precisionIndex,
      consistencyIndex: consistencyIndex,
    );
  }

  /// Calculate global statistics from a list of match statistics
  static FNoseGlobalStatsModel calculateGlobalStats({
    required List<FNoseMatchStatsModel> matchStats,
    required int totalMatches,
    required String lastMatchId,
  }) {
    if (matchStats.isEmpty) {
      return FNoseGlobalStatsModel(
        totalMatches: totalMatches,
        validMatches: 0,
        avgTouchTime: 0.0,
        avgDistance: 0.0,
        avgAngle: 0.0,
        avgTimeCV: 0.0,
        avgDistanceCV: 0.0,
        avgAngleCV: 0.0,
        avgPrecisionIndex: 0.0,
        avgConsistencyIndex: 0.0,
        lastUpdated: DateTime.now(),
        lastMatchId: lastMatchId,
      );
    }

    // Calculate averages
    final avgTouchTime = matchStats.map((s) => s.avgTouchTime).reduce((a, b) => a + b) / matchStats.length;
    final avgDistance = matchStats.map((s) => s.avgDistance).reduce((a, b) => a + b) / matchStats.length;
    final avgAngle = matchStats.map((s) => s.avgAngle).reduce((a, b) => a + b) / matchStats.length;
    final avgTimeCV = matchStats.map((s) => s.timeCV).reduce((a, b) => a + b) / matchStats.length;
    final avgDistanceCV = matchStats.map((s) => s.distanceCV).reduce((a, b) => a + b) / matchStats.length;
    final avgAngleCV = matchStats.map((s) => s.angleCV).reduce((a, b) => a + b) / matchStats.length;
    final avgPrecisionIndex = matchStats.map((s) => s.precisionIndex).reduce((a, b) => a + b) / matchStats.length;
    final avgConsistencyIndex = matchStats.map((s) => s.consistencyIndex).reduce((a, b) => a + b) / matchStats.length;

    return FNoseGlobalStatsModel(
      totalMatches: totalMatches,
      validMatches: matchStats.length,
      avgTouchTime: avgTouchTime,
      avgDistance: avgDistance,
      avgAngle: avgAngle,
      avgTimeCV: avgTimeCV,
      avgDistanceCV: avgDistanceCV,
      avgAngleCV: avgAngleCV,
      avgPrecisionIndex: avgPrecisionIndex,
      avgConsistencyIndex: avgConsistencyIndex,
      lastUpdated: DateTime.now(),
      lastMatchId: lastMatchId,
    );
  }

  /// Calculate standard deviation
  static double _calculateStandardDeviation(List<double> values) {
    if (values.isEmpty) return 0.0;
    
    final mean = values.reduce((a, b) => a + b) / values.length;
    final squaredDifferences = values.map((value) => pow(value - mean, 2)).toList();
    final variance = squaredDifferences.reduce((a, b) => a + b) / values.length;
    
    return sqrt(variance);
  }
} 