import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:msupperlimbs/features/fnose/data/models/fnose_match_model.dart';

class FNoseMatchRepository {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// Builds the Firestore document path for a specific match
  /// Path: users/{userId}/sessions/{sessionId}/fnose_matches/{matchId}
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
        .collection('fnose_matches')
        .doc(matchId);
  }

  /// Creates a new FNose match document with full data (no merge)
  Future<void> createMatch(FNoseMatchModel match) async {
    final docRef = _matchDocRef(match.userId, match.sessionId, match.matchId);
    await docRef.set(match.toMap(), SetOptions(merge: false));
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

  /// Salva dados brutos de pose (como JSON) sob o documento do match, permitindo múltiplos chunks
  /// Path: .../fnose_matches/{matchId}/pose_data/{chunkId}
  Future<void> savePoseData(
    String userId,
    String sessionId,
    String matchId,
    String poseDataJson,
    String chunkId, // novo parâmetro
  ) async {
    final subdocRef = _matchDocRef(userId, sessionId, matchId)
        .collection('pose_data')
        .doc(chunkId);

    await subdocRef.set({
      'json': poseDataJson,
      'createdAt': FieldValue.serverTimestamp(),
    });
  }

  /// Saves raw touch data (as JSON) under the match document
  /// Path: .../fnose_matches/{matchId}/touch_data/raw
  Future<void> saveTouchData(
    String userId,
    String sessionId,
    String matchId,
    String touchDataJson,
  ) async {
    final subdocRef = _matchDocRef(userId, sessionId, matchId)
        .collection('touch_data')
        .doc('raw');

    await subdocRef.set({
      'json': touchDataJson,
      'createdAt': FieldValue.serverTimestamp(),
    });
  }
}
