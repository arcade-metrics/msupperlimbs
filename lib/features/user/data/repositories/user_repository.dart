import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:msupperlimbs/features/user/domain/entities/user.dart';

class UserRepository {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Future<UserModel?> getUser(String uid) async {
    final doc = await _firestore.collection('users').doc(uid).get();
    if (doc.exists) {
      return UserModel.fromMap(doc.data()!);
    }
    return null;
  }

  Future<bool> userExists(String uid) async {
    final doc = await _firestore.collection('users').doc(uid).get();
    return doc.exists;
  }

  Future<void> createUser(UserModel user) async {
    final userMap = user.toMap();
    await _firestore.collection('users').doc(user.uid).set(userMap);
  }

  Future<void> updateLastAccess(String uid) async {
    await _firestore.collection('users').doc(uid).update({
      'lastAccess': DateTime.now().toUtc().toIso8601String(),
    });
  }

  Future<void> updateUser(UserModel user) async {
    final userMap = user.toMap();
    await _firestore.collection('users').doc(user.uid).set(userMap);
  }
}
