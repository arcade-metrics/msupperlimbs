import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:msupperlimbs/features/fnose/data/models/touch_data_param_model.dart';
import 'package:msupperlimbs/features/fnose/motion/utils/touch_logger_utils.dart';

final touchDataProvider =
    FutureProvider.family<List<TouchLog>, TouchDataParams>((ref, params) async {
  final doc = await FirebaseFirestore.instance
      .collection('users')
      .doc(params.userId)
      .collection('sessions')
      .doc(params.sessionId)
      .collection('fnose_matches')
      .doc(params.matchId)
      .collection('touch_data')
      .doc('raw')
      .get();

  final data = doc.data();
  if (data == null || data['json'] == null) return [];

  final jsonList = jsonDecode(data['json'])['touch_data'] as List;
  return jsonList.map((e) => TouchLog.fromMap(e)).toList();
});
