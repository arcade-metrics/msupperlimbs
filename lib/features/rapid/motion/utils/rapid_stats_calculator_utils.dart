import 'dart:math';
import 'package:msupperlimbs/features/rapid/data/models/rapid_match_model.dart';

class RapidStatsCalculator {
  /// Calculate comprehensive match statistics for rapid game
  static Map<String, dynamic> calculateMatchStats({
    required List<Map<String, dynamic>> tapLogs,
    required List<Map<String, dynamic>> pulseStateLogs,
    required RapidMatchModel match,
  }) {
    try {
      // Basic validation
      const minTapsRequired = 3;
      const minTimeRequired = 5; // seconds
      final isValidMatch = tapLogs.length >= minTapsRequired &&
          match.totalTime >= minTimeRequired;

      if (tapLogs.isEmpty) {
        return _getDefaultStats(minTapsRequired, minTimeRequired);
      }

      // Calculate tap frequency statistics
      final tapStats = _calculateTapFrequencyStats(tapLogs, match.totalTime);
      
      // Calculate pulse height statistics
      final pulseStats = _calculatePulseHeightStats(pulseStateLogs);
      
      // Calculate time in each state
      final stateTimings = _calculateStateTimings(pulseStateLogs);

      return {
        'tapCount': tapLogs.length,
        'avgTapFrequency': tapStats['avgFrequency'],
        'maxTapFrequency': tapStats['maxFrequency'],
        'minTapFrequency': tapStats['minFrequency'],
        'tapFrequencyCV': tapStats['frequencyCV'],
        'avgPulseHeight': pulseStats['avgHeight'],
        'maxPulseHeight': pulseStats['maxHeight'],
        'timeInActiveState': stateTimings['active'] ?? 0.0,
        'timeInIdleState': stateTimings['idle'] ?? 0.0,
        'timeInUnstableState': stateTimings['unstable'] ?? 0.0,
        'timeInFlatlineState': stateTimings['flatline'] ?? 0.0,
        'isValidMatch': isValidMatch,
        'minTapsRequired': minTapsRequired,
        'minTimeRequired': minTimeRequired,
      };
    } catch (e) {
      print('[ERROR] Failed to calculate rapid match stats: $e');
      return _getDefaultStats(3, 5);
    }
  }

  static Map<String, dynamic> _getDefaultStats(int minTaps, int minTime) {
    return {
      'tapCount': 0,
      'avgTapFrequency': 0.0,
      'maxTapFrequency': 0.0,
      'minTapFrequency': 0.0,
      'tapFrequencyCV': 0.0,
      'avgPulseHeight': 0.0,
      'maxPulseHeight': 0.0,
      'timeInActiveState': 0.0,
      'timeInIdleState': 0.0,
      'timeInUnstableState': 0.0,
      'timeInFlatlineState': 0.0,
      'isValidMatch': false,
      'minTapsRequired': minTaps,
      'minTimeRequired': minTime,
    };
  }

  static Map<String, double> _calculateTapFrequencyStats(
    List<Map<String, dynamic>> tapLogs, 
    int totalTime
  ) {
    if (tapLogs.isEmpty || totalTime <= 0) {
      return {
        'avgFrequency': 0.0,
        'maxFrequency': 0.0,
        'minFrequency': 0.0,
        'frequencyCV': 0.0,
      };
    }

    final tapCount = tapLogs.length;
    final avgFrequency = tapCount / totalTime;

    // Calculate frequency in time windows (e.g., per second)
    final frequencies = <double>[];
    final windowSize = 1000; // 1 second in milliseconds
    
    if (tapLogs.isNotEmpty) {
      final startTime = tapLogs.first['timestamp'] as int;
      final endTime = tapLogs.last['timestamp'] as int;
      final duration = endTime - startTime;
      
      if (duration > 0) {
        final numWindows = (duration / windowSize).ceil();
        
        for (int i = 0; i < numWindows; i++) {
          final windowStart = startTime + (i * windowSize);
          final windowEnd = windowStart + windowSize;
          
          final tapsInWindow = tapLogs.where((tap) {
            final timestamp = tap['timestamp'] as int;
            return timestamp >= windowStart && timestamp < windowEnd;
          }).length;
          
          frequencies.add(tapsInWindow.toDouble());
        }
      }
    }

    if (frequencies.isEmpty) {
      return {
        'avgFrequency': avgFrequency,
        'maxFrequency': avgFrequency,
        'minFrequency': avgFrequency,
        'frequencyCV': 0.0,
      };
    }

    final maxFrequency = frequencies.reduce(max);
    final minFrequency = frequencies.reduce(min);
    
    // Calculate coefficient of variation
    final mean = frequencies.reduce((a, b) => a + b) / frequencies.length;
    final variance = frequencies
        .map((f) => pow(f - mean, 2))
        .reduce((a, b) => a + b) / frequencies.length;
    final stdDev = sqrt(variance);
    final cv = mean > 0 ? stdDev / mean : 0.0;

    return {
      'avgFrequency': avgFrequency,
      'maxFrequency': maxFrequency,
      'minFrequency': minFrequency,
      'frequencyCV': cv,
    };
  }

  static Map<String, double> _calculatePulseHeightStats(
    List<Map<String, dynamic>> pulseStateLogs
  ) {
    if (pulseStateLogs.isEmpty) {
      return {
        'avgHeight': 0.0,
        'maxHeight': 0.0,
      };
    }

    final heights = pulseStateLogs
        .map((log) => (log['pulseHeight'] as num).toDouble())
        .toList();
    
    final avgHeight = heights.reduce((a, b) => a + b) / heights.length;
    final maxHeight = heights.reduce(max);

    return {
      'avgHeight': avgHeight,
      'maxHeight': maxHeight,
    };
  }

  static Map<String, double> _calculateStateTimings(
    List<Map<String, dynamic>> pulseStateLogs
  ) {
    final stateTimings = <String, double>{
      'idle': 0.0,
      'active': 0.0,
      'unstable': 0.0,
      'flatline': 0.0,
    };

    if (pulseStateLogs.length < 2) return stateTimings;

    for (int i = 1; i < pulseStateLogs.length; i++) {
      final currentLog = pulseStateLogs[i];
      final previousLog = pulseStateLogs[i - 1];
      
      final currentTime = currentLog['timestamp'] as int;
      final previousTime = previousLog['timestamp'] as int;
      final timeDiff = (currentTime - previousTime) / 1000.0; // Convert to seconds
      
      final state = previousLog['pulseState'] as String;
      stateTimings[state] = (stateTimings[state] ?? 0.0) + timeDiff;
    }

    return stateTimings;
  }
}
