import 'dart:async';
import 'dart:math';

import 'package:msupperlimbs/features/match/application/match_uploader.dart';
import 'package:msupperlimbs/features/match/data/match_api.dart';
import 'package:msupperlimbs/features/match/domain/match_context.dart';
import 'package:msupperlimbs/features/rapid/domain/rapid_game_result.dart';

/// One Rapid match on ciatec-core, from the start of play to the finish:
/// create the match → context → pose chunks → event batches → metrics →
/// finish (idempotency key, `upload_stats`) → end of the play session.
class RapidMatchFlow {
  RapidMatchFlow(
    this._api,
    this._accessToken, {
    MatchUploader Function()? uploader,
  }) : _newUploader = uploader ?? MatchUploader.new;

  static const slug = 'msupperlimbs-rapid';

  final MatchApi _api;
  final String? Function() _accessToken;
  final MatchUploader Function() _newUploader;
  final _finishKey = newIdempotencyKey();

  Future<CreatedMatch>? _match;
  bool _contextSent = false;
  bool _closed = false;

  String get _token {
    final token = _accessToken();
    if (token == null) throw StateError('Not authenticated');
    return token;
  }

  /// At the start of play: the server freezes the settings and starts its
  /// clock here. Runs in the background; [complete] waits for it.
  void start(Map<String, dynamic> context) {
    if (_match != null) return;
    final opening = _open(context);
    _match = opening;
    unawaited(opening.then<void>((_) {}, onError: (Object _) {}));
  }

  Future<CreatedMatch> _open(Map<String, dynamic> context) async {
    final level = await _api.gameLevel(_token, slug);
    final match = await _api.createMatch(_token, level: level);
    try {
      await _api.context(_token, slug, match.id, context);
      _contextSent = true;
    } catch (_) {
      // Sent again by [complete]; the first write wins on the server.
    }
    return match;
  }

  /// Uploads [result] and finishes the match. Throws if anything fails;
  /// every step is safe to repeat.
  Future<RapidGameResult> complete(
    RapidGameResult result,
    Map<String, dynamic> context,
  ) async {
    start(context);
    final match = await _match!;
    final up = _newUploader();
    if (!_contextSent) {
      await up.send(
        context,
        () => _api.context(_token, slug, match.id, context),
      );
      _contextSent = true;
    }
    await up.sendPose(
      result.poseSamples,
      (chunk) => _api.pose(_token, slug, match.id, chunk),
    );
    await up.sendEvents(
      result.events,
      (batch) => _api.events(_token, slug, match.id, batch),
    );
    final metrics = result.toMetricsJson();
    await up.send(metrics, () => _api.metrics(_token, slug, match.id, metrics));
    final finish = {
      'score': result.tapCount,
      'duration_ms': max(1, result.durationMs),
      'completed': true,
      'client_meta': buildClientMeta(),
      'extra': {'upload_stats': up.stats.toJson()},
    };
    await up.send(
      finish,
      () => _api.finish(_token, match.id, finish, idempotencyKey: _finishKey),
    );
    _closed = true;
    await _endSession(match, cancelled: false);
    return result.copyWith(
      matchId: match.id,
      sessionId: match.sessionId,
      clearSaveError: true,
    );
  }

  /// The player left mid-match: finish it as not completed. Best effort,
  /// never throws; does nothing if the match was never opened or is closed.
  Future<void> cancel({required int score, required int durationMs}) async {
    final opening = _match;
    if (opening == null || _closed) return;
    _closed = true;
    try {
      final match = await opening;
      await _api.finish(_token, match.id, {
        'score': score,
        'duration_ms': max(1, durationMs),
        'completed': false,
        'client_meta': buildClientMeta(),
      }, idempotencyKey: _finishKey);
      await _endSession(match, cancelled: true);
    } catch (_) {
      // Left open on the server; nothing the player can do about it here.
    }
  }

  Future<void> _endSession(
    CreatedMatch match, {
    required bool cancelled,
  }) async {
    try {
      await _api.endSession(_token, match.sessionId, cancelled: cancelled);
    } catch (_) {
      // The match is already finished; an open session is harmless.
    }
  }
}
