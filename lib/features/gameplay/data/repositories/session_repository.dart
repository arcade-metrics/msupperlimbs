import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import '../models/session_model.dart';
import '../models/session_log_model.dart';

class SessionRepository {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Future<bool> sessionExists(String userId, String date) async {
    // date format: YYYYMMDD
    final sessionQuery = await _firestore
        .collection('sessions')
        .doc(userId)
        .collection('sessions')
        .where('date', isEqualTo: date)
        .get();

    return sessionQuery.docs.isNotEmpty;
  }

  Future<SessionModel?> getSession(String userId, String date) async {
    // date format: YYYYMMDD
    final querySnapshot = await _firestore
        .collection('users')
        .doc(userId)
        .collection('sessions')
        .where('date', isEqualTo: date)
        .limit(1)
        .get();

    if (querySnapshot.docs.isNotEmpty) {
      return SessionModel.fromMap(querySnapshot.docs.first.data());
    }
    return null;
  }

  Future<void> createSession(SessionModel session) async {
    await _firestore
        .collection('users')
        .doc(session.userId)
        .collection('sessions')
        .doc(session.sessionId)
        .set(session.toMap());
  }

  Future<void> addSessionLog(SessionLogModel log) async {
    await _firestore
        .collection('users')
        .doc(log.userId)
        .collection('sessions')
        .doc(log.sessionId)
        .collection('logs')
        .doc(log.logId)
        .set(log.toMap());
  }
}
