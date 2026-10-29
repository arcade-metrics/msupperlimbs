import 'dart:async';

import 'package:msupperlimbs/core/network/api_client.dart';

/// Game, preset and level a player's matches of one game are created in.
class GameLevel {
  const GameLevel({
    required this.gameId,
    required this.presetId,
    required this.levelId,
  });

  final String gameId;
  final String presetId;
  final String levelId;
}

class CreatedMatch {
  const CreatedMatch({required this.id, required this.sessionId});

  final String id;
  final String sessionId;
}

/// ciatec-core routes of an MS Upper Limbs match (`MSUPPERLIMBS-API.md`).
///
/// The msupperlimbs routes (`/{slug}/matches/…`) are camelCase; the shared
/// ones (`/sessions/…`, `/matches/…`) are snake_case.
class MatchApi {
  MatchApi(this._api);

  final ApiClient _api;
  final _levels = <String, Future<GameLevel>>{};

  /// Resolved once per app run and game; a failure is not cached.
  Future<GameLevel> gameLevel(String accessToken, String slug) {
    final cached = _levels[slug];
    if (cached != null) return cached;
    final resolving = _resolveLevel(accessToken, slug);
    _levels[slug] = resolving;
    unawaited(
      resolving.then<void>((_) {}, onError: (Object _) => _levels.remove(slug)),
    );
    return resolving;
  }

  Future<GameLevel> _resolveLevel(String accessToken, String slug) async {
    final catalog = await _api.getJson(
      '/catalog/games',
      accessToken: accessToken,
    );
    final games = (catalog['games'] as List).cast<Map<String, dynamic>>();
    final game = games.where((g) => g['slug'] == slug).firstOrNull;
    if (game == null) throw StateError('Game $slug is not in the catalog');
    final gameId = game['id'] as String;
    final assigned = await _api.getJson(
      '/matches/preset?game_id=$gameId',
      accessToken: accessToken,
    );
    return GameLevel(
      gameId: gameId,
      presetId: (assigned['preset'] as Map<String, dynamic>)['id'] as String,
      levelId: assigned['current_level_id'] as String,
    );
  }

  /// Not idempotent: a retry could open a second match.
  Future<CreatedMatch> createMatch(
    String accessToken, {
    required GameLevel level,
    String? calibrationRunId,
  }) async {
    final json = await _api.postJson(
      '/sessions/matches',
      accessToken: accessToken,
      body: {
        'game_id': level.gameId,
        'level_id': level.levelId,
        'calibration_run_id': ?calibrationRunId,
      },
    );
    return CreatedMatch(
      id: json['id'] as String,
      sessionId: json['session_id'] as String,
    );
  }

  Future<void> context(
    String accessToken,
    String slug,
    String matchId,
    Map<String, dynamic> body,
  ) => _api.postJson(
    '/$slug/matches/$matchId/context',
    accessToken: accessToken,
    body: body,
  );

  Future<void> pose(
    String accessToken,
    String slug,
    String matchId,
    Map<String, dynamic> chunk,
  ) => _api.postJson(
    '/$slug/matches/$matchId/telemetry/pose',
    accessToken: accessToken,
    body: chunk,
  );

  Future<void> events(
    String accessToken,
    String slug,
    String matchId,
    Map<String, dynamic> batch,
  ) => _api.postJson(
    '/$slug/matches/$matchId/events',
    accessToken: accessToken,
    body: batch,
  );

  Future<void> metrics(
    String accessToken,
    String slug,
    String matchId,
    Map<String, dynamic> body,
  ) => _api.postJson(
    '/$slug/matches/$matchId/metrics',
    accessToken: accessToken,
    body: body,
  );

  /// Same [idempotencyKey] and body on a retry → 200 instead of 409.
  Future<void> finish(
    String accessToken,
    String matchId,
    Map<String, dynamic> body, {
    required String idempotencyKey,
  }) => _api.postJson(
    '/matches/$matchId/finish',
    accessToken: accessToken,
    body: body,
    headers: {'Idempotency-Key': idempotencyKey},
  );

  Future<void> endSession(
    String accessToken,
    String sessionId, {
    bool cancelled = false,
  }) => _api.postJson(
    '/sessions/$sessionId/end?cancelled=$cancelled',
    accessToken: accessToken,
  );
}
