import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:msupperlimbs/features/fnose/data/models/fnose_settings_model.dart';

class FNoseSettingsRepository {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Future<FNoseSettingsModel?> getFNoseSettings(String userId) async {
    final docRef = _firestore
        .collection('users')
        .doc(userId)
        .collection('settings')
        .doc('fnoseSettings');

    final snapshot = await docRef.get();

    if (snapshot.exists) {
      return FNoseSettingsModel.fromMap(snapshot.data()!);
    }
    return null;
  }

  Future<void> saveFNoseSettings(
      String userId, FNoseSettingsModel settings) async {
    final docRef = _firestore
        .collection('users')
        .doc(userId)
        .collection('settings')
        .doc('fnoseSettings');

    await docRef.set(settings.toMap(), SetOptions(merge: true));
  }
}
