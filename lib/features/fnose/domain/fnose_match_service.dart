import 'package:flutter/foundation.dart';
import 'package:intl/intl.dart';
import 'package:msupperlimbs/features/fnose/data/models/enums/fnose_game_mode_enum.dart';
import 'package:msupperlimbs/features/fnose/data/models/fnose_match_model.dart';
import 'package:msupperlimbs/features/fnose/data/models/fnose_adv_settings_model.dart';
import 'package:msupperlimbs/features/fnose/data/repositories/fnose_match_repository.dart';

class FNoseMatchService {
  final FNoseMatchRepository _fnoseMatchRepository;

  FNoseMatchService(this._fnoseMatchRepository);

  // Generates a unique match ID using UTC timestamp
  String _generateMatchId(DateTime now) {
    return 'fnose_${DateFormat('yyyyMMdd_HHmmss').format(now)}_${now.millisecondsSinceEpoch}';
  }

  // Starts a new FNose match session and stores it in Firestore
  Future<FNoseMatchModel> startMatch({
    required String userId,
    required String sessionId,
    required int totalTime,
    required FNoseGameMode gameMode,
    required int imageWidth,
    required int imageHeight,
    required int screenWidth,
    required int screenHeight,
    FNoseAdvSettingsModel? advSettings,
  }) async {
    final now = DateTime.now().toUtc();
    final matchId = _generateMatchId(now);

    // Convert advSettings to Map for JSON storage
    Map<String, dynamic>? advSettingsData;
    if (advSettings != null) {
      advSettingsData = advSettings.toMap();
    }

    final match = FNoseMatchModel(
      matchId: matchId,
      userId: userId,
      sessionId: sessionId,
      totalTime: totalTime,
      gameMode: gameMode.name,
      createdAt: now,
      imageWidth: imageWidth,
      imageHeight: imageHeight,
      screenWidth: screenWidth,
      screenHeight: screenHeight,
      advSettingsData: advSettingsData,
    );

    await _fnoseMatchRepository.createMatch(match);
    return match;
  }

  // Updates match with all calculated fields including statistics
  Future<void> updateMatch(FNoseMatchModel match) async {
    try {
      await _fnoseMatchRepository.updateMatchFields(
        userId: match.userId,
        sessionId: match.sessionId,
        matchId: match.matchId,
        fieldsToUpdate: {
          'totalLeftSparks': match.totalLeftSparks,
          'totalRightSparks': match.totalRightSparks,
          'totalSparks': match.totalSparks,
          'targetCalibrationOffset': match.targetCalibrationOffset,
          'avgTouchTime': match.avgTouchTime,
          'avgDistance': match.avgDistance,
          'avgAngle': match.avgAngle,
          'timeCV': match.timeCV,
          'distanceCV': match.distanceCV,
          'angleCV': match.angleCV,
          'precisionIndex': match.precisionIndex,
          'consistencyIndex': match.consistencyIndex,
          'isValidMatch': match.isValidMatch,
          'minTouchesRequired': match.minTouchesRequired,
          'minTimeRequired': match.minTimeRequired,
        },
      );
      debugPrint('[SERVICE] Match updated successfully');
    } catch (e, stack) {
      debugPrint('[ERROR] updateMatch failed: $e');
      debugPrint(stack.toString());
      rethrow;
    }
  }

  // Salva dados brutos de pose em um chunk específico
  Future<void> savePoseData(FNoseMatchModel match, String poseJson, String chunkId) {
    return _fnoseMatchRepository.savePoseData(
      match.userId,
      match.sessionId,
      match.matchId,
      poseJson,
      chunkId,
    );
  }

  // Saves raw touch data to the match's touch_data subcollection
  Future<void> saveTouchData(FNoseMatchModel match, String touchJson) {
    return _fnoseMatchRepository.saveTouchData(
      match.userId,
      match.sessionId,
      match.matchId,
      touchJson,
    );
  }
}
