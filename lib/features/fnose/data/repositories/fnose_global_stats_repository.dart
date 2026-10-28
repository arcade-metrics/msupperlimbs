import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:msupperlimbs/features/fnose/data/models/fnose_global_stats_model.dart';
import 'package:msupperlimbs/features/fnose/data/models/fnose_match_stats_model.dart';

class FNoseGlobalStatsRepository {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Get global stats
  Future<FNoseGlobalStatsModel?> getGlobalStats() async {
    try {
      final doc = await _firestore
          .collection('games')
          .doc('fnose')
          .collection('global_stats')
          .doc('stats')
          .get();

      if (doc.exists) {
        return FNoseGlobalStatsModel.fromMap(doc.data()!);
      }
      return null;
    } catch (e) {
      print('[ERROR] getGlobalStats failed: $e');
      rethrow;
    }
  }

  // Save global stats
  Future<void> saveGlobalStats(FNoseGlobalStatsModel stats) async {
    try {
      await _firestore
          .collection('games')
          .doc('fnose')
          .collection('global_stats')
          .doc('stats')
          .set(stats.toMap());
    } catch (e) {
      print('[ERROR] saveGlobalStats failed: $e');
      rethrow;
    }
  }

  // Add match stats to recent matches
  Future<void> addMatchStats(FNoseMatchStatsModel matchStats) async {
    try {
      await _firestore
          .collection('games')
          .doc('fnose')
          .collection('recent_matches')
          .doc(matchStats.matchId)
          .set(matchStats.toMap());
    } catch (e) {
      print('[ERROR] addMatchStats failed: $e');
      rethrow;
    }
  }

  // Get recent matches (limited to 100)
  Future<List<FNoseMatchStatsModel>> getRecentMatches() async {
    try {
      final querySnapshot = await _firestore
          .collection('games')
          .doc('fnose')
          .collection('recent_matches')
          .orderBy('timestamp', descending: true)
          .limit(100)
          .get();

      return querySnapshot.docs
          .map((doc) => FNoseMatchStatsModel.fromMap(doc.data()))
          .toList();
    } catch (e) {
      print('[ERROR] getRecentMatches failed: $e');
      rethrow;
    }
  }

  // Remove oldest match if we have more than 100
  Future<void> cleanupOldMatches() async {
    try {
      final querySnapshot = await _firestore
          .collection('games')
          .doc('fnose')
          .collection('recent_matches')
          .orderBy('timestamp', descending: false)
          .get();

      if (querySnapshot.docs.length > 100) {
        final docsToDelete = querySnapshot.docs
            .take(querySnapshot.docs.length - 100)
            .toList();

        final batch = _firestore.batch();
        for (final doc in docsToDelete) {
          batch.delete(doc.reference);
        }
        await batch.commit();
      }
    } catch (e) {
      print('[ERROR] cleanupOldMatches failed: $e');
      rethrow;
    }
  }

  // Get user stats
  Future<FNoseGlobalStatsModel?> getUserStats(String userId) async {
    try {
      final doc = await _firestore
          .collection('games')
          .doc('fnose')
          .collection('user_stats')
          .doc(userId)
          .get();

      if (doc.exists) {
        return FNoseGlobalStatsModel.fromMap(doc.data()!);
      }
      return null;
    } catch (e) {
      print('[ERROR] getUserStats failed: $e');
      rethrow;
    }
  }

  // Save user stats
  Future<void> saveUserStats(String userId, FNoseGlobalStatsModel stats) async {
    try {
      await _firestore
          .collection('games')
          .doc('fnose')
          .collection('user_stats')
          .doc(userId)
          .set(stats.toMap());
    } catch (e) {
      print('[ERROR] saveUserStats failed: $e');
      rethrow;
    }
  }
} 