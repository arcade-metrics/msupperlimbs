import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:msupperlimbs/features/fnose/data/models/fnose_adv_settings_model.dart';

class FNoseAdvSettingsRepository {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Future<FNoseAdvSettingsModel?> getFNoseAdvSettings(String userId) async {
    final docRef = _firestore
        .collection('users')
        .doc(userId)
        .collection('settings')
        .doc('fnoseAdvSettings');

    final snapshot = await docRef.get();

    if (snapshot.exists) {
      return FNoseAdvSettingsModel.fromMap(snapshot.data()!);
    }
    return null;
  }

  Future<void> saveFNoseAdvSettings(
      String userId, FNoseAdvSettingsModel settings) async {
    final docRef = _firestore
        .collection('users')
        .doc(userId)
        .collection('settings')
        .doc('fnoseAdvSettings');

    await docRef.set(settings.toMap(), SetOptions(merge: true));
  }
}
