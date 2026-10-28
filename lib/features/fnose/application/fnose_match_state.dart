import 'dart:convert';
import 'dart:ui';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:msupperlimbs/features/fnose/application/fnose_match_service_provider.dart';
import 'package:msupperlimbs/features/fnose/application/fnose_global_stats_provider.dart';
import 'package:msupperlimbs/features/fnose/data/models/enums/fnose_game_mode_enum.dart';
import 'package:msupperlimbs/features/fnose/data/models/fnose_match_model.dart';
import 'package:msupperlimbs/features/fnose/data/models/fnose_adv_settings_model.dart';
import 'package:msupperlimbs/features/fnose/domain/fnose_match_service.dart';
import 'package:msupperlimbs/features/fnose/motion/utils/stats_calculator_utils.dart';
import 'package:msupperlimbs/features/fnose/motion/utils/touch_logger_utils.dart';
import 'package:msupperlimbs/core/domain/device_info_service.dart';
import 'package:msupperlimbs/features/fnose/presentation/widgets/fnose_saving_overlay.dart';

class FNoseMatchNotifier extends StateNotifier<FNoseMatchModel?> {
  final FNoseMatchService _matchService;
  final FNoseGlobalStatsService _globalStatsService;

  FNoseMatchNotifier(this._matchService, this._globalStatsService)
      : super(null);

  Future<void> startMatch({
    required String userId,
    required String sessionId,
    required FNoseGameMode gameMode,
    required int totalTime,
    required int imageWidth,
    required int imageHeight,
    required int screenWidth,
    required int screenHeight,
    FNoseAdvSettingsModel? advSettings,
  }) async {
    final match = await _matchService.startMatch(
      userId: userId,
      sessionId: sessionId,
      totalTime: totalTime,
      gameMode: gameMode,
      imageWidth: imageWidth,
      imageHeight: imageHeight,
      screenWidth: screenWidth,
      screenHeight: screenHeight,
      advSettings: advSettings,
    );
    state = match;
  }

  Future<void> finalizeMatch({
    required List<Map<String, dynamic>> poseLog,
    required List<Map<String, dynamic>> touchLogs,
    required int leftCount,
    required int rightCount,
    required Offset calibrationOffset,
    Function(SavingPhase phase, double progress)? onProgress,
  }) async {
    if (state == null) return;

    final offsetMap = {
      'dx': calibrationOffset.dx,
      'dy': calibrationOffset.dy,
    };

    try {
      final updated = state!.copyWith(
        totalLeftSparks: leftCount,
        totalRightSparks: rightCount,
        totalSparks: leftCount + rightCount,
        targetCalibrationOffset: offsetMap,
      );

      final match = state!;
      // --- NOVO: Dividir poseLog em chunks de até 15 segundos (ou N poses por chunk) ---
      const int chunkDurationMs = 15000; // 15 segundos
      List<List<Map<String, dynamic>>> poseChunks = [];
      if (poseLog.isNotEmpty && poseLog.first.containsKey('timestamp')) {
        int chunkStart = poseLog.first['timestamp'] ?? 0;
        List<Map<String, dynamic>> currentChunk = [];
        for (final pose in poseLog) {
          int ts = pose['timestamp'] ?? 0;
          if (ts - chunkStart >= chunkDurationMs && currentChunk.isNotEmpty) {
            poseChunks.add(currentChunk);
            currentChunk = [];
            chunkStart = ts;
          }
          currentChunk.add(pose);
        }
        if (currentChunk.isNotEmpty) poseChunks.add(currentChunk);
      } else {
        // fallback: dividir em chunks de 500 poses
        const int chunkSize = 500;
        for (int i = 0; i < poseLog.length; i += chunkSize) {
          poseChunks.add(poseLog.sublist(i, (i + chunkSize).clamp(0, poseLog.length)));
        }
      }

      // --- Salvar cada chunk separadamente ---
      debugPrint('[DEBUG] Pose data chunks: ${poseChunks.length}');
      for (int i = 0; i < poseChunks.length; i++) {
        debugPrint('[DEBUG] - Chunk $i: ${poseChunks[i].length} frames');
      }
      
      onProgress?.call(SavingPhase.savingPoseData, 0.0);
      for (int i = 0; i < poseChunks.length; i++) {
        final chunk = poseChunks[i];
        final chunkJson = jsonEncode({'pose_data': chunk});
        final chunkId = 'chunk_$i';
        debugPrint('[DEBUG] Saving chunk $chunkId (${chunk.length} frames, JSON size: ${chunkJson.length} bytes)');
        await _matchService.savePoseData(match, chunkJson, chunkId);
        debugPrint('[DEBUG] Chunk $chunkId saved successfully');
        onProgress?.call(SavingPhase.savingPoseData, (i + 1) / poseChunks.length);
      }
      onProgress?.call(SavingPhase.savingPoseData, 1.0);

      // --- Touch data permanece igual ---
      final touchJson = jsonEncode({'touch_data': touchLogs});
      onProgress?.call(SavingPhase.savingTouchData, 0.0);
      await _matchService.saveTouchData(match, touchJson);
      onProgress?.call(SavingPhase.savingTouchData, 1.0);

      // --- Estatísticas e atualização do match ---
      onProgress?.call(SavingPhase.calculatingStats, 0.0);
      final matchStats = await _calculateMatchStats(touchLogs, match);
      onProgress?.call(SavingPhase.calculatingStats, 1.0);

      onProgress?.call(SavingPhase.updatingMatch, 0.0);
      final updatedWithStats = updated.copyWith(
        avgTouchTime: matchStats['avgTouchTime'] as double?,
        avgDistance: matchStats['avgDistance'] as double?,
        avgAngle: matchStats['avgAngle'] as double?,
        timeCV: matchStats['timeCV'] as double?,
        distanceCV: matchStats['distanceCV'] as double?,
        angleCV: matchStats['angleCV'] as double?,
        precisionIndex: matchStats['precisionIndex'] as double?,
        consistencyIndex: matchStats['consistencyIndex'] as double?,
        isValidMatch: matchStats['isValidMatch'] as bool?,
        minTouchesRequired: matchStats['minTouchesRequired'] as int?,
        minTimeRequired: matchStats['minTimeRequired'] as int?,
      );

      debugPrint('[MATCH] Calling updateMatch...');
      await _matchService.updateMatch(updatedWithStats);
      state = updatedWithStats;
      onProgress?.call(SavingPhase.updatingMatch, 1.0);

      // --- Atualização de global stats permanece igual ---
      onProgress?.call(SavingPhase.updatingGlobalStats, 0.0);
      try {
        final touchLogsList =
            touchLogs.map((log) => TouchLog.fromMap(log)).toList();
        await _globalStatsService.updateGlobalStats(
          touchLogs: touchLogsList,
          matchId: match.matchId,
          userId: match.userId,
          timestamp: DateTime.now(),
        );
        debugPrint('[MATCH] Global stats updated successfully');
        onProgress?.call(SavingPhase.updatingGlobalStats, 1.0);
      } catch (e) {
        debugPrint('[ERROR] Failed to update global stats: $e');
        onProgress?.call(SavingPhase.updatingGlobalStats, 1.0);
      }
    } catch (e, stack) {
      debugPrint('[ERROR] finalizeMatch: $e');
      debugPrint(stack.toString());
      rethrow;
    }
  }

  FNoseMatchModel? getCurrentMatch() => state;

  /// Calculate comprehensive match statistics
  Future<Map<String, dynamic>> _calculateMatchStats(
    List<Map<String, dynamic>> touchLogs,
    FNoseMatchModel match,
  ) async {
    try {
      // Convert touch logs to TouchLog objects
      final touchLogsList =
          touchLogs.map((log) => TouchLog.fromMap(log)).toList();

      // Calculate basic stats using existing calculator
      final basicStats = StatsCalculator.calculateMatchStats(
        touchLogs: touchLogsList,
        matchId: match.matchId,
        userId: match.userId,
        timestamp: DateTime.now(),
      );

      // Validation criteria
      const minTouchesRequired = 5;
      const minTimeRequired = 10; // seconds
      final isValidMatch = touchLogsList.length >= minTouchesRequired &&
          match.totalTime >= minTimeRequired;

      return {
        'avgTouchTime': basicStats.avgTouchTime,
        'avgDistance': basicStats.avgDistance,
        'avgAngle': basicStats.avgAngle,
        'timeCV': basicStats.timeCV,
        'distanceCV': basicStats.distanceCV,
        'angleCV': basicStats.angleCV,
        'precisionIndex': basicStats.precisionIndex,
        'consistencyIndex': basicStats.consistencyIndex,
        'isValidMatch': isValidMatch,
        'minTouchesRequired': minTouchesRequired,
        'minTimeRequired': minTimeRequired,
      };
    } catch (e) {
      debugPrint('[ERROR] Failed to calculate match stats: $e');
      // Return default values on error
      return {
        'avgTouchTime': 0.0,
        'avgDistance': 0.0,
        'avgAngle': 0.0,
        'timeCV': 0.0,
        'distanceCV': 0.0,
        'angleCV': 0.0,
        'precisionIndex': 0.0,
        'consistencyIndex': 0.0,
        'isValidMatch': false,
        'minTouchesRequired': 5,
        'minTimeRequired': 10,
      };
    }
  }
}

final fnoseMatchStateProvider =
    StateNotifierProvider<FNoseMatchNotifier, FNoseMatchModel?>((ref) {
  return FNoseMatchNotifier(
    ref.read(fnoseMatchServiceProvider),
    ref.read(fnoseGlobalStatsServiceProvider),
  );
});
