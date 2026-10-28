import 'package:flutter_riverpod/flutter_riverpod.dart';

final matchProvider = StateProvider<MatchState?>((ref) => null);

class MatchState {
  final String matchId;
  final int totalTime;
  final bool showLandmarks;
  final int score;

  MatchState({
    required this.matchId,
    required this.totalTime,
    required this.showLandmarks,
    this.score = 0,
  });

  MatchState copyWith({int? score}) {
    return MatchState(
      matchId: matchId,
      totalTime: totalTime,
      showLandmarks: showLandmarks,
      score: score ?? this.score,
    );
  }
}
