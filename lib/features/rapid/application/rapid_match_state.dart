import 'dart:convert';
import 'dart:ui';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:msupperlimbs/features/rapid/application/rapid_match_service_provider.dart';
import 'package:msupperlimbs/features/rapid/data/models/rapid_match_model.dart';
import 'package:msupperlimbs/features/rapid/domain/rapid_match_service.dart';
import 'package:msupperlimbs/features/rapid/motion/utils/rapid_stats_calculator_utils.dart';
import 'package:msupperlimbs/features/rapid/presentation/widgets/rapid_saving_overlay.dart';

class RapidMatchNotifier extends StateNotifier<RapidMatchModel?> {
  final RapidMatchService _matchService;

  RapidMatchNotifier(this._matchService) : super(null);

  Future<void> startMatch({
    required String userId,
    required String sessionId,
    required String gameMode,
    required int totalTime,
    required int imageWidth,
    required int imageHeight,
    required int screenWidth,
    required int screenHeight,
    String? selectedHand,
    String? visualizationType,
    Map<String, dynamic>? settingsData,
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
      selectedHand: selectedHand,
      visualizationType: visualizationType,
      settingsData: settingsData,
    );
    state = match;
  }

  Future<void> finalizeMatch({
    required List<Map<String, dynamic>> poseData,
    required List<Map<String, dynamic>> tapLogs,
    required List<Map<String, dynamic>> pulseStateLogs,
    Function(SavingPhase phase, double progress)? onProgress,
    Map<String, dynamic>? additionalData,
  }) async {
    if (state == null) return;

    try {
      final match = state!;
      debugPrint('[MATCH STATE] Received data for finalization:');
      debugPrint('  - Pose data: ${poseData.length} entries');
      debugPrint('  - Tap logs: ${tapLogs.length} entries');
      debugPrint('  - Pulse state logs: ${pulseStateLogs.length} entries');
      
      // Save pose data in chunks (filtered by selected hand)
      onProgress?.call(SavingPhase.savingPoseData, 0.0);
      await _savePoseDataInChunks(poseData, match, onProgress);
      onProgress?.call(SavingPhase.savingPoseData, 1.0);
      
      // Save tap data in chunks if large
      onProgress?.call(SavingPhase.savingTapData, 0.0);
      if (tapLogs.isNotEmpty) {
        await _saveTapDataInChunks(tapLogs, match);
      } else {
        debugPrint('[MATCH STATE] No tap data to save');
      }
      onProgress?.call(SavingPhase.savingTapData, 1.0);
      
      // Save pulse state data in chunks if large
      onProgress?.call(SavingPhase.savingPulseStateData, 0.0);
      if (pulseStateLogs.isNotEmpty) {
        await _savePulseStateDataInChunks(pulseStateLogs, match);
      } else {
        debugPrint('[MATCH STATE] No pulse state data to save');
      }
      onProgress?.call(SavingPhase.savingPulseStateData, 1.0);
      
      // Calculate match statistics
      onProgress?.call(SavingPhase.calculatingStats, 0.0);
      final matchStats = _calculateMatchStats(tapLogs, pulseStateLogs, match);
      onProgress?.call(SavingPhase.calculatingStats, 1.0);
      
      // Update match with statistics
      onProgress?.call(SavingPhase.updatingMatch, 0.0);
      final updatedMatch = match.copyWith(
        tapCount: matchStats['tapCount'] as int?,
        avgTapFrequency: matchStats['avgTapFrequency'] as double?,
        maxTapFrequency: matchStats['maxTapFrequency'] as double?,
        minTapFrequency: matchStats['minTapFrequency'] as double?,
        tapFrequencyCV: matchStats['tapFrequencyCV'] as double?,
        avgPulseHeight: matchStats['avgPulseHeight'] as double?,
        maxPulseHeight: matchStats['maxPulseHeight'] as double?,
        timeInActiveState: matchStats['timeInActiveState'] as double?,
        timeInIdleState: matchStats['timeInIdleState'] as double?,
        timeInUnstableState: matchStats['timeInUnstableState'] as double?,
        timeInFlatlineState: matchStats['timeInFlatlineState'] as double?,
        isValidMatch: matchStats['isValidMatch'] as bool?,
        minTapsRequired: matchStats['minTapsRequired'] as int?,
        minTimeRequired: matchStats['minTimeRequired'] as int?,
      );
      
      await _matchService.updateMatch(updatedMatch);
      state = updatedMatch;
      onProgress?.call(SavingPhase.updatingMatch, 1.0);
      
      debugPrint('[RAPID MATCH] Match finalized successfully');
      
    } catch (e, stack) {
      debugPrint('[ERROR] Failed to finalize rapid match: $e');
      debugPrint(stack.toString());
      rethrow;
    }
  }

  Future<void> _savePoseDataInChunks(
    List<Map<String, dynamic>> poseData,
    RapidMatchModel match,
    Function(SavingPhase phase, double progress)? onProgress,
  ) async {
    const int chunkSize = 500;
    List<List<Map<String, dynamic>>> poseChunks = [];
    
    for (int i = 0; i < poseData.length; i += chunkSize) {
      poseChunks.add(poseData.sublist(i, (i + chunkSize).clamp(0, poseData.length)));
    }

    for (int i = 0; i < poseChunks.length; i++) {
      final chunkId = 'chunk_$i';
      final chunkJson = jsonEncode({'pose_data': poseChunks[i]});
      
      await _matchService.savePoseData(
        userId: match.userId,
        sessionId: match.sessionId,
        matchId: match.matchId,
        poseDataJson: chunkJson,
        chunkId: chunkId,
      );
      
      if (onProgress != null) {
        final progress = (i + 1) / poseChunks.length;
        onProgress(SavingPhase.savingPoseData, progress);
      }
    }
  }

  Future<void> _saveTapDataInChunks(
    List<Map<String, dynamic>> tapLogs,
    RapidMatchModel match,
  ) async {
    const int maxTapsPerChunk = 500;
    final chunks = <List<Map<String, dynamic>>>[];
    
    // Always save in chunks for consistency
    for (int i = 0; i < tapLogs.length; i += maxTapsPerChunk) {
      chunks.add(tapLogs.sublist(i, (i + maxTapsPerChunk).clamp(0, tapLogs.length)));
    }
    
    for (int i = 0; i < chunks.length; i++) {
      final chunkJson = jsonEncode({'tap_data': chunks[i]});
      final chunkId = 'chunk_$i';
      debugPrint('[MATCH STATE] Saving tap data chunk $i: ${chunkJson.length} bytes');
      await _matchService.saveTapDataChunk(match, chunkJson, chunkId);
    }
  }

  Future<void> _savePulseStateDataInChunks(
    List<Map<String, dynamic>> pulseStateLogs,
    RapidMatchModel match,
  ) async {
    const int maxStatesPerChunk = 500;
    final chunks = <List<Map<String, dynamic>>>[];
    
    // Always save in chunks for consistency
    for (int i = 0; i < pulseStateLogs.length; i += maxStatesPerChunk) {
      chunks.add(pulseStateLogs.sublist(i, (i + maxStatesPerChunk).clamp(0, pulseStateLogs.length)));
    }
    
    for (int i = 0; i < chunks.length; i++) {
      final chunkJson = jsonEncode({'pulse_state_data': chunks[i]});
      final chunkId = 'chunk_$i';
      debugPrint('[MATCH STATE] Saving pulse state data chunk $i: ${chunkJson.length} bytes');
      await _matchService.savePulseStateDataChunk(match, chunkJson, chunkId);
    }
  }

  Map<String, dynamic> _calculateMatchStats(
    List<Map<String, dynamic>> tapLogs,
    List<Map<String, dynamic>> pulseStateLogs,
    RapidMatchModel match,
  ) {
    return RapidStatsCalculator.calculateMatchStats(
      tapLogs: tapLogs,
      pulseStateLogs: pulseStateLogs,
      match: match,
    );
  }
}

final rapidMatchStateProvider =
    StateNotifierProvider<RapidMatchNotifier, RapidMatchModel?>((ref) {
  return RapidMatchNotifier(
    ref.read(rapidMatchServiceProvider),
  );
});
