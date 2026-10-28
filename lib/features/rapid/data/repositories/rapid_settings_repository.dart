import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:msupperlimbs/features/rapid/data/models/rapid_settings_model.dart';

class RapidSettingsRepository {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Future<RapidSettingsModel?> getRapidSettings(String userId) async {
    final docRef = _firestore
        .collection('users')
        .doc(userId)
        .collection('settings')
        .doc('rapidSettings');

    final snapshot = await docRef.get();

    if (snapshot.exists) {
      return RapidSettingsModel.fromMap(snapshot.data()!);
    }
    return null;
  }

  Future<void> saveRapidSettings(
      String userId, RapidSettingsModel settings) async {
    final docRef = _firestore
        .collection('users')
        .doc(userId)
        .collection('settings')
        .doc('rapidSettings');

    await docRef.set(settings.toMap(), SetOptions(merge: true));
  }
}


