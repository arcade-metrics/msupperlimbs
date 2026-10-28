import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:msupperlimbs/features/rapid/data/models/rapid_match_model.dart';

class RapidMatchRepository {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// Builds the Firestore document path for a specific match
  /// Path: users/{userId}/sessions/{sessionId}/rapid_matches/{matchId}
  DocumentReference<Map<String, dynamic>> _matchDocRef(
    String userId,
    String sessionId,
    String matchId,
  ) {
    return _firestore
        .collection('users')
        .doc(userId)
        .collection('sessions')
        .doc(sessionId)
        .collection('rapid_matches')
        .doc(matchId);
  }

  /// Creates a new Rapid match document with full data (no merge)
  Future<void> createMatch(RapidMatchModel match) async {
    try {
      final docRef = _matchDocRef(match.userId, match.sessionId, match.matchId);
      final data = match.toMap();
      debugPrint('[RAPID REPO] Creating match at path: users/${match.userId}/sessions/${match.sessionId}/rapid_matches/${match.matchId}');
      debugPrint('[RAPID REPO] Match data: $data');
      await docRef.set(data, SetOptions(merge: false));
      debugPrint('[RAPID REPO] Match created successfully');
    } catch (e, stack) {
      debugPrint('[ERROR] Failed to create rapid match: $e');
      debugPrint(stack.toString());
      rethrow;
    }
  }

  /// Updates specific fields of an existing match document
  Future<void> updateMatchFields({
    required String userId,
    required String sessionId,
    required String matchId,
    required Map<String, dynamic> fieldsToUpdate,
  }) async {
    final docRef = _matchDocRef(userId, sessionId, matchId);
    await docRef.update(fieldsToUpdate);
  }

  /// Saves raw pose data (as JSON) under the match document
  Future<void> savePoseData(
    String userId,
    String sessionId,
    String matchId,
    String poseDataJson,
    String chunkId,
  ) async {
    final subdocRef = _matchDocRef(userId, sessionId, matchId)
        .collection('pose_data')
        .doc(chunkId);

    await subdocRef.set({
      'json': poseDataJson,
      'createdAt': FieldValue.serverTimestamp(),
    });
  }

  /// Saves tap data chunk (as JSON) under the match document
  /// Path: .../rapid_matches/{matchId}/tap_data/{chunkId}
  Future<void> saveTapDataChunk(
    String userId,
    String sessionId,
    String matchId,
    String tapDataJson,
    String chunkId,
  ) async {
    final subdocRef = _matchDocRef(userId, sessionId, matchId)
        .collection('tap_data')
        .doc(chunkId);

    await subdocRef.set({
      'json': tapDataJson,
      'createdAt': FieldValue.serverTimestamp(),
    });
  }

  /// Saves pulse state data chunk (as JSON) under the match document
  /// Path: .../rapid_matches/{matchId}/pulse_state_data/{chunkId}
  Future<void> savePulseStateDataChunk(
    String userId,
    String sessionId,
    String matchId,
    String pulseStateDataJson,
    String chunkId,
  ) async {
    final subdocRef = _matchDocRef(userId, sessionId, matchId)
        .collection('pulse_state_data')
        .doc(chunkId);

    await subdocRef.set({
      'json': pulseStateDataJson,
      'createdAt': FieldValue.serverTimestamp(),
    });
  }
}
