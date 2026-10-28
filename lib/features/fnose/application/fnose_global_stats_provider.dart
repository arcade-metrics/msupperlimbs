import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:msupperlimbs/features/fnose/data/models/fnose_global_stats_model.dart';
import 'package:msupperlimbs/features/fnose/data/models/fnose_match_stats_model.dart';
import 'package:msupperlimbs/features/fnose/data/repositories/fnose_global_stats_repository.dart';
import 'package:msupperlimbs/features/fnose/motion/utils/stats_calculator_utils.dart';
import 'package:msupperlimbs/features/fnose/motion/utils/touch_logger_utils.dart';

// Repository provider
final fnoseGlobalStatsRepositoryProvider = Provider<FNoseGlobalStatsRepository>((ref) {
  return FNoseGlobalStatsRepository();
});

// Global stats provider
final fnoseGlobalStatsProvider = FutureProvider<FNoseGlobalStatsModel?>((ref) async {
  final repository = ref.read(fnoseGlobalStatsRepositoryProvider);
  return await repository.getGlobalStats();
});

// Recent matches provider
final fnoseRecentMatchesProvider = FutureProvider<List<FNoseMatchStatsModel>>((ref) async {
  final repository = ref.read(fnoseGlobalStatsRepositoryProvider);
  return await repository.getRecentMatches();
});

// User stats provider
final fnoseUserStatsProvider = FutureProvider.family<FNoseGlobalStatsModel?, String>((ref, userId) async {
  final repository = ref.read(fnoseGlobalStatsRepositoryProvider);
  return await repository.getUserStats(userId);
});

// User recent matches provider (last 5 matches)
final fnoseUserRecentMatchesProvider = FutureProvider.family<List<FNoseMatchStatsModel>, String>((ref, userId) async {
  final repository = ref.read(fnoseGlobalStatsRepositoryProvider);
  final allMatches = await repository.getRecentMatches();
  final userMatches = allMatches.where((match) => match.userId == userId).toList();
  // Sort by timestamp descending and take last 5
  userMatches.sort((a, b) => b.timestamp.compareTo(a.timestamp));
  return userMatches.take(5).toList();
});

// Service provider for updating stats
final fnoseGlobalStatsServiceProvider = Provider<FNoseGlobalStatsService>((ref) {
  final repository = ref.read(fnoseGlobalStatsRepositoryProvider);
  return FNoseGlobalStatsService(repository);
});

class FNoseGlobalStatsService {
  final FNoseGlobalStatsRepository _repository;

  FNoseGlobalStatsService(this._repository);

  /// Update global stats with a new match
  Future<void> updateGlobalStats({
    required List<TouchLog> touchLogs,
    required String matchId,
    required String userId,
    required DateTime timestamp,
  }) async {
    try {
      // Calculate match stats
      final matchStats = StatsCalculator.calculateMatchStats(
        touchLogs: touchLogs,
        matchId: matchId,
        userId: userId,
        timestamp: timestamp,
      );

      // Add match to recent matches
      await _repository.addMatchStats(matchStats);

      // Clean up old matches if needed
      await _repository.cleanupOldMatches();

      // Get updated recent matches
      final recentMatches = await _repository.getRecentMatches();

      // Get current global stats
      final currentGlobalStats = await _repository.getGlobalStats();
      final totalMatches = (currentGlobalStats?.totalMatches ?? 0) + 1;

      // Calculate new global stats
      final newGlobalStats = StatsCalculator.calculateGlobalStats(
        matchStats: recentMatches,
        totalMatches: totalMatches,
        lastMatchId: matchId,
      );

      // Save updated global stats
      await _repository.saveGlobalStats(newGlobalStats);

      // Update user stats
      await _updateUserStats(userId, matchStats);

      print('[SUCCESS] Global stats updated for match: $matchId');
    } catch (e) {
      print('[ERROR] Failed to update global stats: $e');
      rethrow;
    }
  }

  /// Update user-specific stats
  Future<void> _updateUserStats(String userId, FNoseMatchStatsModel newMatchStats) async {
    try {
      // Get user's recent matches
      final recentMatches = await _repository.getRecentMatches();
      final userMatches = recentMatches.where((m) => m.userId == userId).toList();

      // Calculate user stats
      final userStats = StatsCalculator.calculateGlobalStats(
        matchStats: userMatches,
        totalMatches: userMatches.length,
        lastMatchId: newMatchStats.matchId,
      );

      // Save user stats
      await _repository.saveUserStats(userId, userStats);

      print('[SUCCESS] User stats updated for user: $userId');
    } catch (e) {
      print('[ERROR] Failed to update user stats: $e');
      // Don't rethrow - user stats failure shouldn't break global stats
    }
  }

  /// Refresh global stats (useful for testing)
  Future<void> refreshGlobalStats() async {
    try {
      final recentMatches = await _repository.getRecentMatches();
      final currentGlobalStats = await _repository.getGlobalStats();
      
      if (recentMatches.isNotEmpty) {
        final newGlobalStats = StatsCalculator.calculateGlobalStats(
          matchStats: recentMatches,
          totalMatches: currentGlobalStats?.totalMatches ?? recentMatches.length,
          lastMatchId: recentMatches.first.matchId,
        );

        await _repository.saveGlobalStats(newGlobalStats);
        print('[SUCCESS] Global stats refreshed');
      }
    } catch (e) {
      print('[ERROR] Failed to refresh global stats: $e');
      rethrow;
    }
  }
} 