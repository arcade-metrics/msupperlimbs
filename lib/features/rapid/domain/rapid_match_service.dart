import 'package:flutter/foundation.dart';
import 'package:intl/intl.dart';
import 'package:msupperlimbs/features/rapid/data/models/rapid_match_model.dart';
import 'package:msupperlimbs/features/rapid/data/repositories/rapid_match_repository.dart';

class RapidMatchService {
  final RapidMatchRepository _rapidMatchRepository;

  RapidMatchService(this._rapidMatchRepository);

  // Generates a unique match ID using UTC timestamp
  String _generateMatchId(DateTime now) {
    return 'rapid_${DateFormat('yyyyMMdd_HHmmss').format(now)}_${now.millisecondsSinceEpoch}';
  }

  // Starts a new Rapid match session and stores it in Firestore
  Future<RapidMatchModel> startMatch({
    required String userId,
    required String sessionId,
    required int totalTime,
    required String gameMode,
    required int imageWidth,
    required int imageHeight,
    required int screenWidth,
    required int screenHeight,
    String? selectedHand,
    String? visualizationType,
    Map<String, dynamic>? settingsData,
  }) async {
    final now = DateTime.now().toUtc();
    final matchId = _generateMatchId(now);

    final match = RapidMatchModel(
      matchId: matchId,
      userId: userId,
      sessionId: sessionId,
      totalTime: totalTime,
      gameMode: gameMode,
      createdAt: now,
      imageWidth: imageWidth,
      imageHeight: imageHeight,
      screenWidth: screenWidth,
      screenHeight: screenHeight,
      selectedHand: selectedHand,
      visualizationType: visualizationType,
      settingsData: settingsData,
    );

    debugPrint('[RAPID SERVICE] Starting match creation for user: $userId, session: $sessionId');
    await _rapidMatchRepository.createMatch(match);
    debugPrint('[RAPID SERVICE] Match created successfully: ${match.matchId}');
    return match;
  }

  // Updates match with additional data
  Future<void> updateMatchFields({
    required String userId,
    required String sessionId,
    required String matchId,
    required Map<String, dynamic> fieldsToUpdate,
  }) async {
    await _rapidMatchRepository.updateMatchFields(
      userId: userId,
      sessionId: sessionId,
      matchId: matchId,
      fieldsToUpdate: fieldsToUpdate,
    );
  }

  // Saves pose data for the match
  Future<void> savePoseData({
    required String userId,
    required String sessionId,
    required String matchId,
    required String poseDataJson,
    required String chunkId,
  }) async {
    await _rapidMatchRepository.savePoseData(
      userId,
      sessionId,
      matchId,
      poseDataJson,
      chunkId,
    );
  }
  
  // Saves additional data for the match (like tap count, etc.)
  Future<void> saveAdditionalData({
    required String userId,
    required String sessionId,
    required String matchId,
    required Map<String, dynamic> additionalData,
  }) async {
    await updateMatchFields(
      userId: userId,
      sessionId: sessionId,
      matchId: matchId,
      fieldsToUpdate: {
        'additionalData': additionalData,
        'updatedAt': DateTime.now().toUtc(),
      },
    );
  }

  // Updates match with all calculated fields including statistics
  Future<void> updateMatch(RapidMatchModel match) async {
    try {
      await _rapidMatchRepository.updateMatchFields(
        userId: match.userId,
        sessionId: match.sessionId,
        matchId: match.matchId,
        fieldsToUpdate: {
          'tapCount': match.tapCount,
          'avgTapFrequency': match.avgTapFrequency,
          'maxTapFrequency': match.maxTapFrequency,
          'minTapFrequency': match.minTapFrequency,
          'tapFrequencyCV': match.tapFrequencyCV,
          'avgPulseHeight': match.avgPulseHeight,
          'maxPulseHeight': match.maxPulseHeight,
          'timeInActiveState': match.timeInActiveState,
          'timeInIdleState': match.timeInIdleState,
          'timeInUnstableState': match.timeInUnstableState,
          'timeInFlatlineState': match.timeInFlatlineState,
          'isValidMatch': match.isValidMatch,
          'minTapsRequired': match.minTapsRequired,
          'minTimeRequired': match.minTimeRequired,
        },
      );
      debugPrint('[SERVICE] Rapid match updated successfully');
    } catch (e, stack) {
      debugPrint('[ERROR] updateMatch failed: $e');
      debugPrint(stack.toString());
      rethrow;
    }
  }

  // Saves tap data chunk for the match
  Future<void> saveTapDataChunk(RapidMatchModel match, String tapJson, String chunkId) {
    return _rapidMatchRepository.saveTapDataChunk(
      match.userId,
      match.sessionId,
      match.matchId,
      tapJson,
      chunkId,
    );
  }

  // Saves pulse state data chunk for the match
  Future<void> savePulseStateDataChunk(RapidMatchModel match, String pulseStateJson, String chunkId) {
    return _rapidMatchRepository.savePulseStateDataChunk(
      match.userId,
      match.sessionId,
      match.matchId,
      pulseStateJson,
      chunkId,
    );
  }
}
