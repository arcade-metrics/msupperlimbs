import 'package:msupperlimbs/features/fnose/domain/fnose_game_engine.dart';
import 'package:msupperlimbs/features/match/application/match_flow.dart';
import 'package:msupperlimbs/features/match/application/match_uploader.dart';
import 'package:msupperlimbs/features/match/data/match_api.dart';

/// An FNose match on ciatec-core ([MatchFlow] for `msupperlimbs-fnose`),
/// linked to the setup calibration run when there is one.
class FnoseMatchFlow {
  FnoseMatchFlow(
    MatchApi api,
    String? Function() accessToken, {
    MatchUploader Function()? uploader,
  }) : _flow = MatchFlow(api, accessToken, slug: slug, uploader: uploader);

  static const slug = 'msupperlimbs-fnose';

  final MatchFlow _flow;

  /// [calibrationRunId] is the upload of the setup that just finished.
  void start(
    Map<String, dynamic> context, {
    Future<String?>? calibrationRunId,
  }) => _flow.start(context, calibrationRunId: calibrationRunId);

  Future<FnoseGameResult> complete(
    FnoseGameResult result,
    Map<String, dynamic> context,
  ) async {
    final match = await _flow.complete(
      MatchUpload(
        poseFrames: result.poseSamples,
        events: result.events,
        metrics: result.toMetricsJson(),
        score: result.totalSparks,
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
