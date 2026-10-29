import 'package:msupperlimbs/features/match/application/match_flow.dart';
import 'package:msupperlimbs/features/match/application/match_uploader.dart';
import 'package:msupperlimbs/features/match/data/match_api.dart';
import 'package:msupperlimbs/features/rapid/domain/rapid_game_result.dart';

/// A Rapid match on ciatec-core ([MatchFlow] for `msupperlimbs-rapid`).
class RapidMatchFlow {
  RapidMatchFlow(
    MatchApi api,
    String? Function() accessToken, {
    MatchUploader Function()? uploader,
  }) : _flow = MatchFlow(api, accessToken, slug: slug, uploader: uploader);

  static const slug = 'msupperlimbs-rapid';

  final MatchFlow _flow;

  void start(Map<String, dynamic> context) => _flow.start(context);

  Future<RapidGameResult> complete(
    RapidGameResult result,
    Map<String, dynamic> context,
  ) async {
    final match = await _flow.complete(
      MatchUpload(
        poseFrames: result.poseSamples,
        events: result.events,
        metrics: result.toMetricsJson(),
        score: result.tapCount,
        durationMs: result.durationMs,
      ),
      context,
    );
    return result.copyWith(
      matchId: match.id,
      sessionId: match.sessionId,
      clearSaveError: true,
    );
  }

  Future<void> cancel({required int score, required int durationMs}) =>
      _flow.cancel(score: score, durationMs: durationMs);
}
